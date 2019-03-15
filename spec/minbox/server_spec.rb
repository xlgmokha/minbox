# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Minbox::Server do
  describe '#handle' do
    let(:host) { 'localhost' }
    let(:port) { 8080 }

    context 'when handling a simple client' do
      def create_mail(to: Faker::Internet.email, from: Faker::Internet.email)
        Mail.new do |x|
          x.from from
          x.to to
          x.subject 'test message'
          x.body "#{Time.now} This is a test message."
          yield x if block_given?
        end
      end

      context 'when sending a single email' do
        let(:result) do
          Net::SMTP.start(host, port) do |smtp|
            smtp.send_message(create_mail.to_s, Faker::Internet.email, Faker::Internet.email)
          end
        end

        specify { expect(result).to be_success }
        specify { expect(result.status.to_i).to be(250) }
      end

      context 'when sending multiple emails' do
        let(:n) { rand(10) }
        let(:result) do
          Net::SMTP.start(host, port) do |smtp|
            n.times do
              smtp.send_message(create_mail.to_s, Faker::Internet.email, Faker::Internet.email)
            end
          end
        end

        specify { expect(result).to eql(n) }
      end

      context 'with plain authentication' do
        let(:result) do
          Net::SMTP.start(host, port, 'mail.from.domain', 'username', 'password', :plain) do |smtp|
            smtp.send_message(create_mail.to_s, Faker::Internet.email, Faker::Internet.email)
          end
        end

        specify { expect(result).to be_success }
        specify { expect(result.status.to_i).to be(250) }
      end

      context 'with login authentication' do
        let(:result) do
          Net::SMTP.start(host, port, 'mail.from.domain', 'username', 'password', :login) do |smtp|
            smtp.send_message(create_mail.to_s, Faker::Internet.email, Faker::Internet.email)
          end
        end

        specify { expect(result).to be_success }
        specify { expect(result.status.to_i).to be(250) }
      end

      context 'with attachment' do
        let(:result) do
          mail = create_mail do |x|
            x.add_file __FILE__
          end
          Net::SMTP.start(host, port, 'mail.from.domain', 'username', 'password', :login) do |smtp|
            smtp.debug_output = STDOUT
            smtp.send_message(mail.to_s, Faker::Internet.email, Faker::Internet.email)
          end
        end

        specify { expect(result).to be_success }
        specify { expect(result.status.to_i).to be(250) }
      end

      context 'with html part' do
        let(:result) do
          mail = create_mail do |x|
            x.text_part do
              body 'this is plain text'
            end
            x.html_part do
              body '<h1>this is html</h1>'
            end
          end
          Net::SMTP.start(host, port) do |smtp|
            smtp.send_message(mail.to_s, Faker::Internet.email, Faker::Internet.email)
          end
        end

        specify { expect(result).to be_success }
        specify { expect(result.status.to_i).to be(250) }
      end

      context 'when upgrading to tls' do
        let(:result) do
          `(echo 'QUIT'; sleep 1) | openssl s_client -connect #{host}:#{port} -starttls smtp 2>&1`
        end

        specify { expect(result).to end_with("DONE\n") }
        specify { expect(result).to include('250 OK') }
      end
    end
  end
end
