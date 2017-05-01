describe RabbitMQ::Server do
  let(:url) { "amqp://localhost" }

  context "module to setup server url" do
    before do
      allow(Bunny).to receive(:new).and_return(double(start: nil))
    end

    context ".url=" do
      it "sets the url to reach a RabbitMQ server" do
        expect { described_class.url= url }.to change(described_class, :url).to(url)
      end

      it "a new connection to that server is open" do
        described_class.class_variable_set(:@@connection, 'a_connection')
        expect { described_class.url= url }.to change(described_class, :connection)
      end
    end

    context ".url" do
      before do
        described_class.url = url
      end

      it "returns the current server url" do
        expect(described_class.url).to eq(url)
      end
    end

    context ".connection" do
      before do
        described_class.url = url
      end

      it "returns a connection to the current server, if any" do
        expect(described_class).to respond_to(:connection)
      end
    end
  end
end
