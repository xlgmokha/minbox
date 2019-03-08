module Minbox
  class Server
    attr_reader :host, :port, :logger

    def initialize(host = 'localhost', port = 25, logger = Minbox.logger)
      @host = host
      @port = port
      @logger = logger
    end

    def listen!(&block)
      logger.debug("Starting server on port #{port}...")
      @server = @original_server = TCPServer.new(port.to_i)
      logger.debug("Server started!")

      loop do
        handle(@server.accept, &block)
      rescue StandardError => error
        logger.error(error)
      end
    end

    def handle(socket, &block)
      logger.debug("client connected: #{socket.inspect}")
      Client.new(host, socket, logger).mail_message(&block)
    end

    def shutdown!
      @server&.close
    end
  end
end
