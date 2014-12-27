FactoryGirl.define do
	factory :empty_bag, class:IB::Bag do
		symbol  'GOOG'
		sec_type  :bag
		currency 'USD' 
		exchange 'SMART' 
	end

	factory :apple_bag, class:IB::Bag do
		  symbol  'AAPL'
		 sec_type  :bag
		   currency  'USD'
		exchange 'SMART' 

		after(:build) do |bag|  
			bag.combo_legs << build(:ib_option_contract)
			bag.combo_legs << build(:ib_option_contract)
		end
	end
	# create a fake butterfly bag
	factory :butterfly, class:IB::Bag do
			symbol 'FAKE'
			exchange 'SMART' 
			sec_type  :bag
			currency  'USD'
			after(:build) do |bag|  
				[1, -2 , 1].each do | w |
					bag.combo_legs << build( :combo_leg, weight:w )
				end
			end

	end

	factory :butterfliege, class:IB::Bag do
		## transient definiert Default-Parameter, die im Aufruf überschrieben werden können
		transient do
			expire '201503'
			legs [ 1, 2, 3 ]
			kind 'PUT'
			exchange 'SMART' 
			symbol 'AAPL'
		end
		sec_type  :bag
		currency  'USD'
		# e --> class::.:: @build_strategy=#<FactoryGirl::Strategy::Build:0x0000000328c208>, @overrides={:expire=>"201501", :legs=>[500, 510, 520], :kind=>"CALL", :symbol=>"AAPL", :sec_type=>:bag, :currency=>"USD", :exchange=>"SMART"}, @cached_attributes={:expire=>"201501", :legs=>[500, 510, 520], :kind=>"CALL", :symbol=>"AAPL", :sec_type=>:bag, :currency=>"USD", :exchange=>"SMART"}, @instance=#<IB::Bag:0x00000003299d90 @attributes={"created_at"=>2014-12-25 15:12:32 +0100, "updated_at"=>2014-12-25 15:12:32 +0100, "con_id"=>0, "right"=>"", "exchange"=>"SMART", "include_expired"=>false, "sec_type"=>"BAG", "symbol"=>"AAPL", "currency"=>"USD"
		after(:build) do |bag, e|  
			bag.exchange = e.exchange 
			bag.symbol = e.symbol
			list_of_con_ids = e.legs.zip([1,-2,1]).each do | strike, weight |
				contract = build(:tws_option_contract, symbol:bag.symbol, right:e.kind, strike:strike, expiry:e.expire )
				bag.combo_legs << build( :combo_leg, weight:weight,  con_id:contract.con_id )

			end
		end

	end

end
