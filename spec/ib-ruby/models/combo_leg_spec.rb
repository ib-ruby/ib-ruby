require 'model_helper'

describe IB::Models::ComboLeg do

  let(:props) do
    {:con_id => 81032967,
     :ratio => 2,
     :action => :buy,
     :exchange => 'CBOE',
     :open_close => :open,
     :short_sale_slot => :broker,
     :designated_location => nil,
     :exempt_code => 12}
  end

  let(:human) do
    "<ComboLeg: buy 2 con_id 81032967 at CBOE>"
  end

  let(:defaults) do
    {:con_id => 0,
     :open_close => :same,
     :designated_location => '',
     :exempt_code => -1,
     :exchange => 'SMART', # Unless SMART, Order modification fails
    }
  end

  let(:errors) do
    {:ratio => ["is not a number"],
     :side => ["should be buy/sell/short"]}
  end

  let(:assigns) do
    {:open_close =>
         {['SAME', 'same', 'S', 's', :same, 0, '0'] => :same,
          ['OPEN', 'open', 'O', 'o', :open, 1, '1'] => :open,
          ['CLOSE', 'close', 'C', 'c', :close, 2, '2'] => :close,
          ['UNKNOWN', 'unknown', 'U', 'u', :unknown, 3, '3'] => :unknown,
          [42, nil, 'Foo', :bar] => /should be same.open.close.unknown/},

     :side =>
         {['BOT', 'BUY', 'Buy', 'buy', :BUY, :BOT, :Buy, :buy, 'B', :b] => :buy,
          ['SELL', 'SLD', 'Sel', 'sell', :SELL, :SLD, :Sell, :sell, 'S', :S] => :sell,
          ['SSHORT', 'Short', 'short', :SHORT, :short, 'T', :T] => :short,
          ['SSHORTX', 'Shortextemt', 'shortx', :short_exempt, 'X', :X] => :short_exempt,
          [42, nil, 'ASK', :foo] => /should be buy.sell.short/},

     :designated_location =>
         {[42, 'FOO', :bar] => /should be blank or orders will be rejected/},
    }
  end

  it_behaves_like 'Model'

end # describe IB::Models::Contract::ComboLeg
