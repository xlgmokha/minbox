# frozen_string_literal: true

RSpec.describe Minbox::Inbox do
  subject! { described_class.instance(root_dir: 'tmp') }

  before do
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
  end

  after do
    FileUtils.rm(Dir.glob('tmp/*.eml'))
  end

  describe "#empty!" do
    before :example do
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
    specify { expect(subject.emails(count: 2)).to match_array(['1.eml', '2.eml']) }
  end

  describe "#wait_until!" do
    context "when the condition is satisfied" do
      before { subject.wait_until! { |x| x.count == 2 } }

      specify { expect(subject.emails).to match_array(['1.eml', '2.eml']) }
    end

    context "when the condition is not satisfied" do
      specify do
        expect do
          subject.wait_until!(seconds: 0.1) { |inbox| false }
        end.to raise_error(/timeout/)
      end
    end
  end

  describe "#open" do
    context "when opening an email in the inbox" do
      let(:result) { subject.open('2.eml') }

      specify { expect(result.subject).to eql('goodbye world') }
    end

    context "when opening an email not in the inbox" do
      let(:result) { subject.open("#{SecureRandom.uuid}.eml") }

      specify { expect(result).to be_nil }
    end
  end
end
