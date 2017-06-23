module RabbitMQ
  module Actors
    module Base

      # The base class for RabbitMQ producers, workers, publishers, consumers...
      # @abstract Subclass and override #pre_initialize and/or #post_initialize to define
      #   actual agent classes.
      #
      # @example
      #   module RabbitMQ
      #     module Actors
      #       module Base
      #
      #         class Producer < Agent
      #           def post_initialize(queue_name:, opts = {})
      #             set_reply_queue(opts[:reply_queue_name])
      #           end
      #
      #           def publish(message, correlation_key: true)
      #             options = { routing_key: queue.name, durable: durable }
      #             options.merge!(reply_to: reply_queue.name)           if reply_queue
      #             options.merge!(correlation_id: SecureRandom.hex(10)) if correlation_key
      #             exchange.publish(message, options)
      #           end
      #
      #           def close!
      #             channel.close
      #           end
      #         end
      #       end
      #     end
      #   end
      #
      class Agent
        attr_reader :queue

        # Instantiate a new agent.
        # #pre_initialize and #post_initialize methods are called just at the beginning
        # and end respectively.
        # Redefine them in your subclass to complete your subclass initialization process.
        #
        # @option opts [String]  :queue_name the queue name to bind the agent with if any.
        # @option opts [Boolean] :exclusive (true) if the queue can only be used by this agent and
        #   removed when this agent's connection is closed.
        # @option opts [Boolean] :auto_delete (true) if the queue will be deleted when
        #   there are no more consumers subscribed to it.
        # @option opts [Logger]  :logger  the logger where to output info about agent's activity.
        # Rest of options required by your subclasses.
        def initialize(**opts)
          pre_initialize(**opts)
          set_queue(opts[:queue_name], **opts) if opts[:queue_name]
          set_logger(opts[:logger])
          post_initialize(**opts)
        end

        private

        # @!attribute [r] logger
        # @return [Logger] the logger where to log agent's activity
        attr_reader :logger

        # The connection object to the RabbitMQ server.
        # @return [Bunny::Session] the connection object.
        def connection
          @connection ||= Server.connection
        end

        # The channel where to send messages through
        # @return [Bunny::Channel] the talking channel to RabbitMQ server.
        def channel
          @channel ||= connection.create_channel
        end

        # Method called just at the beginning of initializing an instance.
        # Redefine it in your class to do the specific init you want.
        # @param args [Array], list of params received in the initialize call.
        def pre_initialize(*args)
        end

        # Method called just at the end of initializing an instance.
        # Redefine it in your class to do the specific init you want.
        # @param args [Array], list of params received in the initialize call.
        def post_initialize(*args)
        end

        # Create/open a durable queue of the given name.
        # @param name [String] name of the queue.
        # @param opts [Hash] properties of the queue.
        # @raise [Exception] if queue already set.
        # @return [Bunny::Queue] the queue where to address/get messages.
        def set_queue(name, **opts)
          raise "Queue already set" if queue
          auto_delete = opts.fetch(:auto_delete, true)
          exclusive   = opts.fetch(:exclusive,   true)
          @queue = channel.queue(name, durable: true, auto_delete: auto_delete, exclusive: exclusive)
        end

        # Set logger to output agent info.
        # If logger is nil, STDOUT with a DEBUG level of severity is set up as logger.
        # @param logger [Logger] where to address output info.
        # @return [Logger] the logger instance where to output info.
        def set_logger(logger)
          @logger = logger || Logger.new(STDOUT)
        end
      end
    end
  end
end
