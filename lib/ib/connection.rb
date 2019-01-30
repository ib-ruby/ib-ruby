require 'thread'
require 'active_support'
require 'ib/socket'
require 'ib/logger'
require 'ib/messages'

module IB
  # Encapsulates API connection to TWS or Gateway
  class Connection

  
  ## -------------------------------------------- Interface ---------------------------------
  ## public attributes: socket, next_local_id ( alias next_order_id)
  ## public methods:  connect (alias open), disconnect, connected?
  ##		      subscribe, unsubscribe
  ##		      send_message (alias dispatch)
  ##		      place_order, modify_order, cancel_order
  ## public data-queue: received,  received?, wait_for, clear_received
  ## misc:	      reader_running? 

  include LogDev   # provides default_logger

    mattr_accessor :current
    mattr_accessor :logger  ## borrowed from active_support
    # Please note, we are realizing only the most current TWS protocol versions,
    # thus improving performance at the expense of backwards compatibility.
    # Older protocol versions support can be found in older gem versions.

    attr_accessor  :socket #   Socket to IB server (TWS or Gateway)
    attr_accessor  :next_local_id # Next valid order id 
    attr_accessor  :client_id 
    attr_accessor  :server_version
    attr_accessor  :client_version
    alias next_order_id next_local_id
    alias next_order_id= next_local_id=
    
    def initialize host: '127.0.0.1',
                   port: '4002', # IB Gateway connection (default --> demo) 4001:  production
                       #:port => '7497', # TWS connection  --> demo				  7496:  production
                   connect: true, # Connect at initialization
                   received:  true, # Keep all received messages in a @received Hash
#									 redis: false,    # future plans
                   logger: default_logger,
                   client_id: random_id, 
                   client_version: IB::Messages::CLIENT_VERSION,	# lib/ib/server_versions.rb
									 optional_capacities: "", # TWS-Version 974: "+PACEAPI" 
                   #server_version: IB::Messages::SERVER_VERSION, # lib/messages.rb
		   **any_other_parameters_which_are_ignored
			 # V 974 release motes
# API messages sent at a higher rate than 50/second can now be paced by TWS at the 50/second rate instead of potentially causing a disconnection. This is now done automatically by the RTD Server API and can be done with other API technologies by invoking SetConnectOptions("+PACEAPI") prior to eConnect.


    # convert parameters into instance-variables and assign them
		method(__method__).parameters.each do |type, k|
			next unless type == :key
			case k
			when :logger
				self.logger = logger  
			else
				v = eval(k.to_s)
				instance_variable_set("@#{k}", v) unless v.nil?
			end
		end

		# A couple of locks to avoid race conditions in JRuby
		@subscribe_lock = Mutex.new
		@receive_lock = Mutex.new
		@message_lock = Mutex.new

		@connected = false
		self.next_local_id = nil

		#     self.subscribe(:Alert) do |msg|
		#       puts msg.to_human
		#     end

		# TWS always sends NextValidId message at connect -subscribe save this id
		## this block is executed before tws-communication is established
		yield self if block_given?

		self.subscribe(:NextValidId) do |msg|
			logger.progname = "Connection#connect"
			self.next_local_id = msg.local_id
			logger.info { "Got next valid order id: #{next_local_id}." }
		end

		# Ensure the transmission of NextValidId.
		# works even if no reader_thread is established
		if connect
			disconnect if connected?
			 update_next_order_id
			Kernel.exit if self.next_local_id.nil?
		end
		#start_reader if @received && connected?
		Connection.current = self
		end

		# read actual order_id and
		# connect if not connected
		def update_next_order_id
			i,finish = 0, false
			sub = self.subscribe(:NextValidID) { finish =  true }
			connected? ?  self.send_message( :RequestIds )  : open()
			Timeout::timeout(1, IB::TransmissionError,"Could not get NextValidId" ) do
				loop { sleep 0.1; break if finish  }
			end
			self.unsubscribe sub
		end

		### Working with connection

		def connect
			logger.progname='IB::Connection#connect' 
			if connected?
				error  "Already connected!"
				return
			end

			self.socket = IBSocket.open(@host, @port)  # raises  Errno::ECONNREFUSED  if no connection is possible
			socket.initialising_handshake
			socket.decode_message( socket.recieve_messages ) do  | the_message |
				#				logger.info{ "TheMessage :: #{the_message.inspect}" }
				@server_version =  the_message.shift.to_i
				error "ServerVersion does not match  #{@server_version} <--> #{MAX_CLIENT_VER}" if @server_version != MAX_CLIENT_VER

				@remote_connect_time = DateTime.parse the_message.shift
				@local_connect_time = Time.now
			end

			# Sending (arbitrary) client ID to identify subsequent communications.
			# The client with a client_id of 0 can manage the TWS-owned open orders.
			# Other clients can only manage their own open orders.

			# V100 initial handshake
			# Parameters borrowed from the python client
			start_api = 71
			version = 2
			#			optcap = @optional_capacities.empty? ? "" : " "+ @optional_capacities 
			socket.send_messages start_api, version, @client_id  , @optional_capacities 
			@connected = true
			logger.info { "Connected to server, version: #{@server_version},\n connection time: " +
								 "#{@local_connect_time} local, " +
									 "#{@remote_connect_time} remote."}

			# if the client_id is wrong or the port is not accessible the first read attempt fails
			# get the first message and proceed if something reasonable is recieved
			the_message = process_message   # recieve next_order_id
			error "Check Port/Client_id ", :reader if the_message == " "
			start_reader  
		end

    alias open connect # Legacy alias

    def disconnect
      if reader_running?
        @reader_running = false
        @reader_thread.join
      end
      if connected?
        socket.close
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
      @subscribe_lock.synchronize do
        subscriber = args.last.respond_to?(:call) ? args.pop : block
        id = random_id

        error  "Need subscriber proc or block ", :args  unless subscriber.is_a? Proc

        args.each do |what|
          message_classes =
          case
          when what.is_a?(Class) && what < Messages::Incoming::AbstractMessage
            [what]
          when what.is_a?(Symbol)
            [Messages::Incoming.const_get(what)]
          when what.is_a?(Regexp)
            Messages::Incoming::Classes.values.find_all { |klass| klass.to_s =~ what }
          else
            error  "#{what} must represent incoming IB message class", :args 
          end
     # @subscribers_lock.synchronize do
          message_classes.flatten.each do |message_class|
            # TODO: Fix: RuntimeError: can't add a new key into hash during iteration
            subscribers[message_class][id] = subscriber
          end
     # end  # lock
        end

        id
      end
    end

    # Remove all subscribers with specific subscriber id
		def unsubscribe *ids
			@subscribe_lock.synchronize do
				ids.collect do |id|
					removed_at_id = subscribers.map { |_, subscribers| subscribers.delete id }.compact
					logger.error  "No subscribers with id #{id}"   if removed_at_id.empty?
					removed_at_id # return_value
				end.flatten
			end
		end
    ### Working with received messages Hash

    # Clear received messages Hash
    def clear_received *message_types
      @receive_lock.synchronize do
        if message_types.empty?
          received.each { |message_type, container| container.clear }
        else
          message_types.each { |message_type| received[message_type].clear }
        end
      end
    end

    # Hash of received messages, keyed by message type
    def received
      @received_hash ||= Hash.new do |hash, message_type| 
				# enable access to the hash via 
				# ib.received[:MessageType].attribute  
				the_array = Array.new 
				def the_array.method_missing(method, *key)
					unless method == :to_hash || method == :to_str #|| method == :to_int
						return self.map{|x| x.public_send(method, *key)}
					end
				end
			hash[message_type] = the_array
			end
    end

    # Check if messages of given type were received at_least n times
    def received? message_type, times=1
      @receive_lock.synchronize do
        received[message_type].size >= times
      end
    end


    # Wait for specific condition(s) - given as callable/block, or
    # message type(s) - given as Symbol or [Symbol, times] pair.
    # Timeout after given time or 1 second.
		#
		# wait_for depends heavyly on Connection#received. If collection of messages through recieved
		# is turned off, wait_for loses most of its functionality
    def wait_for *args, &block
      timeout = args.find { |arg| arg.is_a? Numeric } # extract timeout from args
      end_time = Time.now + (timeout || 1) # default timeout 1 sec
      conditions = args.delete_if { |arg| arg.is_a? Numeric }.push(block).compact

      until end_time < Time.now || satisfied?(*conditions)
        if reader_running?
          sleep 0.05
        else
          process_messages 50
        end
      end
    end

    ### Working with Incoming messages from IB


    def reader_running?
      @reader_running && @reader_thread && @reader_thread.alive?
    end

    # Process incoming messages during *poll_time* (200) msecs, nonblocking
    def process_messages poll_time = 50 # in msec
      time_out = Time.now + poll_time/1000.0
      while (time_left = time_out - Time.now) > 0
        # If socket is readable, process single incoming message
				#process_message if select [socket], nil, nil, time_left
				# the following  checks for shutdown of TWS side; ensures we don't run in a spin loop.
				# unfortunately, it raises Errors in windows environment
				# disabled for now 
        if select [socket], nil, nil, time_left
        #  # Peek at the message from the socket; if it's blank then the
        #  # server side of connection (TWS) has likely shut down.
          socket_likely_shutdown = socket.recvmsg(100, Socket::MSG_PEEK)[0] == ""
				#
        #  # We go ahead process messages regardless (a no-op if socket_likely_shutdown).
          process_message
        #  
        #  # After processing, if socket has shut down we sleep for 100ms
        #  # to avoid spinning in a tight loop. If the server side somehow
        #  # comes back up (gets reconnedted), normal processing
        #  # (without the 100ms wait) should happen.
         sleep(0.1) if socket_likely_shutdown
        end
      end
    end

    ### Sending Outgoing messages to IB

    # Send an outgoing message.
		# returns the used request_id if appropiate, otherwise "true"
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
        error "Only able to send outgoing IB messages", :args
      end
      error   "Not able to send messages, IB not connected!"  unless connected?
			begin
      @message_lock.synchronize do
      message.send_to socket
      end
			rescue Errno::EPIPE
				logger.error{ "Broken Pipe, trying to reconnect"  }
				disconnect
				connect
				retry
			end 
			## return the transmitted message
		  message.data[:request_id].presence || true
    end

    alias dispatch send_message # Legacy alias

    # Place Order (convenience wrapper for send_message :PlaceOrder).
    # Assigns client_id and order_id fields to placed order. Returns assigned order_id.
    def place_order order, contract
      order.place contract, self  
    end

    # Modify Order (convenience wrapper for send_message :PlaceOrder). Returns order_id.
    def modify_order order, contract
      order.modify contract, self
    end

    # Cancel Orders by their local ids (convenience wrapper for send_message :CancelOrder).
    def cancel_order *local_ids
      local_ids.each do |local_id|
        send_message :CancelOrder, :local_id => local_id.to_i
      end
    end

    # Start reader thread that continuously reads messages from @socket in background.
    # If you don't start reader, you should manually poll @socket for messages
    # or use #process_messages(msec) API.
    def start_reader
			return(@reader_thread) if @reader_running
			if connected?
				Thread.abort_on_exception = true
				@reader_running = true
				@reader_thread = Thread.new { process_messages while @reader_running }
			else
				logger.fatal {"Could not start reader, not connected!"}
				nil  # return_value
			end
    end

		protected
		# Message subscribers. Key is the message class to listen for.
		# Value is a Hash of subscriber Procs, keyed by their subscription id.
		# All subscriber Procs will be called with the message instance
		# as an argument when a message of that type is received.
		def subscribers
			@subscribers ||= Hash.new { |hash, subs| hash[subs] = Hash.new }
		end

		# Process single incoming message (blocking!)
		def process_message
			logger.progname='IB::Connection#process_message' if logger.is_a?(Logger)

			socket.decode_message(  socket.recieve_messages ) do | the_decoded_message |
				#	puts "THE deCODED MESSAGE #{ the_decoded_message.inspect}"
				msg_id = the_decoded_message.shift.to_i

				# Debug:
				logger.debug { "Got message #{msg_id} (#{Messages::Incoming::Classes[msg_id]})"}

				# Create new instance of the appropriate message type,
				# and have it read the message from socket.
				# NB: Failure here usually means unsupported message type received
				logger.error { "Got unsupported message #{msg_id}" } unless Messages::Incoming::Classes[msg_id]
				error "Something strange happened - Reader has to be restarted" , :reader if msg_id.to_i.zero?
				msg = Messages::Incoming::Classes[msg_id].new(the_decoded_message)

				# Deliver message to all registered subscribers, alert if no subscribers
				# Ruby 2.0 and above: Hashes are ordered. 
				# Thus first declared subscribers of  a class are executed first 
				@subscribe_lock.synchronize do
					subscribers[msg.class].each { |_, subscriber| subscriber.call(msg) }
				end
				logger.warn { "No subscribers for message #{msg.class}!" } if subscribers[msg.class].empty?

				# Collect all received messages into a @received Hash
				if @received
					@receive_lock.synchronize do
						received[msg.message_type] << msg
					end
				end
			end
		end

		def random_id
			rand 999999999
		end

		# Check if all given conditions are satisfied
		def satisfied? *conditions
			!conditions.empty? &&
				conditions.inject(true) do |result, condition|
				result && if condition.is_a?(Symbol)
				received?(condition)
			elsif condition.is_a?(Array)
				received?(*condition)
			elsif condition.respond_to?(:call)
				condition.call
			else
				logger.error { "Unknown wait condition #{condition}" }
			end
		end
	end
end # class Connection
end # module IB
