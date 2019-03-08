module Minbox
  class Client
    attr_reader :host, :socket, :logger

    def initialize(host, socket, logger)
      @host = host
      @logger = logger
      @socket = socket
    end

    def mail_message(&block)
      write "220"
      while connected? && (line = read)
        case line
        when /^EHLO/i then ehlo(line)
        when /^HELO/i then helo(line)
        when /^MAIL FROM/i then mail_from(line)
        when /^RCPT TO/i then rcpt_to(line)
        when /^DATA/i then data(line, &block)
        when /^QUIT/i then quit
        when /^STARTTLS/i then start_tls
        when /^RSET/i then reset
        when /^NOOP/i then noop
        when /^AUTH PLAIN/i then auth_plain(line)
        when /^AUTH LOGIN/i then auth_login(line)
        else
          logger.error(line)
          write '502 Invalid/unsupported command'
        end
      end
    end

    private

    def quit
      write "221 Bye"
      close
      @server.downgrade
    end

    def data(line, &block)
      write "354 End data with <CR><LF>.<CR><LF>"
      body = []
      line = read
      until line.nil? || line.match(/^\.\r\n$/)
        body << line
        line = read
      end
      write "250 OK"
      block.call(Mail.new(body.join))
    end

    def rcpt_to(line)
      write "250 OK"
    end

    def mail_from(line)
      write "250 OK"
    end

    def ehlo(line)
      _ehlo, _client_domain = line.split(" ")
      write "250-#{host}"
      #write "250 AUTH PLAIN LOGIN"
      write "250 STARTTLS"
      write "250 OK"
    end

    def helo(line)
      _ehlo, _client_domain = line.split(" ")
      write "250 #{host}"
    end

    def start_tls
      write "220 Ready to start TLS"
      ssl_context = OpenSSL::SSL::SSLContext.new()
      ssl_context.cert = OpenSSL::X509::Certificate.new(File.open("server.pem"))
      ssl_context.key = OpenSSL::PKey::RSA.new(File.open("server.pem"))
      ssl_context.ssl_version = :SSLv23
      ssl_socket = OpenSSL::SSL::SSLSocket.new(@socket, ssl_context)
      # ssl_socket.sync_close = true
      # ssl_socket.connect
      @socket = ssl_socket
      # write "502 TLS not available"
    end

    def reset
      write '250 OK'
    end

    def noop
      write '250 OK'
    end

    def auth_plain(line)
      data = line.gsub(/AUTH PLAIN ?/i, '')
      if data.strip == ''
        write '334'
        data = read
      end
      parts = Base64.decode64(data).split("\0")
      username, password = parts[-2], parts[-1]
      logger.debug("#{username}:#{password}")
      return write '535 Authenticated failed - protocol error' unless username && password
      write "235 2.7.0 Authentication successful"
    end

    def auth_login(line)
      username = line.gsub!(/AUTH LOGIN ?/i, '')
      if username.strip == ''
        write '334 VXNlcm5hbWU6'
        username = read
        write '334 UGFzc3dvcmQ6'
      else
        write '334 UGFzc3dvcmQ6'
      end
      password = Base64.decode64(read)
      logger.debug("#{username}:#{password}")

      return write '535 Authenticated failed - protocol error' unless username && password
      write "235 2.7.0 Authentication successful"
    end

    def write(message)
      message = "#{message}\r\n"
      logger.debug("S: #{message.inspect}")
      socket.puts message
    end

    def read
      line = socket.gets
      logger.debug("C: #{line.inspect}")
      line
    end

    def close
      socket&.close
      @socket = nil
    end

    def connected?
      @socket
    end
  end
end
