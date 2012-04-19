require 'model_helper'

describe IB::Models::Contracts::Option do # AKA IB::Option

  let(:props) do
    {:symbol => 'AAPL',
     :expiry => '201301',
     :strike => 600,
     :right => :put,
    }
  end

  let(:human) do
    "<Option: AAPL 201301 put 600 SMART >"
  end

  let(:defaults) do
    {:sec_type => :option,
     :con_id => 0,
     :strike => 0,
     :min_tick => 0,
     :include_expired => false,
     #:created_at => Time,   # Does not work in DB mode
    }
  end

  let(:errors) do
    {:right => ["should be put or call"],
     :strike => ["must be greater than 0"],
    }
  end

  let(:assigns) do
    {:expiry =>
         {[200609, '200609'] => '200609',
          [20060913, '20060913'] => '20060913',
          [:foo, 2006, 42, 'bar'] => /should be YYYYMM or YYYYMMDD/},

     :sec_type =>
         {['OPT', :option] => :option,
          IB::CODES[:sec_type].reject { |k, v,| k == :option }.to_a =>
              /should be an option/},

     :right =>
         {["PUT", "put", "P", "p", :put] => :put,
          ["CALL", "call", "C", "c", :call] => :call,
          ['', '0', '?', :none, :foo, 'BAR', 42] => /should be put or call/},

     :exchange =>
         {[:cboe, 'cboE', 'CBOE'] => 'CBOE',
          [:smart, 'SMART', 'smArt'] => 'SMART'},

     :primary_exchange =>
         {[:cboe, 'cboE', 'CBOE'] => 'CBOE',
          [:SMART, 'SMART'] => /should not be SMART/},

     :symbol =>
         {['AAPL', :AAPL] => 'AAPL'},

     :local_symbol =>
         {['AAPL  130119C00500000', :'AAPL  130119C00500000'] =>
              'AAPL  130119C00500000',
          'BAR'=> /invalid OSI code/},

     :strike => {[0, -30.0] => /must be greater than 0/},

     :multiplier => {['123', 123] => 123},

     [:under_con_id, :min_tick, :coupon] => {123 => 123}

    }
  end

  context 'using shorter class name without properties' do
    subject { IB::Models::Option.new }
    it_behaves_like 'Model instantiated empty'
  end

  context 'using shortest class name without properties' do
    subject { IB::Option.new }
    it_behaves_like 'Model instantiated empty'
  end

  it_behaves_like 'Model'
  it_behaves_like 'Self-equal Model'

  context 'properly initiated' do
    subject { IB::Option.new props }
    it_behaves_like 'Contract'

    it 'has extra osi accessor, aliasing :local_symbol' do
      subject.osi = 'FOO'
      subject.local_symbol.should == 'FOO'
      subject.local_symbol = 'bar'
      subject.osi.should == 'bar'
    end
  end

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

  context '.from_osi class builder' do
    subject { IB::Option.from_osi 'AAPL130119C00500000' }

    it 'builds a valid Option contract from OSI code' do
      subject.should be_an IB::Option
      subject.should be_valid
      subject.symbol.should == 'AAPL'
      subject.expiry.should == '130118' # <- NB: Change in date!
      subject.right.should == :call
      subject.strike.should == 500
      #subject.osi.should == 'AAPL  130119C00500000'
    end

    it_behaves_like 'Contract'
  end

end # describe IB::Contract
