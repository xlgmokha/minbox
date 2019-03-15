# frozen_string_literal: true

module Minbox
  class Command
    attr_reader :regex

    def initialize(regex)
      @regex = regex
    end

    def matches?(line)
      line.match?(regex)
    end
  end

  class Ehlo < Command
    def initialize
      super(/^EHLO/i)
    end

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

  class Helo < Command
    def initialize
      super(/^HELO/i)
    end

    def run(client, line)
      _ehlo, _client_domain = line.split(' ')
      client.write "250 #{client.server.host}"
    end
  end

  class Noop < Command
    def run(client, line)
      client.write '250 OK'
    end
  end

  class Quit < Command
    def initialize
      super(/^QUIT/i)
    end

    def run(client, line)
      client.write '221 Bye'
      client.close
    end
  end

  class Data < Command
    def initialize
      super(/^DATA/i)
    end

    def run(client, line, &block)
      client.write '354 End data with <CR><LF>.<CR><LF>'
      body = []
      line = client.read
      until line.nil? || line.match(/^\.\r\n$/)
        body << line
        line = client.read
      end
      client.write '250 OK'
      block.call(Mail.new(body.join)) unless body.empty?
    end
  end

  class StartTls < Command
    def initialize
      super(/^STARTTLS/i)
    end

    def run(client, line)
      client.write '220 Ready to start TLS'
      client.secure_socket!
    end
  end

  class AuthPlain < Command
    def initialize
      super(/^AUTH PLAIN/i)
    end

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

  class AuthLogin < Command
    def initialize
      super(/^AUTH LOGIN/i)
    end

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
    def matches?(line)
      true
    end

    def run(client, line)
      client.logger.error(line)
      client.write '502 Invalid/unsupported command'
    end
  end

  class Client
    attr_reader :server, :socket, :logger
    attr_reader :commands

    def initialize(server, socket, logger)
      @server = server
      @logger = logger
      @socket = socket
      @commands = [
        Ehlo.new,
        Helo.new,
        Noop.new(/^MAIL FROM/i),
        Noop.new(/^RCPT TO/i),
        Noop.new(/^RSET/i),
        Noop.new(/^NOOP/i),
        Quit.new,
        Data.new,
        StartTls.new,
        AuthPlain.new,
        AuthLogin.new
      ]
    end

    def handle(&block)
      write "220 #{server.host} ESMTP"
      while connected? && (line = read)
        command = commands.find { |x| x.matches?(line) } || Unsupported.new
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
