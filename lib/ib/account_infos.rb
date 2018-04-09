module AccountInfos
  def initialize_account_infos continously: false
    
    tws.subscribe( :AccountValue, :PortfolioValue, :AccountUpdateTime, :AccountDownloadEnd )  do | msg |
      logger.progname = 'Gateway#account_infos'
      case msg
      when IB::Messages::Incoming::AccountUpdateTime
	# print "heartbeat "

      when IB::Messages::Incoming::AccountValue
	  for_selected_account( msg.account_name ) do | account |
	   # debugging:  puts "#{account.account} => AccountValue "
	    account.account_values.update_or_create msg.account_value, :currency, :key
	  end

      when IB::Messages::Incoming::AccountDownloadEnd
	logger.progname = 'Gateway#account_infos'
	account = active_accounts.detect{ |x| x.account ==  msg.account_name }
	logger.info{ "#{account.account} => Count of AccountValues: #{account.account_values.size} "  }
	
	send_message :RequestAccountData, subscribe: false, account_code: account.account unless continously

      when IB::Messages::Incoming::PortfolioValue
	  logger.progname = 'Gateway#account_infos'


	  for_selected_account( msg.account_name ) do | ac |
	    ac.contracts.update_or_create  msg.contract
	    ac.portfolio_values.update_or_create( msg.portfolio_value ){ :contract }
			msg.portfolio_value.account = ac
	  end
      end # case
    end # do block


  end
=begin
Query's the tws for Account- and PortfolioValues
The parameter can either be the account_id, the IB::Account-Object or 
an Array of account_id and IB::Account-Objects.

=end
  def get_account_data accounts: :all
    logger.progname = 'Gateway#get_account_data'
    a = if accounts == :all
      active_accounts
    else
      [accounts].flatten
    end
    a.each do | ac |
	account = if ac.is_a? IB::Account
		    ac
		  else
		    active_accounts.find{|x| x.account == ac } 
		  end
	logger.info{ "#{account.account} :: Requesting AccountData " }
	send_message :RequestAccountData, subscribe: true, account_code: account.account
	sleep 0.2
    end
  end


  def all_contracts
    aa = []
    for_active_accounts{|a| a.contracts.each{|y| aa.update_or_create y, :con_id }}
    aa
  end

end # module
