# frozen_string_literal: true

module Minbox
  class Ehlo
    def run(client, line)
      _ehlo, _client_domain = line.split(' ')
      client.write "250-#{client.server.host} offers a warm hug of welcome"
      client.write '250-8BITMIME'
      client.write '250-ENHANCEDSTATUSCODES'
      # client.write "250 STARTTLS"
      client.write '250-AUTH PLAIN LOGIN'
      client.write '250 OK'
    end
  end

  class Helo
    def run(client, line)
      _ehlo, _client_domain = line.split(' ')
      client.write "250 #{client.server.host}"
    end
  end

  class Noop
    def run(client, _line)
      client.write '250 OK'
    end
  end

  class Quit
    def run(client, _line)
      client.write '221 Bye'
      client.close
    end
  end

  class Data
    def run(client, _line)
      client.write '354 End data with <CR><LF>.<CR><LF>'
      body = []
      line = client.read
      until line.nil? || line.match(/^\.\r\n$/)
        body << line
        line = client.read
      end
      client.write '250 OK'
      yield(Mail.new(body.join)) unless body.empty?
    end
  end

  class StartTls
    def run(client, _line)
      client.write '220 Ready to start TLS'
      client.secure_socket!
    end
  end

  class AuthPlain
    def run(client, line)
      data = line.gsub(/AUTH PLAIN ?/i, '')
      if data.strip == ''
        client.write '334'
        data = client.read
      end
      parts = Base64.decode64(data).split("\0")
      username = parts[-2]
      password = parts[-1]
      client.authenticate(username, password)
    end
  end

  class AuthLogin
    def run(client, line)
      username = line.gsub!(/AUTH LOGIN ?/i, '')
      if username.strip == ''
        client.write '334 VXNlcm5hbWU6'
        username = client.read
      end
      client.write '334 UGFzc3dvcmQ6'
      password = Base64.decode64(client.read)
      client.authenticate(username, password)
    end
  end

  class Unsupported
    def run(client, line)
      client.logger.error(line)
      client.write '502 Invalid/unsupported command'
    end
  end

  class Client
    COMMANDS = Hashie::Rash.new(
      /^AUTH LOGIN/i => AuthLogin.new,
      /^AUTH PLAIN/i => AuthPlain.new,
      /^DATA/i => Data.new,
      /^EHLO/i => Ehlo.new,
      /^HELO/i => Helo.new,
      /^MAIL FROM/i => Noop.new,
      /^NOOP/i => Noop.new,
      /^QUIT/i => Quit.new,
      /^RCPT TO/i => Noop.new,
      /^RSET/i => Noop.new,
      /^STARTTLS/i => StartTls.new,
    )
    UNSUPPORTED = Unsupported.new
    attr_reader :server, :socket, :logger

    def initialize(server, socket, logger)
      @server = server
      @logger = logger
      @socket = socket
    end

    def handle(&block)
      write "220 #{server.host} ESMTP"
      while connected? && (line = read)
        command = COMMANDS.fetch(line, UNSUPPORTED)
        command.run(self, line, &block)
      end
      close
    rescue Errno::ECONNRESET, Errno::EPIPE => error
      logger.error(error)
      close
    end

    def secure_socket!
      socket = OpenSSL::SSL::SSLSocket.new(@socket, server.ssl_context)
      socket.sync_close = true
      @socket = socket.accept
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

    def authenticate(username, password)
      logger.debug("#{username}:#{password}")
      return write '535 Authenticated failed - protocol error' unless username && password

      write '235 2.7.0 Authentication successful'
    end
  end
end
