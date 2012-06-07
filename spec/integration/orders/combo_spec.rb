require 'order_helper'
require 'combo_helper'

describe "Combo Order", :connected => true, :integration => true, :slow => true do

  let(:contract_type) { :butterfly }

  before(:all) { verify_account }

  context 'What-if order' do
    before(:all) do
      @ib = IB::Connection.new OPTS[:connection].merge(:logger => mock_logger)
      @ib.wait_for :NextValidId

      @contract = butterfly 'GOOG', '201301', 'CALL', 500, 510, 520

      place_order @contract,
                  :order_ref => 'What_if',
                  :limit_price => 0.01,
                  :total_quantity => 10,
                  :what_if => true

      @ib.wait_for :OpenOrder, 8
    end

    after(:all) { close_connection }

    it 'changes client`s next_local_id' do
      @local_id_placed.should == @local_id_before
      @ib.next_local_id.should == @local_id_before + 1
    end

    it { @ib.received[:OpenOrder].should have_at_least(1).open_order_message }
    it { @ib.received[:OrderStatus].should have_exactly(0).status_messages }

    it 'responds with margin info' do
      order_should_be /PreSubmitted/
      order = @ib.received[:OpenOrder].first.order
      order.what_if.should == true
      order.equity_with_loan.should be_a Float
      order.init_margin.should be_a Float
      order.maint_margin.should be_a Float
      order.equity_with_loan.should be > 0
      order.init_margin.should be > 0
      order.maint_margin.should be > 0
    end

    it 'responds with commission info',
       :pending => 'API Bug: No commission in what_if for Combo orders' do
      order = @ib.received[:OpenOrder].first.order
      order.commission.should be_a Float
      order.commission.should be > 1
    end

    it 'is not actually being placed though' do
      @ib.clear_received
      @ib.send_message :RequestOpenOrders
      @ib.wait_for :OpenOrderEnd
      @ib.received[:OpenOrder].should have_exactly(0).order_message
    end
  end

  context "Limit" do # , :if => :us_trading_hours
    before(:all) do
      @ib = IB::Connection.new OPTS[:connection].merge(:logger => mock_logger)
      @ib.wait_for :NextValidId
      @ib.clear_received # to avoid conflict with pre-existing Orders

      @contract = butterfly 'GOOG', '201301', 'CALL', 500, 510, 520

      place_order @contract,
                  :order_ref => 'Original',
                  :limit_price => 0.01,
                  :total_quantity => 10

      @ib.wait_for [:OpenOrder, 2], [:OrderStatus, 2], 6
    end

    after(:all) { close_connection }

    it_behaves_like 'Placed Order'
  end # Limit
end # Combo Orders

__END__
