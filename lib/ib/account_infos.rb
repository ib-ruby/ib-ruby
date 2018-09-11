module AccountInfos
  def initialize_account_infos continously: false
    


	end  # def
=begin
Queries the tws for Account- and PortfolioValues
The parameter can either be the account_id, the IB::Account-Object or 
an Array of account_id and IB::Account-Objects.

returns the thread waiting for completing the request


call it via

	G.get_account_data.join 
	or
	G.get_account_data("account-number" ord IB::Account-Object).join

for sequencial processing
=end
	def get_account_data *accounts
		logger.progname = 'Gateway#get_account_data'
		delay =  200   #  set the max waiting time (in 1/10-seconds) 
									 #  in order to set the timeframe before raising an IB::Error	
			
		subscribe_id = tws.subscribe( :AccountValue, :PortfolioValue,:AccountDownloadEnd )  do | msg |

			for_selected_account( msg.account_name ) do | account |   # enter mutex controlled zone
				case msg
				when IB::Messages::Incoming::AccountValue
					account.account_values.update_or_create msg.account_value, :currency, :key
					account.update_attribute :last_updated, Time.now
				when IB::Messages::Incoming::AccountDownloadEnd
					send_message :RequestAccountData, subscribe: false, account_code: account.account
					if account.account_values.size > 100
						account.update_attribute :connected, true   ## flag: Account is completely initialized
						logger.debug{ "#{account.account} => Count of AccountValues: #{account.account_values.size} "  }
					else # unreasonable account_data recieved -  try again
						logger.fatal{ "#{account.account} => Count of AccountValues too small: #{account.account_values.size} "  }
						send_message :RequestAccountData, subscribe: true, account_code: account.account
					end
				when IB::Messages::Incoming::PortfolioValue
					account.contracts.update_or_create  msg.contract
					account.portfolio_values.update_or_create( msg.portfolio_value ){ :contract }
					msg.portfolio_value.account = account
					# link contract -> portfolio value
					account.contracts.find{|x| x.con_id == msg.contract.con_id}.portfolio_values << account.portfolio_values.find{|y| y == msg.portfolio_value}
				end # case
			end # for_selected_account 

		end # subscribe

		accounts =  active_accounts if accounts.empty?
		
		Thread.new do 
			# Account-infos are requested sequencially.
			# On a slow hardware, the multithreaded approach fails
		accounts.each do | ac |
			account =  ac.is_a?( IB::Account ) ?  ac  : active_accounts.find{|x| x.account == ac } 
			logger.debug{ "#{account.account} :: Requesting AccountData " }
			account.update_attribute :connected, false  # indicates: AccountUpdate in Progress
			send_message :RequestAccountData, subscribe: true, account_code: account.account
			i = 0
			loop do
				break if account.connected 
				i +=1
				sleep 0.1
				error "Account Infos not correctly processed. Please restart TWS/Gateway." if i > delay
			end	
		end

		       tws.unsubscribe subscribe_id
		       logger.debug { "Accountdata successfully read" }
		end
		# the thread is returned, thus the calling object can perform a 'join'
	end


  def all_contracts
		active_accounts.map(&:contracts).flat_map(&:itself).uniq(&:con_id)
  end

end # module
