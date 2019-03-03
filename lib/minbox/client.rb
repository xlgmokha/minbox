module Minbox
  class Client
    attr_reader :host, :socket, :logger

    def initialize(host, socket, logger)
      @host = host
      @logger = logger
      @body = []
      @socket = socket
    end

    def mail_message
      socket.puts "220"
      while socket && (line = socket.gets)
        case line
        when /^EHLO/i then ehlo(line)
        when /^HELO/i then helo(line)
        when /^MAIL FROM/i then mail_from(line)
        when /^RCPT TO/i then rcpt_to(line)
        when /^DATA/i then data(line)
        when /^QUIT/i then quit
        when /^STARTTLS/i then start_tls
        when /^RSET/i then reset
        when /^NOOP/i then noop
        else
          logger.error(line)
          socket.puts('502 Invalid/unsupported command')
        end
      end
      Mail.new(@body.join)
    end

    private

    def quit
      socket.puts "221 Bye"
      socket.close
      @socket = nil
    end

    def data(line)
      socket.puts "354 End data with <CR><LF>.<CR><LF>"
      line = socket.gets
      until line.match(/^\.\r\n$/)
        @body << line
        line = socket.gets
      end
      socket.puts "250 OK"
      quit
    end

    def rcpt_to(line)
      socket.puts "250 OK"
    end

    def mail_from(line)
      socket.puts "250 OK"
    end

    def ehlo(line)
      _ehlo, _client_domain = line.split(" ")
      socket.puts "250-#{host}"
      socket.puts "250 OK"
    end

    def helo(line)
      _ehlo, _client_domain = line.split(" ")
      socket.puts "250 #{host}"
    end

    def start_tls
      socket.puts "502 TLS not available"
    end

    def reset
      @body = []
      socket.puts '250 OK'
    end

    def noop
      socket.puts '250 OK'
    end
  end
end
