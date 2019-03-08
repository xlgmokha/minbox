require 'thor'
require 'mail'

require 'minbox'
require 'minbox/secure_server'

module Minbox
  module Cli
    class Application < Thor
      package_name "minbox"

      desc 'client <HOST> <PORT>', 'SMTP client'
      def client(host = 'localhost', port = 25)
        mail = Mail.new do
          from 'Your Name <me@example.org>'
          to 'Destination Address <them@example.com>'
          subject 'test message'
          body "#{Time.now} This is a test message."
        end
        require 'net/smtp'
        smtp = Net::SMTP.new(host, port)
        smtp.enable_starttls
        smtp.start do |smtp|
          smtp.send_message(mail.to_s, 'me+1@example.org', 'them+1@example.com')
          smtp.send_message(mail.to_s, 'me+2@example.org', 'them+2@example.com')
        end
      end

      method_option :output, type: :array, default: ['stdout']
      desc 'server <HOST> <PORT>', 'SMTP server'
      def server(host = 'localhost', port = '25')
        publisher = Publisher.from(options[:output])
        Server.new(host, port).listen! do |mail|
          publisher.publish(mail)
        end
      end

      method_option :output, type: :array, default: ['stdout']
      desc 'secure_server <HOST> <PORT>', 'SMTP secure server'
      def secure_server(host = 'localhost', port = '25')
        # publisher = Publisher.from(options[:output])
        SecureServer.new(port).listen do |socket|
          puts "HELLLLLLLOOOOO"
          read_line = socket.gets
          puts read_line
        end
      end

      desc 'version', 'Display the current version'
      def version
        say Minbox::VERSION
      end
    end
  end
end
