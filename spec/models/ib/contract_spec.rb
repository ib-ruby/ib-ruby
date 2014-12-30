require 'model_helper'
require 'combo_helper'
## needs tws-connection (update connect.yml, if nessacary)
describe IB::Contract ,
	:props =>  { 
	:symbol => 'AAPL',
	:sec_type => :option,
	:expiry => '201503',
	:strike => 110,
	:right => :put,
	:sec_id => 'US0378331005',
	:sec_id_type => 'ISIN',
	:multiplier => 10,
	:exchange => 'SMART',
	:currency => 'USD',
	:local_symbol => 'AAPL  150320C00110000'} ,

	:human => "<Contract: AAPL option 201503 put 110.0 SMART USD>",

	:errors => {:sec_type => ["should be valid security type"] },

	:assigns => {:expiry =>
               {[200609, '200609'] => '200609',
                [20060913, '20060913'] => '20060913',
                [:foo, 2006, 42, 'bar'] => /should be YYYYMM or YYYYMMDD/},

               :sec_type => codes_and_values_for(:sec_type).
               merge([:foo, 'BAR', 42] => /should be valid security type/),

               :sec_id =>
               {[:US0378331005, 'us0378331005', 'US0378331005'] => 'US0378331005',
                [:'37833100', 37833100, '37833100'] => '37833100',
                [:'AAPL.O', 'AAPL.O'] => 'AAPL.O',
                },

               :sec_id_type =>
               {[:isin, 'ISIN', 'iSin'] => 'ISIN',
                [:sedol, :SEDOL, 'sEDoL', 'SEDOL'] => 'SEDOL',
                [:cusip, :CUSIP, 'Cusip', 'CUSIP'] => 'CUSIP',
                [:ric, :RIC, 'rIC', 'RIC'] => 'RIC',
                nil => nil,
                '' => '',
                [:foo, 'BAR', 'baz'] => /should be valid security identifier/},

               :right =>
               {["PUT", "put", "P", "p", :put] => :put,
                ["CALL", "call", "C", "c", :call] => :call,
                ['', '0', '?', :none] => :none,
                [:foo, 'BAR', 42] => /should be put, call or none/},

               :exchange => string_upcase_assigns.merge(
               [:smart, 'SMART', 'smArt'] => 'SMART'),

               :primary_exchange =>string_upcase_assigns.merge(
               [:SMART, 'SMART'] => /should not be SMART/),

               :multiplier => to_i_assigns,

               :strike => to_f_assigns,

               :include_expired => boolean_assigns,
} do
  it_behaves_like 'Model with invalid defaults' 
  it_behaves_like 'Self-equal Model'
  it_behaves_like 'Contract'
 end

  context 'testing for Contract type (sec_type)' do

    it 'correctly defines Contract type (sec_type) for Option contract' do
      [IB::Contract.new(:sec_type => :option),
       IB::Contract.new(:sec_type => 'OPT'),
       IB::Option.new
      ].each do |contract|
        expect( contract).not_to be_bag
        expect( contract).not_to be_bond
        expect( contract).not_to be_stock
        expect( contract).to be_option
      end
    end

    it 'correctly defines Contract type for Bag Contracts' do
      [IB::Contract.new(:sec_type => :bag),
       IB::Contract.new(:sec_type => 'BAG'),
       IB::Bag.new
      ].each do |contract|
        expect( contract).to be_bag
        expect( contract).not_to be_bond
        expect( contract).not_to be_stock
        expect( contract).not_to be_option
      end
    end

    it 'correctly defines Contract type for Stock Contracts' do
      [IB::Contract.new(:sec_type => :stock),
       IB::Contract.new(:sec_type => 'STK'),
      ].each do |contract|
        expect( contract).not_to be_bag
        expect( contract).not_to be_bond
        expect( contract).to be_stock
        expect( contract).not_to be_option
      end
    end

    it 'correctly defines Contract type for Bond Contracts' do
      [IB::Contract.new(:sec_type => :bond),
       IB::Contract.new(:sec_type => 'BOND'),
      ].each do |contract|
        expect( contract).not_to be_bag
        expect( contract).to be_bond
        expect( contract).not_to be_stock
        expect( contract).not_to be_option
      end
    end

#  end
#
  context "serialization", :connected => true do
    
    let( :contract ) { FactoryGirl.build :ib_option_contract }
		       #IB::Contract.new props }
    let( :bag ){ FactoryGirl.build( :butterfliege ,{symbol:'GOOG', expire:'201501', legs:[500,510,520], kind:'CALL'}) }
    let( :google_option_1){ FactoryGirl.build(:tws_option_contract, symbol:'GOOG', right:'CALL', strike: 500, expiry:'201501')}	
    let( :google_option_2){ FactoryGirl.build(:tws_option_contract, symbol:'GOOG', right:'CALL', strike: 510, expiry:'201501')}	
    let( :google_option_3){ FactoryGirl.build(:tws_option_contract, symbol:'GOOG', right:'CALL', strike: 520, expiry:'201501')}	


    it "serializes long" do
      expect( contract.serialize_long).to eq ["AAPL", "OPT", "201503", 110.0, "P", 10, "SMART", nil, "USD", "AAPL  150320C00110000"]
    end

    it "serializes short" do
      expect( contract.serialize_short).to eq ["AAPL", "OPT", "201503", 110.0, "P", 10, "SMART", "USD", "AAPL  150320C00110000"]
    end

    it "serializes combo (BAG) contracts for Order placement" do
     expect( bag.serialize_long(:con_id, :sec_id)).to eq [0, "GOOG", "BAG", "", 0.0, "", nil, "SMART", nil, "USD", "", nil, nil]
    end

    it 'also serializes attached combo legs' do
      expect( contract.serialize_legs(:extended) ).to eq []

#      expect( bag.serialize_legs ).to eq [3, 176695686, 1, "BUY", "SMART", 176695703, 2, "SELL", "SMART", 176695716, 1, "BUY", "SMART"]
      expect( bag.serialize_legs ).to eq [3, 	google_option_1.con_id, 1, "BUY", "SMART", 
					  	google_option_2.con_id, 2, "SELL", "SMART", 
					  	google_option_3.con_id, 1, "BUY", "SMART"]

     expect( bag.serialize_legs(:extended) ).to eq [3, google_option_1.con_id, 1, "BUY", "SMART", 0, 0, "", -1,
						       google_option_2.con_id, 2, "SELL", "SMART", 0, 0, "", -1,
						       google_option_3.con_id, 1, "BUY", "SMART", 0, 0, "", -1]
        end
  end #serialization


end # describe IB::Contract
