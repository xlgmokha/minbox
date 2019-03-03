module Minbox
  class Client
    attr_reader :host, :socket, :logger

    def initialize(host, socket, logger)
      @host = host
      @logger = logger
      @body = []
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
        when /^DATA/i then data(line)
        when /^QUIT/i then quit
        when /^STARTTLS/i then start_tls
        when /^RSET/i then reset
        when /^NOOP/i then noop
        else
          logger.error(line)
          write '502 Invalid/unsupported command'
        end
      end
      block.call(Mail.new(@body.join))
    end

    private

    def quit
      write "221 Bye"
      close
    end

    def data(line)
      write "354 End data with <CR><LF>.<CR><LF>"
      line = read
      until line.nil? || line.match(/^\.\r\n$/)
        @body << line
        line = read
      end
      write "250 OK"
      quit
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
      write "250 OK"
    end

    def helo(line)
      _ehlo, _client_domain = line.split(" ")
      write "250 #{host}"
    end

    def start_tls
      write "502 TLS not available"
    end

    def reset
      @body = []
      write '250 OK'
    end

    def noop
      write '250 OK'
    end

    def write(message)
      logger.debug message
      socket.puts message
    end

    def read
      line = socket.gets
      logger.debug line
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
