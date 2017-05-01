require_relative 'agent'

module RabbitMQ
  module Actors
    module Base

      # The base class to define actual RabbitMQ message producer classes.
      # @abstract Subclass and override #pre_initialize and #exchange to define actual producer classes.
      #
      # @example
      #   module RabbitMQ::Actors
      #     class MasterProducer < Base::Producer
      #       def initialize(queue_name:, **opts)
      #         super(opts.merge(queue_name: queue_name))
      #       end
      #
      #       def publish(message, message_id:, **opts)
      #         super(message, opts.merge(message_id: message_id, routing_key: queue.name))
      #       end
      #
      #       private
      #
      #       def exchange
      #         @exchange ||= channel.default_exchange
      #       end
      #     end
      #   end
      #
      class Producer < Agent
        # Send a messages to RabbitMQ server.
        # Log the action to the logger with info severity.
        # @param message [String] the message body to be sent.
        # @param :message_id [String] user-defined id for replies to refer to this message using :correlation_id
        # @param :opts [Hash] receives extra options from your subclass
        # @see Bunny::Exchange#publish for extra options
        def publish(message, message_id:, **opts)
          options = opts.merge(message_id: message_id).reverse_merge!(persistent: true)
          options.merge!(reply_to: reply_queue.name) if reply_queue
          logger.info(self.class.name) { "Just Before #{self} publishes message: #{message} with options: #{options}" }
          exchange.publish(message, options)
          logger.info(self.class.name) { "Just After #{self} publishes message: #{message} with options: #{options}" }
          self
        end

        delegate :on_return, to: :exchange

        # Close the connection channel to RabbitMQ.
        # Log the action to the logger with info severity.
        def close
          logger.info(self.class.name) { "Just Before #{self} closes RabbitMQ channel!" }
          channel.close
          logger.info(self.class.name) { "Just After #{self} closes RabbitMQ channel!" }
        end
        alias_method :and_close, :close

        private

        attr_reader :reply_queue

        # If opts[:reply_queue_name].present? set the queue where a consumer should reply.
        # @see #initialize for the list of options that can be received.
        def post_initialize(**opts)
          set_reply_queue(opts[:reply_queue_name]) if opts[:reply_queue_name].present?
        end

        # The RabbitMQ exchange where to publish the message
        # @raise [Exception] so it must be override in subclasses.
        def exchange
          raise "This is an abstract class. Override exchange method in descendant class"
        end

        # Set the RabbitMQ queue where a consumer should send replies.
        # @param name [String] name of the queue.
        # @raise [Exception] if reply_queue already set.
        # @return [Bunny::Queue]
        def set_reply_queue(name)
          raise "Reply Queue already set" if reply_queue
          @reply_queue = channel.queue(name, durable: true, auto_delete: true, exclusive: false)
        end
      end
    end
  end
end
