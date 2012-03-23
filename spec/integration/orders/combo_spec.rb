require 'order_helper'

#OPTS[:silent] = false

def butterfly symbol, expiry, right, *strikes
  raise 'No Connection!' unless @ib && @ib.connected?

  legs = strikes.zip([1, -2, 1]).map do |strike, weight|
    # Create contract
    contract = IB::Models::Contract::Option.new :symbol => symbol,
                                                :expiry => expiry,
                                                :right => right,
                                                :strike => strike
    # Find out contract's con_id
    @ib.clear_received :ContractData, :ContractDataEnd
    @ib.send_message :RequestContractData, :id => strike, :contract => contract
    @ib.wait_for :ContractDataEnd, 3
    con_id = @ib.received[:ContractData].last.contract.con_id

    # Create Comboleg from con_id and weight
    IB::Models::ComboLeg.new :con_id => con_id, :weight => weight
  end

  # Create new Combo contract
  IB::Models::Contract::Bag.new :symbol => symbol,
                                :currency => "USD", # Only US options in combo Contracts
                                :exchange => "SMART",
                                :legs => legs
end

describe "Combo Order", :connected => true, :integration => true, :slow => true do

  before(:all) { verify_account }

  context "Limit" do # , :if => :us_trading_hours
    before(:all) do
      @ib = IB::Connection.new OPTS[:connection].merge(:logger => mock_logger)
      @ib.wait_for :NextValidId
      @ib.clear_received # to avoid conflict with pre-existing Orders

      @contract = butterfly 'GOOG', '201301', 'CALL', 500, 510, 520

      place_order @contract, :limit_price => 0.01 #, :what_if => true
      @ib.wait_for :OpenOrder, :OrderStatus, 5
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
        @attached_order = IB::Models::Order.new :total_quantity => 100,
                                                :limit_price => 0.5,
                                                :action => 'SELL',
                                                :order_type => 'LMT',
                                                :parent_id => @order_id_placed

        @order_id_attached = @ib.place_order @attached_order, @contract
        @order_id_after = @ib.next_order_id
        @ib.wait_for :OpenOrder, :OrderStatus, 5
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

