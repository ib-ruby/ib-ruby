require 'model_helper'

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
     :include_expired => false}
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
