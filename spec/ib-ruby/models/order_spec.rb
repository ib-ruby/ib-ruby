require 'model_helper'

describe IB::Models::Order do

  let(:props) do
    {:order_id => 13,
     :client_id => 1111,
     :perm_id => 173276893,
     :parent_id => 0,
     :order_type => 'MIT',
     :side => 'BUY',
     :limit_price => 0.01,
     :total_quantity => 100,
     :tif => 'GTC',
     :open_close => 'C',
     :oca_group => '',
     :oca_type => 3,
     :origin => IB::Order::Origin_Firm,
     :designated_location => "WHATEVER",
     :exempt_code => 123,
     :delta_neutral_order_type => "HACK",
     :commission_currency => "USD",
     :status => 'PreSubmitted',
     :transmit => 1,
     :outside_rth => 0,
     :what_if => 0,
     :not_held => 0}
  end

  let(:values) do
    {:what_if => false,
     :transmit => true,
     :outside_rth => false,
     :not_held => false,
     :side => :buy,
    }
  end

  let(:defaults) do
    {:outside_rth => false,
     :open_close => "O",
     :tif => 'DAY',
     :order_type => 'LMT',
     :origin => IB::Order::Origin_Customer,
     :transmit => true,
     :designated_location => '',
     :exempt_code => -1,
     :delta_neutral_order_type => '',
     :what_if => false,
     :not_held => false,
     :status => 'New'}
  end

  let(:errors) do
    {:side=>["should be buy/sell/short"],
     :order_id => ["is not a number"], }
  end

  let(:assigns) do
    {:side =>
         {['BOT', 'BUY', 'Buy', 'buy', :BUY, :BOT, :Buy, :buy, 'B', :b] => :buy,
          ['SELL', 'SLD', 'Sel', 'sell', :SELL, :SLD, :Sell, :sell, 'S', :S] => :sell,
          ['SSHORT', 'Short', 'short', :SHORT, :short] => :short},
     [:what_if, :not_held, :outside_rth, :hidden, :transmit, :block_order, :sweep_to_fill,
      :override_percentage_constraints, :all_or_none, :etrade_only, :firm_quote_only
     ] => {[1, true] => true, [0, false]=> false},
    }
  end

  it_behaves_like 'Model'

  context 'equality' do
    subject { IB::Order.new props }

    it 'is  self-equal ' do
      should == subject
    end

    it 'is equal to Order with the same properties' do
      should == IB::Order.new(props)
    end

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
