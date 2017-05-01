describe RabbitMQ::Actors::Base::Consumer do

  context "Consumers are intended to be listener agents of messages from a RabbitMQ server.
           This class is meant to be subclassed overiding the #perform method to process a received message" do
    let(:message_id)   { SecureRandom.hex(10) }
    let(:message)      { 'message' }
    let(:queue_name)   { generate(:queue_name) }
    let(:topic_name)   { generate(:queue_name) }
    let(:binding_keys) { ['topic.*', '*.interesenting'] }
    let(:manual_ack)   { true }
    let(:handler)      { Proc.new {} }
    let(:logger)       { l = Logger.new(STDOUT); l.level = Logger::ERROR; l }
    let(:options)      { { } }
    let(:consumer)     { described_class.new(logger: logger, **options) }
    let(:exchange)     { consumer.send(:exchange) }
    let(:queue)        { consumer.queue }

    stub_rabbitmq!

    context "Instantiation" do
      context "When a :queue_name option to identify the queue where to listen from is provided" do
        let(:options) { { queue_name: queue_name } }

        it "a queue with that name is associated to the consumer" do
          expect(queue.name).to eq(queue_name)
        end
      end

      it "By default , a durable, exclusive, auto-deletable queue is associated to the consumer to receive messages from the producer" do
        expect(queue).to be_present
        expect(queue).to be_durable
        expect(queue).to be_exclusive
        expect(queue).to be_auto_delete
      end

      it "By default RabbitMQ will remove a message after it has been delivered to this consumer and therefore
          will not wait for this consumer acknowledgment" do
        expect(consumer.send(:manual_ack)).to be_falsey
      end

      context "When manual_ack: true option is provided" do
        let(:options) { { manual_ack: true } }

        it "RabbitMQ expects the consumer to explicitly acknowledge delivered messages" do
          expect(consumer.send(:manual_ack)).to be_truthy
        end
      end

      context "When :on_cancellation option is provided" do
        let(:options) { { on_cancellation: handler } }

        it "the proc is stored to be executed when the consumer is cancelled" do
          expect(consumer.send(:on_cancellation)).to eq(handler)
        end
      end
    end

    context "#start: wait listening the associated queue" do
      let(:delivery_info) { double(delivery_tag: '1', consumer: double(cancel: true)) }
      let(:properties)    { double }
      let(:payload)       { double }
      let(:options)       { { queue_name: queue_name, manual_ack: manual_ack } }

      before do
        allow(queue).to receive(:subscribe)
      end

      context "the call" do
        before do
          consumer.start!
        end

        it "is done with no params" do
          expect(queue).to have_received(:subscribe)
        end

        it "blocks the consumer waiting for a message from RabbitMQ" do
          expect(queue).to have_received(:subscribe).with(hash_including(block: true))
        end
      end

      context "When a message arrives" do
        before do
          allow(queue).to receive(:subscribe).and_yield(delivery_info, properties, payload)
        end

        it "#perfom is called" do
          expect(consumer).to receive(:perform).with(delivery_info: delivery_info, properties: properties, body: payload)
          consumer.start!
        end

        context "when #perfom has been overriden" do
          before do
            allow(consumer).to receive(:perform).and_return(:perform_result)
          end

          context "When manual acknowledgment was setup" do
            before do
              consumer.start!
            end

            it "a manual acknowledgement is sent back after finishing #perform" do
              expect(channel).to have_received(:ack).with(delivery_info.delivery_tag)
            end
          end

          context "When manual acknowledgment was not setup" do
            let(:manual_ack) { false }

            before do
              consumer.start!
            end

            it "a manual acknowledgement is not sent back after finishing #perform.
                RabbitMQ will remove the message from the server as soon it is received by the consumer" do
              expect(channel).not_to have_received(:ack).with(delivery_info.delivery_tag)
            end
          end

          context "when the consumer is cancelled for any reason" do
            let(:result) { consumer.start! }

            before do
              allow(handler).to receive(:call)
              result
            end

            context "When customized :on_cancellation Proc was provided" do
              let(:options) { { on_cancellation: handler } }

              it "the code is executed" do
                expect(handler).to have_received(:call)
              end
            end

            it "the connection to RabbitMQ is closed" do
              expect(connection).to have_received(:close)
            end

            it "and #perform's output is returned from #start" do
              expect(result).to eq(:perform_result)
            end
          end
        end
      end
    end
  end
end
