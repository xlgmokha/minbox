module Minbox
  class Client
    attr_reader :host, :socket, :logger

    def initialize(host, socket, logger)
      @host = host
      @logger = logger
      @mail = { headers: [], body: [] }
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
        else
          logger.error(line)
          socket.puts('502 Invalid/unsupported command')
        end
      end
      Mail.new(@mail[:body].join)
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
        @mail[:body] << line
        line = socket.gets
      end
      socket.puts "250 OK"
      quit
    end

    def rcpt_to(line)
      @mail[:headers] << line
      socket.puts "250 OK"
    end

    def mail_from(line)
      @mail[:headers] << line
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
  end
end
