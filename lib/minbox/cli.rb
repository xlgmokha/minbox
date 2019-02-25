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

      desc 'version', 'Display the current version'
      def version
        say Minbox::VERSION
      end
    end
  end
end
