[![Gem Version](https://badge.fury.io/rb/rabbitmq-actors.svg)](https://badge.fury.io/rb/rabbitmq-actors)
[![Build Status](https://travis-ci.org/ltello/rabbitmq-actors.svg?branch=master)](https://travis-ci.org/ltello/rabbitmq-actors)
[![Code Climate](https://codeclimate.com/github/ltello/rabbitmq-actors/badges/gpa.svg)](https://codeclimate.com/github/ltello/rabbitmq-actors)
[![Issue Count](https://codeclimate.com/github/ltello/rabbitmq-actors/badges/issue_count.svg)](https://codeclimate.com/github/ltello/rabbitmq-actors)
[![Test Coverage](https://codeclimate.com/github/ltello/rabbitmq-actors/badges/coverage.svg)](https://codeclimate.com/github/ltello/rabbitmq-actors/coverage)
[![Coverage Status](https://coveralls.io/repos/github/ltello/rabbitmq-actors/badge.svg)](https://coveralls.io/github/ltello/rabbitmq-actors)
[![Dependency Status](https://gemnasium.com/badges/github.com/ltello/rabbitmq-actors.svg)](https://gemnasium.com/github.com/ltello/rabbitmq-actors)

# RabbitMQ::Actors

rabbitmq-actors is a simple and direct way to use RabbitMQ in your Ruby applications.
It uses the excellent [bunny](http://rubybunny.info/) Ruby client to RabbitMQ and basically, it provides a set of Ruby classes
implementing the most common producer-consumer patterns for multiple applications to exchange messages
using a RabbitMQ message broker:
- _master/worker_
- _publisher/subscriber_
- _routing producers/consumers_
- _topic producers/consumers_ and
- _headers producers/consumers_


## Installation

If you don't have RabbitMQ installed, you can do it following the instructions in [RabbitMQ website](https://www.rabbitmq.com/download.html).
On Mac OSX, the fastest way is via [Homebrew](https://brew.sh/):
```
$ brew install rabbitmq
$ rabbitmq-server
```
Make sure, `/usr/local/sbin` is in your `$PATH`

Once rabbitmq is installed locally or remotely accessible, add this line to your application's Gemfile:

```ruby
gem 'rabbitmq-actors'
```

and execute:

    $ bundle

or install it yourself as:

    $ gem install rabbitmq-actors

## Usage

To use rabbitmq-actors in your application, the first thing you need to do is set the url where the RabbitMQ messaging broker is running:

```
RabbitMQ::Server.url = 'amqp://localhost' # talk to local RabbitMQ server
```

### Patterns
There are different ways you can use RabbitMQ depending on the domain of your application.
RabbitMQ allows you to implement several message exchange patterns between producers and consumers.
Use the one/s that fit most the needs of your application:

### Master - Worker pattern
Under this strategy, one or several programs (masters) produce and publish messages to a known work queue.
On the other hand, consumer programs (workers) bind to that queue so that RabbitMQ distributes all the received
messages among the workers in a round robin manner. Therefore, every message is routed to only one of the workers.
 
**Creating a master producer**
                     
This gem provides the `RabbitMQ::Actors::MasterProducer` class to help you implement master producers in your 
application:

```
master = RabbitMQ::Actors::MasterProducer.new(
  queue_name:       'transactions',
  auto_delete:      false,
  reply_queue_name: 'confirmations',
  logger:           Rails.logger)
```
In the example above, `master` is a new MasterProducer instance routing messages to the `"purchases"`
queue (which won't be automatically deleted by RabbitMQ when there are no consumers listening to it: `auto_delete: false`). 

The `reply_queue_name` param will add a `reply_to: "confirmations"` property to every message published by
this master instance so that the consumer receiving the message knows the queue where it has to publish
any response message.

The activity happening inside `master` (when publishing messages, closing connections...) will be logged to 
`Rails.logger` (STDOUT by default) with `:info` severity level.


**Publishing messages**

To publish a message using our fresh new `master` instance, we just call `publish` instance method with some
mandatory arguments (message and :message_id):

```
message = { stock: 'Apple', number: 1000 }.to_json
master.publish(message, message_id: '1234837325', content_type: "application/json")
```

- `message` is a string containing the body of the message to be published to RabbitMQ
- `:message_id` is a keyword argument and contains any id our application uses to identify the message.
 
There are lots of optional params you can add to publish a message (see the
MasterProducer code documentation and Bunny::Exchange#publish code documentation):

  - `persistent:` Should the message be persisted to disk?. Default true.
  - `mandatory:` Should the message be returned if it cannot be routed to any queue?
  - `timestamp:` A timestamp associated with this message
  - `expiration:` Expiration time after which the message will be deleted
  - `type:` Message type, e.g. what type of event or command this message represents. Can be any string
  - `reply_to:` Queue name other apps should send the response to. Default to `:reply_queue_name if set at creation time.
  - `content_type:` Message content type (e.g. application/json)
  - `content_encoding:` Message content encoding (e.g. gzip)
  - `correlation_id:` Message correlated to this one, e.g. what request this message is a reply for
  - `priority:` Message priority, 0 to 9. Not used by RabbitMQ, only applications
  - `user_id:` Optional user ID. Verified by RabbitMQ against the actual connection username
  - `app_id:` Optional application ID


**Closing the channel**

Finally, close the channel when no more messages are going to be published by the master instance:
```
master.close
```
or using a chained method call after publishing the last message:
```
master.publish(message, message_id: '1234837325', content_type: "application/json").and_close
```

Actors (consumers and producers of all types) can share a connection to RabbitMQ broker
but each one connects via its own private channel. Although RabbitMQ can have thousands
of channels open simulataneously, it is a good practice to close it when an actor is not 
being used anymore.

**Defining a worker consumer**
                     
To define worker consumers of master produced messages, subclass `RabbitMQ::Actors::Worker` class and
define a private `perform` instance method to process a received message like this:

```
  class MyListener < RabbitMQ::Actors::Worker  
    def initialize
      super(queue_name:      'transactions',
            manual_ack:      true
            logger:          Rails.logger,
            on_cancellation: ->{ ActiveRecord::Base.connection.close }
    end
  
    private
  
    def perform(**task)
      message, message_id = JSON.parse(task[:body]), task[:properties][:message_id]
      ... 
      # your code to process the message
    end
  end
```

`RabbitMQ::Actors::Worker` class requires a mandatory keyword argument to initialize instances:

- `queue_name:` string containing the name of the durable queue where to receive messages from.
 
Other optional params you can add to initialize a worker (see the Worker code documentation):

  - `manual_ack:` tells RabbitMQ to wait for a manual acknowledge from the worker before 
 marking a message as "processed" and remove it from the queue. If true, the acknowledgement will be 
 automatically sent by the worker after returning from `perform` method. Defaults to false.
  - `logger:` where to log worker activity with :info severity. Defaults to STDOUT if none provided.
  - `on_cancellation`: a Proc/Lambda object to be called right before the worker is terminated.
  
 
**Running a worker consumer**

Call #start! method on a worker instance to start listening and processing messages from the associated queue.
 
 ```
 MyListener.new.start!
 ```
 
 Press ^c on a console to stop a worker or send a process termination signal.


### Publish - Subscribe pattern
The idea behind this strategy is to broadcast messages to all the subscribed consumers (subscribers)
as opposed to only one consumer as it was the case in the Master - Worker pattern.
 
**Creating a publisher**
                     
Instantiate the class `RabbitMQ::Actors::Publisher` to create publishers of messages under this scheme:

```
  publisher = RabbitMQ::Actors::Publisher.new(exchange_name: 'sports', logger: Rails.logger)
```

`exchange_name:` param is mandatory and contains the name of the RabbitMQ exchange where to publis the
messages.

As we know from the master producer, the activity happening inside `publisher` can be sent to a logger
instance (`Rails.logger` in the example) with `:info` severity level.

Again, like master producers, `RabbitMQ::Actors::Publisher` you can pass a `reply_queue_name:` keyword
param to create a new instance. 


**Publishing messages**

The way for a publisher to publish messages is identical to that of master producers. See documentation 
above.

```
publisher.publish(message, message_id: '1232357390', content_type: "application/json")
```

**Closing the channel**

```
publisher.close
```
or using the chained way:
```
publisher.publish(message, message_id: '1234837390', content_type: "application/json").and_close
```


**Defining a subscriber**
                     
To define your subscriber class, make it a subclass of `RabbitMQ::Actors::Subscriber` class and
define a private `perform` instance method to process a received message like this:

```
  class ScoresListener < RabbitMQ::Actors::Subscriber
    def initialize
      super(exchange_name:   'scores',
            logger:          Rails.logger,
            on_cancellation: ->{ ActiveRecord::Base.connection.close })
    end
  
    private
  
    def perform(**task)
      match_data = JSON.parse(task[:body])
      process_match(match_data)
    end
    ...
  end
```

`RabbitMQ::Actors::Publiser` class requires the following mandatory keyword argument:

- `exchange_name:` name of the exchange where to consume messages from.
 
You can also add `logger:` and `on_cancellation:` keyword params (see worker documentation above)
  
 
**Running a subscriber**

Like every consumer actor, call #start! method on an instance to start listening and processing messages.
 
 ```
 ScoresListener.new.start!
 ```
 
 Press ^c on a console or send a process termination signal to stop it.


### Routing pattern
The routing pattern is similar to _publish/subscribe_ strategy but messages are not routed to all consumers but
only to those bound to the value a property of the message named `routing_key`.
Every consumer bound to the exchange states those `routing_key` values it is interested in. When a message
arrives it comes with a certain `routing_key` value, so the exchange routes it to only those consumers
interested in that particular value.
 
**Creating a routing producer**
                     
Instantiate the class `RabbitMQ::Actors::RoutingProducer` to create publishers of messages under this scheme:

```
  routing_producer = RabbitMQ::Actors::RoutingProducer.new(
    exchange_name:     'sports',
    replay_queue_name: 'scores',
    logger:            Rails.logger)
```
The description of the 3 params is similar to that of the previous producer classes. See above.

**Publishing messages**

```
  message = {
    championship: 'Wimbledon',
    match: {
      player_1: 'Rafa Nadal',
      player_2: 'Roger Federed',
      date:     '01-Jul-2016'
    } }.to_json
  
  routing_producer.publish(message, message_id: '1234837633', content_type: "application/json", routing_key: 'tennis')
```
The way to publish messages is similar to that of the rest of producers. Note the mandatory param `routing_key:`

  - `routing_key:` send the message only to queues bound to this string value.
  
**Closing the channel**

```
routing_producer.close
```
or using the chained way:
```
routing_producer.publish(message, message_id: '1234837633', content_type: "application/json", routing_key: 'tennis').and_close
```


**Defining a routing consumer**
                     
Use the class `RabbitMQ::Actors::RoutingConsumer` in a similar way as to the rest of consumer types:

```
  class TennisListener < RabbitMQ::Actors::RoutingConsumer
    def initialize
      super(exchange_name:   'sports',
            binding_keys:    ['tennis'],
            logger:          Rails.logger,
            on_cancellation: ->{ ActiveRecord::Base.connection.close })
    end
  
    private
  
    def perform(**task)
      match_data = JSON.parse(task[:body])
      process_tennis_match(match_data)
    end
    ...
  end
  
  class FootballListener < RabbitMQ::Actors::RoutingConsumer
    def initialize
      super(exchange_name:   'sports',
            binding_keys:    ['football', 'soccer'],
            logger:          Rails.logger,
            on_cancellation: ->{ ActiveRecord::Base.connection.close })
    end
  
    private
  
    def perform(**task)
      match_data = JSON.parse(task[:body])
      process_footbal_match(match_data)
    end
    ...
  end
```

`RabbitMQ::Actors::RoutingConsumer` class requires the following mandatory keyword arguments:

- `exchange_name:` name of the exchange where to consume messages from.
- `binding_keys:`  a string or list of strings with the routing key values this consumer is interested in.
 
You can also add `logger:` and `on_cancellation:` keyword params (see worker documentation above)
  
 
**Running a routing consumer**

Like every consumer actor, call #start! method on an instance to start listening and processing messages.
 
 ```
 TennisListener.new.start!
 FootballListener.new.start!
 ```
 
 Press ^c on a console or send a process termination signal to stop it.
 

### Topics pattern
The topics pattern is very similar to the routing one. However routing keys are not free string values. Instead,
every routing key is a dot separated list of words.

Binding keys can use special chars to match one or several words:

`* can substitute for exactly one word`
`# can substitute for zero or more words`
 
**Creating a topic producer**
                     
Instantiate the class `RabbitMQ::Actors::TopicProducer` to create publishers of messages under this scheme:

```
  topic_producer = RabbitMQ::Actors::TopicProducer.new(topic_name: 'weather', logger: Rails.logger)
```

where 

 - `topic_name:` (mandatory) is the name of the exchange to send messages to.
  
`reply_queue_name:` and `logger` are the 2 optional params that can be added.


**Publishing messages**

```
  message = { temperature: 20, rain: 30%, wind: 'NorthEast' }.to_json
  topic_producer.publish(message, message_id: '1234837633', content_type: "application/json", routing_key: 'Europe.Spain.Madrid')
```

Note the special format of the mandatory `routing_key:` param
  
  
**Closing the channel**

```
topic_producer.close
```

or using the chained way:

```
  topic_producer.publish(message, message_id: '1234837633', content_type: "application/json", routing_key: 'Europe.Spain.Madrid').and_close
```


**Defining a topic consumer**
                     
Use the class `RabbitMQ::Actors::TopicConsumer` in a similar way as to the rest of consumer types:

``` 
  class SpainTennisListener < RabbitMQ::Actors::TopicConsumer
    def initialize
      super(topic_name:      'sports',
            binding_keys:    '#.tennis.#.spain.#',
            logger:          Rails.logger,
            on_cancellation: ->{ ActiveRecord::Base.connection.close })
    end
  
    private
  
    def perform(**task)
      match_data = JSON.parse(task[:body])
      process_tennis_match(match_data)
    end
  
    def process_tennis_match(data)
      ...
    end
  end
  
  class AmericaSoccerListener < RabbitMQ::Actors::TopicConsumer
    def initialize
      super(exchange_name:   'sports',
            binding_keys:    '#.soccer.#.america.#',
            logger:          Rails.logger,
            on_cancellation: ->{ ActiveRecord::Base.connection.close })
    end
  
    private
  
    def perform(**task)
      match_data = JSON.parse(task[:body])
      process_soccer_match(match_data)
    end
  
    def process_soccer_match(data)
      ...
    end
  end
```

`RabbitMQ::Actors::TopicConsumer` class requires the following mandatory keyword arguments:

- `topic_name:` name of the exchange where to consume messages from.
- `binding_keys:` a string or list of strings with the routing key matching patterns this consumer 
is interested in.
 
As always, you can also add `logger:` and `on_cancellation:` keyword params (see worker documentation above)
  
 
**Running a topic consumer**

Like every consumer actor, call #start! method on an instance to start listening and processing messages.
 
 ```
 SpainTennisListener.new.start!
 AmericaSoccerListener.new.start!
 ```
 
 Press ^c on a console or send a process termination signal to stop it.
 
 
### Headers pattern
The headers pattern is a strategy based on headers instead of routing keys to deliver messages
to consumers. Messages add a `headers:` property including pairs of key-value entries.
Consumers show interest in certain headers to get messages sent.
 
**Creating a headers producer**
                     
Instantiate the class `RabbitMQ::Actors::HeadersProducer` to create publishers of messages under this scheme:

```
  headers_producer = RabbitMQ::Actors::HeadersProducer.new(headers_name: 'reports', logger: Rails.logger)
```

where 

 - `headers_name:` (mandatory) is the name of the exchange to send messages to.
  
`reply_queue_name:` and `logger` are the 2 optional params that can be added.


**Publishing messages**

```
  message = 'A report about USA economy'
  headers_producer.publish(
    message, 
    message_id: '1234837633',
    headers: { 'type' => :economy, 'area' => 'USA'})
```

where
 
  - `headers:` send the message only to consumers bound to this exchange and matching any/all
   of these header pairs.

As usual, `message` and `message_id:` are also mandatory params. See documentation above for
all the optional message params.
  
  
**Closing the channel**

```
headers_producer.close
```

or using the chained way:

```
  headers_producer.publish(...).and_close
```


**Defining a headers consumer**
                     
Use the class `RabbitMQ::Actors::HeadersConsumer` in a similar way as to the rest of consumer types:

````
   class NewYorkBranchListener < RabbitMQ::Actors::HeadersConsumer
     def initialize
       super(headers_name:    'reports',
             binding_headers: { 'type' => :econony, 'area' => 'USA', 'x-match' => 'any' },
             logger:          Rails.logger,
             on_cancellation: ->{ ActiveRecord::Base.connection.close })
     end
   
     private
   
     def perform(**task)
       report_data = JSON.parse(task[:body])
       process_report(report_data)
     end
   
     def process_report(data)
       ...
     end
   end
   
   class LondonBranchListener < RabbitMQ::Actors::HeadersConsumer
     def initialize
       super(headers_name:    'reports',
             binding_headers: { 'type' => :industry, 'area' => 'Europe', 'x-match' =>'any' },
             logger:          Rails.logger,
             on_cancellation: ->{ ActiveRecord::Base.connection.close })
     end
   
     private
   
     def perform(**task)
       report_data = JSON.parse(task[:body])
       process_report(report_data)
     end
   
     def process_report(data)
       ...
     end
   end
````

`RabbitMQ::Actors::HedersConsumer` class requires the following mandatory keyword arguments:

- `headers_name:` name of the exchange where to consume messages from.
- `binding_headers:` hash of headers this consumer is interested in.

Note the special mandatory binding header `'x-match'`. Its value can be one of these:
  - `'any'` receive the message if any of the message headers matches any of the binding headers.
  - `'all'` receive the message only if all of the binding headers are included in the message headers.

Optional params `logger:` and `on_cancellation:`
  
 
**Running a headers consumer**

Like every consumer actor, call #start! method on an instance to start listening and processing messages.
 
```
  NewYorkBranchListener.new.start!
  LondonBranchListener.new.start!
```
 
 Press ^c on a console or send a process termination signal to stop it.
 

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/ltello/rabbitmq-actors

