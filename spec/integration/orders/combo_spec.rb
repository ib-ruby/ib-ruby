require 'order_helper'

#OPTS[:silent] = false

def butterfly symbol, expiry, right, *strikes
  raise 'No Connection!' unless @ib && @ib.connected?

  legs = strikes.zip([1, -2, 1]).map do |strike, weight|
    # Create contract
    contract = IB::Option.new :symbol => symbol,
                              :expiry => expiry,
                              :right => right,
                              :strike => strike
    # Find out contract's con_id
    @ib.clear_received :ContractData, :ContractDataEnd
    @ib.send_message :RequestContractData, :id => strike, :contract => contract
    @ib.wait_for :ContractDataEnd, 3
    con_id = @ib.received[:ContractData].last.contract.con_id

    # Create Comboleg from con_id and weight
    IB::ComboLeg.new :con_id => con_id, :weight => weight
  end

  # Create new Combo contract
  IB::Bag.new :symbol => symbol,
              :currency => "USD", # Only US options in combo Contracts
              :exchange => "SMART",
              :legs => legs
end

describe "Combo Order", :connected => true, :integration => true, :slow => true do

  let(:contract_type) { :butterfly }

  before(:all) { verify_account }

  context 'What-if order' do
    before(:all) do
      @ib = IB::Connection.new OPTS[:connection].merge(:logger => mock_logger)
      @ib.wait_for :NextValidId

      @contract = butterfly 'GOOG', '201301', 'CALL', 500, 510, 520

      place_order @contract, :limit_price => 0.01, :what_if => true

      @ib.wait_for :OpenOrder, 8
    end

    after(:all) { close_connection }

    it 'changes client`s next_order_id' do
      @order_id_placed.should == @order_id_before
      @ib.next_order_id.should == @order_id_before + 1
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

      place_order @contract, :limit_price => 0.01 #, :what_if => true
      @ib.wait_for [:OpenOrder, 2], [:OrderStatus, 2], 8
      #@ib.wait_for :OpenOrder, :OrderStatus, 8
    end

    after(:all) { close_connection }

    it_behaves_like 'Placed Order'
  end # Limit

  context "Limit with attached takeprofit" do

    before(:all) do
      @ib = IB::Connection.new OPTS[:connection].merge(:logger => mock_logger)
      @ib.wait_for :NextValidId
      @ib.clear_received # to avoid conflict with pre-existing Orders

      @contract = butterfly 'GOOG', '201301', 'CALL', 500, 510, 520

      place_order @contract, :limit_price => 0.01, :transmit => false
      @ib.wait_for :OpenOrder, :OrderStatus, 2
    end

    after(:all) { close_connection }

    it 'does not transmit original Order just yet' do
      @ib.received[:OpenOrder].should have_exactly(0).order_message
      @ib.received[:OrderStatus].should have_exactly(0).status_message
    end

    context 'Attaching takeprofit' do
      before(:all) do
        @attached_order = IB::Order.new :total_quantity => 100,
                                        :limit_price => 0.5,
                                        :action => 'SELL',
                                        :order_type => 'LMT',
                                        :parent_id => @order_id_placed

        @order_id_attached = @ib.place_order @attached_order, @contract
        @order_id_after = @ib.next_order_id
        @ib.wait_for [:OpenOrder, 2], [:OrderStatus, 2], 8
      end

      it_behaves_like 'Placed Order'
    end

    context 'When original Order cancels' do
      it 'attached takeprofit is cancelled implicitely' do
        @ib.send_message :RequestOpenOrders
        @ib.wait_for :OpenOrderEnd
        @ib.received[:OpenOrder].should have_exactly(0).order_message
        @ib.received[:OrderStatus].should have_exactly(0).status_message
      end
    end
  end # Attached
end # Combo Orders

