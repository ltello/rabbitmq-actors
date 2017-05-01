require_relative '../../base/producer'

module RabbitMQ
  module Actors
    # A producer of messages routed to all the queues bound to the message's routing_key via matching patterns
    #
    # @example
    #   RabbitMQ::Server.url = 'amqp://localhost'
    #
    #   publisher = RabbitMQ::Actors::TopicProducer.new(topic_name: 'weather', logger: Rails.logger)
    #   message   = { temperature: 20, rain: 30%, wind: 'NorthEast' }.to_json
    #   publisher.publish(message, message_id: '1234837633', content_type: "application/json", routing_key: 'Europe.Spain.Madrid')
    #
    class TopicProducer < Base::Producer
      # @!attribute [r] topic_name
      #   @return [Bunny::Exchange] the topic exchange where to publish messages.
      attr_reader :topic_name

      # @param :topic_name [String] name of the topic exchange where to send messages to.
      # @option opts [String] :reply_queue_name the name of the queue where a consumer should reply.
      # @option opts [Logger] :logger the logger where to output info about this agent's activity.
      def initialize(topic_name:, **opts)
        super(opts.merge(topic_name: topic_name))
      end

      # Send a message to the RabbitMQ server.
      # @param message [String] the message body to be sent.
      # @param :message_id [String] user-defined id for replies to refer to this message using :correlation_id
      # @param :routing_key [String] send the message only to queues bound to this exchange and matching this routing_key
      # @see Bunny::Exchange#publish for extra options:
      # @option opts [Boolean] :persistent Should the message be persisted to disk?. Default true.
      # @option opts [Boolean] :mandatory Should the message be returned if it cannot be routed to any queue?
      # @option opts [Integer] :timestamp A timestamp associated with this message
      # @option opts [Integer] :expiration Expiration time after which the message will be deleted
      # @option opts [String]  :type Message type, e.g. what type of event or command this message represents. Can be any string
      # @option opts [String]  :reply_to Queue name other apps should send the response to. Default to
      #   replay_queue_name if it was defined at creation time.
      # @option opts [String]  :content_type Message content type (e.g. application/json)
      # @option opts [String]  :content_encoding Message content encoding (e.g. gzip)
      # @option opts [String]  :correlation_id Message correlated to this one, e.g. what request this message is a reply for
      # @option opts [Integer] :priority Message priority, 0 to 9. Not used by RabbitMQ, only applications
      # @option opts [String]  :user_id Optional user ID. Verified by RabbitMQ against the actual connection username
      # @option opts [String]  :app_id Optional application ID
      def publish(message, message_id:, routing_key:, **opts)
        super(message, opts.merge(message_id: message_id, routing_key: routing_key))
      end

      private

      # Sets the exchange name to connect to.
      # @see #initialize for the list of options that can be received.
      def pre_initialize(**opts)
        @topic_name = opts[:topic_name]
        super
      end

      # The durable RabbitMQ topic exchange where to publish messages.
      # @return [Bunny::Exchange]
      def exchange
        @exchange ||= channel.topic(topic_name, durable: true)
      end
    end
  end
end
