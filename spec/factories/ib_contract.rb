#This will guess the Account class
FactoryGirl.define do
	factory :ib_contract, class:IB::Contract do
		con_id 2586596
		currency 'USD' 
		exchange 'SMART' 
	end

	factory :ib_option_contract, class:IB::Contract do
		  symbol  'AAPL'
		 sec_type  :option
		  expiry  '201503'
		   strike  110
		   right  :put
		   sec_id  'US0378331005'
		   sec_id_type  'ISIN'
		   multiplier  10
		   exchange  'SMART'
		   currency  'USD'
		   local_symbol  'AAPL  150320C00110000'

	end
	# liest einen Optionsdatensatz aus der TWS aus
	factory :default_option, class:IB::Option do
		symbol  'AAPL'
		expiry  '201301'
		strike  600.5
		right  :put
	end

	factory :tws_option_contract, class:IB::Contract do
		transient do
			expire '201503'
			right :put
			symbol 'AAPL'
			strike 110
		end
		sec_type  :option
		multiplier  100
		currency  'USD'
		exchange 'SMART' 
		after(:build) do | con_tract, e |
			ib = IB::Connection.current.presence ||  IB::Connection.new( OPTS[:connection].merge(:logger => mock_logger))
			ib.subscribe(:Alert, :ManagedAccounts, :ContractDataEnd) { |msg| puts msg.to_human }
			ib.wait_for :ManagedAccounts
			ib.clear_received :ContractData, :ContractDataEnd
			con_tract.symbol=e.symbol
			con_tract.strike = e.strike
			con_tract.right =  e.right
			con_tract.expiry = e.expiry
			ib.send_message :RequestContractData, :id => e.strike, :contract => con_tract
			ib.wait_for :ContractDataEnd, 3
#			puts "IB::CONTRACT:"
#			puts ib.received[:ContractData].last.contract.inspect
			get_contract_data = -> (item){ib.received[:ContractData].last.contract.send(item)}
			con_tract.con_id= get_contract_data[:con_id]
#			ib.close_connection

		end


	end
end
