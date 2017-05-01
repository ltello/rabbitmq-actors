require_relative 'agent'

module RabbitMQ
  module Actors
    module Base

      # The base class to define actual RabbitMQ message consumer classes.
      # @abstract Subclass and override #perform to define actual consumer classes.
      #
      # @example
      #   module RabbitMQ
      #     module Actors
      #       class Worker < Base::Consumer
      #         def initialize(queue_name:, **opts)
      #           super(opts.merge(queue_name: queue_name))
      #         end
      #       end
      #     end
      #   end
      #
      class Consumer < Agent
        # @param :queue_name [String] the queue name to bind the consumer with.
        # @option opts [Boolean] :manual_ack to tell RabbitMQ server not to remove the message from
        #   re-delivery until a manual acknowledgment from the consumer has been received.
        # @option opts [Proc] :on_cancellation to be executed if the agent is cancelled
        # Rest of options required by your subclasses.
        def initialize(queue_name: '', **opts)
          super(opts.merge(queue_name: queue_name))
        end

        # Start listening to the queue and block waiting for a new task to be assigned by the server.
        # Perform the task, acknowledge if required and keep listening waiting for the message to come.
        # @raise [Exception] if something goes wrong during the execution of the task.
        def start!
          @_cancelled = false
          channel.prefetch(1)
          queue.subscribe(block: true, manual_ack: manual_ack?, on_cancellation: cancellation_handler) do |delivery_info, properties, body|
            begin
              logger.info(self.class.name) { "#{self} received task: #{body}" }
              self.perform_result = perform(delivery_info: delivery_info, properties: properties, body: body)
              done!(delivery_info)
              logger.info(self.class.name) { "#{self} performed task!" }
            rescue Exception => e
              logger.error "Error when #{self} performing task: #{e.message}"
              cancellation_handler.call
              fail(e)
            end
          end
          cancellation_handler.call
          perform_result
        end

        private

        # @!attribute [rw] perform_result
        #   @return [Object] the result of execution of the last task received by the consumer
        attr_accessor :perform_result

        # @!attribute [r] manual_ack
        #   @return [Boolean] whether to acknowledge execution of messages to the server
        attr_reader   :manual_ack
        alias_method  :manual_ack?, :manual_ack

        # @!attribute [r] on_cancellation
        #   @return [Proc] the proc to be executed before the consumer is finished.
        attr_reader :on_cancellation

        # Set manual_ack flag based on options received.
        # Also set the code to execute before terminating the consumer.
        # @see #initialize for the list of options that can be received.
        def pre_initialize(**opts)
          @manual_ack      = opts[:manual_ack].present?
          @on_cancellation = opts[:on_cancellation] || ->{}
        end

        # Set the code to execute when the consumer is cancelled before exit.
        # Execute the provided code and close the connection to RabbitMQ server.
        # @return [Proc] handler to execute before exit.
        def cancellation_handler
          lambda do
            if not @_cancelled
              on_cancellation.call
              connection.close
              @_cancelled = true
            end
          end
        end

        # Perform the assigned task
        # @param task [Hash] the properties of the message received.
        # @raise [Exception] Override this method in your subclass.
        def perform(**task)
          raise "No work defined! for this task: #{task[:body]}. Define #perform private method in your class"
        end

        # Hook to be executed after the consumer completes an assigned task.
        # Send acknowledgement to the channel if required
        # @param delivery_info [Bunny Object] contains delivery info about the message to acknowledge.
        def done!(delivery_info)
          channel.ack(delivery_info.delivery_tag) if manual_ack?
        end
      end
    end
  end
end
