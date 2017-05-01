require_relative '../../base/consumer'

module RabbitMQ
  module Actors
    # A consumer of messages from RabbitMQ based on exchange and message headers matching.
    # @abstract Subclass and override #perform to define your customized headers worker class.
    #
    # @example
    #   class NewYorkBranchListener < RabbitMQ::Actors::HeadersConsumer
    #     def initialize
    #       super(headers_name:    'reports',
    #             binding_headers: { 'type' => :econony, 'area' => 'Usa', 'x-match' => 'any' },
    #             logger:          Rails.logger,
    #             on_cancellation: ->{ ActiveRecord::Base.connection.close })
    #     end
    #
    #     private
    #
    #     def perform(**task)
    #       report_data = JSON.parse(task[:body])
    #       process_report(report_data)
    #     end
    #
    #     def process_report(data)
    #       ...
    #     end
    #   end
    #
    #   class LondonBranchListener < RabbitMQ::Actors::HeadersConsumer
    #     def initialize
    #       super(headers_name:    'reports',
    #             binding_headers: { 'type' => :industry, 'area' => 'Europe', 'x-match' =>'any' },
    #             logger:          Rails.logger,
    #             on_cancellation: ->{ ActiveRecord::Base.connection.close })
    #     end
    #
    #     private
    #
    #     def perform(**task)
    #       report_data = JSON.parse(task[:body])
    #       process_report(report_data)
    #     end
    #
    #     def process_report(data)
    #       ...
    #     end
    #   end
    #
    #   RabbitMQ::Server.url = 'amqp://localhost'
    #
    #   NewYorkBranchListener.new.start!
    #   LondonBranchListener.new.start!
    #
    class HeadersConsumer < Base::Consumer
      # @!attribute [r] headers_name
      #   @return [Bunny::Exchange] the headers exchange where to get messages from.
      attr_reader :headers_name

      # @!attribute [r] binding_headers
      #   @return [Hash] the headers this worker is interested in.
      #     The header 'x-match' MUST be included with value
      #     'any' (match if any message header value matches) or
      #     'all' (all message header values must match)
      attr_reader :binding_headers

      # @param :headers_name [String] name of the headers exchange this worker will receive messages.
      # @param :binding_headers [Hash] headers this worker is interested in.
      #   Default to all: '#'
      # @option opts [Boolean] :manual_ack to acknowledge messages to the RabbitMQ server
      #   once executed.
      # @option opts [Proc] :on_cancellation to be executed before the worker is terminated
      # @option opts [Logger] :logger the logger where to output info about this agent's activity.
      # Rest of options required by your subclass.
      def initialize(headers_name:, binding_headers:, **opts)
        super(opts.merge(headers_name: headers_name, binding_headers: binding_headers))
      end

      private

      # Set headers exchange_name and binding_headers this worker is bound to.
      # @see #initialize for the list of options that can be received.
      def pre_initialize(**opts)
        @headers_name    = opts[:headers_name]
        @binding_headers = opts[:binding_headers]
        super
      end

      # Bind this worker's queue to the headers exchange and to the given binding_key patterns
      # @see #initialize for the list of options that can be received.
      def post_initialize(**opts)
        bind_queue_to_exchange_routing_keys
        super
      end

      # The durable RabbitMQ headers exchange from where messages are received
      # @return [Bunny::Exchange]
      def exchange
        @exchange ||= channel.headers(headers_name, durable: true)
      end

      # Bind this worker's listening queue to the headers exchange and receive only messages with headers
      # matching all/any of the ones in binding_headers.
      def bind_queue_to_exchange_routing_keys
        queue.bind(exchange, arguments: binding_headers)
      end
    end
  end
end
