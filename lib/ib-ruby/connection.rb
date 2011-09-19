require 'ib-ruby/socket'
require 'logger'

if RUBY_VERSION < "1.9"
  require 'sha1'
else
  require 'digest/sha1'
  include Digest
end

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

    attr_reader :next_order_id

    def initialize(opts = {})
      @options = DEFAULT_OPTIONS.merge(opts)

      @connected = false
      @next_order_id = nil
      @server = Hash.new # information about server and server connection state

      # Message listeners. Key is the message class to listen for.
      # Value is an Array of Procs. The proc will be called with the populated message
      # instance as its argument when a message of that type is received.
      # TODO: change Array of Procs into a Hash to allow unsubscribing
      @listeners = Hash.new { |hash, key| hash[key] = Array.new }

      self.open(@options) if @options[:open]
    end

    def server_version
      @server[:version]
    end

    def open(opts = {})
      raise Exception.new("Already connected!") if @connected

      opts = @options.merge(opts)

      # Subscribe to the NextValidID message from TWS that is always
      # sent at connect, and save the id.
      self.subscribe(Messages::Incoming::NextValidID) do |msg|
        @next_order_id = msg.data[:id]
        puts "Got next valid order id #{@next_order_id}."
      end

      @server[:socket] = IBSocket.open(opts[:host], opts[:port])

      # Secret handshake.
      @server[:socket].send(CLIENT_VERSION)
      @server[:version] = @server[:socket].read_int
      @server[:local_connect_time] = Time.now()
      raise(Exception.new("TWS version >= #{SERVER_VERSION} required.")) if @server[:version] < SERVER_VERSION

      puts "\tGot server version: #{@server[:version]}."
      #logger.debug("\tGot server version: #{@server[:version]}.")

      # Server version >= 20 sends the server time back. Our min server version is 38
      @server[:remote_connect_time] = @server[:socket].read_string
      #logger.debug("\tServer connect time: #{@server[:remote_connect_time]}.")

      # Server wants an arbitrary client ID at this point. This can be used
      # to identify subsequent communications.
      @server[:client_id] = SHA1.digest(Time.now.to_s + $$.to_s).unpack("C*").join.to_i % 999999999
      @server[:socket].send(@server[:client_id])
      #logger.debug("\tSent client id # #{@server[:client_id]}.")

      #logger.debug("Starting reader thread..")
      Thread.abort_on_exception = true
      @server[:reader_thread] = Thread.new { self.reader }

      @connected = true
    end

    def close
      @server[:reader_thread].kill # Thread uses blocking I/O, so join is useless.
      @server[:socket].close()
      @server = Hash.new
      @@server_version = nil
      @connected = false
      #logger.debug("Disconnected.")
    end

    def to_s
      "IB Connector: #{ @connected ? "connected." : "disconnected."}"
    end

    # Subscribe to incoming message events of type message_class.
    # code is a Proc that will be called with the message instance as its argument.
    def subscribe(*args, &block)
      code = args.last.respond_to?(:call) ? args.pop : block

      raise ArgumentError.new "Need listener proc or block" unless code.is_a? Proc

      args.each do |message_class|
        if message_class.is_a? Symbol
          message_class = Messages::Incoming.const_get(message_class)
        end

        unless message_class < Messages::Incoming::AbstractMessage
          raise ArgumentError.new "#{message_class} must be an IB message class"
        end

        @listeners[message_class].push(code)
      end
    end

    # Send an outgoing message.
    def send(message, *args)
      if message.is_a? Symbol
        message = Messages::Outgoing.const_get(message).new *args
      end

      raise Exception.new("only sending Messages::Outgoing") unless message.is_a? Messages::Outgoing::AbstractMessage

      message.send(@server)
    end

    protected

    def reader
      loop do
        # this blocks, so Thread#join is useless.
        msg_id = @server[:socket].read_int

        # Debug:
        unless [1, 2, 4, 6, 7, 8, 9, 21, 53].include? msg_id
          puts "Got message #{msg_id} (#{Messages::Incoming::Table[msg_id]})"
        end

        # Create a new instance of the appropriate message type, and have it read the message.
        # NB: Failure here usually means unsupported message type received
        msg = Messages::Incoming::Table[msg_id].new(@server[:socket], @server[:version])

        if @listeners[msg.class].size > 0
          @listeners[msg.class].each { |listener| listener.call(msg) }
        else
          # Warn if nobody listened to an incoming message.
          puts " WARNING: Nobody listened to incoming message #{msg.class}"
        end
      end # loop
    end # reader
  end # class Connection
  IB = Connection # Legacy alias
end # module IB
