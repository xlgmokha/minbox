RSpec.describe Minbox::Server do
  subject { described_class.new }

  describe "#handle" do
    context "when handling a simple client" do
      let(:client) { StringIO.new }

      specify do
        client.puts("EHLO localhost")
        subject.handle(client)
      end
    end
  end
end
