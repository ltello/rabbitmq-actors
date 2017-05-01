if RSpec.respond_to?(:configure)
  require_relative 'rspec/stub'

  RSpec.configure do |config|
    config.extend  RabbitMQ::Actors::Testing::Rspec::Stub
    config.include RabbitMQ::Actors::Testing::Rspec::Stub
  end
end
