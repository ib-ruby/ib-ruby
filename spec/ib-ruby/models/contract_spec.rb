require 'model_helper'
require 'combo_helper'

describe IB::Models::Contracts::Contract do # AKA IB::Contract

  let(:props) do
    {:symbol => 'AAPL',
     :sec_type => :option,
     :expiry => '201301',
     :strike => 600,
     :right => :put,
     :multiplier => 10,
     :exchange => 'SMART',
     :currency => 'USD',
     :local_symbol => 'AAPL  130119C00500000'}
  end

  let(:human) do
    "<Contract: AAPL option 201301 put 600 SMART USD>"
  end

  let(:defaults) do
    {:con_id => 0,
     :strike => 0,
     :min_tick => 0,
     :coupon => 0,
     :callable => false,
     :puttable => false,
     :convertible => false,
     :next_option_partial => false,
     :include_expired => false,
     :created_at => Time,
    }
  end

  let(:errors) do
    {:sec_type => ["should be valid security type"],
    }
  end

  let(:assigns) do
    {:expiry =>
         {[200609, '200609'] => '200609',
          [20060913, '20060913'] => '20060913',
          [:foo, 2006, 42, 'bar'] => /should be YYYYMM or YYYYMMDD/},

     :sec_type => codes_and_values_for(:sec_type).
         merge([:foo, 'BAR', 42] => /should be valid security type/),

     :right =>
         {["PUT", "put", "P", "p", :put] => :put,
          ["CALL", "call", "C", "c", :call] => :call,
          ['', '0', '?', :none] => :none,
          [:foo, 'BAR', 42] => /should be put, call or none/},

     :exchange =>
         {[:cboe, 'cboE', 'CBOE'] => 'CBOE',
          [:smart, 'SMART', 'smArt'] => 'SMART'},

     :primary_exchange =>
         {[:cboe, 'cboE', 'CBOE'] => 'CBOE',
          [:SMART, 'SMART'] => /should not be SMART/},

     :multiplier => {['123', 123] => 123},

     [:under_con_id, :min_tick, :coupon] => {123 => 123},

     [:callable, :puttable, :convertible, :next_option_partial] =>
         {[1, true] => true, [0, false] => false},
    }
  end

  it_behaves_like 'Model'
  it_behaves_like 'Self-equal Model'

  context 'testing for Contract type (sec_type)' do

    it 'correctly defines Contract type (sec_type) for Option contract' do
      [IB::Contract.new(:sec_type => :option),
       IB::Contract.new(:sec_type => 'OPT'),
       IB::Option.new
      ].each do |contract|
        contract.should_not be_bag
        contract.should_not be_bond
        contract.should_not be_stock
        contract.should be_option
      end
    end

    it 'correctly defines Contract type for Bag Contracts' do
      [IB::Contract.new(:sec_type => :bag),
       IB::Contract.new(:sec_type => 'BAG'),
       IB::Bag.new
      ].each do |contract|
        contract.should be_bag
        contract.should_not be_bond
        contract.should_not be_stock
        contract.should_not be_option
      end
    end

    it 'correctly defines Contract type for Bag Contracts' do
      [IB::Contract.new(:sec_type => :stock),
       IB::Contract.new(:sec_type => 'STK'),
      ].each do |contract|
        contract.should_not be_bag
        contract.should_not be_bond
        contract.should be_stock
        contract.should_not be_option
      end
    end

    it 'correctly defines Contract type for Bond Contracts' do
      [IB::Contract.new(:sec_type => :bond),
       IB::Contract.new(:sec_type => 'BOND'),
      ].each do |contract|
        contract.should_not be_bag
        contract.should be_bond
        contract.should_not be_stock
        contract.should_not be_option
      end
    end

  end

  context 'using shorter class name without properties' do
    subject { IB::Models::Contract.new }
    it_behaves_like 'Model instantiated empty'
    it_behaves_like 'Self-equal Model'
    it_behaves_like 'Contract'
  end

  context 'using shortest class name without properties' do
    subject { IB::Contract.new }
    it_behaves_like 'Model instantiated empty'
    it_behaves_like 'Self-equal Model'
    it_behaves_like 'Contract'
  end

  context "serialization" do
    before(:all) do
      @ib = IB::Connection.new OPTS[:connection].merge(:logger => mock_logger)
      @ib.wait_for :ManagedAccounts
      @combo = butterfly 'GOOG', '201301', 'CALL', 500, 510, 520
      close_connection
    end

    subject { IB::Contract.new props }

    it "serializes long" do
      subject.serialize_long.should ==
          ["AAPL", "OPT", "201301", 600, "P", 10, "SMART", nil, "USD", "AAPL  130119C00500000"]
    end

    it "serializes short" do
      subject.serialize_short.should ==
          ["AAPL", "OPT", "201301", 600, "P", 10, "SMART", "USD", "AAPL  130119C00500000"]
    end

    it "serializes combo (BAG) contracts for Order placement" do
      @combo.serialize_long(:con_id, :sec_id).should ==
          [0, "GOOG", "BAG", nil, 0.0, "", nil, "SMART", nil, "USD", nil, nil, nil]
    end

    it 'also serializes attached combo legs' do
      subject.serialize_legs.should == []
      subject.serialize_legs(:extended).should == []

      @combo.serialize_legs.should ==
          [3, 81032967, 1, "BUY", "SMART", 81032968, 2, "SELL", "SMART", 81032973, 1, "BUY", "SMART"]

      @combo.serialize_legs(:extended).should ==
          [3, 81032967, 1, "BUY", "SMART", 0, 0, "", -1,
           81032968, 2, "SELL", "SMART", 0, 0, "", -1,
           81032973, 1, "BUY", "SMART", 0, 0, "", -1]
    end
  end #serialization


end # describe IB::Contract
