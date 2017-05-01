describe RabbitMQ::Actors::MasterProducer do

  context "master producers are intended to be basic publisher agents of messages to RabbitMQ system." do
    let(:message_id)                 { SecureRandom.hex(10) }
    let(:message)                    { 'message' }
    let(:queue_name)                 { generate(:queue_name) }
    let(:reply_queue_name)           { generate(:queue_name) }
    let(:logger)                     { l = Logger.new(STDOUT); l.level = Logger::ERROR; l }
    let(:producer)                   { described_class.new(queue_name: queue_name, logger: logger) }
    let(:producer_with_replay_queue) { described_class.new(queue_name: queue_name, reply_queue_name: reply_queue_name, logger: logger) }

    stub_rabbitmq!

    context "Instantiation" do
      it "You have to provide a :queue_name" do
        expect {subject}.to raise_error(ArgumentError)
      end

      it "The queue to talk to is set to be durable" do
        expect(producer.queue).to be_durable
      end

      it "The queue to talk to is set to not be exclusive" do
        expect(producer.queue).not_to be_exclusive
      end

      it "A :reply_queue_name to be included in the published messages can also be provided" do
        expect(producer_with_replay_queue).to be_a(described_class)
        expect(producer_with_replay_queue.send(:reply_queue).name).to eq(reply_queue_name)
      end

      it "See parent class Agent to see other valid options to provide" do
      end
    end

    context "#publish: sends a message to a RabbitMQ channel default_exchange with routing_key the queue name provided" do
      let(:opts) { {} }
      let(:master_producer) { producer }

      before do
        master_producer.publish(message, message_id: message_id, **opts)
      end

      it "a persistent message gets sent to RabbitMQ" do
        expect(default_exchange).to have_received(:publish)
          .with(message, message_id: message_id, routing_key: queue_name, persistent: true)
      end

      context "When additional options provided" do
        let(:opts) { {another_option: :another_option_value} }

        it "those are included in the persistent published message to RabbitMQ" do
          expect(default_exchange)
            .to have_received(:publish)
                  .with(message, message_id: message_id, routing_key: queue_name, persistent: true, **opts)
        end
      end

      context "When the producer was initialized with a reply_queue_name" do
        let(:master_producer) { producer_with_replay_queue }

        it "a reply_to: option is also published" do
          expect(default_exchange)
            .to have_received(:publish)
                  .with(message, message_id: message_id, routing_key: queue_name, persistent: true, reply_to: reply_queue_name)
        end
      end
    end

    context "#close or #and_close: to close the RabbitMQ channel" do
      before do
        producer.send(close_method_name)
      end

      context "When using #close" do
        let(:close_method_name) { :close }

        it "the RabbitMQ channel get closed" do
          expect(channel).to have_received(:close)
        end
      end

      context "When using #and_close" do
        let(:close_method_name) { :and_close }

        it "the RabbitMQ channel get closed" do
          expect(channel).to have_received(:close)
        end
      end
    end
  end
end
