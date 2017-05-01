module RabbitMQ
  module Actors
    module Testing
    end
  end
end

require_relative 'testing/rspec' if defined?(RSpec)
