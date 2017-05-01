describe RabbitMQ::Actors::Worker do

  context "basic workers are intended to be message consumer agents from a specific queue of the RabbitMQ server" do
    let(:message_id) { SecureRandom.hex(10) }
    let(:message)    { 'message' }
    let(:queue_name) { generate(:queue_name) }
    let(:logger)     { l = Logger.new(STDOUT); l.level = Logger::ERROR; l }
    let(:options)    { { queue_name: queue_name } }
    let(:worker)     { described_class.new(logger: logger, **options) }
    let(:queue)      { worker.queue }

    stub_rabbitmq!

    context "Instantiation" do
      context "When a :queue_name option to identify the queue where to listen from is not provided" do
        let(:options) { { } }

        it "an ArgumentError is raised" do
          expect { worker }.to raise_error(ArgumentError)
        end
      end

      it "The queue to get messages from is named after queue_name" do
        expect(queue.name).to eq(queue_name)
      end

      it "The queue to get messages from is set to be durable" do
        expect(queue).to be_durable
      end

      it "The queue to get messages from is set to not be exclusive" do
        expect(queue).not_to be_exclusive
      end

      it "See parent class Agent to see other valid options to provide" do
      end
    end
  end
end
