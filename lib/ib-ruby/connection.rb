require 'ib-ruby/socket'
require 'ib-ruby/logger'

module IB
  # Encapsulates API connection to TWS or Gateway
  class Connection

    # Please note, we are realizing only the most current TWS protocol versions,
    # thus improving performance at the expense of backwards compatibility.
    # Older protocol versions support can be found in older gem versions.

    CLIENT_VERSION = 48 # Was 27 in original Ruby code
    SERVER_VERSION = 53 # Minimal server version. Latest, was 38 in current Java code.
    DEFAULT_OPTIONS = {:host =>'127.0.0.1',
                       :port => '4001', # IB Gateway connection (default)
                       #:port => '7496', # TWS connection, with annoying pop-ups
                       :client_id => nil, # Will be randomly assigned
                       :connect => true, # Connect at initialization
                       :reader => true, # Start a separate reader Thread
                       :received => true, # Keep all received messages in a Hash
                       :logger => nil,
    }

    # Singleton to make active Connection universally accessible as IB::Connection.current
    class << self
      attr_accessor :current
    end

    attr_reader :server #         Info about IB server and server connection state
    attr_accessor :next_order_id #  Next valid order id

    def initialize opts = {}
      @options = DEFAULT_OPTIONS.merge(opts)

      self.default_logger = @options[:logger] if @options[:logger]
      @connected = false
      @next_order_id = nil
      @server = Hash.new

      connect if @options[:connect]
      Connection.current = self
    end

    ### Working with connection

    def connect
      raise "Already connected!" if connected?

      # TWS always sends NextValidID message at connect - save this id
      self.subscribe(:NextValidID) do |msg|
        @next_order_id = msg.order_id
        log.info "Got next valid order id: #{@next_order_id}."
      end

      @server[:socket] = IBSocket.open(@options[:host], @options[:port])

      # Secret handshake
      @server[:socket].send(CLIENT_VERSION)
      @server[:version] = @server[:socket].read_int
      raise "TWS version >= #{SERVER_VERSION} required." if @server[:version] < SERVER_VERSION

      @server[:local_connect_time] = Time.now()
      @server[:remote_connect_time] = @server[:socket].read_string

      # Sending (arbitrary) client ID to identify subsequent communications.
      # The client with a client_id of 0 can manage the TWS-owned open orders.
      # Other clients can only manage their own open orders.
      @server[:client_id] = @options[:client_id] || random_id
      @server[:socket].send(@server[:client_id])

      @connected = true
      log.info "Connected to server, version: #{@server[:version]}, connection time: " +
                   "#{@server[:local_connect_time]} local, " +
                   "#{@server[:remote_connect_time]} remote."

      start_reader if @options[:reader] # Allows reconnect
    end

    alias open connect # Legacy alias

    def disconnect
      if reader_running?
        @reader_running = false
        @server[:reader].join
      end
      if connected?
        @server[:socket].close
        @server = Hash.new
        @connected = false
      end
    end

    alias close disconnect # Legacy alias

    def connected?
      @connected
    end

    ### Working with message subscribers

    # Subscribe Proc or block to specific type(s) of incoming message events.
    # Listener will be called later with received message instance as its argument.
    # Returns subscriber id to allow unsubscribing
    def subscribe *args, &block
      subscriber = args.last.respond_to?(:call) ? args.pop : block
      id = random_id

      raise ArgumentError.new "Need subscriber proc or block" unless subscriber.is_a? Proc

      args.each do |what|
        message_classes =
            case
              when what.is_a?(Class) && what < Messages::Incoming::AbstractMessage
                [what]
              when what.is_a?(Symbol)
                [Messages::Incoming.const_get(what)]
              when what.is_a?(Regexp)
                Messages::Incoming::Table.values.find_all { |klass| klass.to_s =~ what }
              else
                raise ArgumentError.new "#{what} must represent incoming IB message class"
            end
        message_classes.flatten.each do |message_class|
          # TODO: Fix: RuntimeError: can't add a new key into hash during iteration
          subscribers[message_class][id] = subscriber
        end
      end
      id
    end

    # Remove all subscribers with specific subscriber id (TODO: multiple ids)
    def unsubscribe *ids
      removed = []
      ids.each do |id|
        removed_at_id = subscribers.map { |_, subscribers| subscribers.delete id }.compact
        raise "No subscribers with id #{id}" if removed_at_id.empty?
        removed << removed_at_id
      end
      removed.flatten
    end

    # Message subscribers. Key is the message class to listen for.
    # Value is a Hash of subscriber Procs, keyed by their subscription id.
    # All subscriber Procs will be called with the message instance
    # as an argument when a message of that type is received.
    def subscribers
      @subscribers ||= Hash.new { |hash, subs| hash[subs] = Hash.new }
    end

    ## Check if subscribers for given type exists
    #def subscribed? message_type
    #  message_type
    #  (subscribers[message_type.class] ||
    #      subscribers[message_type.class] ||
    #      subscribers[message_type]).empty?
    #end

    ### Working with received messages Hash

    # Hash of received messages, keyed by message type
    def received
      @received ||= Hash.new { |hash, message_type| hash[message_type] = Array.new }
    end

    # Check if messages of given type were received at_least n times
    def received? message_type, times=1
      received[message_type].size >= times
    end

    # Clear received messages Hash
    def clear_received message_type=nil
      if message_type
        received[message_type].clear
      else
        received.each { |_, message_type| message_type.clear }
      end
    end

    ### Working with Incoming messages from IB

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

    def reader_running?
      @reader_running && @server[:reader] && @server[:reader].alive?
    end

    # Process incoming messages during *poll_time* (200) msecs, nonblocking
    def process_messages poll_time = 200 # in msec
      time_out = Time.now + poll_time/1000.0
      while (time_left = time_out - Time.now) > 0
        # If server socket is readable, process single incoming message
        process_message if select [@server[:socket]], nil, nil, time_left
      end
    end

    # Process single incoming message (blocking!)
    def process_message
      msg_id = @server[:socket].read_int # This read blocks!

      # Debug:
      log.debug "Got message #{msg_id} (#{Messages::Incoming::Table[msg_id]})"

      # Create new instance of the appropriate message type, and have it read the message.
      # NB: Failure here usually means unsupported message type received
      msg = Messages::Incoming::Table[msg_id].new(@server[:socket])

      # Deliver message to all registered subscribers, alert if no subscribers
      subscribers[msg.class].each { |_, subscriber| subscriber.call(msg) }
      log.warn "No subscribers for message #{msg.class}!" if subscribers[msg.class].empty?

      # Collect all received messages into a @received Hash
      received[msg.message_type] << msg if @options[:received]
    end

    ### Sending Outgoing messages to IB

    # Send an outgoing message.
    def send_message what, *args
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
      raise "Not able to send messages, IB not connected!" unless connected?
      message.send_to(@server)
    end

    alias dispatch send_message # Legacy alias

    # Place Order (convenience wrapper for send_message :PlaceOrder).
    # Assigns client_id and order_id fields to placed order. Returns assigned order_id.
    def place_order order, contract
      send_message :PlaceOrder,
                   :order => order,
                   :contract => contract,
                   :id => @next_order_id
      order.client_id = @server[:client_id]
      order.order_id = @next_order_id
      @next_order_id += 1
      order.order_id
    end

    # Cancel Orders by their ids (convenience wrapper for send_message :CancelOrder).
    def cancel_order *order_ids
      order_ids.each do |order_id|
        send_message :CancelOrder, :id => order_id.to_i
      end
    end

    protected

    def random_id
      rand 999999999
    end

  end # class Connection
end # module IB
