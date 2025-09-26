# frozen_string_literal: true

RSpec.describe Minbox::Inbox do
  subject!(:inbox) { described_class.instance(root_dir: "tmp") }

  before do
    IO.write("tmp/1.eml", Mail.new do
      to Faker::Internet.email
      from Faker::Internet.email
      subject "hello world"
    end.to_s)
    IO.write("tmp/2.eml", Mail.new do
      to Faker::Internet.email
      from Faker::Internet.email
      subject "[ACTION] goodbye world"
    end.to_s)
  end

  after do
    FileUtils.rm(Dir.glob("tmp/*.eml"))
  end

  describe "#empty!" do
    before do
      IO.write("tmp/3.eml", Mail.new do
        to Faker::Internet.email
        from Faker::Internet.email
        subject "hello world"
      end.to_s)
      inbox.empty!
    end

    specify { expect(inbox.count).to be_zero }
  end

  describe "#emails" do
    specify { expect(inbox.emails(count: 2).map(&:subject)).to match_array(["[ACTION] goodbye world", "hello world"]) }
  end

  describe "#wait_until!" do
    context "when the condition is satisfied" do
      before { inbox.wait_until! { |x| x.count == 2 } }

      specify { expect(inbox.emails(count: 2).map(&:subject)).to match_array(["[ACTION] goodbye world", "hello world"]) }
    end

    context "when the condition is not satisfied" do
      specify do
        expect do
          inbox.wait_until!(seconds: 0.1) { |_inbox| false }
        end.to raise_error(/timeout/)
      end
    end
  end

  describe "#open" do
    context "when opening an email by subject" do
      specify { expect(inbox.open(subject: "[ACTION] goodbye world").subject).to eql("[ACTION] goodbye world") }
      specify { expect(inbox.open(subject: /goodbye/).subject).to eql("[ACTION] goodbye world") }
      specify { expect(inbox.open(subject: /hello/).subject).to eql("hello world") }
      specify { expect(inbox.open(subject: /world/).subject).to eql("hello world") }
    end

    context "when opening an email not in the inbox" do
      let(:result) { inbox.open(subject: SecureRandom.uuid) }

      specify { expect(result).to be_nil }
    end
  end
end
