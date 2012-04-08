require 'model_helper'

shared_examples_for 'Contract' do
  it 'summary points to itself (ContractDetails artifact' do
    subject.summary.should == subject
  end

  it 'becomes invalid if assigned wrong :sec_type property' do
    c = IB::Contract.new props
    c.should be_valid
    c.sec_type = 'FOO'
    c.should be_invalid
    c.errors.messages.should == {:sec_type => ["should be valid security type"]}
  end

  it 'becomes invalid if assigned wrong :right property' do
    c = IB::Contract.new props
    c.should be_valid
    c.right = 'BAR'
    c.should be_invalid
    c.errors.messages.should == {:right => ["should be put, call or nil"]}
  end

  it 'becomes invalid if assigned wrong :expiry property' do
    c = IB::Contract.new props
    c.should be_valid
    c.expiry = 'BAR'
    c.should be_invalid
    c.errors.messages.should == {:expiry => ["should be YYYYMM or YYYYMMDD"]}
  end

  it 'becomes invalid if primary_exchange is set to SMART' do
    c = IB::Contract.new props
    c.should be_valid
    c.primary_exchange = 'SMART'
    c.should be_invalid
    c.errors.messages.should == {:primary_exchange => ["should not be SMART"]}
  end

end

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

  let(:values) do
    {:right => 'PUT',
     :sec_type => 'OPT',
    }
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
     :include_expired => false}
  end

  let(:errors) do
    {:sec_type => ["should be valid security type"],
    }
  end

  let(:assigns) do
    {:expiry =>
         {[200609, '200609'] => '200609',
          [nil, ''] => nil},
     :multiplier => {['123', 123] => 123},
     :sec_type => IB::SECURITY_TYPES.values,
     :right =>
         {["PUT", "put", "P", "p", :put] => 'PUT',
          ["CALL", "call", "C", "c", :call] => 'CALL'},
     # ContractDetails properties
     [:under_con_id, :min_tick, :coupon] => {123 => 123},
     [:callable, :puttable, :convertible, :next_option_partial] =>
         {[1, true] => true, [0, false] => false},
    }
  end

  it_behaves_like 'Model'
  it_behaves_like 'Self-equal Model'

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
    subject { IB::Contract.new props }

    it "serializes long" do
      subject.serialize_long.should ==
          ["AAPL", "OPT", "201301", 600, "PUT", 10, "SMART", nil, "USD", "AAPL  130119C00500000"]
    end

    it "serializes short" do
      subject.serialize_short.should ==
          ["AAPL", "OPT", "201301", 600, "PUT", 10, "SMART", "USD", "AAPL  130119C00500000"]
    end
  end #serialization

end # describe IB::Contract
