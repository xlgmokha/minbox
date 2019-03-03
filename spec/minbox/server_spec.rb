require 'net/smtp'

RSpec.describe Minbox::Server do
  subject { described_class.new }

  describe "#handle" do
    let(:publisher) { ->(mail) { inbox << mail } }
    let(:inbox) { [] }
    let(:server) { described_class.new(host, port) }
    let(:host) { 'localhost' }
    let(:port) { (9000..9999).to_a.sample }

    before :example do
      server_thread = Thread.new do
        server.listen! do |mail|
          publisher.publish(mail)
        end
      end
      server_thread.join(5)
    end

    after :example do
      server.shutdown!
    end

    context "when handling a simple client" do
      let(:mail) do
        Mail.new do
          from 'Your Name <me@example.org>'
          to 'Destination Address <them@example.com>'
          subject 'test message'
          body "#{Time.now} This is a test message."
        end
      end

      specify do
        Net::SMTP.start(host, port) do |smtp|
          smtp.send_message(mail.to_s, 'me@example.org', 'them@example.com')
        end
      end
    end
  end
end
