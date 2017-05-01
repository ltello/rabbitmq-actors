require_relative '../../base/consumer'

module RabbitMQ
  module Actors
    # A consumer of messages from RabbitMQ based on queue name.
    # @abstract Subclass and override #perform to define your customized worker class.
    #
    # @example
    #   class MyListener < RabbitMQ::Actors::Worker
    #     class_attribute :queue_name, instance_writer: false
    #
    #     def initialize
    #       super(queue_name:      queue_name,
    #             manual_ack:      true
    #             logger:          Rails.logger,
    #             on_cancellation: ->{ ActiveRecord::Base.connection.close }
    #     end
    #
    #   private
    #
    #     def perform(**task)
    #       answer, transaction_guid = JSON.parse(task[:body]), task[:properties][:correlation_id]
    #       transaction = referred_transaction(transaction_guid: transaction_guid, tid: answer['tid'])
    #       return _no_transaction!(message_id: transaction_guid, transaction: transaction) if transaction.errors.present?
    #       update_transaction(transaction, answer.symbolize_keys)
    #     end
    #
    #     def referred_transaction(transaction_guid:, tid:)
    #       ...
    #     end
    #
    #     def update_transaction(purchase, **attrs)
    #       ...
    #     end
    #
    #     def _no_transaction!(message_id:, transaction:)
    #       log_event(type:        'Transaction',
    #                 message_id:  message_id,
    #                 description: 'ERROR: answer does not identify any transaction',
    #                 payload:     { errors: transaction.errors.full_messages },
    #                 severity:    :high)
    #       transaction
    #     end
    #   end
    #
    #   RabbitMQ::Server.url = 'amqp://localhost'
    #
    #   MyListener.queue_name = "transactions"
    #   MyListener.new.start!
    #
    class Worker < Base::Consumer
      # @param :queue_name [String] name of the durable queue where to receive messages from.
      # @option opts [Boolean] :manual_ack to acknowledge messages to the RabbitMQ server
      #   once executed.
      # @option opts [Proc] :on_cancellation to be executed before the worker is terminated
      # @option opts [Logger] :logger the logger where to output info about this agent's activity.
      # Rest of options required by your subclass.
      def initialize(queue_name:, **opts)
        super(opts.merge(queue_name: queue_name, exclusive: false))
      end
    end
  end
end
