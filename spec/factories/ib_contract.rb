#This will guess the Account class
FactoryGirl.define do
	factory :ib_contract, class:IB::Contract do
		con_id  	265598 # apple7765  # gps 2586596 ewp
		currency 'USD' 
		exchange 'SMART' 
		 sec_type  :stock
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
		expiry  '201501'
		strike  100.5
		right  :put
	end

	factory :tws_contract, class:IB::Contract do
		transient do
			symbol 'AAPL'
		end
		sec_type  :stock
		currency  'USD'
		exchange 'SMART' 

		after(:build) do | con_tract, e |
			ib = IB::Connection.current.presence ||  IB::Connection.new( OPTS[:connection].merge(:logger => mock_logger))
			ib.subscribe(:Alert, :ManagedAccounts) { |msg| puts "TWS-Response: #{msg.to_human}" }
			exitcondition= false
			ib.subscribe(:ContractData,  :ContractDataEnd) do |msg| 
				case msg
				when IB::Messages::Incoming::ContractData
				puts con_tract.con_id =  msg.contract.con_id
				puts "ContractData Con_id: #{msg.contract.con_id}"
				IB::Messages::Incoming::ContractDataEnd
				exitcondition = true
				end
			end
			ib.wait_for :ManagedAccounts,5
			 raise "Unable to verify IB PAPER ACCOUNT" unless ib.received?(:ManagedAccounts)
#			ib.clear_received :ContractData, :ContractDataEnd
#			received = ib.received[:ManagedAccounts].first.accounts_list.split(',')
#			raise "Connected to wrong account #{received}, expected #{account}" unless received.include?(account)
			con_tract.symbol=e.symbol
			con_tract.strike = e.strike if con_tract.sec_type==:option
			con_tract.right =  e.right if con_tract.sec_type==:option
			con_tract.expiry = e.expiry if con_tract.sec_type==:option
			ib.send_message :RequestContractData, 
				:id => 1.times.inject([]) {|r,n| v = rand(200) until v and not r.include? v; r << v}.pop ,
				:contract => con_tract
			ib.wait_for :ContractDataEnd, 3
#			puts "IB::CONTRACT:"
#			puts ib.received[:ContractData].last.contract.inspect
#			get_contract_data = -> (item){ib.received[:ContractData].last.contract.send(item)}
#			con_tract.con_id= get_contract_data[:con_id]
#			ib.close_connection

		end
		# Inheritance by nesting factories
		factory :tws_option_contract do
			transient do
				expire '201503'
				right :put
				strike 110
			end
			sec_type  :option
			multiplier  100
		end


	end
end
