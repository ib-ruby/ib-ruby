require 'socket'
require 'logger'
require 'bigdecimal'
require 'bigdecimal/util'

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

  #logger = Logger.new(STDERR)

  class IBSocket < TCPSocket

    # send nice null terminated binary data
    def send(data)
      self.syswrite(data.to_s + "\0")
    end

    def read_string
      self.gets("\0").chop
    end

    def read_int
      self.read_string.to_i
    end

    def read_int_max
      str = self.read_string
      str.nil? || str.empty? ? nil : str.to_i
    end

    def read_boolean
      self.read_string.to_i != 0
    end

    # Floating-point numbers shouldn't be used to store money.
    def read_decimal
      self.read_string.to_d
    end

    def read_decimal_max
      str = self.read_string
      str.nil? || str.empty? ? nil : str.to_d
    end
  end # class IBSocket

  class IB

    # Please note, we are realizing only the most current TWS protocol versions,
    # thus improving performance at the expense of backwards compatibility.
    # Older protocol versions can be found in older gem versions.

    CLIENT_VERSION = 27 # 48 drops dead # Was 27 in original Ruby code
    SERVER_VERSION = 53 # Minimal server version. Latest, was 38 in current Java code.
    TWS_IP_ADDRESS = "127.0.0.1"
    TWS_PORT = "7496"

    attr_reader :next_order_id

    def initialize(options_in = {})
      @options = {:ip => TWS_IP_ADDRESS, :port => TWS_PORT, }.merge(options_in)

      @connected = false
      @next_order_id = nil
      @server = Hash.new # information about server and server connection state

      # Message listeners. Key is the message class to listen for.
      # Value is an Array of Procs. The proc will be called with the populated message
      # instance as its argument when a message of that type is received.
      @listeners = Hash.new { |hash, key| hash[key] = Array.new }

      #logger.debug("IB#init: Initializing...")

      self.open(@options)
    end

    def server_version
      @server[:version]
    end


    def open(options_in = {})
      raise Exception.new("Already connected!") if @connected

      opts = @options.merge(options_in)

      # Subscribe to the NextValidID message from TWS that is always
      # sent at connect, and save the id.
      self.subscribe(IncomingMessages::NextValidID) do |msg|
        @next_order_id = msg.data[:order_id]
        #logger.info { "Got next valid order id #{@next_order_id}." }
      end

      @server[:socket] = IBSocket.open(opts[:ip], opts[:port])
      #logger.info("* TWS socket connected to #{@options[:ip]}:#{@options[:port]}.")

      # Secret handshake.
      @server[:socket].send(CLIENT_VERSION)
      @server[:version] = @server[:socket].read_int
      @server[:local_connect_time] = Time.now()
      @@server_version = @server[:version]
      raise(Exception.new("TWS version >= #{SERVER_VERSION} required.")) if @@server_version < SERVER_VERSION

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
    def subscribe(message_class, code = nil, &block)
      code ||= block

      raise ArgumentError.new "Need listener proc or block" unless code.is_a? Proc
      unless message_class < IncomingMessages::AbstractMessage
        raise ArgumentError.new "#{message_class} must be an IB message class"
      end

      @listeners[message_class].push(code)
    end

    # Send an outgoing message.
    def dispatch(message)
      raise Exception.new("dispatch() must be given an OutgoingMessages::AbstractMessage subclass") unless message.is_a?(OutgoingMessages::AbstractMessage)

      #logger.info("Sending message " + message.inspect)
      message.send(@server)
    end

    protected

    def reader
      #logger.debug("Reader started.")

      while true
        # this blocks, so Thread#join is useless.
        msg_id = @server[:socket].read_int

        #logger.debug { "Reader: got message id #{msg_id}.\n" }

        # Create a new instance of the appropriate message type, and have it read the message.
        # NB: Failure here usually means unsupported message type received
        msg = IncomingMessages::Table[msg_id].new(@server[:socket], @server[:version])

        @listeners[msg.class].each { |listener|
          listener.call(msg)
        }

        #logger.debug { " Listeners: #{@listeners.inspect} inclusion: #{ @listeners.include?(msg.class)}" }

        # Log the error messages. Make an exception for the "successfully connected"
        # messages, which, for some reason, come back from IB as errors.
        if msg.is_a?(IncomingMessages::Error)
          # connect strings
          if msg.code == 2104 || msg.code == 2106
            #logger.info(msg.to_human)
          else
            #logger.error(msg.to_human)
          end
        else
          # Warn if nobody listened to a non-error incoming message.
          unless @listeners[msg.class].size > 0
            #logger.warn { " WARNING: Nobody listened to incoming message #{msg.class}" }
          end
        end

        # #logger.debug("Reader done with message id #{msg_id}.")
      end # while
    end # reader

  end # class IB
end # module IB
