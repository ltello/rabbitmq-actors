require_relative '../../base/producer'

module RabbitMQ
  module Actors

    # A producer of messages routed (via a default exchange) to a given queue.
    # Used to distribute tasks among several worker processes listening a shared queue.
    #
    # @example
    #   RabbitMQ::Server.url = 'amqp://localhost'
    #
    #   master = RabbitMQ::Actors::MasterProducer.new(
    #     queue_name:       'purchases',
    #     auto_delete:      false,
    #     reply_queue_name: 'confirmations',
    #     logger:           Rails.logger)
    #
    #   message = { stock: 'Apple', number: 1000 }.to_json
    #   master.publish(message, message_id: '1234837325', content_type: "application/json")
    #
    class MasterProducer < Base::Producer
      # @param :queue_name [String] name of the durable queue where to publish messages.
      # @option opts [Boolean] :auto_delete (true) if the queue will be deleted when
      #   there are no more consumers subscribed to it.
      # @option opts [String] :reply_queue_name the name of the queue where a consumer should reply.
      # @option opts [Logger] :logger the logger where to output info about this agent's activity.
      def initialize(queue_name:, **opts)
        super(opts.merge(queue_name: queue_name, exclusive: false))
      end

      # Send a message to the RabbitMQ server.
      # @param message [String] the message body to be sent.
      # @param :message_id [String] user-defined id for replies to refer to this message using :correlation_id
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
      def publish(message, message_id:, **opts)
        super(message, opts.merge(message_id: message_id, routing_key: queue.name))
      end

      private

      # The default RabbitMQ exchange where to publish messages
      # @return [Bunny::Exchange]
      def exchange
        @exchange ||= channel.default_exchange
      end
    end
  end
end
