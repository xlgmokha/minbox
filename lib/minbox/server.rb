module Minbox
  class Server
    attr_reader :host, :port, :logger

    def initialize(host = 'localhost', port = 25, logger = Minbox.logger)
      @host = host
      @port = port
      @logger = logger
    end

    def listen!(&block)
      logger.debug("Starting server on port #{port}...")
      @server = TCPServer.new(port.to_i)
      #@server = upgrade(@server)
      logger.debug("Server started!")

      loop do
        handle(@server.accept, &block)
      rescue StandardError => error
        logger.error(error)
      end
    end

    def handle(socket, &block)
      logger.debug("client connected: #{socket.inspect}")
      Client.new(host, socket, logger).handle(&block)
    end

    def shutdown!
      @server&.close
    end

    private

    def upgrade(tcp_server)
      server = OpenSSL::SSL::SSLServer.new(tcp_server, ssl_context)
      server.start_immediately = true
      server
    end

    def certificate_for(private_key)
      certificate = OpenSSL::X509::Certificate.new
      subject = '/C=CA/ST=AB/L=Calgary/O=minbox/OU=development/CN=minbox'
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
      extensions.subject_certificate = certificate
      extensions.issuer_certificate = certificate
      certificate.add_extension(
        extensions.create_extension('subjectKeyIdentifier', 'hash', false)
      )
      certificate.add_extension(
        extensions.create_extension('keyUsage', 'keyEncipherment,digitalSignature', true)
      )
    end

    def ssl_context(key = OpenSSL::PKey::RSA.new(2048))
      ssl_context = OpenSSL::SSL::SSLContext.new
      ssl_context.cert = certificate_for(key)
      ssl_context.key = key
      ssl_context.ssl_version = :SSLv23
      ssl_context.renegotiation_cb = lambda do |ssl|
        puts "Negotiating..."
      end
      ssl_context
    end
  end
end
