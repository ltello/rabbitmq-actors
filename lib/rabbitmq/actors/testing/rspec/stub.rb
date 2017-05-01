module RabbitMQ
  module Actors
    module Testing
      module Rspec

        module Stub
          # This is a macro available in your rspec tests to stub the RabbitMQ server
          # and Bunny objects associated to it.
          #
          # describe MyListener do
          #   stub_rabbitmq!
          #
          #   context "..."  do
          #     ...
          #   end
          # end
          def stub_rabbitmq!
            let(:default_exchange) { double(publish: :published, on_return: :on_returned, type: :direct) }
            let(:channel)          { double(prefetch: true, ack: true, default_exchange: default_exchange, close: true) }
            let(:connection)       { double(create_channel: channel).as_null_object }

            before do
              allow(channel).to receive(:queue) do |name, durable:, auto_delete:, exclusive:|
                double(name: name, durable: durable.present?, durable?: durable.present?,
                       auto_delete: auto_delete.present?, auto_delete?: auto_delete.present?,
                       exclusive: exclusive.present?, exclusive?: exclusive.present?, bind: :bound)
              end

              allow(channel).to receive(:direct) do |name|
                double(name: name, publish: :published, type: :direct)
              end

              allow(channel).to receive(:fanout) do |name|
                double(name: name, publish: :published, type: :fanout)
              end

              allow(channel).to receive(:topic) do |name|
                double(name: name, publish: :published, type: :topic)
              end

              allow(channel).to receive(:headers) do |name|
                double(name: name, publish: :published, type: :headers)
              end

              allow(RabbitMQ::Server).to receive(:connection) { connection }
            end
          end
        end
      end
    end
  end
end
