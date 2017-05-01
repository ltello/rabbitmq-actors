describe RabbitMQ::Actors::RoutingProducer do

  context "routing producers are intended to be publishers of messages to a RabbitMQ system based on routing keys" do
    let(:message_id)                 { SecureRandom.hex(10) }
    let(:message)                    { 'message' }
    let(:routing_key)                { 'important' }
    let(:exchange_name)              { generate(:queue_name) }
    let(:reply_queue_name)           { generate(:queue_name) }
    let(:logger)                     { l = Logger.new(STDOUT); l.level = Logger::ERROR; l }
    let(:producer)                   { described_class.new(exchange_name: exchange_name, logger: logger) }
    let(:producer_with_replay_queue) { described_class.new(exchange_name: exchange_name, reply_queue_name: reply_queue_name, logger: logger) }

    stub_rabbitmq!

    context "Instantiation" do
      it "You have to provide an :exchange_name to name the direct exchange where to send messages" do
        expect {subject}.to raise_error(ArgumentError)
      end

      it "A direct exchange named after the exchange_name is created to send messages through" do
        expect(producer.send(:exchange).name).to eq(exchange_name)
        expect(producer.send(:exchange).type).to eq(:direct)
      end

      it "A :reply_queue_name to be included in the published messages can also be provided" do
        expect(producer_with_replay_queue).to be_a(described_class)
        expect(producer_with_replay_queue.send(:reply_queue).name).to eq(reply_queue_name)
      end

      it "See parent class Agent to see other valid options to provide" do
      end
    end

    context "#exchange_name" do
      it "returns the name of the direct exchange used to send messages" do
        expect(producer.exchange_name).to eq(exchange_name)
      end
    end

    context "#publish: sends a message to the RabbitMQ direct exchange with the provided routing_key" do
      let(:opts)             { {} }
      let(:routing_producer) { producer }
      let(:exchange)         { routing_producer.send(:exchange) }

      before do
        routing_producer.publish(message, message_id: message_id, routing_key: routing_key, **opts)
      end

      it "a persistent routed message gets sent to RabbitMQ" do
        expect(exchange).to have_received(:publish)
          .with(message, message_id: message_id, routing_key: routing_key, persistent: true)
      end

      context "When additional options provided" do
        let(:opts) { {another_option: :another_option_value} }

        it "those are included in the persistent published message to RabbitMQ" do
          expect(exchange).to have_received(:publish)
            .with(message, message_id: message_id, routing_key: routing_key, persistent: true, **opts)
        end
      end

      context "When the producer was initialized with a reply_queue_name" do
        let(:routing_producer) { producer_with_replay_queue }

        it "a reply_to: option is also published" do
          expect(exchange).to have_received(:publish)
            .with(message, message_id: message_id, routing_key: routing_key, persistent: true, reply_to: reply_queue_name)
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
