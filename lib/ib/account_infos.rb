module AccountInfos
  def initialize_account_infos
    
    valid_account = ->( account_id ) do
		if IB.db_backed? 
		    Account.single!( account_id)
		  else
		    active_accounts.find{| ac | ac.account ==  account_id }
		  end
    end


    tws.subscribe( :AccountValue, :PortfolioValue, :AccountUpdateTime, :AccountDownloadEnd )  do | msg |
      logger.progname = 'Gateway#account_infos'
      case msg
      when IB::Messages::Incoming::AccountUpdateTime
	# print "heartbeat "

      when IB::Messages::Incoming::AccountValue
	account =   valid_account[ msg.account_name ]
	if account.is_a? IB::Account
	  logger.progname = 'Gateway#account_value'
	  account.account_values << msg.account_value
	  #	  account.attach_portfoliodata  msg.data
	else
	  logger.error{ "wrong AccountValueDataset #{msg.inspect}" }
	end
      when IB::Messages::Incoming::AccountDownloadEnd

	logger.progname = 'AccountDataStorage#account_download_end'
	account = valid_account[ msg.account_name ]
	logger.info { "#{account.name} => Count of AccountValues: #{account.account_values.size} "  }
	tws.send_message :RequestAccountData, subscribe: false, account_code: account.account
	       # 	account.send_account_data
	       #	@active_subscription=false
      when IB::Messages::Incoming::PortfolioValue
	account = valid_account[ msg.account_name ]
	account.portfolio_values << msg.portfolio_value
	account.contracts << msg.contract
      end # case
      ActiveRecord::Base.connection.close if IB.db_backed?
    end # do block


  end
=begin
Query's the tws for Account- and PortfolioValues
The parameter can either be the account_id, the IB::Account-Object or 
an Array of account_id and IB::Account-Objects.

=end
  def get_account_data accounts: :all
    logger.progname = 'Gateway#get_account_data'
    accounts =   active_accounts if accounts == :all
    accounts = [accounts] unless  accounts.is_a? Array
    accounts.each do | account |
      account =  active_accounts.find{|x| x.account == account } unless account.is_a? IB::Account
      if account.is_a? IB::Account
	# reset account  (works only with tabelless models)
	account.portfolio_values, account.account_values, account.contracts = []
	tws.send_message :RequestAccountData, :subscribe => true, :account_code => account.account
	sleep 1
      else
	logger.error{ "Invalid Account specified :#{accounts.inspect}" }
      end
    end

  end

end # module
