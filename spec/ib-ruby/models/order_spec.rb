require 'model_helper'

describe IB::Models::Order do

  let(:props) do
    {:local_id => 23,
     :order_ref => 'Test',
     :client_id => 1111,
     :perm_id => 173276893,
     :parent_id => 0,
     :side => :buy,
     :order_type => :market_if_touched,
     :limit_price => 0.1,
     :quantity => 100,
     :tif => :good_till_cancelled,
     :open_close => :close,
     :oca_group => '',
     :oca_type => :reduce_no_block,
     :origin => :firm,
     :designated_location => "WHATEVER",
     :exempt_code => 123,
     :delta_neutral_order_type => :market,
     :transmit => false,
     :outside_rth => true,
     :what_if => true,
     :not_held => true}
  end

  # TODO: :presents => { Object => "Formatted"}
  let(:human) do
    "<Order: Test MIT GTC buy 100 New 0.1 #23/173276893 from 1111>"
  end

  let(:defaults) do
    {:open_close => :open,
     :short_sale_slot => :default,
     :tif => :day,
     :order_type => :limit,
     :origin => :customer,
     :transmit => true,
     :designated_location => '',
     :exempt_code => -1,
     :what_if => false,
     :status => 'New',
     #:created_at => Time,   # Does not work in DB mode
    }
  end

  let(:errors) do
    {:side =>["should be buy/sell/short"]}
  end

  let(:assigns) do
    {[:order_type, :delta_neutral_order_type] => codes_and_values_for(:order_type),

     :open_close =>
         {[42, nil, 'Foo', :bar] => /should be same.open.close.unknown/,
          ['SAME', 'same', 'S', 's', :same, 0, '0'] => :same,
          ['OPEN', 'open', 'O', 'o', :open, 1, '1'] => :open,
          ['CLOSE', 'close', 'C', 'c', :close, 2, '2'] => :close,
          ['UNKNOWN', 'unknown', 'U', 'u', :unknown, 3, '3'] => :unknown,
         },

     [:what_if, :not_held, :outside_rth, :hidden, :transmit, :block_order,
      :sweep_to_fill, :override_percentage_constraints, :all_or_none,
      :etrade_only, :firm_quote_only, :opt_out_smart_routing, :scale_auto_reset,
      :scale_random_percent] => boolean_assigns,
    }
  end

  let(:aliases) do
    {[:side, :action] => buy_sell_short_assigns,
     [:local_id, :order_id] => numeric_or_nil_assigns,
     [:quantity, :total_quantity] => numeric_or_nil_assigns,
    }
  end

  let(:associations) do
    {:order_states => [IB::OrderState.new(:status => :Foo),
                       IB::OrderState.new(:status => 'Bar'),],

     :executions => [IB::Execution.new(:local_id => 23,
                                       :client_id => 1111,
                                       :perm_id => 173276893,
                                       :exchange => "IDEALPRO",
                                       :exec_id => "0001f4e8.4f5d48f1.01.01",
                                       :price => 0.1,
                                       :average_price => 0.1,
                                       :shares => 40,
                                       :cumulative_quantity => 40,
                                       :side => :buy,
                                       :time => "20120312  15:41:09"),
                     IB::Execution.new(:local_id => 23,
                                       :client_id => 1111,
                                       :perm_id => 173276893,
                                       :exchange => "IDEALPRO",
                                       :exec_id => "0001f4e8.4f5d48f1.01.02",
                                       :price => 0.1,
                                       :average_price => 0.1,
                                       :shares => 60,
                                       :cumulative_quantity => 100,
                                       :side => :buy,
                                       :time => "20120312  15:41:10")]
    }
  end

  it_behaves_like 'Model'
  it_behaves_like 'Self-equal Model'

  context 'Order associations' do
    after(:all) { DatabaseCleaner.clean }

    subject { IB::Order.new props }

    it 'has order_states collection with at least one extra accessors to OrderState properties' do
      subject.order_states.should_not be_nil
      subject.order_states.should be_an Array # lies, it's more like association proxy
    end

    it 'has at least one (initial, New) OrderState' do
      subject.order_states.should have_exactly(1).state
      last_state = subject.order_states.last
      last_state.should be_an IB::OrderState
      last_state.status.should == 'New'
      #subject.save
      last_state.order.should == subject
    end

    it 'has abbreviated accessor to last (current) OrderState' do
      subject.order_state.should == subject.order_states.last
    end

    it 'has extra accessors to OrderState properties' do
      subject.order_state.should_not be_nil
      subject.status.should == 'New'
    end

    context 'update Order state by ' do

      it 'either adding new State to order_states ' do
        subject.order_states << IB::OrderState.new(:status => :Foo)
        subject.order_states.push IB::OrderState.new :status => :Bar

        subject.status.should == 'Bar'
        subject.save
        subject.order_states.should have_exactly(3).states
        subject.order_states.first.order.should == subject
      end

      it 'or simply assigning to order_state accessor' do
        subject.order_state = :Foo
        subject.order_state = IB::OrderState.new :status => :Bar

        subject.status.should == 'Bar'
        subject.order_states.should have_exactly(3).states
      end
    end

  end

  context 'equality' do
    subject { IB::Order.new props }

    it_behaves_like 'Self-equal Model'

    it 'is not equal for Orders with different limit price' do
      order1 = IB::Order.new :quantity => 100,
                             :limit_price => 1,
                             :action => 'BUY'

      order2 = IB::Order.new :total_quantity => 100,
                             :limit_price => 2,
                             :action => 'BUY'
      order1.should_not == order2
      order2.should_not == order1
    end

    it 'is not equal for Orders with different total_quantity' do
      order1 = IB::Order.new :quantity => 20000,
                             :limit_price => 1,
                             :action => 'BUY'

      order2 = IB::Order.new :total_quantity => 100,
                             :action => 'BUY',
                             :limit_price => 1
      order1.should_not == order2
      order2.should_not == order1
    end

    it 'is not equal for Orders with different action/side' do
      order1 = IB::Order.new :quantity => 100,
                             :limit_price => 1,
                             :action => 'SELL'

      order2 = IB::Order.new :quantity => 100,
                             :action => 'BUY',
                             :limit_price => 1
      order1.should_not == order2
      order2.should_not == order1
    end

    it 'is not equal for Orders with different order_type' do
      order1 = IB::Order.new :quantity => 100,
                             :limit_price => 1,
                             :action => 'BUY',
                             :order_type => 'LMT'

      order2 = IB::Order.new :quantity => 100,
                             :action => 'BUY',
                             :limit_price => 1,
                             :order_type => 'MKT'
      order1.should_not == order2
      order2.should_not == order1
    end
  end

end # describe IB::Order
