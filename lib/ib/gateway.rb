#module GWSupport
# provide  AR4- ActiveRelation-like-methods to Array-Class
#refine  Array do
	class Array 
  # returns the item (in case of first) or the hole array (in case of create)
  def first_or_create item, *condition, &b
    int_array = if condition.empty? 
	       [ find_all{ |x| x == item } ] if !block_given?
	     else
	       condition.map{ |c| find_all{|x| x[ c ] == item[ c ] }}
	     end || []
    if block_given?
      relation = yield
      part_2 = find_all{ |x| x.send( relation ) == item.send( relation ) }
      int_array <<  part_2 unless part_2.empty?
    end
    # reduce performs a logical "&" between the array-elements
    # we are only interested in the first entry
    r= int_array.reduce( :& )
    r.present? ? r.first : self.push( item ) 
  end
  def update_or_create item, *condition, &b
    member = first_or_create( item, *condition, &b) 
    self[ index( member ) ] = item  unless member.is_a?(Array)
    self  # always returns the array 
  end

  # performs [ [ array ] & [ array ] & [..] ].first
  def intercept
    a = self.dup
    s = a.pop
    while a.present?
      s = s & a.pop
    end
    s.first unless s.nil?  # return_value (or nil)
  end
end # refine
#end # module

module IB

=begin
The  Gateway-Class defines anything which has to be done before a connection can be established.
The Default Skeleton can easily be substituted by customized actions

The IB::Gateway can be used in three modes
(1) IB::Gateway.new( connect:true, --other arguments-- ) do | gateway |
  ** subscribe to Messages and define the response  **
  # This block is executed before a connect-attempt is made 
    end
(2) gw = IB:Gateway.new
    ** subscribe to Messages **
    gw.connect
(3) IB::Gateway.new connect:true, host: 'localhost' ....

Independently IB::Alert.alert_#{nnn} should be defined for a proper response to warnings, error-
and system-messages. 
  

The Connection to the TWS is realized throught IB::Connection. Additional to __IB::Connection.current__
IB::Gateway.tws points to the active Connection.

To support asynchronic access, the :recieved-Array of the Connection-Class is not active.
The Array is easily confused, if used in production mode with a FA-Account and has limit.
Thus IB::Conncetion.wait_for(message) is not available until the programm is called with
IB::Gateway.new  serial_array: true (, ...)



=end

class Gateway

 require 'active_support'

 include LogDev   # provides default_logger
 include AccountInfos  # provides Handling of Account-Data provided by the tws
 include OrderHandling 

# include GWSupport   # introduces update_or_create, first_or_create and intercept to the Array-Class

  # from active-support. Add Logging at Class + Instance-Level
  mattr_accessor :logger
  # similar to the Connection-Class: current represents the active instance of Gateway
  mattr_accessor :current
  mattr_accessor :tws
  

=begin
ActiveAccounts returns a list of Account-Objects 
Thus orders can be verified in a FA-environment.

If only one Account is transmitted,  User and Advisor are identical.

(returns an empty array if the array is not initialized, eg not connected)
=end
  def active_accounts
     @accounts.find_all{|x| x.user? && x.connected }
  end
	
=begin
ForActiveAccounts enables a thread-safe access to account-data
=end

  def for_active_accounts &b
    active_accounts.map{|y| for_selected_account y.account,  &b }
  end
=begin
ForSelectAccount provides  an Account-Object-Environment 
(with AccountValues, Portfolio-Values, Contracts and Orders)
to deal with in the specifed block.

It returns an Array of the return-values of the block
=end

  def for_selected_account account_or_id
		sa = account_or_id.is_a?(IB::Account) ? account_or_id :  @accounts.detect{|x| x.account == account_or_id }
    @account_lock.synchronize do
      yield sa if block_given? && sa.is_a?( IB::Account )
    end
  end
=begin
The Advisor is always the first account
(returns nil if the array is not initialized, eg not connected)
=end
  def advisor
    @accounts.first
  end

  def initialize  port: 4002, # 7497, 
		  host: '127.0.0.1',   # 'localhost:4001' is also accepted
		  client_id:  random_id,
		  subscribe_managed_accounts: true, 
		  subscribe_alerts: true, 
		  subscribe_order_messages: true, 
		  connect: true, 
		  get_account_data: false,
		  serial_array: false, 
		  logger: default_logger,
			watchlists: [] ,  # array of watchlists (IB::Symbols::{watchlist}) containing descriptions for complex positions
			&b

    host, port = (host+':'+port.to_s).split(':') 
    
		self.logger = logger
    logger.info { '-' * 20 +' initialize ' + '-' * 20 }
    logger.tap{|l| l.progname =  'Gateway#Initialize' }
    
		@connection_parameter = { received: serial_array, port: port, host: host, connect: false, logger: logger, client_id: client_id }
    
		@account_lock = Mutex.new
		@watchlists = watchlists
		@gateway_parameter = { s_m_a: subscribe_managed_accounts, 
													 s_a: subscribe_alerts,
													 s_o_m: subscribe_order_messages,
													 g_a_d: get_account_data }

		
		Thread.report_on_exception = true
		# https://blog.bigbinary.com/2018/04/18/ruby-2-5-enables-thread-report_on_exception-by-default.html
    Gateway.current = self
    # establish Alert-framework
    IB::Alert.logger = logger
    # initialise Connection without connecting
    prepare_connection &b
    # finally connect to the tws
    if connect || get_account_data
      if connect(100)  # tries to connect for about 2h
				get_account_data(watchlists: watchlists.map{|b| IB::Symbols.allocate_collection b})  if get_account_data
				#    request_open_orders() if request_open_orders || get_account_data 
      else
				@accounts = []   # definitivley reset @accounts
      end
    end

  end

	def active_watchlists
		@watchlists
	end
	
  def get_host
    "#{@connection_parameter[:host]}: #{@connection_parameter[:port] }"
  end
  def change_host host: @connection_parameter[:host], 
		  port: @connection_parameter[:port],
		  client_id: @connection_parameter[:client_id]
    host, port = (host+':'+port.to_s).split(':') 
    @connection_parameter[:client_id] = client_id 
    @connection_parameter[:host] = host 
    @connection_parameter[:port] = port 
    
  end

  def update_local_order order
		# @local_orders is initialized by #PrepareConnection
    @local_orders.update_or_create order, :local_id
  end
  
=begin
Proxy for Connection#SendMessage
allows reconnection if a socket_error occurs
=end

  def send_message what, *args
    logger.tap{|l| l.progname =  'Gateway#SendMessage' }
    begin
    tws.send_message what, *args
    rescue Errno::EPIPE 
      logger.info 'Connection interrupted ... start again'
      prepare_connection ; connect
      retry
    rescue Errno::ECONNRESET => e
      logger.info 'Connection refused ... re-establishing'
      prepare_connection ; connect
      retry
    end
  end

=begin
Cancels one or multible orders

Argument is either an order-object or a local_id
=end

  def cancel_order *orders 

    logger.tap{|l| l.progname =  'Gateway#CancelOrder' }
	
     orders.compact.each do |o|
			 local_id = if o.is_a? (IB::Order)
										logger.info{ "Cancelling #{o.to_human}" }
										o.local_id
									else
										o
									end
         send_message :CancelOrder, :local_id => local_id.to_i
     end

  end


  def prepare_connection &b
    tws.disconnect if tws.is_a? IB::Connection
    self.tws = IB::Connection.new  @connection_parameter do |c|
    # the accounts-array keeps any account tranmitted first after connecting 
    # the local_orders-Array keeps any recent order, that has a positive local_id
	#		c.subscribe(:NextValidId) do |msg|
	#			logger.progname = "Gateway#connect"
	#			c.next_local_id = msg.local_id
	#			logger.info { "Got next valid order id: #{next_local_id}." }
#			end
		end
    @accounts = @local_orders = Array.new

    # prepare Advisor-User hierachie
    initialize_managed_accounts if @gateway_parameter[:s_m_a]
    initialize_alerts if @gateway_parameter[:s_a]
    initialize_order_handling if @gateway_parameter[:s_o_m] || @gateway_parameter[:g_a_d] 
    ## apply other initialisations which should apper before the connection as block
    ## i.e. after connection order-state events are fired if an open-order is pending
    ## a possible response is best defined before the connect-attempt is done
		# ##  Attention
		# ##  @accounts are not initialized yet
    if block_given? 
      yield self 
    
    end
  end

  ## ------------------------------------- connect ---------------------------------------------##
=begin
Zentrale Methode 
Es wird ein Connection-Objekt (IB::Connection.current) angelegt, dass mit den Daten aus config/connect.yml initialisiert wird.
Sollte keine TWS vorhanden sein, wird eine entsprechende Meldung ausgegeben und der Verbindungsversuch 
wiederholt.
Weiterhin meldet sich die Anwendung zur Auswertung von Messages der TWS an.

=end
	def connect maximal_count_of_retry=100



		i= -1
		logger.progname =  'Gateway#connect' 
		begin
			tws_ready =  false
			tws.connect# { tws_ready =  true } 
		rescue  Errno::ECONNREFUSED => e
			i+=1
			if i < maximal_count_of_retry
				if i.zero?
					logger.info 'No TWS!'
				else
					logger.info {"No TWS        Retry #{i}/ #{maximal_count_of_retry} " }
				end
				sleep i<50 ? 10 : 60   # Die ersten 50 Versuche im 10 Sekunden Abstand, danach 1 Min.
				retry
			else
				logger.info { "Giving up!!" }
				#Kernel.exit(false)
				return false
			end
		rescue Errno::EHOSTUNREACH => e
			logger.error 'Cannot connect to specified host'
			logger.error  e
			return false
		rescue SocketError => e
			logger.error 'Wrong Adress, connection not possible'
			return false
		end

		tws.start_reader
		# let NextValidId-Event appear
		loop do
#			puts "Connected: #{tws.connected?}"
#			puts "NextLocalId: #{tws.next_local_id}"
			break if tws.next_local_id.present?
			sleep 0.1
		end
		# initialize @accounts (incl. aliases)
		tws.send_message :RequestFA, fa_data_type: 3
		logger.debug { "Communications successfully established" }
	end	# def


=begin
InitializeManagedAccounts 
defines the Message-Handler for :ManagedAccounts
Its always active. 
=end

  def initialize_managed_accounts
		rec_id = tws.subscribe( :ReceiveFA )  do |msg|
			unless IB.db_backed?
				msg.accounts.each do |a|
					for_selected_account( a.account  ){| the_account | the_account.update_attribute :alias, a.alias } unless a.alias.blank?
				end
				logger.info { "Accounts initialized \n #{@accounts.map( &:to_human  ).join " \n " }" }
			end
		end

		man_id = tws.subscribe( :ManagedAccounts ) do |msg| 
			logger.progname =  'Gateway#InitializeManagedAccounts' 
			if @accounts.empty?
					# just validate the message and put all together into an array
					@accounts =  msg.accounts_list.split(',').map do |a| 
						account = IB::Account.new( account: a.upcase ,  connected: true )
					end
      else
				logger.info {"already #{@accounts.size} accounts initialized "}
				@accounts.each{|x| x.update_attribute :connected ,  true }
			end # if
		end # subscribe do
  end # def



  def initialize_alerts

		tws.subscribe(  :AccountUpdateTime  ){| msg | logger.debug{ msg.to_human }}
    tws.subscribe(:Alert) do |msg| 
      logger.progname = 'Gateway#Alerts'
      logger.debug " ----------------#{msg.code}-----"
      # delegate anything to IB::Alert
      IB::Alert.send("alert_#{msg.code}", msg )
    end
  end

  def reconnect
    logger.progname = 'Gateway#reconnect'
    if tws.present?
      disconnect
      sleep 1
    end
    logger.info "trying to reconnect ..."
    connect
  end

	def disconnect
		logger.progname = 'Gateway#disconnect'

		tws.disconnect if tws.present?
		@accounts = [] # each{|y| y.update_attribute :connected,  false }
		logger.info "Connection closed" 
	end

# Handy method to ensure that a connection is established and active.
#
# The connection is resetted on the IB-side at least once a day. Then the 
# IB-Ruby-Connection has to be reestablished, too. 
# 
# check_connection reconnects if nesessary and returns false if the connection is lost. 
# 
# It delays the process by 6 ms (150 MBit Cable connection)
#
#  a =  Time.now; G.check_connection; b= Time.now ;b-a
#   => 0.00066005
# 
	def check_connection
				answer = nil; count=0
				z= tws.subscribe( :CurrentTime ) { answer = true }
				while (answer.nil?)
					begin
						tws.send_message(:RequestCurrentTime)												# 10 ms  ##
						i=0; loop{ break if answer || i > 40; i+=1; sleep 0.0001}
					rescue IOError, Errno::ECONNREFUSED   # connection lost
						count = 6
					rescue IB::Error # not connected
						reconnect 
						count +=1
						sleep 1
						retry if count <= 5
					end
					count +=1
					break if count > 5
				end
				tws.unsubscribe z
			count < 5  && answer #  return value
	end

private

  def random_id
    rand 99999
  end

end  # class

end # module

__END__
