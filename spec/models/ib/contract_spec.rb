require 'model_helper'
require 'combo_helper'

RSpec.describe IB::Contract, focus: true, 
  :props =>
  {:symbol => 'AAPL',
   :sec_type => :option,
   :expiry => '201301',
   :strike => 600.5,
   :right => :put,
   :sec_id => 'US0378331005',
   :sec_id_type => 'ISIN',
   :multiplier => 10,
   :exchange => 'SMART',
   :currency => 'USD',
   :local_symbol => 'AAPL  130119C00500000'},

  :human => "<Contract: AAPL option 201301 put 600.5 SMART USD>",

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

#  it_behaves_like 'Model with invalid defaults'
  it_behaves_like 'Self-equal Model'

#  context 'testing for Contract type (sec_type)' do
#
#    it 'correctly defines Contract type (sec_type) for Option contract' do
#      [IB::Contract.new(:sec_type => :option),
#       IB::Contract.new(:sec_type => 'OPT'),
#       IB::Option.new
#      ].each do |contract|
#        contract.should_not be_bag
#        contract.should_not be_bond
#        contract.should_not be_stock
#        contract.should be_option
#      end
#    end
#
#    it 'correctly defines Contract type for Bag Contracts' do
#      [IB::Contract.new(:sec_type => :bag),
#       IB::Contract.new(:sec_type => 'BAG'),
#       IB::Bag.new
#      ].each do |contract|
#        contract.should be_bag
#        contract.should_not be_bond
#        contract.should_not be_stock
#        contract.should_not be_option
#      end
#    end
#
#    it 'correctly defines Contract type for Bag Contracts' do
#      [IB::Contract.new(:sec_type => :stock),
#       IB::Contract.new(:sec_type => 'STK'),
#      ].each do |contract|
#        contract.should_not be_bag
#        contract.should_not be_bond
#        contract.should be_stock
#        contract.should_not be_option
#      end
#    end
#
#    it 'correctly defines Contract type for Bond Contracts' do
#      [IB::Contract.new(:sec_type => :bond),
#       IB::Contract.new(:sec_type => 'BOND'),
#      ].each do |contract|
#        contract.should_not be_bag
#        contract.should be_bond
#        contract.should_not be_stock
#        contract.should_not be_option
#      end
#    end
#
#  end
#
#  context "serialization", :connected => true do
#    before(:all) do
#      # TODO: Change butterfly into a stub, reduce dependency on IB connection
#      @ib = IB::Connection.new OPTS[:connection].merge(:logger => mock_logger)
#      @ib.wait_for :ManagedAccounts
#      @combo = butterfly 'GOOG', '201301', 'CALL', 500, 510, 520
#      close_connection
#    end
#
#    subject { IB::Contract.new props }
#
#    it "serializes long" do
#      subject.serialize_long.should ==
#        ["AAPL", "OPT", "201301", 600.5, "P", 10, "SMART", nil, "USD", "AAPL  130119C00500000"]
#    end
#
#    it "serializes short" do
#      subject.serialize_short.should ==
#        ["AAPL", "OPT", "201301", 600.5, "P", 10, "SMART", "USD", "AAPL  130119C00500000"]
#    end
#
#    it "serializes combo (BAG) contracts for Order placement" do
#      @combo.serialize_long(:con_id, :sec_id).should ==
#        [0, "GOOG", "BAG", "", 0.0, "", nil, "SMART", nil, "USD", "", nil, nil]
#    end
#
#    it 'also serializes attached combo legs' do
#      subject.serialize_legs.should == []
#      subject.serialize_legs(:extended).should == []
#
#      @combo.serialize_legs.should ==
#        [3, 81032967, 1, "BUY", "SMART", 81032968, 2, "SELL", "SMART", 81032973, 1, "BUY", "SMART"]
#
#      @combo.serialize_legs(:extended).should ==
#        [3, 81032967, 1, "BUY", "SMART", 0, 0, "", -1,
#         81032968, 2, "SELL", "SMART", 0, 0, "", -1,
#         81032973, 1, "BUY", "SMART", 0, 0, "", -1]
#        end
#  end #serialization


end # describe IB::Contract
