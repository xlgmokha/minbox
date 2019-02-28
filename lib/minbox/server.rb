module Minbox
  class Server
    attr_reader :host, :port, :logger

    def initialize(host, port, logger = Minbox.logger)
      @host = host
      @port = port
      @logger = logger
    end

    def listen!
      logger.debug("Starting server...")
      server = TCPServer.new(port.to_i)
      logger.debug("Server started!")
      loop do
        yield handle(server.accept)
      rescue StandardError => error
        logger.error(error)
      end
    end

    def handle(client)
      mail = { headers: [], body: [] }

      client.puts "220"
      ehlo, _client_domain = client.gets.split(" ")

      if ["HELO", "EHLO"].include?(ehlo)
        client.puts "250-#{host}"
        client.puts "250 OK"
      else
        puts 'Ooops...'
        client.close
        return
      end

      data = client.gets
      until data.start_with?("DATA")
        mail[:headers] << data
        client.puts "250 OK"
        data = client.gets
      end
      client.puts "354 End data with <CR><LF>.<CR><LF>"

      data = client.gets
      until data.match(/^\.\r\n$/)
        mail[:body] << data
        data = client.gets
      end

      client.puts "250 OK"
      client.puts "221 Bye"
      client.close

      Mail.new(mail[:body].join)
    end
  end
end
