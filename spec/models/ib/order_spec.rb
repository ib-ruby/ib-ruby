require 'model_helper'
require 'message_helper'

## :props has to be a HashWithIndifferentAccess.
#Otherwise the seralization (IB::Order.new(props.merge(serializable_props))) fails
describe IB::Order,
  :props => HashWithIndifferentAccess.new(
  :local_id => 23,
   :order_ref => 'Test',
   :client_id => 1111,
   :perm_id => 173276893,
   :parent_id => 0,
   :side => :buy,
   :tif => :good_till_cancelled,
   :order_type => :market_if_touched,
   :limit_price => 0.1,
   :quantity => 100,
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
   :not_held => true),

  # TODO: :presents => { Object => "Formatted"}
  :human => "<Order: Test MIT GTC buy 100 @ 0.1 New #23/173276893 from 1111>",

  :errors => {:side =>["should be buy/sell/short"]},

  :assigns =>
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

   [:local_id, :perm_id, :parent_id] => numeric_or_nil_assigns,
   },

  :aliases =>
  {[:side, :action] => buy_sell_short_assigns,
   [:quantity, :total_quantity] => numeric_or_nil_assigns,
   },

  :collections =>
  {:order_states =>[{:status => :Foo},
                    {:status => 'Bar'},],

   :executions =>
   [{:local_id => 23,
     :client_id => 1111,
     :perm_id => 173276893,
     :exchange => "IDEALPRO",
     :exec_id => "0001f4e8.4f5d48f1.01.01",
     :price => 0.1,
     :average_price => 0.1,
     :shares => 40,
     :cumulative_quantity => 40,
     :side => :buy,
     :time => "20120312  15:41:09"},

    {:local_id => 23,
     :client_id => 1111,
     :perm_id => 173276893,
     :exchange => "IDEALPRO",
     :exec_id => "0001f4e8.4f5d48f1.01.02",
     :price => 0.1,
     :average_price => 0.1,
     :shares => 60,
     :cumulative_quantity => 100,
     :side => :buy,
     :time => "20120312  15:41:10"}]
} do

  it_behaves_like 'Self-equal Model'
  it_behaves_like 'Model with invalid defaults'

  if OPTS[:db]
  context 'Order associations' do
    after(:all) { DatabaseCleaner.clean if IB.db_backed? }

    subject { IB::Order.new props }

    it 'has order_states collection' do
      expect( subject.order_states ).not_to be_nil
      expect( subject.order_states ).to be_an ActiveRecord::Associations::CollectionProxy
    end

    it 'has at least one (initial, New) OrderState' do
      expect( subject.order_states).to have_exactly(1).state
      last_state = subject.order_states.last
      expect( last_state).to be_an IB::OrderState
      expect( last_state.status ).to eq 'New'
      subject.save
      expect( last_state.order).to eq subject if IB.db_backed?
    end

    it 'has abbreviated accessor to last (current) OrderState' do
      expect( subject.order_state ).to eq subject.order_states.last
    end

    it 'has extra accessors to OrderState properties' do
      expect( subject.order_state ).not_to be_nil

      expect( subject.status ).to eq 'New'
      expect( subject.commission ).to be_nil
      expect( subject.commission_currency ).to be_nil
       expect( subject.min_commission ).to be_nil
       expect( subject.max_commission ).to be_nil
       expect( subject.warning_text ).to be_nil
       expect( subject.init_margin ).to be_nil
       expect( subject.maint_margin ).to be_nil
       expect( subject.equity_with_loan ).to be_nil
      # Properties arriving via OrderStatus message
       expect( subject.filled ).to eq 0
       expect( subject.remaining ).to eq 0 
       expect( subject.price ).to eq 0 
       expect( subject.last_fill_price ).to eq 0 
       expect( subject.average_price ).to eq 0 
       expect( subject.average_fill_price ).to eq 0
       expect( subject.why_held ).to be_nil
      # Testing Order state
       expect( subject ).to be_new
       expect( subject ).not_to be_submitted
       expect( subject ).not_to be_pending
       expect( subject ).to be_active
       expect( subject ).not_to be_inactive
       expect( subject ).not_to be_complete_fill
    end

    context 'update Order state by ' do

      it 'either adding new State to order_states ' do
        subject.order_states << IB::OrderState.new(:status => :Foo)
        subject.order_states.push IB::OrderState.new :status => :Bar

        expect( subject.status).to eq 'Bar'
        subject.save
        expect( subject.order_states ).to have_exactly(3).states
        expect( subject.order_states.first.order ).to eq subject if IB.db_backed?
      end

      it 'or simply assigning to order_state accessor' do
        subject.order_state = :Foo
        subject.order_state = IB::OrderState.new :status => :Bar

        expect( subject.status).to eq 'Bar'
        expect( subject.order_states ).to have_exactly(3).states
      end
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
      expect( order1 ).not_to eq order2
    end

    it 'is not equal for Orders with different total_quantity' do
      order1 = IB::Order.new :quantity => 20000,
        :limit_price => 1,
        :action => 'BUY'

      order2 = IB::Order.new :total_quantity => 100,
        :action => 'BUY',
        :limit_price => 1
      expect( order1 ).not_to eq order2
    end

    it 'is not equal for Orders with different action/side' do
      order1 = IB::Order.new :quantity => 100,
        :limit_price => 1,
        :action => 'SELL'

      order2 = IB::Order.new :quantity => 100,
        :action => 'BUY',
        :limit_price => 1
      expect( order1 ).not_to eq order2
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
      expect( order1 ).not_to eq order2
    end
  end

  context 'DB-backed serialization of properties', :db => true do
    let(:serializable_props) do
      {
        :algo_strategy => "ArrivalPx",
        :algo_params => { "maxPctVol" => "0.01",
                          "riskAversion" => "Passive",
                          "startTime" => "9:00:00 EST",
                          "endTime" => "15:00:00 EST",
                          "forceCompletion" => "0",
                          "allowPastEndTime" => "1"},
        :combo_params => {"NonGuaranteed" => "1",
                          "LeginPrio" => "0"},
        :leg_prices => [1,2,3],
      }
    end
## this approach is only straightforward, if the tests are executed sequentielly
    let( :serializable_order) { IB::Order.new(props.merge(serializable_props)) }

    after(:all) { DatabaseCleaner.clean if IB::DB }

    it 'is saved to DB with serializable_props' do
      expect( serializable_order.save ).to be_truthy
    end

    it 'is loaded from DB with serializable_props' do
#	    serializable_order.save
      models = described_class.all
      expect( models).to  have_exactly(1).model
      order = models.first
      expect( order.algo_strategy).to eq serializable_props[:algo_strategy]
      expect( order.algo_params).to eq serializable_props[:algo_params]
      expect( order.combo_params ).to eq serializable_props[:combo_params]
      expect( order.leg_prices ).to eq serializable_props[:leg_prices]
      #p order.combo_params
    end
  end # DB

end # describe IB::Order
