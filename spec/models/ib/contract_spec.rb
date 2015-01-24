###
# The following Error occurs frequently
#* ib_contract - Validation failed: Con has already been taken (ActiveRecord::RecordInvalid)
#
# This is caused by the uniqueness-validation  of Con_id, with fails during the Initialisation of Factorys
# 
# just repeat the test


require 'model_helper'
require 'combo_helper'
require 'contract_helper'
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
  context "serialization", :connected => true  do
    
if IB::Connection.current.nil?
	IB::Connection.new( OPTS[:connection].merge(:logger => mock_logger))
	to_be_disconnected =  true
end
let( :contract ) { FactoryGirl.build :ib_option_contract }
#IB::Contract.new props }
let( :bag ){ FactoryGirl.build( :butterfliege ,{symbol:'F', expire:'201503', legs:[14,15,16], kind:'Put'}) }
let( :ford_option_1){ FactoryGirl.build(:default_option, strike: 14)}	
let( :ford_option_2){ FactoryGirl.build(:default_option, strike: 15)}	
let( :ford_option_3){ FactoryGirl.build(:default_option, strike: 16)}	


    it "serializes long" do
      expect( contract.serialize_long).to eq ["AAPL", "OPT", "201503", 110.0, "P", 10, "SMART", nil, "USD", "AAPL  150320C00110000"]
    end

    it "serializes short" do
      expect( contract.serialize_short).to eq ["AAPL", "OPT", "201503", 110.0, "P", 10, "SMART", "USD", "AAPL  150320C00110000"]
    end

    it "serializes combo (BAG) contracts for Order placement" do
     expect( bag.serialize_long(:con_id, :sec_id)).to eq [0, "F", "BAG", "", 0.0, "", nil, "SMART", nil, "USD", "", nil, nil]
    end

    it 'also serializes attached combo legs' do
      expect( contract.serialize_legs(:extended) ).to eq []
      ford_option_1.read_contract_from_tws
	ford_option_2.read_contract_from_tws
	ford_option_3.read_contract_from_tws
	bag.legs[0].con_id= ford_option_1.con_id
	bag.legs[1].con_id= ford_option_2.con_id
	bag.legs[2].con_id= ford_option_3.con_id
#      expect( bag.serialize_legs ).to eq [3, 176695686, 1, "BUY", "SMART", 176695703, 2, "SELL", "SMART", 176695716, 1, "BUY", "SMART"]
      expect( bag.serialize_legs ).to eq [3, 	ford_option_1.con_id, 1, "BUY", "SMART", 
					  	ford_option_2.con_id, 2, "SELL", "SMART", 
					  	ford_option_3.con_id, 1, "BUY", "SMART"]

     expect( bag.serialize_legs(:extended) ).to eq [3, ford_option_1.con_id, 1, "BUY", "SMART", 0, 0, "", -1,
						       ford_option_2.con_id, 2, "SELL", "SMART", 0, 0, "", -1,
						       ford_option_3.con_id, 1, "BUY", "SMART", 0, 0, "", -1]
   
#     IB::Connection.current.disconnect if to_be_disconnected
    end
  end #serialization


  describe 'tws_reader' do
    before { IB::Connection.new( OPTS[:connection].merge(:logger => mock_logger)) if IB::Connection.current.nil? }
    let( :list_of_stocks )  { ["BAP","LNN","T","MSFT","GE"] }


    describe  "default Stock" do 
      it_behaves_like  "correctly query's the tws" do  # valid contract
	let( :contract ){ FactoryGirl.build( :con_id_contract ) }
      end
    end
    describe  "User-Defined Stock" do 
      it_behaves_like  "correctly query's the tws" do  # valid contract
	let( :contract ){ FactoryGirl.build( :default_stock, symbol:'AAPL' ) }
      end
    end

    describe  "User-Defined Stock, saved to the DB" do 
      it_behaves_like  "correctly query's the tws" do   # valid database-record

	let( :contract ){ FactoryGirl.create( :default_stock, symbol:'AAPL' ) }
      end
    end
    describe  "default Option"  do 
      it_behaves_like  "correctly query's the tws" do  
	let( :contract ){ FactoryGirl.build( :default_option ) }
      end
    end

    describe  "default Future"   do 
      it_behaves_like  "correctly query's the tws" do  
	let( :contract ){ FactoryGirl.build( :default_future ) }
      end
    end	
    describe  "User defined Future"   do 
      it_behaves_like  "correctly query's the tws" do  
	let( :contract ){ FactoryGirl.create( :default_future, symbol:'ES', exchange:'GLOBEX', multiplier:50 ) }
      end
    end
    describe "Invalid Stock-Symbol" do
      it_behaves_like  "invalid query of tws" do  # invalid symbol
	let( :contract ){ FactoryGirl.build( :default_stock, symbol:'AARL' ) }
      end
    end	
    describe "Invalid Stock-Symbol living in the DB" do
      it_behaves_like  "invalid query of tws" do  # invalid symbol in database-record
	let( :contract ){ FactoryGirl.create( :default_stock, symbol:'AARL' ) }
      end
    end
    describe  "User default Forex contract", focus:true  do
      it_behaves_like  "correctly query's the tws" do  
	let( :contract ){ IB::Symbols::Forex[:eurusd] }
      end
    end

    it "adds valid records to the database and updates contract_details as well" do
      list_of_stocks.each do |stock|
	contract= FactoryGirl.create( :default_stock, symbol:stock )
	# validity-test:
	expect{ contract.read_contract_from_tws }.to change{ contract.con_id }
	expect( contract.contract_detail ).to be_a IB::ContractDetail
	nc=  IB::Contract.find contract.id
	expect{ nc.read_contract_from_tws }.not_to change{ nc.contract_detail }

      end
      expect( IB::Contract.count).to eq list_of_stocks.size
    end

    ["15","16","17"].each do |strike|
      it_behaves_like  "correctly query's the tws"  do
	let( :contract ){ FactoryGirl.build( :default_option, strike:strike ) } #, symbol:'FAST', strike:strike, expiry:201503) }
      end # descirbe FG

    end # loop
    #	  ["AAPL","BAP","LNN","T","MSFT","GE"].each do |stock|
    #		  describe  FactoryGirl.create( :default_stock , symbol:stock)  do
    #		  it_returns_a 'correct ib contract object after a tws-query' 
    #		  end # descirbe FG
    #	  end
  end # describe tws_reader

  describe 'database interactions' , focus:true do

    context "without a given ConID" do
      let ( :stock ){ FactoryGirl.build( :default_stock ) }

      it " can be saved " do
	expect{ stock.save}.to change{ IB::Contract.count }.by(1)
      end
      it " can  be saved twice " do
	expect{ 2.times{ stock.dup.save} }.to change{ IB::Contract.count }.by 2
      end
    end # context

    context "with a given ConID" do
      let ( :stock ){IB::Contract.new con_id: 265598  }

      it " can be saved " do
	expect{ stock.save }.to change{ IB::Contract.count }.by(1)
      end
      it " cannot  be saved twice " do
	anotherstock = IB::Contract.new con_id: 265598
	expect{ 2.times{ stock.dup.save} }.not_to change{ IB::Contract.count }
	expect{ anotherstock.save! }.to raise_error ActiveRecord::RecordInvalid  #:(RuntimeError)
      end

    end # context

  end

  describe 'multithreading is supported by update_contract' , focus:true do
    # lets define 10 stocks
      let(:contracts) do
	[ 'A', 'T', 'V', 'DE', 'TAP', 'AAPL', 'MSFT', 'YNDX', 'DDR', 'ZBB'].collect do |y|
	  FactoryGirl.create( :default_stock, symbol: y )
	end
      end

      context 'perform update_contract' do
	it 'call the method' do
	  threadArray =  Array.new
	  contracts.each do |contract|
	    threadArray << Thread.new( contract){|c| c.read_contract_from_tws save_details:true }
	  end
	  threadArray.each{|t| t.join}  # wait for the threads to finish 

	  contracts.each do |c|
	    expect(c.con_id).to be_a Numeric
	    expect(c.contract_detail).to be_a IB::ContractDetail
	  end

	  
	 end
    end # context

  end # describe

end # describe IB::Contract
