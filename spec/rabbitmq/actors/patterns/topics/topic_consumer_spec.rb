describe RabbitMQ::Actors::TopicConsumer do

  context "topic workers are intended to be listener agents of topic messages from a RabbitMQ server" do
    let(:message_id)   { SecureRandom.hex(10) }
    let(:message)      { 'message' }
    let(:topic_name)   { generate(:queue_name) }
    let(:binding_keys) { ['topic.*', '*.interesenting'] }
    let(:logger)       { l = Logger.new(STDOUT); l.level = Logger::ERROR; l }
    let(:options)      { { topic_name: topic_name, binding_keys: binding_keys } }
    let(:worker)       { described_class.new(logger: logger, **options) }
    let(:queue)        { worker.queue }

    stub_rabbitmq!

    context "Instantiation" do
      context "When a :topic_name option to identify the topic exchange where to listen from is not provided" do
        let(:options) { { binding_keys: binding_keys } }

        it "an ArgumentError is raised" do
          expect { worker }.to raise_error(ArgumentError)
        end
      end

      context "When a list of :binding_keys to filter messages is not provided" do
        let(:options) { { topic_name: topic_name } }

        it "all of the exchange messages are received" do
          expect(worker.binding_keys).to eq(['#'])
        end
      end

      it "A topic exchange named after the topic_name is created to receive messages from" do
        expect(worker.send(:exchange).name).to eq(topic_name)
        expect(worker.send(:exchange).type).to eq(:topic)
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

      it "The queue is bound to all the provided binding_keys to selectively receive messages from the exchange" do
        binding_keys.each do |key|
          expect(queue).to have_received(:bind).with(worker.send(:exchange), routing_key: key)
        end
      end

      it "See parent class Agent to see other valid options to provide" do
      end
    end

    context "#topic_name" do
      it "returns the name of the RabbitMQ topic used to exchange messages" do
        expect(worker.topic_name).to eq(topic_name)
      end
    end

    context "#binding_keys" do
      it "returns the list of the routing keys the worker is listening to" do
        expect(worker.binding_keys).to eq(Array(binding_keys))
      end
    end
  end
end
