require 'model_helper'

describe IB::Models::Order do

  let(:props) do
    {:order_id => 23,
     :order_ref => 'Test',
     :client_id => 1111,
     :perm_id => 173276893,
     :parent_id => 0,
     :side => :buy,
     :order_type => :market_if_touched,
     :limit_price => 0.01,
     :total_quantity => 100,
     :tif => :good_till_cancelled,
     :open_close => :close,
     :oca_group => '',
     :oca_type => :reduce_no_block,
     :origin => :firm,
     :designated_location => "WHATEVER",
     :exempt_code => 123,
     :delta_neutral_order_type => :market,
     :commission_currency => "USD",
     :status => 'PreSubmitted',
     :transmit => false,
     :outside_rth => true,
     :what_if => true,
     :not_held => true}
  end

  # TODO: :presents => { Object => "Formatted"}
  let(:human) do
    "<Order: Test MIT GTC buy 100 PreSubmitted 0.01 id 23/173276893 from 1111>"
  end

  let(:defaults) do
    {:outside_rth => false,
     :open_close => :open,
     :short_sale_slot => :default,
     :tif => :day,
     :order_type => :limit,
     :origin => :customer,
     :transmit => true,
     :designated_location => '',
     :exempt_code => -1,
     :what_if => false,
     :not_held => false,
     :status => 'New',
     :created_at => Time,
    }
  end

  let(:errors) do
    {:side =>["should be buy/sell/short"],
     :order_id => ["is not a number"], }
  end

  let(:assigns) do
    {[:order_type, :delta_neutral_order_type] => codes_and_values_for(:order_type),
     :open_close =>
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
          [1, nil, 'ASK', :foo] => /should be buy.sell.short/, },

     [:what_if, :not_held, :outside_rth, :hidden, :transmit, :block_order, :sweep_to_fill,
      :override_percentage_constraints, :all_or_none, :etrade_only, :firm_quote_only,
      :opt_out_smart_routing, :scale_auto_reset, :scale_random_percent
     ] => {[1, true] => true, [0, false] => false},
    }
  end

  it_behaves_like 'Model'
  it_behaves_like 'Self-equal Model'


  context 'equality' do
    subject { IB::Order.new props }

    it_behaves_like 'Self-equal Model'

    it 'is not equal for Orders with different limit price' do
      order1 = IB::Order.new :total_quantity => 100,
                             :limit_price => 1,
                             :action => 'BUY'

      order2 = IB::Order.new :total_quantity => 100,
                             :limit_price => 2,
                             :action => 'BUY'
      order1.should_not == order2
      order2.should_not == order1
    end

    it 'is not equal for Orders with different total_quantity' do
      order1 = IB::Order.new :total_quantity => 20000,
                             :limit_price => 1,
                             :action => 'BUY'

      order2 = IB::Order.new :total_quantity => 100,
                             :action => 'BUY',
                             :limit_price => 1
      order1.should_not == order2
      order2.should_not == order1
    end

    it 'is not equal for Orders with different action/side' do
      order1 = IB::Order.new :total_quantity => 100,
                             :limit_price => 1,
                             :action => 'SELL'

      order2 = IB::Order.new :total_quantity => 100,
                             :action => 'BUY',
                             :limit_price => 1
      order1.should_not == order2
      order2.should_not == order1
    end

    it 'is not equal for Orders with different order_type' do
      order1 = IB::Order.new :total_quantity => 100,
                             :limit_price => 1,
                             :action => 'BUY',
                             :order_type => 'LMT'

      order2 = IB::Order.new :total_quantity => 100,
                             :action => 'BUY',
                             :limit_price => 1,
                             :order_type => 'MKT'
      order1.should_not == order2
      order2.should_not == order1
    end
  end

end # describe IB::Order
