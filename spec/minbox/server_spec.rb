require 'spec_helper'

RSpec.describe Minbox::Server do
  describe "#handle" do
    let(:host) { 'localhost' }
    let(:port) { 8080 }

    context "when handling a simple client" do
      def create_mail(to: Faker::Internet.email, from: Faker::Internet.email)
        Mail.new do
          from from
          to to
          subject 'test message'
          body "#{Time.now} This is a test message."
        end
      end

      context "when sending a single email" do
        let(:result) do
          Net::SMTP.start(host, port) do |smtp|
            smtp.send_message(create_mail.to_s, Faker::Internet.email, Faker::Internet.email)
          end
        end

        specify { expect(result).to be_success }
        specify { expect(result.status.to_i).to eql(250) }
      end

      context "when sending multiple emails" do
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

      context "with plain authentication" do
        let(:result) do
          Net::SMTP.start(host, port, 'mail.from.domain', 'username', 'password', :plain) do |smtp|
            smtp.send_message(create_mail.to_s, Faker::Internet.email, Faker::Internet.email)
          end
        end

        specify { expect(result).to be_success }
        specify { expect(result.status.to_i).to eql(250) }
      end

      context "with login authentication" do
        let(:result) do
          Net::SMTP.start(host, port, 'mail.from.domain', 'username', 'password', :login) do |smtp|
            smtp.send_message(create_mail.to_s, Faker::Internet.email, Faker::Internet.email)
          end
        end

        specify { expect(result).to be_success }
        specify { expect(result.status.to_i).to eql(250) }
      end

      context "with a text/html part" do

      end

    end
  end
end
