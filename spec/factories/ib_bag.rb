FactoryGirl.define do
	factory :empty_bag, class:IB::Bag do
		symbol  'GOOG'
		sec_type  :bag
		currency 'USD' 
		exchange 'SMART' 
	end

#	factory :apple_bag, class:IB::Bag do
#		  symbol  'AAPL'
#		 sec_type  :bag
#		   currency  'USD'
#		exchange 'SMART' 
#
#		after(:build) do |bag|  
#			bag.legs << build(:ib_option_contract)
#			bag.legs << build(:ib_option_contract)
#		end
#	end
	# create a fake butterfly bag
	factory :butterfly, class:IB::Bag do
			symbol 'FAKE'
			exchange 'SMART' 
			sec_type  :bag
			currency  'USD'
			after(:build) do |bag|  
				[1, -2 , 1].each do | w |
					bag.legs << build( :combo_leg, weight:w )
				end
			end

	end
	factory :butterfliege, class:IB::Bag do
		## transient definiert Default-Parameter, die im Aufruf überschrieben werden können
		transient do
			### if wrong attributes are set, the factory becomes invalid 
			### and no tests ar performed at all (FactoryGirl::InvalidFactoryError)
			expire '201503' 	## Expiry of the options, adjust to appropiate date
			legs [ 110, 115, 105]  ## strikes of the apple-options. make sure they are valid
			kind 'PUT'
			exchange 'SMART' 
			symbol 'AAPL'
		end
		sec_type  :bag
		currency  'USD'
		after(:build) do |bag, e|  
			bag.exchange = e.exchange 
			bag.symbol = e.symbol
			if IB::Connection.current.nil?
				IB::Connection.new( OPTS[:connection].merge(:logger => Logger.new(STDOUT)))
			end
			list_of_con_ids = e.legs.zip( [ 1,-2, 1 ] ).each do | strike, weight |
				contract = build(:default_option, currency:bag.currency, symbol:bag.symbol, right:e.kind, strike:strike, expiry:e.expire )
#				puts "Butterfliege::contract :>#{contract.inspect}"
#				contract=contract.update_contract
				bag.legs << build( :combo_leg, weight:weight,  con_id:contract.con_id )
			end
		end

	end

end
