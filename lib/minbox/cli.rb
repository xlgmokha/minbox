# frozen_string_literal: true

require "mail"
require "net/smtp"
require "openssl"
require "thor"

require "minbox"

module Minbox
  module Cli
    class Application < Thor
      package_name "minbox"

      method_option :from, type: :string, default: "me@example.org"
      method_option :to, type: :array, default: ["them@example.org"]
      method_option :subject, type: :string, default: "#{Time.now} This is a test message."
      method_option :body, type: :string, default: "#{Time.now} This is a test message."
      desc "send <HOST> <PORT>", "Send mail to SMTP server"
      def send(host = "localhost", port = 25)
        Net::SMTP.start(host, port) do |smtp|
          smtp.debug_output = Minbox.logger
          smtp.send_message(create_mail(options).to_s, options[:from], options[:to])
        end
      end

      method_option :output, type: :array, default: ["stdout"]
      method_option :tls, type: :boolean, default: false
      desc "server <HOST> <PORT>", "SMTP server"
      def server(host = "localhost", port = "25")
        publisher = Publisher.from(options[:output])
        server = Server.new(host: host, port: port, tls: options[:tls])
        server.listen! do |mail|
          publisher.publish(mail)
        end
      end

      desc "version", "Display the current version"
      def version
        say Minbox::VERSION
      end

      private

      def create_mail(options)
        Mail.new do |x|
          x.to = options[:to]
          x.from = options[:from]
          x.subject = options[:subject]
          x.body = STDIN.tty? ? options[:body] : $stdin.read
        end
      end
    end
  end
end
