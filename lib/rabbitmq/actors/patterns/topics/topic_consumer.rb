require_relative '../../base/consumer'

module RabbitMQ
  module Actors
    # A consumer of messages from RabbitMQ based on exchange and routing key matching patterns.
    # @abstract Subclass and override #perform to define your customized topic worker class.
    #
    # @example
    #   class SpainTennisListener < RabbitMQ::Actors::TopicConsumer
    #     def initialize
    #       super(topic_name:      'sports',
    #             binding_keys:    '#.tennis.#.spain.#',
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
    #
    #     def process_tennis_match(data)
    #       ...
    #     end
    #   end
    #
    #   class AmericaSoccerListener < RabbitMQ::Actors::TopicConsumer
    #     def initialize
    #       super(exchange_name:   'sports',
    #             binding_keys:    '#.soccer.#.america.#',
    #             logger:          Rails.logger,
    #             on_cancellation: ->{ ActiveRecord::Base.connection.close })
    #     end
    #
    #     private
    #
    #     def perform(**task)
    #       match_data = JSON.parse(task[:body])
    #       process_soccer_match(match_data)
    #     end
    #
    #     def process_soccer_match(data)
    #       ...
    #     end
    #   end
    #
    #   RabbitMQ::Server.url = 'amqp://localhost'
    #
    #   SpainTennisListener.new.start!
    #   AmericaSoccerListener.new.start!
    #
    class TopicConsumer < Base::Consumer
      # @!attribute [r] topic_name
      #   @return [Bunny::Exchange] the topic exchange where to get messages from.
      attr_reader :topic_name

      # @!attribute [r] binding_keys
      #   @return [String, Array] the routing key patterns this worker is interested in.
      attr_reader :binding_keys

      # @param :topic_name   [String] name of the topic exchange this worker will receive messages.
      # @param :binding_keys [String, Array] routing key patterns this worker is interested in.
      #   Default to all: '#'
      # @option opts [Boolean] :manual_ack to acknowledge messages to the RabbitMQ server
      #   once executed.
      # @option opts [Proc] :on_cancellation to be executed before the worker is terminated
      # @option opts [Logger] :logger the logger where to output info about this agent's activity.
      # Rest of options required by your subclass.
      def initialize(topic_name:, binding_keys: '#', **opts)
        super(opts.merge(topic_name: topic_name, binding_keys: binding_keys))
      end

      private

      # Set topic exchange_name and binding_keys this worker is bound to.
      # @see #initialize for the list of options that can be received.
      def pre_initialize(**opts)
        @topic_name   = opts[:topic_name]
        @binding_keys = Array(opts[:binding_keys])
        super
      end

      # Bind this worker's queue to the topic exchange and to the given binding_key patterns
      # @see #initialize for the list of options that can be received.
      def post_initialize(**opts)
        bind_queue_to_exchange_routing_keys
        super
      end

      # The durable RabbitMQ topic exchange from where messages are received
      # @return [Bunny::Exchange]
      def exchange
        @exchange ||= channel.topic(topic_name, durable: true)
      end

      # Bind this worker's listening queue to the topic exchange and receive only messages with routing key
      # matching the patterns in binding_keys.
      def bind_queue_to_exchange_routing_keys
        binding_keys.each do |key|
          queue.bind(exchange, routing_key: key)
        end
      end
    end
  end
end
