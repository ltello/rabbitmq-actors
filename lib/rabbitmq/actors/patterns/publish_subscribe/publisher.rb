require_relative '../../base/producer'

module RabbitMQ
  module Actors
    # A producer of messages routed to all the consumers bound to the exchange.
    #
    # @example
    #   RabbitMQ::Server.url = 'amqp://localhost'
    #
    #   publisher = RabbitMQ::Actors::Publisher.new(exchange_name: 'sports', logger: Rails.logger)
    #
    #   message = {
    #     championship: 'Premier League',
    #     match: {
    #       team_1: 'Chelsea',
    #       team_2: 'Manchester City',
    #       date:   '03-Sep-2016',
    #       score:  '2-2'
    #     } }.to_json
    #
    #   publisher.publish(message, message_id: '1234837633', content_type: "application/json")
    #
    class Publisher < Base::Producer
      # @!attribute [r] exchange_name
      #   @return [Bunny::Exchange] the fanout exchange where to publish messages.
      attr_reader :exchange_name

      # @param :exchange_name [String] name of the exchange where to publish messages.
      # @option opts [String] :reply_queue_name the name of the queue where a consumer should reply.
      # @option opts [Logger] :logger the logger where to output info about this agent's activity.
      def initialize(exchange_name:, **opts)
        super(opts.merge(exchange_name: exchange_name))
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
        super(message, opts.merge(message_id: message_id))
      end

      private

      # Sets the exchange name to connect to.
      # @see #initialize for the list of options that can be received.
      def pre_initialize(**opts)
        @exchange_name = opts[:exchange_name]
        super
      end

      # The durable RabbitMQ fanout exchange where to publish messages.
      # @return [Bunny::Exchange]
      def exchange
        @exchange ||= channel.fanout(exchange_name, durable: true)
      end
    end
  end
end
