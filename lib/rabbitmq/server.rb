module RabbitMQ
  module Server

    # The url to the server
    mattr_reader :url, instance_accessor: false

    # The bunny connection object to the server
    mattr_reader :connection, instance_accessor: false

    class << self
      # Set the url to the server and open a new connection
      def url=(url)
        @@url        = url
        @@connection = Bunny.new(url).start
      end
    end
  end
end
