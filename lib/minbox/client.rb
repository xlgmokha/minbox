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

      line = socket.gets
      process(line, socket)

      data = socket.gets
      until data.start_with?("DATA")
        mail[:headers] << data
        socket.puts "250 OK"
        data = socket.gets
      end
      socket.puts "354 End data with <CR><LF>.<CR><LF>"

      data = socket.gets
      until data.match(/^\.\r\n$/)
        mail[:body] << data
        data = socket.gets
      end

      socket.puts "250 OK"
      socket.puts "221 Bye"
      socket.close

      Mail.new(mail[:body].join)
    end

    private

    def process(line, socket)
      case line
      when /^EHLO/i then ehlo(line, socket)
      when /^HELO/i then helo(line, socket)
      else
        socket.puts('502 Invalid/unsupported command')
      end
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
