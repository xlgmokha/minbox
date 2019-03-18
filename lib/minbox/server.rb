# frozen_string_literal: true

module Minbox
  class Server
    SUBJECT = '/C=CA/ST=AB/L=Calgary/O=minbox/OU=development/CN=minbox'
    attr_reader :host, :logger, :key, :server

    def initialize(host: 'localhost', port: 25, tls: false, logger: Minbox.logger, thread_pool: Concurrent::CachedThreadPool.new)
      @host = host
      @logger = logger
      @tls = tls
      @key = OpenSSL::PKey::RSA.new(2048)
      logger.debug("Starting server on port #{port}...")
      @server = TCPServer.new(port.to_i)
      @thread_pool = thread_pool
    end

    def tls?
      @tls
    end

    def listen!(&block)
      @server = upgrade(@server) if tls?
      logger.debug('Server started!')

      loop do
        handle(server.accept, &block)
      rescue StandardError => error
        logger.error(error)
      end
    end

    def handle(socket, &block)
      @thread_pool.post do
        logger.debug("client connected: #{socket.inspect}")
        Client.new(self, socket, logger).handle(&block)
      end
    end

    def shutdown!
      server&.close
    end

    def ssl_context
      @ssl_context ||=
        begin
          ssl_context = OpenSSL::SSL::SSLContext.new
          ssl_context.cert = certificate_for(key)
          ssl_context.key = key
          ssl_context.ssl_version = :TLSv1_2
          ssl_context
        end
    end

    private

    def upgrade(tcp_server)
      server = OpenSSL::SSL::SSLServer.new(tcp_server, ssl_context)
      server.start_immediately = true
      server
    end

    def certificate_for(private_key, subject = SUBJECT)
      certificate = OpenSSL::X509::Certificate.new
      certificate.subject = certificate.issuer = OpenSSL::X509::Name.parse(subject)
      certificate.not_before = Time.now
      certificate.not_after = certificate.not_before + 30 * 24 * 60 * 60 # 30 days
      certificate.public_key = private_key.public_key
      certificate.serial = 1
      certificate.version = 2
      apply_ski_extension_to(certificate)
      certificate.sign(private_key, OpenSSL::Digest::SHA256.new)
      certificate
    end

    def apply_ski_extension_to(certificate)
      extensions = OpenSSL::X509::ExtensionFactory.new
      extensions.subject_certificate =
        extensions.issuer_certificate = certificate
      [
        ['subjectKeyIdentifier', 'hash', false],
        ['keyUsage', 'keyEncipherment,digitalSignature', true],
      ].each do |x|
        certificate.add_extension(extensions.create_extension(x[0], x[1], x[2]))
      end
    end
  end
end
