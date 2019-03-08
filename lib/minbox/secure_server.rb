module Minbox
  class SecureServer
    
    def initialize(port)
      server = TCPServer.new(port)
      sslContext = OpenSSL::SSL::SSLContext.new
      sslContext.cert = OpenSSL::X509::Certificate.new(File.open("server.pem"))
      sslContext.key = OpenSSL::PKey::RSA.new(File.open("server.pem"))
      @sslServer = OpenSSL::SSL::SSLServer.new(server, sslContext)
    end

    def listen
      loop do 
        yield @sslServer.accept
      end
    end
  end
end
