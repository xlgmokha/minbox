require 'thor'
require 'mail'

require 'minbox'

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
        Net::SMTP.start(host, port) do |smtp|
          smtp.send_message(mail.to_s, 'me@example.org', 'them@example.com')
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

      desc 'version', 'Display the current version'
      def version
        say Minbox::VERSION
      end

      private

      def publishers_for(output)
        publisher = Publisher.new
        output.each do |x|
          case x
          when 'stdout'
            publisher.add(LogPublisher.new)
          when 'redis'
            publisher.add(RedisPublisher.new)
          when 'file'
            publisher.add(FilePublisher.new)
          end
        end
        publisher
      end
    end
  end
end
