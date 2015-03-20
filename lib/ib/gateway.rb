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
  

The Connection to the TWS is realized throught IB::Connection. Thus IB::Connection.current is
available and still points to the active IB::Connection.  
However, to support asynchronic access, the :recieved-Array of the Connection-Class is not active.
The Array is easily confused, if used in production mode with a FA-Account.
IB::Conncetion.wait_for(message) is not available. 

=end

class Gateway
  require 'active_support'

 include LogDev   # provides default_logger
  # from active-support. Add Logging at Class + Instance-Level
  mattr_accessor :logger
  # similar to the Connection-Class: current represents the active instance of Gateway
  mattr_accessor :current
  mattr_reader :tws


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
The Advisor is always the first account
(returns nil if the array is not initialized, eg not connected)
=end
  def advisor
    @accounts.first 
  end

  def initialize  port: 7496, 
		  host: '127.0.0.1', 
		  subscribe_managed_accounts: true, 
		  subscribe_alerts: true, 
		  connect: false, 
		  logger: default_logger
    self.logger = logger
    logger.info { '-' * 20 +' initialize ' + '-' * 20 }
    logger.tap{|l| l.progname =  'Gateway#Initialize' }
    connection_parameter = { recieved: false, port: port, host: host, connect: false, logger: logger }
    Gateway.current = self
    # establish Alert-framework
    IB::Alert.logger = logger
    # initialise Connection without connecting
    tws = IB::Connection.new  connection_parameter
    # prepare Advisor-User hierachie
    @accounts=Array.new

    initialize_managed_accounts if subscribe_managed_accounts
    initialize_alerts  if subscribe_alerts
    ## apply other initialisations which should apper before the connection as block
    ## i.e. after connection order-state events are fired if an open-order is pending
    ## a possible response is best defined before the connect-attempt is done
    if block_given? 
      yield self, tws
    else
#      subscribe_order_messages
    end
    # finally connect to the tws
    connect() if connect
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
      IB::Connection.current.connect { tws_ready =  true } 
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
	Kernel.exit(false)
      end
    end # begin - rescue
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


    IB::Connection.current.subscribe(:ManagedAccounts) do |msg| 
      logger.progname =  'Gateway#InitializeManagedAccounts' 
      if @accounts.empty?
	unless IB.db_backed?
	  # just validate the mmessage and put all together into an array
	@accounts =  msg.accounts_list.split(',').map do |a| 
	    account = IB::Account.new( account: a,  connected: true )
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
		       Advisor.create( :account => advisor_id.downcase, :connected => true, :name => 'advisor' )
		     else
		       logger.info {"updating active-Advisor-Flag #{advisor_id}"}
		       a.first.update_attribute :connected , true
		       a.first # return-value
		     end
	  user_id.each do | this_user_id |
	    if (a= advisor.users.of_ib_user_id(this_user_id)).empty?
	      logger.info {"creating a new user #{this_user_id}"}
	      advisor.users << User.new( :account => this_user_id.downcase, :connected => true , :name =>    "user#{this_user_id[-2 ..-1]}")
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

    IB::Connection.current.subscribe(:Alert) do |msg| 
      logger.progname = 'Gateway#Alerts'
      logger.debug " ----------------#{msg.code}-----"
      # delegate anything to IB::Alert
      IB::Alert.send("alert_#{msg.code}", msg )
    end
  end

  def reconnect
    logger.progname = 'Gateway#reconnect'
    unless IB::Connection.current.nil?
      disconnect
      sleep 1
    end
    logger.info "trying to reconnect ..."
    connect
  end

  def disconnect
    logger.progname = 'Gateway#disconnect'
    unless IB::Connection.current.nil?
      IB::Connection.current.disconnect 
      #IB::Connection.current=nil
      #	@imap_accounts.each{|account,imap| imap.stop }
      if IB.db_backed?
      	Account.update_all :connected => false
      else
	@accounts.each{|y| y.update_attribute :connected,  false }
      end
      logger.info "Connection closed"
    end

  end
end  # class

end # module