describe RabbitMQ::Actors::HeadersConsumer do

  context "headers workers are intended to be listener agents of headers messages from a RabbitMQ server" do
    let(:message_id)      { SecureRandom.hex(10) }
    let(:message)         { 'message' }
    let(:headers_name)    { generate(:queue_name) }
    let(:binding_headers) { { 'type' => :industry, 'area' => 'Europe', 'x-match' => 'any' } }
    let(:logger)          { l = Logger.new(STDOUT); l.level = Logger::ERROR; l }
    let(:options)         { { headers_name: headers_name, binding_headers: binding_headers } }
    let(:worker)          { described_class.new(logger: logger, **options) }
    let(:queue)           { worker.queue }

    stub_rabbitmq!

    context "Instantiation" do
      context "When a :headers_name option to identify the headers exchange where to listen from is not provided" do
        let(:options) { { binding_headers: binding_headers } }

        it "an ArgumentError is raised" do
          expect { worker }.to raise_error(ArgumentError)
        end
      end

      context "When a :binding_headers option to match message header values is not provided" do
        let(:options) { { headers_name: headers_name } }

        it "an ArgumentError is raised" do
          expect { worker }.to raise_error(ArgumentError)
        end
      end

      it "A headers exchange named after the headers_name is created to receive messages from" do
        expect(worker.send(:exchange).name).to eq(headers_name)
        expect(worker.send(:exchange).type).to eq(:headers)
      end

      it "A queue is associated to the worker to receive messages from the producer" do
        expect(worker.queue).to be_present
      end

      it "The queue to get messages from is set to be durable" do
        expect(worker.queue).to be_durable
      end

      it "The queue to get messages from is set to be exclusive" do
        expect(worker.queue).to be_exclusive
      end

      it "The queue is bound to the provided binding_headers to selectively receive messages from the exchange" do
        expect(queue).to have_received(:bind).with(worker.send(:exchange), arguments: binding_headers)
      end

      it "See parent class Agent to see other valid options to provide" do
      end
    end

    context "#headers_name" do
      it "returns the name of the RabbitMQ headers used to exchange messages" do
        expect(worker.headers_name).to eq(headers_name)
      end
    end

    context "#binding_headers" do
      it "returns the hash of binding_headers the worker is listening to" do
        expect(worker.binding_headers).to eq(binding_headers)
      end
    end
  end
end
