require 'order_helper'


shared_examples_for 'OpenOrder message' do
  it { should be_an IB::Messages::Incoming::OpenOrder }
  its(:message_type) { is_expected.to eq :OpenOrder }
  its(:message_id) { is_expected.to eq 5 }
  its(:version) { is_expected.to eq 34}
  its(:data) { is_expected.not_to  be_empty }
  its(:buffer ) { is_expected.to be_empty }  # Work on openOrder-Message has to be finished.
  							## Integration of Conditions !
  its(:local_id) { is_expected.to be_an Integer }
  its(:status) { is_expected.to match /Submit/ }
  its(:to_human) { is_expected.to match /<OpenOrder/ }


  it 'has proper order accessor' do
    o = subject.order
    expect( o ).to be_an IB::Order
    expect( o.client_id ).to eq(1111).or eq(2111)
    expect( o.parent_id ).to be_zero
    expect( o.local_id ).to be_an Integer
    expect( o.perm_id ).to  be_an Integer
    expect(IB::VALUES[:clearing_intent].values). to include o.clearing_intent
    expect( o.order_type ).to eq :limit
    expect( IB::VALUES[:tif].values ).to include o.tif
    #expect( o.status ).to match /Submit/
    expect( o.clearing_intent ).to eq :ib
  end

  it 'has proper order_state accessor' do
    os = subject.order_state
    expect(os.local_id).to be_an Integer
    expect(os.perm_id).to  be_an Integer 
    expect(os.perm_id.to_s).to  match  /^\d{9,11}$/   # has 9 to 11 numeric characters
    expect(os.client_id).to eq(1111).or eq(2111)
    expect(os.parent_id).to be_zero
    expect(os.submitted?).to be_truthy
  end


end

describe IB::Messages::Incoming::OpenOrder do

  context 'Instantiated with buffer data'  do
    subject do
#      IB::Messages::Incoming::OpenOrder.new :version => 34,
#                                            :order =>
#                                                {:local_id => 1313,
#                                                 :perm_id => 172323928,
#                                                 :client_id => 1111,
#                                                 :parent_id => 0,
#                                                 :side => :buy,
#                                                 :order_type => :limit,
#                                                 :limit_price => 49.13,
#                                                 :total_quantity => 100.0,
#                                                },
#                                            :order_state =>
#                                                {:local_id => 1313,
#                                                 :perm_id => 172323928,
#                                                 :client_id => 1111,
#                                                 :parent_id => 0,
#                                                 :status => 'PreSubmitted',
#                                                },
#                                            :contract =>
#                                                {:symbol => 'WFC',
#                                                 :exchange => 'NYSE',
#                                                 :currency => 'USD',
#                                                 :sec_type => :stock
#                                                }
#
	    #instead of using a synthetic order, we build one from the response
	    #of a previously placed Limit.order
   IB::Messages::Incoming::OpenOrder.new ["34",
      "1313", "7516", "WFC", "STK", "", "0", "?", "", "NYSE", "USD", "WFC", "WFC", "BUY", 
			"100", "LMT", "49.13", "0.0", "GTC", "", "DU167349", "C", "0",
     "", "1111", "172323828", "0", "0", "0", "", "", "", "", "", "", "", "",
     "0", "", "", "0", "", "-1", "0", "", "", "", "", "", "", "0", "0", "0",
     "", "3", "0", "0", "", "0", "0", "", "0", "None", "", "0", "", "", "",
     "?", "0", "0", "", "0", "0", "", "", "", "", "", "0", "0", "0", "", "",
     "", "", "0", "", "IB", "0", "0", "", "0", "0", "Submitted",
     "1.7976931348623157E308", "1.7976931348623157E308",
     "1.7976931348623157E308", "", "", "", "", "", "0", "0", "0", "None",
     "1.7976931348623157E308", "1.7976931348623157E308",
     "1.7976931348623157E308", "1.7976931348623157E308",
     "1.7976931348623157E308", "1.7976931348623157E308", "0", "", "", "",
     "1.7976931348623157E308"]

    
    end

    it_behaves_like 'OpenOrder message'
  end

	context 'degraded Message' do
		subject do
			IB::Messages::Incoming::OpenOrder.new ["34",
					"1313", "7516", "WFC", "STK", "", "0", "?", "", "NYSE", "USD", "WFC", "WFC",
					"BUY", "100", "LMT", "49.13", "0.0", "GTC", "", "DU167349", "C", "0",
					"", "1111", "172323828", "0", "0", "0", "", "", "", "", "", "", "", "",
					"0", "", "", "0", "", "-1", "0", "", "", "", "", "", "", "0", "0", "0",
					"", "3", "0", "0", "", "0", "0", "", "0", "None", "", "0", "", "", "",
					"?", "0", "0", "", "0", "0", "", "", "", "", "", "0", "0", "0", "", ""]
		end

		it "matches the error message" do
			expect { subject}.
				to raise_error(IB::TransmissionError)
		end
	end

	context 'stock order with conditions' do
		subject do
			IB::Messages::Incoming::OpenOrder.new ["34",
				 "0", "37018770", "T", "STK", "", "0", "?", "", "SMART", "USD", "T", "T",
				 "BUY", "100", "LMT", "24.0", "0.0", "GTC", "", "DU167348", "?", "0",
				 "", "1111","1916223656", "0", "0", "0", "", "", "", "", "", "", "", "", "", "", "", "0",
				 "", "-1", "0", "", "", "", "", "", "", "0", "0", "0", "", "3", "0", "0", "",
				 "0", "0", "", "0", "None", "", "0", "", "", "", "?", "0", "0", "", "0", "0",
				 "", "", "", "", "", "0", "0", "0", "", "", "", "", "0", "", "IB", "0", "0",
				 "", "0", "0", "PreSubmitted", "1.7976931348623157E308",
				 "1.7976931348623157E308", "1.7976931348623157E308", "", "", "", "", "", "0","0",
				 "3",																									# count of conditions
				 "1", "a", "1", "2456.0", "299552802", "GLOBEX", "4", # PriceCondition
				 "4", "a", "1", "56",																	# MarginCondition
				 "3", "a", "0", "20191218 10:41:39 GMT+01:00",				# TimeCondition
				 "1", "0",																						# oth + cancel-order-flags
				 "Default",			# adjusted_order_type
				 "1.7976931348623157E308", "1.7976931348623157E308", "1.7976931348623157E308",	
				 # trigger_price. trail_stop_price,  adjusted_stop_limit_price
				 "1.7976931348623157E308", "1.7976931348623157E308", "1.7976931348623157E308", 
				 # adjusted_trailing_amount, adjustrable_traling_unit, soft_dollar_tier_name, 
				 "0", "", "", #  --value , --display_name, cash_quantity
				 "", "1.7976931348623157E308"] # mifit2 dicisionmaker, -- decision_algo
																			 # mifit2_executionmaker, --execution_algo  ### missing??
		end


		it 'contains conditions' do
			expect( subject.conditions.size ).to eq 3
			expect( subject.conditions.at(0)).to be_an  IB::PriceCondition 
			expect( subject.conditions.at(1)).to be_an  IB::MarginCondition 
			expect( subject.conditions.at(2)).to be_an  IB::TimeCondition 
			expect( subject.order.conditions_ignore_rth ).to be_truthy 
			expect( subject.order.adjusted_order_type ).to eq "Default" 
		end


    it_behaves_like 'OpenOrder message'
		
	end
  context 'received from IB' do
    before(:all) do
      verify_account
      ib = IB::Connection.new OPTS[:connection].merge(:logger => mock_logger)
      ib.wait_for :NextValidId
      @order_id =  place_the_order do | the_price| 
				IB::Limit.order price: the_price -2 , action: :buy, size: 100, account: ACCOUNT
			end
      expect(ib.received?(:OpenOrder)).to  be_truthy
    end

    after(:all) { IB::Connection.current.cancel_order(@order_id); close_connection } 

		context IB::Messages::Incoming::OpenOrder do
    subject { IB::Connection.current.received[:OpenOrder].first }

    it 'has proper contract accessor' do
      c = subject.contract
      expect(c).to be_an IB::Contract
      expect(c.symbol).to eq  'WFC'
      expect(c.exchange).to eq 'NYSE'
    end
     

    it_behaves_like 'OpenOrder message'
		end
    #it 'has extended order_state attributes' do
  end



  context 'Combo recieved from IB' do
    subject do
      # recorded OpenOrder Message of the ICE Combo from Sample-Contracts
     IB::Messages::Incoming::OpenOrder.new  ["34", "16", "28812380", "IECombo",
					     "BAG", "", "0", "?", "", "SMART",
					     "USD", "28812380", "COMB", "BUY",
					     "100", "LMT", "5.45", "0.0",
					     "GTC", "", "DU167348", "C", "0",
					     "", "1111", "164391210", "0", "0",
					     "0", "", "", "", "", "", "", "",
					     "", "0", "", "", "0", "", "-1",
					     "0", "", "", "", "", "", "", "0",
					     "0", "0", "", "3", "0", "0", "",
					     "0", "0", "", "0", "None", "",
					     "0", "", "", "", "?", "0", "0",
					     "", "0", "0", "", "", "", "",
					     "9408|-1,43645865|1", "2", "9408",
					     "1", "SELL", "SMART", "0", "0",
					     "", "-1", "43645865", "1", "BUY",
					     "SMART", "0", "0", "", "-5", "0",
					     "1", "NonGuaranteed", "1", "", "",
					     "", "", "0", "", "IB", "0", "0",
					     "", "0", "0", "PreSubmitted",
					     "1.7976931348623157E308",
					     "1.7976931348623157E308",
					     "1.7976931348623157E308", "", "",
					     "", "", "", "0", "0", "0", "None",
					     "1.7976931348623157E308",
					     "1.7976931348623157E308",
					     "1.7976931348623157E308",
					     "1.7976931348623157E308",
					     "1.7976931348623157E308",
					     "1.7976931348623157E308", "0", "",
					     "", "", "1.7976931348623157E308"]

    end
    
    it_behaves_like 'OpenOrder message'

    it 'has proper contract accessor' do
      c = subject.contract
      expect( c ).to be_a IB::Bag
      expect( c.symbol).to eq 'IECombo'
      expect( c.trading_class).to eq 'COMB'
#      expect( c.local_symbol).to eq  subject.contract.con_id.to_s
    end
    it "has essential fields"  do
      
      expect(subject.order.limit_price).to eq 5.45
      expect(subject.order.client_id).to eq(1111).or eq(2111)
      expect(subject.order.oca_type).to eq  :reduce_no_block
      expect(subject.order.delta_neutral_order_type).to eq :none
      expect(subject.status).to match /Submit/
#      expect/subject.
#      expect(subject.buffer).to be_empty 
      puts subject.contract.combo_legs.to_s
      expect( subject.contract.combo_legs).to have(2).items
      expect( subject.order.combo_params ).to eq :NonGuaranteed=>"1"
      expect( subject.order.clearing_intent ).to eq  :ib
    end

    it_behaves_like 'OpenOrder message'
    
  end
    context "OptionSpread recieved from IB" do
			subject do 
				IB::Messages::Incoming::OpenOrder.new ["34", "7", 
							"17356630", "DBK", "BAG", "", "0", "?", "", 
							"DTB", "EUR", "DBK", "COMB", "SELL", "5", "LMT", "56.0", "0.0", "GTC", "", 
							"DU167348", "O", "0", "", "1111", "1696530848", "0", "0", "0", 
							"", "", "", "", "", "", "", "", "", "", "", "0", "", "-1", "0", 
							"", "", "", "", "", "", "0", "0", "0", "", "3", "1", "1", "", "0", 
							"0", "", "0", "None", "", "0", "", "", "", "?", "0", "0", "", "0", 
							"0", "", "", "", "", "270580382|-1,270581032|1", "2", "270580382", 
							"1", "SELL", "DTB", "0", "0", "", "-1", "270581032", 
							"1", "BUY", "DTB", "0", "0", "", "-1", "0", "0", "", "", "", "", "0", "",
							"IB", "0", "0", "", "0", "0", "Submitted", "1.7976931348623157E308", 
							"1.7976931348623157E308", "1.7976931348623157E308", "", "", "", "", "", 
							"0", "0", "0", "None", "1.7976931348623157E308", "57.0", "1.7976931348623157E308", 
							"1.7976931348623157E308", "1.7976931348623157E308", "1.7976931348623157E308", "0", 
							"", "", "", "1.7976931348623157E308"]
			end
# to generate the order:
      # o = Combo.order action: :sell, size: 5, price: 56
      # c =  Symbols::Combo.dbk_straddle
      # C.place_order o, c
			#

    it_behaves_like 'OpenOrder message'
#		it{ puts subject.inspect  }
    end


    context "Forex cash_qty order recieved from IB" do
# to generate the order:
      # o = ForexLimit.order action: :buy, size: 15000, cash_qty: true
      # c =  Symbols::Forex.eurusd
      # C.place_order o, c
    end



end # describe IB::Messages:Incoming

__END__


