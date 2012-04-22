require 'model_helper'

describe IB::Models::Bag do # AKA IB::Bag

  let(:props) do
    {:symbol => 'GOOG',
     :exchange => 'SMART',
     :currency => 'USD',
     :legs => [IB::ComboLeg.new(:con_id => 81032967, :weight => 1),
               IB::ComboLeg.new(:con_id => 81032968, :weight => -2),
               IB::ComboLeg.new(:con_id => 81032973, :weight => 1)]
    }
  end

  let(:human) do
    "<Bag: GOOG SMART USD legs: 81032967|1,81032968|-2,81032973|1 >"
  end

  let(:errors) do
    {:legs => ["legs cannot be empty"],
    }
  end

  let(:assigns) do
    {:expiry =>
         {[nil, ''] => '',
          [20060913, '20060913', 200609, '200609', :foo, 2006, 42, 'bar'] =>
              /should be blank/},

     :sec_type =>
         {['BAG', :bag] => :bag,
          IB::CODES[:sec_type].reject { |k, _| k == :bag }.to_a =>
              /should be a bag/},

     :right =>
         {['?', :none, '', '0'] => :none,
          ["PUT", :put, "CALL", "C", :call, :foo, 'BAR', 42] =>
              /should be none/},

     :exchange =>
         {[:cboe, 'cboE', 'CBOE'] => 'CBOE',
          [:smart, 'SMART', 'smArt'] => 'SMART'},

     :primary_exchange =>
         {[:cboe, 'cboE', 'CBOE'] => 'CBOE',
          [:SMART, 'SMART'] => /should not be SMART/},

     [:symbol, :local_symbol] =>
         {['AAPL', :AAPL] => 'AAPL'},

     :multiplier => {['123', 123] => 123}
    }
  end

  context 'using shortest class name without properties' do
    subject { IB::Bag.new }
    it_behaves_like 'Model instantiated empty'
  end

  it_behaves_like 'Model'
  it_behaves_like 'Self-equal Model'

  context 'properly initiated' do
    subject { IB::Bag.new props }

    it_behaves_like 'Contract'

    it 'has extra legs_description accessor' do
      subject.legs_description.should == "81032967|1,81032968|-2,81032973|1"
    end
  end

  it 'correctly defines Contract type (sec_type) for Bag contract' do
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

end # describe IB::Bag
