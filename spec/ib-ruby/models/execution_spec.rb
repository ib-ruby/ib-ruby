require 'model_helper'

describe IB::Models::Execution do # AKA IB::Execution

  let(:props) do
    {:account_name => "DU111110",
     :client_id => 1111,
     :exchange => "IDEALPRO",
     :exec_id => "0001f4e8.4f5d48f1.01.01",
     :liquidation => 1,
     :order_id => 373,
     :perm_id => 1695693619,
     :price => 1.31075,
     :average_price => 1.31075,
     :shares => 20000,
     :cumulative_quantity => 20000,
     :side => 'BOT',
     :time => "20120312  15:41:09"
    }
  end

  let(:values) do
    {:liquidation => true,
     :side => :buy,
    }
  end

  let(:defaults) do
    {:order_id => 0,
     :client_id => 0,
     :perm_id => 0,
     :shares=> 0,
     :price => 0,
     :liquidation => false,
     :created_at => Time}
  end

  let(:errors) do
    {:side=>["should be buy or sell"],
     :cumulative_quantity=>["is not a number"],
     :average_price=>["is not a number"]}
  end

  let(:assigns) do
    {:side =>
         {['BOT', 'BUY', 'Buy', 'buy', :BUY, :BOT, :Buy, :buy, 'B', :b] => :buy,
          ['SELL', 'SLD', 'Sel', 'sell', :SELL, :SLD, :Sell, :sell, 'S', :S] => :sell},
     :liquidation => {1 => true, 0 => false},
    }
  end

  context 'instantiation without properties' do
    subject { IB::Execution.new }

    it_behaves_like 'Model instantiated empty'
  end

  context 'instantiation with properties' do
    subject { IB::Execution.new props }

    it_behaves_like 'Model instantiated with properties'
  end

end # describe IB::Models::Contract
