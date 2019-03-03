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
      ehlo, _client_domain = socket.gets.split(" ")

      if ["HELO", "EHLO"].include?(ehlo)
        socket.puts "250-#{host}"
        socket.puts "250 OK"
      else
        logger.error 'Ooops...'
        socket.close
        return
      end

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
  end
end
