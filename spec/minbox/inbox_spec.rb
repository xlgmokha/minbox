# frozen_string_literal: true

RSpec.describe Minbox::Inbox do
  subject { described_class.new }

  before do
    FileUtils.rm(Dir.glob('tmp/*.eml'))
    subject.start
  end

  describe "#empty!" do
    before :example do
      IO.write("tmp/1.eml", Mail.new do
        to Faker::Internet.email
        from Faker::Internet.email
        subject "hello world"
      end.to_s)
      subject.empty!
    end

    specify { expect(subject.count).to be_zero }
  end

  describe "#emails" do
    before :example do
      pid = fork do
        IO.write("tmp/1.eml", Mail.new do
          to Faker::Internet.email
          from Faker::Internet.email
          subject "hello world"
        end.to_s)
        IO.write("tmp/2.eml", Mail.new do
          to Faker::Internet.email
          from Faker::Internet.email
          subject "goodbye world"
        end.to_s)
        sleep 0.3
      end
      Process.wait(pid)
      @result = subject.emails
    end

    specify { expect(@result).to match_array(['1.eml', '2.eml']) }
  end

  describe "#open" do
    before :example do
      pid = fork do
        IO.write("tmp/1.eml", Mail.new do
          to Faker::Internet.email
          from Faker::Internet.email
          subject "hello world"
        end.to_s)
        IO.write("tmp/2.eml", Mail.new do
          to Faker::Internet.email
          from Faker::Internet.email
          subject "goodbye world"
        end.to_s)
        sleep 0.3
      end
      Process.wait(pid)
    end

    context "when opening an email in the inbox" do
      before { @result = subject.open('2.eml') }

      specify { expect(@result.subject).to eql('goodbye world') }
    end

    context "when opening an email not in the inbox" do
      before { @result = subject.open("#{SecureRandom.uuid}.eml") }

      specify { expect(@result).to be_nil }
    end
  end
end
