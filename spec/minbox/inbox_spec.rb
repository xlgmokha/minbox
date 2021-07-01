# frozen_string_literal: true

RSpec.describe Minbox::Inbox do
  subject! { described_class.instance(root_dir: "tmp") }

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
      subject.empty!
    end

    specify { expect(subject.count).to be_zero }
  end

  describe "#emails" do
    specify { expect(subject.emails(count: 2).map(&:subject)).to match_array(["[ACTION] goodbye world", "hello world"]) }
  end

  describe "#wait_until!" do
    context "when the condition is satisfied" do
      before { subject.wait_until! { |x| x.count == 2 } }

      specify { expect(subject.emails(count: 2).map(&:subject)).to match_array(["[ACTION] goodbye world", "hello world"]) }
    end

    context "when the condition is not satisfied" do
      specify do
        expect do
          subject.wait_until!(seconds: 0.1) { |_inbox| false }
        end.to raise_error(/timeout/)
      end
    end
  end

  describe "#open" do
    context "when opening an email by subject" do
      specify { expect(subject.open(subject: "[ACTION] goodbye world").subject).to eql("[ACTION] goodbye world") }
      specify { expect(subject.open(subject: /goodbye/).subject).to eql("[ACTION] goodbye world") }
      specify { expect(subject.open(subject: /hello/).subject).to eql("hello world") }
      specify { expect(subject.open(subject: /world/).subject).to eql("hello world") }
    end

    context "when opening an email not in the inbox" do
      let(:result) { subject.open(subject: SecureRandom.uuid) }

      specify { expect(result).to be_nil }
    end
  end
end
