require 'thor'

require 'minbox'

module Minbox
  module Cli
    class Application < Thor
      package_name "minbox"

      desc 'client <HOST> <PORT>', 'SMTP client'
      def client(host = 'localhost', port = 25)
        mail = <<END_OF_MESSAGE
From: Your Name <me@example.org>
To: Destination Address <them@example.com>
Subject: test message
Date: Sat, 23 Jun 2001 16:26:43 +0900
Message-Id: <unique.message.id.string@example.com>

This is a test message.
END_OF_MESSAGE

        require 'net/smtp'
        Net::SMTP.start(host, port) do |smtp|
          smtp.send_message(mail, 'me@example.org', 'them@example.com')
        end       
      end

      desc 'server <HOST> <PORT>', 'SMTP server'
      def server(host = 'localhost', port = '25')
        require 'socket'

        server = TCPServer.new(port.to_i)
        loop do
          client = server.accept
          mail = { headers: [], body: [] }

          client.puts "220"
          ehlo, client_domain = client.gets.split(" ")
          puts ehlo, client_domain

          client.puts "250-#{host}"
          client.puts "250-8BITMIME"
          client.puts "250-SIZE 10485760"
          client.puts "250-AUTH PLAIN LOGIN"
          client.puts "250 OK"

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
        end
      end

      desc 'version', 'Display the current version'
      def version
        say Minbox::VERSION
      end
    end
  end
end
