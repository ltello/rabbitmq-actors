describe RabbitMQ::Actors::Subscriber do

  context "subscribers are intended to be listeners of all messages published by a fanout RabbitMQ exchange" do
    let(:message_id)    { SecureRandom.hex(10) }
    let(:message)       { 'message' }
    let(:exchange_name) { generate(:queue_name) }
    let(:logger)        { l = Logger.new(STDOUT); l.level = Logger::ERROR; l }
    let(:options)       { { exchange_name: exchange_name } }
    let(:worker)        { described_class.new(logger: logger, **options) }
    let(:queue)         { worker.queue }

    stub_rabbitmq!

    context "Instantiation" do
      context "When an :exchange_name option to identify the exchange where to listen from is not provided" do
        let(:options) { { } }

        it "an ArgumentError is raised" do
          expect { worker }.to raise_error(ArgumentError)
        end
      end

      it "A fanout exchange named after the exchange_name is set to receive messages from" do
        expect(worker.send(:exchange).name).to eq(exchange_name)
        expect(worker.send(:exchange).type).to eq(:fanout)
      end

      it "A queue is associated to the worker to receive messages from the producer" do
        expect(worker.queue).to be_present
      end

      it "The queue is bound to the exchange to receive all its published messages" do
        expect(queue).to have_received(:bind).with(worker.send(:exchange))
      end

      it "The queue to get messages from is set to be durable" do
        expect(worker.queue).to be_durable
      end

      it "The queue to get messages from is set to be exclusive" do
        expect(worker.queue).to be_exclusive
      end

      it "See parent class Agent to see other valid options to provide" do
      end
    end

    context "#exchange_name" do
      it "returns the name of the RabbitMQ exchange used to route messages" do
        expect(worker.exchange_name).to eq(exchange_name)
      end
    end
  end
end
