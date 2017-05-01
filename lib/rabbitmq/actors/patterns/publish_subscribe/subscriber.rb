require_relative '../../base/consumer'

module RabbitMQ
  module Actors
    # A consumer of all messages produced by a fanout RabbitMQ exchange.
    # @abstract Subclass and override #perform to define your customized subscriber class.
    #
    # @example
    #   class ScoresListener < RabbitMQ::Actors::Subscriber
    #     def initialize
    #       super(exchange_name:   'scores',
    #             logger:          Rails.logger,
    #             on_cancellation: ->{ ActiveRecord::Base.connection.close })
    #     end
    #
    #     private
    #
    #     def perform(**task)
    #       match_data = JSON.parse(task[:body])
    #       process_match(match_data)
    #     end
    #     ...
    #   end
    #
    #   RabbitMQ::Server.url = 'amqp://localhost'
    #
    #   ScoresListener.new.start!
    #
    class Subscriber < Base::Consumer
      # @!attribute [r] exchange_name
      #   @return [Bunny::Exchange] the exchange where to get messages from.
      attr_reader :exchange_name

      # @param :exchange_name [String] name of the exchange where to consume messages from.
      # @option opts [Proc]   :on_cancellation to be executed before the worker is terminated
      # @option opts [Logger] :logger the logger where to output info about this agent's activity.
      # Rest of options required by your subclass.
      def initialize(exchange_name:, **opts)
        super(opts.merge(exchange_name: exchange_name))
      end

      private

      # Set exchange_name this worker is bound to.
      # @see #initialize for the list of options that can be received.
      def pre_initialize(**opts)
        @exchange_name = opts[:exchange_name]
        super
      end

      # Bind this worker's queue to the exchange
      # @see #initialize for the list of options that can be received.
      def post_initialize(**opts)
        bind_queue_to_exchange
        super
      end

      # The durable fanout RabbitMQ exchange from where messages are received
      # @return [Bunny::Exchange]
      def exchange
        @exchange ||= channel.fanout(exchange_name, durable: true)
      end

      # Bind this worker's listening queue to the exchange to receive all messages produced.
      def bind_queue_to_exchange
        queue.bind(exchange)
      end
    end
  end
end
