require 'ib-ruby/socket'
require 'logger'

# Add method to_ib to render datetime in IB format (zero padded "yyyymmdd HH:mm:ss")
class Time
  def to_ib
    "#{self.year}#{sprintf("%02d", self.month)}#{sprintf("%02d", self.day)} " +
        "#{sprintf("%02d", self.hour)}:#{sprintf("%02d", self.min)}:#{sprintf("%02d", self.sec)}"
  end
end # Time

module IB
  # Encapsulates API connection to TWS or Gateway
  class Connection

    # Please note, we are realizing only the most current TWS protocol versions,
    # thus improving performance at the expense of backwards compatibility.
    # Older protocol versions support can be found in older gem versions.

    CLIENT_VERSION = 48 # Was 27 in original Ruby code
    SERVER_VERSION = 53 # Minimal server version. Latest, was 38 in current Java code.
    DEFAULT_OPTIONS = {:host =>"127.0.0.1",
                       :port => '4001', # IB Gateway connection (default)
                       #:port => '7496', # TWS connection, with annoying pop-ups
                       :client_id => nil, # Will be randomly assigned
                       :connect => true,
                       :reader => true
    }

    # Singleton to make active Connection universally accessible as IB::Connection.current
    class << self
      attr_accessor :current
    end

    attr_reader :server #         Info about IB server and server connection state
    attr_accessor :next_order_id #  Next valid order id

    def initialize(opts = {})
      @options = DEFAULT_OPTIONS.merge(opts)

      @connected = false
      @next_order_id = nil
      @server = Hash.new

      connect if @options[:connect]
      start_reader if @options[:reader]
      Connection.current = self
    end

    # Message subscribers. Key is the message class to listen for.
    # Value is a Hash of subscriber Procs, keyed by their subscription id.
    # All subscriber Procs will be called with the message instance
    # as an argument when a message of that type is received.
    def subscribers
      @subscribers ||= Hash.new { |hash, key| hash[key] = Hash.new }
    end

    def connect
      raise Exception.new("Already connected!") if @connected

      # TWS always sends NextValidID message at connect - save this id
      self.subscribe(:NextValidID) do |msg|
        @next_order_id = msg.data[:id]
        puts "Got next valid order id: #{@next_order_id}."
      end

      @server[:socket] = IBSocket.open(@options[:host], @options[:port])

      # Secret handshake
      @server[:socket].send(CLIENT_VERSION)
      @server[:version] = @server[:socket].read_int
      raise(Exception.new("TWS version >= #{SERVER_VERSION} required.")) if @server[:version] < SERVER_VERSION

      @server[:local_connect_time] = Time.now()
      @server[:remote_connect_time] = @server[:socket].read_string

      # Sending (arbitrary) client ID to identify subsequent communications.
      # The client with a client_id of 0 can manage the TWS-owned open orders.
      # Other clients can only manage their own open orders.
      @server[:client_id] = @options[:client_id] || random_id
      @server[:socket].send(@server[:client_id])

      @connected = true
      puts "Connected to server, version: #{@server[:version]}, connection time: " +
               "#{@server[:local_connect_time]} local, " +
               "#{@server[:remote_connect_time]} remote."
    end

    alias open connect # Legacy alias

    def disconnect
      if @server[:reader]
        @reader_running = false
        @server[:reader].join
      end
      @server[:socket].close
      @server = Hash.new
      @connected = false
    end

    alias close disconnect # Legacy alias

    def connected?
      @connected
    end

    # Subscribe Proc or block to specific type(s) of incoming message events.
    # Listener will be called later with received message instance as its argument.
    # Returns subscriber id to allow unsubscribing
    def subscribe(*args, &block)
      subscriber = args.last.respond_to?(:call) ? args.pop : block
      subscriber_id = random_id

      raise ArgumentError.new "Need subscriber proc or block" unless subscriber.is_a? Proc

      args.each do |what|
        message_class =
            case
              when what.is_a?(Class) && what < Messages::Incoming::AbstractMessage
                what
              when what.is_a?(Symbol)
                Messages::Incoming.const_get(what)
              else
                raise ArgumentError.new "#{what} must represent incoming IB message class"
            end

        subscribers[message_class][subscriber_id] = subscriber
      end
      subscriber_id
    end

    # Remove all subscribers with specific subscriber id
    def unsubscribe(subscriber_id)

      subscribers.each do |message_class, message_subscribers|
        message_subscribers.delete subscriber_id
      end
    end

    # Send an outgoing message.
    def send_message(what, *args)
      message =
          case
            when what.is_a?(Messages::Outgoing::AbstractMessage)
              what
            when what.is_a?(Class) && what < Messages::Outgoing::AbstractMessage
              what.new *args
            when what.is_a?(Symbol)
              Messages::Outgoing.const_get(what).new *args
            else
              raise ArgumentError.new "Only able to send outgoing IB messages"
          end
      message.send_to(@server)
    end

    alias dispatch send_message # Legacy alias

    # Process incoming messages during *poll_time* (200) msecs
    def process_messages poll_time = 200 # in msec
      time_out = Time.now + poll_time/1000.0
      while (time_left = time_out - Time.now) > 0
        # If server socket is readable, process single incoming message
        process_message if select [@server[:socket]], nil, nil, time_left
      end
    end

    # Process single incoming message (blocking)
    def process_message
      # This read blocks!
      msg_id = @server[:socket].read_int

      # Debug:
      unless [1, 2, 4, 6, 7, 8, 9, 12, 21, 53].include? msg_id
        puts "Got message #{msg_id} (#{Messages::Incoming::Table[msg_id]})"
      end

      # Create new instance of the appropriate message type, and have it read the message.
      # NB: Failure here usually means unsupported message type received
      msg = Messages::Incoming::Table[msg_id].new(@server[:socket])

      subscribers[msg.class].each { |_, subscriber| subscriber.call(msg) }
      puts "No subscribers for message #{msg.class}!" if subscribers[msg.class].empty?
    end

    # Place Order (convenience wrapper for message :PlaceOrder)
    def place_order order, contract
      send_message :PlaceOrder,
                   :order => order,
                   :contract => contract,
                   :id => @next_order_id
      @next_order_id += 1
    end

    protected

    def random_id
      rand 999999999
    end

    # Start reader thread that continuously reads messages from server in background.
    # If you don't start reader, you should manually poll @server[:socket] for messages
    # or use #process_messages(msec) API.
    def start_reader
      Thread.abort_on_exception = true
      @reader_running = true
      @server[:reader] = Thread.new do
        process_messages while @reader_running
      end
    end

  end # class Connection
  #IB = Connection # Legacy alias

end # module IB
