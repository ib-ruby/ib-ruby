require 'model_helper'

describe IB::Models::Execution do # AKA IB::Execution

  let(:props) do
    {:account_name => "DU111110",
     :client_id => 1111,
     :exchange => "IDEALPRO",
     :exec_id => "0001f4e8.4f5d48f1.01.01",
     :liquidation => true,
     :order_id => 373,
     :perm_id => 1695693619,
     :price => 1.31075,
     :average_price => 1.31075,
     :shares => 20000,
     :cumulative_quantity => 20000,
     :side => :buy,
     :time => "20120312  15:41:09"
    }
  end

  let(:human) do
    "<Execution: 20120312  15:41:09 buy 20000 at 1.31075 on IDEALPRO, " +
        "cumulative 20000 at 1.31075, ids 373/1695693619/0001f4e8.4f5d48f1.01.01>"
  end

  let(:defaults) do
    {:order_id => 0,
     :client_id => 0,
     :perm_id => 0,
     :shares=> 0,
     :price => 0,
     :liquidation => false,
     :created_at => Time,
    }
  end

  let(:errors) do
    {:side=>["should be buy/sell/short"],
     :cumulative_quantity=>["is not a number"],
     :average_price=>["is not a number"]}
  end

  let(:assigns) do
    {:side =>
         {['BOT', 'BUY', 'Buy', 'buy', :BUY, :BOT, :Buy, :buy, 'B', :b] => :buy,
          ['SELL', 'SLD', 'Sel', 'sell', :SELL, :SLD, :Sell, :sell, 'S', :S] => :sell},

     [:shares, :cumulative_quantity, :price, :average_price] =>
         {[:foo, 'BAR', nil] => /is not a number/},

     :liquidation => {[1, true] => true, [0, false] => false},
    }
  end

  it_behaves_like 'Model'

end # describe IB::Models::Contract
