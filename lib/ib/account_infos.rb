module IB
class Alert
	class << self
		def alert_2101 msg
			logger.error {msg.message}
			@status_2101 = msg.dup	
		end

		def status_2101 account # resets status and raises IB::TransmissionError
			error account.account + ": " +@status_2101.message, :reader unless @status_2101.nil?
			@status_2101 = nil  # always returns nil 
		end
	end
end 
end #  module

module AccountInfos

=begin
Queries the tws for Account- and PortfolioValues
The parameter can either be the account_id, the IB::Account-Object or 
an Array of account_id and IB::Account-Objects.

raises an IB::TransmissionError if the account-data are not transmitted in time (1 sec)

raises an IB::Error if less then 100 items are recieved-
=end
	def get_account_data  *accounts,  watchlists: []

		logger.progname = 'Gateway#get_account_data'

		@account_data_subscription ||=   subscribe_account_updates

		accounts =  active_accounts if accounts.empty?
		logger.warn{ "No active account present. AccountData are NOT requested" } if accounts.empty?
		# Account-infos have to be requested sequencially. 
		# subsequent (parallel) calls kill the former once on the tws-server-side
		# In addition, there is no need to cancel the subscription of an request, as a new
		# one overwrites the active one.
		accounts.each do | ac |
			account =  ac.is_a?( IB::Account ) ?  ac  : active_accounts.find{|x| x.account == ac } 
			error( "No Account detected " )  unless account.is_a? IB::Account
			# don't repeat the query until 170 sec. have passed since the previous update
			if account.last_updated.nil?  || ( Time.now - account.last_updated ) > 170 # sec   
				logger.debug{ "#{account.account} :: Requesting AccountData " }
				account.update_attribute :connected, false  # indicates: AccountUpdate in Progress
				# reset account and portfolio-values
				account.portfolio_values =  []
				account.account_values =  []
				send_message :RequestAccountData, subscribe: true, account_code: account.account
				Timeout::timeout(3, IB::TransmissionError, "RequestAccountData failed (#{account.account})") do
#					 initialize requests sequencially					
					loop{ sleep 0.1; break if account.connected  }
				end
				if watchlists.present?
					watchlists.each{|w| error "Watchlists must be IB::Symbols--Classes :.#{w.inspect}" unless w.is_a? IB::Symbols }
					account.organize_portfolio_positions watchlists  
				end
				send_message :RequestAccountData, subscribe: false  ## do this only once
			else
				logger.info{ "#{account.account} :: Using stored AccountData " }
			end
		end
	end


  def all_contracts
		active_accounts.map(&:contracts).flat_map(&:itself).uniq(&:con_id)
  end


	private

	# The subscription method should called only once per session.
	# It places subscribers to AccountValue and PortfolioValue Messages, which should remain
	# active through its session.
	# 
	
	def subscribe_account_updates continously: true
		tws.subscribe( :AccountValue, :PortfolioValue,:AccountDownloadEnd )  do | msg |
			for_selected_account( msg.account_name ) do | account |   # enter mutex controlled zone
				case msg
				when IB::Messages::Incoming::AccountValue
					account.account_values << msg.account_value
					account.update_attribute :last_updated, Time.now
					logger.debug { "#{account.account} :: #{msg.account_value.to_human }"}
				when IB::Messages::Incoming::AccountDownloadEnd 
					if account.account_values.size > 10
							# simply don't cancel the subscripton if continously is specified
							# the connected flag is set in any case, indicating that valid data are present
						send_message :RequestAccountData, subscribe: false, account_code: account.account unless continously
						account.update_attribute :connected, true   ## flag: Account is completely initialized
						logger.info { "#{account.account} => Count of AccountValues: #{account.account_values.size}"  }
					else # unreasonable account_data recieved -  request is still active
						error  "#{account.account} => Count of AccountValues too small: #{account.account_values.size}" , :reader 
					end
				when IB::Messages::Incoming::PortfolioValue
						account.contracts.update_or_create  msg.contract
						account.portfolio_values << msg.portfolio_value 
#						msg.portfolio_value.account = account
						# link contract -> portfolio value
#						account.contracts.find{ |x| x.con_id == msg.contract.con_id }
#								.portfolio_values
#								.update_or_create( msg.portfolio_value ) { :account } 
						logger.debug { "#{ account.account } :: #{ msg.contract.to_human }" }
					end # case
			end # for_selected_account 
		end # subscribe
	end  # def 


end # module
