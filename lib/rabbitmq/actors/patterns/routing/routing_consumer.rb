require_relative '../../base/consumer'

module RabbitMQ
  module Actors
    # A consumer of messages from RabbitMQ based on routing keys.
    # @abstract Subclass and override #perform to define your customized routing worker class.
    #
    # @example
    #   class TennisListener < RabbitMQ::Actors::RoutingConsumer
    #     def initialize
    #       super(exchange_name:   'sports',
    #             binding_keys:    ['tennis'],
    #             logger:          Rails.logger,
    #             on_cancellation: ->{ ActiveRecord::Base.connection.close })
    #     end
    #
    #     private
    #
    #     def perform(**task)
    #       match_data = JSON.parse(task[:body])
    #       process_tennis_match(match_data)
    #     end
    #     ...
    #   end
    #
    #   class FootballListener < RabbitMQ::Actors::RoutingConsumer
    #     def initialize
    #       super(exchange_name:   'sports',
    #             binding_keys:    ['football', 'soccer'],
    #             logger:          Rails.logger,
    #             on_cancellation: ->{ ActiveRecord::Base.connection.close })
    #     end
    #
    #     private
    #
    #     def perform(**task)
    #       match_data = JSON.parse(task[:body])
    #       process_footbal_match(match_data)
    #     end
    #     ...
    #   end
    #
    #   RabbitMQ::Server.url = 'amqp://localhost'
    #
    #   TennisListener.new.start!
    #   FootballListener.new.start!
    #
    class RoutingConsumer < Base::Consumer
      # @!attribute [r] exchange_name
      #   @return [Bunny::Exchange] the exchange where to get messages from.
      attr_reader :exchange_name

      # @!attribute [r] binding_keys
      #   @return [String, Array] the routing keys this worker is interested in.
      attr_reader :binding_keys

      # @param :exchange_name [String] name of the exchange where to consume messages from.
      # @param :binding_keys  [String, Array] list of routing keys this worker is interested in.
      #   Default to all: '#'
      # @option opts [Proc] :on_cancellation to be executed before the worker is terminated
      # @option opts [Logger] :logger the logger where to output info about this agent's activity.
      # Rest of options required by your subclass.
      def initialize(exchange_name:, binding_keys: '#', **opts)
        super(opts.merge(exchange_name: exchange_name, binding_keys: binding_keys))
      end

      private

      # Set exchange_name and binding_keys this worker is bound to.
      # @see #initialize for the list of options that can be received.
      def pre_initialize(**opts)
        @exchange_name = opts[:exchange_name]
        @binding_keys  = Array(opts[:binding_keys])
        super
      end

      # Bind this worker's queue to the exchange and to the given binding_keys
      # @see #initialize for the list of options that can be received.
      def post_initialize(**opts)
        bind_queue_to_exchange_routing_keys
        super
      end

      # The durable direct RabbitMQ exchange from where messages are received
      # @return [Bunny::Exchange]
      def exchange
        @exchange ||= channel.direct(exchange_name, durable: true)
      end

      # Bind this worker's listening queue to the exchange and receive only messages with routing key
      # one of the given binding_keys.
      def bind_queue_to_exchange_routing_keys
        binding_keys.each do |key|
          queue.bind(exchange, routing_key: key)
        end
      end
    end
  end
end
