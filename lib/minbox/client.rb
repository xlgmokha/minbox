module Minbox
  class Client
    attr_reader :host, :socket, :mail

    def initialize(host, socket)
      @host = host
      @socket = socket
      @mail = { headers: [], body: [] }
    end

    def mail_message
      socket.puts "220"
      while (line = socket.gets)
        process(line, socket)
      end
      socket.close
      Mail.new(mail[:body].join)
    end

    private

    def process(line, socket)
      case line
      when /^EHLO/i then ehlo(line, socket)
      when /^HELO/i then helo(line, socket)
      when /^MAIL FROM/i then mail_from(line, socket)
      when /^RCPT TO/i then rcpt_to(line, socket)
      when /^DATA/i then data(line, socket)
      when /^QUIT/i then quit(line, socket)
      else
        puts "***" * 10
        puts line.inspect
        puts "***" * 10
        socket.puts('502 Invalid/unsupported command')
      end
    end

    def quit(line, socket)
      socket.puts "221 Bye"
    end

    def data(line, socket)
      socket.puts "354 End data with <CR><LF>.<CR><LF>"
      line = socket.gets
      until line.match(/^\.\r\n$/)
        mail[:body] << line
        line = socket.gets
      end
      socket.puts "250 OK"
      quit(line, socket)
    end

    def rcpt_to(line, socket)
      mail[:headers] << line
      socket.puts "250 OK"
    end

    def mail_from(line, socket)
      mail[:headers] << line
      socket.puts "250 OK"
    end

    def ehlo(line, socket)
      _ehlo, _client_domain = line.split(" ")
      socket.puts "250-#{host}"
      socket.puts "250 OK"
    end

    def helo(line, socket)
      _ehlo, _client_domain = line.split(" ")
      socket.puts "250 #{host}"
    end
  end
end
