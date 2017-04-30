# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'rabbitmq/actors/version'

Gem::Specification.new do |spec|
  spec.name          = "rabbitmq-actors"
  spec.version       = RabbitMQ::Actors::VERSION
  spec.authors       = ["Lorenzo Tello"]
  spec.email         = ["ltello8a@gmail.com"]

  spec.summary       = "Ruby client agents implementing different RabbitMQ producer/consumer patterns."
  spec.description   = "High level classes (consumers, producers, publishers...) for a Ruby application to use RabbitMQ."
  spec.homepage      = "https://github.com/ltello/rabbitmq-actors"

  spec.files         = `git ls-files -z`.split("\x0").reject do |f|
    f.match(%r{^(test|spec|features)/})
  end
  spec.bindir        = "exe"
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_development_dependency "bundler",      "~> 1.13"
  spec.add_development_dependency "rake"                   # Run scripted tasks
  spec.add_development_dependency "rspec",        "~> 3.4" # Test framework
  spec.add_development_dependency "factory_girl", "~> 4.5" # Data factories to be used in tests
  spec.add_development_dependency "byebug",       "~> 5.0" # Debugger
  spec.add_development_dependency "simplecov"              # Code coverage analyzer

  spec.add_runtime_dependency "activesupport", "~> 4.2" # Rails ActiveSupport
  spec.add_runtime_dependency "bunny",         "~> 2.0" # Ruby RabbitMQ client.
end
