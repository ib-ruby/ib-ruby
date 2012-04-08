require 'model_helper'

describe IB::Models::Contracts::Option do # AKA IB::Option

  let(:props) do
    {:symbol => 'AAPL',
     :expiry => '201301',
     :strike => 600,
     :right => :put,
    }
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
     :include_expired => false}
  end

  let(:errors) do
    {:right => ["should be put or call"],
    }
  end

  let(:assigns) do
    {:expiry =>
         {[200609, '200609'] => '200609', [nil, ''] => nil},
     :multiplier => {['123', 123] => 123},
     :sec_type => IB::Contract::CODES[:sec_type].invert,
     :right =>
         {["PUT", "put", "P", "p", :put] => 'PUT',
          ["CALL", "call", "C", "c", :call] => 'CALL'},
     # ContractDetails properties
     [:under_con_id, :min_tick] => {123 => 123},
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

    it 'has extra osi accessor' do
      subject.osi.should == nil
    end

    it 'becomes invalid if assigned wrong :osi property' do
      subject.osi = 'BAR'
      subject.should be_invalid
      subject.errors.messages[:local_symbol].should include "invalid OSI code"
    end
  end

  context '.from_osi class builder' do
    subject { IB::Option.from_osi 'AAPL130119C00500000' }

    it 'builds a valid Option contract from OSI code' do
      subject.should be_an IB::Option
      subject.should be_valid
      subject.symbol.should == 'AAPL'
      subject.expiry.should == '130118' # <- NB: Change in date!
      subject.right.should == 'CALL'
      subject.strike.should == 500
      #subject.osi.should == 'AAPL  130119C00500000'
    end

    it_behaves_like 'Contract'
  end

end # describe IB::Contract
