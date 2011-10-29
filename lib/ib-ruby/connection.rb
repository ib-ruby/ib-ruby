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
                       :port => '4001', # Gateway, TWS: '7496'
                       :open => true
    }

    attr_reader :next_order_id, # Next valid order id
                :server #         Info about server and server connection state

    def initialize(opts = {})
      @options = DEFAULT_OPTIONS.merge(opts)

      @connected = false
      @next_order_id = nil
      @server = Hash.new

      self.open(@options) if @options[:open]
    end

    # Message subscribers. Key is the message class to listen for.
    # Value is a Hash of subscriber Procs, keyed by their subscription id.
    # All subscriber Procs will be called with the message instance
    # as an argument when a message of that type is received.
    def subscribers
      @subscribers ||= Hash.new { |hash, key| hash[key] = Hash.new }
    end

    def open(opts = {})
      raise Exception.new("Already connected!") if @connected

      opts = @options.merge(opts)

      # TWS always sends NextValidID message at connect - save this id
      self.subscribe(:NextValidID) do |msg|
        @next_order_id = msg.data[:id]
        puts "Got next valid order id: #{@next_order_id}."
      end

      @server[:socket] = IBSocket.open(opts[:host], opts[:port])

      # Secret handshake
      @server[:socket].send(CLIENT_VERSION)
      @server[:version] = @server[:socket].read_int
      raise(Exception.new("TWS version >= #{SERVER_VERSION} required.")) if @server[:version] < SERVER_VERSION

      @server[:local_connect_time] = Time.now()
      @server[:remote_connect_time] = @server[:socket].read_string

      # Sending arbitrary client ID to identify subsequent communications.
      @server[:client_id] = random_id
      @server[:socket].send(@server[:client_id])

      # Starting reader thread
      Thread.abort_on_exception = true
      @server[:reader_thread] = Thread.new { self.reader }

      @connected = true
      puts "Connected to server, version: #{@server[:version]}, connection time: " +
               "#{@server[:local_connect_time]} local, " +
               "#{@server[:remote_connect_time]} remote."
    end

    def close
      @server[:reader_thread].kill # Thread uses blocking I/O, so join is useless.
      @server[:socket].close
      @server = Hash.new
      @server[:version] = nil
      @connected = false
    end

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

    # Remove subscriber(s) with specific subscriber id
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
              raise ArgumentError.new("Only able to send Messages::Outgoing")
          end
      message.send_to(@server)
    end

    protected

    def random_id
      rand 999999999
    end

    def reader
      loop do
        # This read blocks, so Thread#join is useless.
        msg_id = @server[:socket].read_int

        # Debug:
        unless [1, 2, 4, 6, 7, 8, 9, 21, 53].include? msg_id
          puts "Got message #{msg_id} (#{Messages::Incoming::Table[msg_id]})"
        end

        # Create new instance of the appropriate message type, and have it read the message.
        # NB: Failure here usually means unsupported message type received
        msg = Messages::Incoming::Table[msg_id].new(@server[:socket])

        subscribers[msg.class].each { |_, subscriber| subscriber.call(msg) }
        puts "No subscribers for incoming message #{msg.class}!" if subscribers[msg.class].empty?
      end # loop
    end # reader

  end

  # class Connection
  IB = Connection # Legacy alias
end # module IB
