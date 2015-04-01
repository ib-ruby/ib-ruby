module IB
=begin
The  Gateway-Class defines anything which has to be done before a connection can be established.
The Default Skeleton can easily be substituted by customized actions

The IB::Gateway can be used in two different modes
(1) IB::Gateway.new( connect:true ) do | gateway |
  { subscribe to Messages and define the response  }
  # This is declared before a connect-attempt is made 
  # The method waits until the connection is ready
    end
(2) gw = IB:Gateway.new
    {subscribe to Messages }
    gw.connect

Independently IB::Alert.alert_#{nnn} should be defined for a proper response to warnings, error-
and system-messages
  

The Connection to the TWS is realized throught IB::Connection. Instead of the previous
Singleton IB::Connection.current now IB::Gateway.tws points to the active Connection.
However, to support asynchronic access, the :recieved-Array of the Connection-Class is not active.
The Array is easily confused, if used in production mode with a FA-Account.
IB::Conncetion.wait_for(message) is not available. 

=end

class Gateway
  require 'active_support'

 include LogDev   # provides default_logger
 include AccountInfos  # provides Handling of Account-Data provided by the tws
 include OrderHandling 
  # from active-support. Add Logging at Class + Instance-Level
  mattr_accessor :logger
  # similar to the Connection-Class: current represents the active instance of Gateway
  mattr_accessor :current
  mattr_accessor :tws


=begin
ActiveAccounts returns a list of Account-Objects 
Thus orders can be verified in a FA-environment
If only one Account is transmitted,  User and Advisor are identical.
(returns an empty array if the array is not initialized, eg not connected)
=end
  def active_accounts
    if IB.db_backed?
     advisor.present? ?  advisor.users : []
    else
      @accounts.size > 1 ? @accounts[1..-1] : @accounts[0..0] 
    end
  end
=begin
ForSelectAccount provides  an Account-Object-Environment 
(with AccountValues, Portfolio-Values, Contracts and Orders)
to deal with in the specifed block
=end

  def for_active_accounts &b
    active_accounts.each{|y| for_selected_account y.account,  &b }
  end
  def for_selected_account account_id
    sa =  @accounts.detect{|x| x.account == account_id }
    yield sa if block_given? && sa.is_a?( IB::Account )
  end
=begin
The Advisor is always the first account
(returns nil if the array is not initialized, eg not connected)
=end
  def advisor
    @accounts.first 
  end

  def initialize  port: 7496, 
		  host: '127.0.0.1',   # 'localhost:4001' is also accepted
		  client_id: nil,
		  subscribe_managed_accounts: true, 
		  subscribe_alerts: true, 
		  subscribe_account_infos: true,
		  subscribe_order_messages: true, 
		  connect: false, 
		  get_account_data: false,
		  serial_array: false, 
		  logger: default_logger
    host, port = (host+':'+port.to_s).split(':') 
    self.logger = logger
    logger.info { '-' * 20 +' initialize ' + '-' * 20 }
    logger.tap{|l| l.progname =  'Gateway#Initialize' }
    @connection_parameter = { received: serial_array, port: port, host: host, connect: false, logger: logger, client_id: client_id }
    @gateway_parameter = { s_m_a: subscribe_managed_accounts, 
			   s_a: subscribe_alerts,
			   s_a_i: subscribe_account_infos, 
			   s_o_m: subscribe_order_messages,
			    g_a_d: get_account_data }
    Gateway.current = self
    # establish Alert-framework
    IB::Alert.logger = logger
    # initialise Connection without connecting
    prepare_connection
    # finally connect to the tws
    if connect || get_account_data
      if connect(100)  # tries to connect for about 2h
	get_account_data()  if get_account_data
	#    request_open_orders() if request_open_orders || get_account_data 
      else
	@accounts=[]   # definitivley reset @accounts
      end
    end

  end

  def get_host
    "#{@connection_parameter[:host]}: #{@connection_parameter[:port] }"
  end
  def change_host host: @connection_parameter[:host], 
		  port: @connection_parameter[:port],
		  client_id: @connection_parameter[:client_id].presence || nil
    host, port = (host+':'+port.to_s).split(':') 
    @connection_parameter[:client_id] = client_id if client_id.present?
    @connection_parameter[:host] = host 
    @connection_parameter[:port] = port 
    
  end

  def update_local_order order
    @local_orders.update_or_create order, :local_id
  end
  
  

  def prepare_connection
    tws.disconnect if tws.is_a? IB::Connection
    self.tws = IB::Connection.new  @connection_parameter
    # the accounts-array keeps any account tranmitted first after connecting 
    # the local_orders-Array keeps any recent order, that has a positive local_id
    @accounts = @local_orders = Array.new

    # prepare Advisor-User hierachie
    initialize_managed_accounts if @gateway_parameter[:s_m_a]
    initialize_alerts  if  @gateway_parameter[:s_a]
    initialize_account_infos if @gateway_parameter[:s_a_i] || @gateway_parameter[:g_a_d]
    initialize_order_handling if@gateway_parameter[:s_o_m] || @gateway_parameter[:g_a_d] 
    ## apply other initialisations which should apper before the connection as block
    ## i.e. after connection order-state events are fired if an open-order is pending
    ## a possible response is best defined before the connect-attempt is done
    if block_given? 
      yield self, tws
    
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
      tws.connect { tws_ready =  true } 
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
    rescue Errno::EPIPE => e
      logger.info 'Connection interrupted ... start again'
      self.tws = IB::Connection.new  @connection_parameter.merge( connect:true )
      
    rescue Errno::ECONNRESET => e
      logger.info 'Connection refused ... re-establishing'
      self.tws = IB::Connection.new  @connection_parameter
      retry
    rescue Errno::EHOSTUNREACH => e
      logger.error 'Cannot connect to specified host'
      logger.error  e
      return false
    rescue SocketError => e
      logger.error 'Wrong Adress, connection not possible'
      return false
    end

    # let NextValidId-Event appear
    loop do
      break if tws_ready
      sleep 0.1
    end
    logger.info { "Communications successfully established" }
  end	# def


=begin
InitializeManagedAccounts 
defines the Message-Handler for :ManagedAccounts
Its always active. If the connection is interrupted and
=end

  def initialize_managed_accounts


    tws.subscribe(:ManagedAccounts) do |msg| 
      logger.progname =  'Gateway#InitializeManagedAccounts' 
      if @accounts.empty?
	unless IB.db_backed?
	  # just validate the mmessage and put all together into an array
	@accounts =  msg.accounts_list.split(',').map do |a| 
	    account = IB::Account.new( account: a.upcase ,  connected: true )
	    if account.save 
		     logger.info {"new #{account.print_type} detected => #{account.account}"}
		     account
	    else
		     logger.fatal {"invalid Account #{account.print_type} => #{account.account}"}
		     nil
	    end
	end.compact
	else
	  # an advisor-user-hierachie ist build.
	  # the database can distingush between several Advisor-Accounts.
	  advisor_id , *user_id =  msg.accounts_list.split(',')
	  Account.update_all :connected => false

	  # alle Konten auf disconnected setzen
	  advisor =  if (a= Advisor.of_ib_user_id(advisor_id)).empty?
		       logger.info {"creating a new advisor #{advisor_id}"}
		       Advisor.create( :account => advisor_id.upcase, :connected => true, :name => 'advisor' )
		     else
		       logger.info {"updating active-Advisor-Flag #{advisor_id}"}
		       a.first.update_attribute :connected , true
		       a.first # return-value
		     end
	  user_id.each do | this_user_id |
	    if (a= advisor.users.of_ib_user_id(this_user_id)).empty?
	      logger.info {"creating a new user #{this_user_id}"}
	      advisor.users << User.new( :account => this_user_id.upcase, :connected => true , :name =>    "user#{this_user_id[-2 ..-1]}")
	    else
	      a.first.update_attribute :connected, true
	      logger.info {"updating active-User-Flag #{this_user_id}"}
	    end
	  end
	  @accounts = [advisor] | advisor.users 
	end

      else
	logger.info {"already #{accounts.size} initialized "}
	@accounts.each{|x| x.update_attrubute :connected ,  true }
      end # if
    end # subscribe do
  end # def



  def initialize_alerts

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
    if tws.present?
      tws.disconnect 
      #	@imap_accounts.each{|account,imap| imap.stop }
      if IB.db_backed?
      	Account.update_all :connected => false
      else
#	@accounts.each{|y| y.update_attribute :connected,  false }
	@accounts = []
      end
      logger.info "Connection closed"
    end

  end


end  # class

end # module

# provide  AR4- ActiveRelation-like-methods to Array-Class
class Array
  # returns the item (in case of first) or the hole array (in case of create)
  def first_or_create item, condition=nil
    if condition.present?
      detect{|x| x[condition] == item[condition]} 
    else
      detect{|x| x==item}
    end || self.push( item )
  end
  def update_or_create item, condition=nil
    member = first_or_create( item, condition) 
    self[index(member)] = item  unless member == self
    self  # always returns the array 
  end

end
__END__
2.2.0 :008 > b = [ IB::Stock.new(symbol:'A'), IB::Stock.new(symbol:'T') ]
 => [#<IB::Stock:0x00000002392d88 @attributes={"symbol"=>"A", "created_at"=>2015-03-28 09:22:37 +0100, "updated_at"=>2015-03-28 09:22:37 +0100, "right"=>"", "include_expired"=>false, "sec_type"=>"STK", "currency"=>"USD", "exchange"=>"SMART"}>, #<IB::Stock:0x00000002391ac8 @attributes={"symbol"=>"T", "created_at"=>2015-03-28 09:22:37 +0100, "updated_at"=>2015-03-28 09:22:37 +0100, "right"=>"", "include_expired"=>false, "sec_type"=>"STK", "currency"=>"USD", "exchange"=>"SMART"}>] 
   2.2.0 :009 > t = IB::Stock.new( symbol:'A', con_id:1234 )
  => #<IB::Stock:0x0000000240c6d8 @attributes={"symbol"=>"A", "con_id"=>1234, "created_at"=>2015-03-28 09:23:33 +0100, "updated_at"=>2015-03-28 09:23:33 +0100, "right"=>"", "include_expired"=>false, "sec_type"=>"STK", "currency"=>"USD", "exchange"=>"SMART"}> 
  2.2.0 :010 > b.update_or_create t, :symbol 
   => [#<IB::Stock:0x0000000240c6d8 @attributes={"symbol"=>"A", "con_id"=>1234, "created_at"=>2015-03-28 09:23:33 +0100, "updated_at"=>2015-03-28 09:23:33 +0100, "right"=>"", "include_expired"=>false, "sec_type"=>"STK", "currency"=>"USD", "exchange"=>"SMART"}>, #<IB::Stock:0x00000002391ac8 @attributes={"symbol"=>"T", "created_at"=>2015-03-28 09:22:37 +0100, "updated_at"=>2015-03-28 09:22:37 +0100, "right"=>"", "include_expired"=>false, "sec_type"=>"STK", "currency"=>"USD", "exchange"=>"SMART"}>] 

