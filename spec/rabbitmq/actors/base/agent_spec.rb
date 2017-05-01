describe RabbitMQ::Actors::Base::Agent do

  context "Agents are intended to be basic clients to exchange messages with a RabbitMQ server.
           This class is meant to be subclassed to create specialized producer and consumer agents" do
    let(:queue_name) { generate(:queue_name) }
    let(:logger)     { l = Logger.new(STDOUT); l.level = Logger::ERROR; l }
    let(:options)    { { logger: logger } }
    let(:agent)      { described_class.new(**options) }
    let(:queue)      { agent.queue }

    stub_rabbitmq!

    before do
      allow_any_instance_of(described_class).to receive(:pre_initialize)
      allow_any_instance_of(described_class).to receive(:post_initialize)
    end

    context "Instantiation" do
      context "When a :queue_name option is provided" do
        let(:options) { { queue_name: queue_name } }

        it "a durable, exclusive queue with that name is associated to the agent" do
          expect(queue).to      be_present
          expect(queue.name).to eq(queue_name)
          expect(queue).to      be_durable
          expect(queue).to      be_exclusive
        end

        context "when auto_delete: false option is provided" do
          let(:options) { { queue_name: queue_name, auto_delete: false } }

          it "the queue is not automatically deleted when no longer used" do
            expect(queue).not_to be_auto_delete
          end
        end

        context "when auto_delete: true or no option is provided" do
          it "the queue gets automatically deleted when no longer used" do
            expect(queue).to be_auto_delete
          end
        end

        context "when exclusive: false option is provided" do
          let(:options) { { queue_name: queue_name, exclusive: false } }

          it "the queue is not exclusively used by the agent creating it" do
            expect(queue).not_to be_exclusive
          end
        end

        context "when exclusive: true or no option is provided" do
          it "the queue is exclusively used by the agent creating it" do
            expect(queue).to be_exclusive
          end
        end
      end

      context "when logger option is provided" do
        it "output of agent processing can be addressed to it" do
          expect(agent.send(:logger)).to eq(logger)
        end
      end

      context "when no logger option is provided" do
        it "output of agent processing can be addressed to standard STDOUT" do
          expect(agent.send(:logger).instance_variable_get(:@logdev).dev).to eq(STDOUT)
        end
      end

      it "#pre_initialize method is called so you can overide it in your subclasses" do
        expect(agent).to have_received(:pre_initialize).once
      end

      it "#post_initialize method is called so you can overide it in your subclasses" do
        expect(agent).to have_received(:post_initialize).once
      end

      it "the server reached is based on existing RabbitMQ::Server.connection" do
        expect(agent.send(:connection)).to eq(RabbitMQ::Server.connection)
      end
    end

    context "#queue" do
      context "when a queue_name was provided" do
        let(:options) { { queue_name: queue_name } }

        it "returns the RabbitMQ queue object the agent is attached to" do
          expect(queue.name).to eq(queue_name)
        end
      end

      context "when no queue_name was provided" do
        it "returns nil" do
          expect(queue).to be_nil
        end
      end
    end
  end
end
