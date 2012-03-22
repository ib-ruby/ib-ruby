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

describe "Combo Orders", :connected => true, :integration => true do

  before(:all) do
    verify_account
  end

  after(:all) { close_connection }

  context "Limit" do # , :if => :us_trading_hours
    before(:all) do
      @ib = IB::Connection.new OPTS[:connection].merge(:logger => mock_logger)
      @ib.wait_for :NextValidId

      @combo = butterfly 'GOOG', '201301', 'CALL', 500, 510, 520
      pp @combo
      place_order @combo, :limit_price => 0.01
      @ib.wait_for [:OpenOrder, 3], [:OrderStatus, 2]
    end

    context "Placing" do
      after(:all) { clean_connection } # Clear logs and message collector

      it_behaves_like 'Placed Order'
    end # Placing

    #context "Retrieving placed" do
    #  before(:all) do
    #    @ib.send_message :RequestOpenOrders
    #    @ib.wait_for :OpenOrderEnd
    #  end
    #
    #  after(:all) { clean_connection } # Clear logs and message collector
    #
    #  it 'does not increase client`s next_order_id further' do
    #    @ib.next_order_id.should == @order_id_after
    #  end
    #
    #  it { @ib.received[:OpenOrder].should have_exactly(1).order_message }
    #  it { @ib.received[:OrderStatus].should have_exactly(1).status_message }
    #  it { @ib.received[:OpenOrderEnd].should have_exactly(1).order_end_message }
    #  it { @ib.received[:Alert].should have_exactly(0).alert_messages }
    #
    #  it 'receives OpenOrder and OrderStatus for placed order' do
    #    order_should_be /Submitted/
    #    status_should_be /Submitted/
    #  end
    #end # Retrieving
    #
    #context "Cancelling placed order" do
    #  before(:all) do
    #    @ib.cancel_order @order_id_placed
    #
    #    @ib.wait_for :OrderStatus, :Alert
    #  end
    #
    #  after(:all) { clean_connection } # Clear logs and message collector
    #
    #  it 'does not increase client`s next_order_id further' do
    #    @ib.next_order_id.should == @order_id_after
    #  end
    #
    #  it 'does not receive OpenOrder message' do
    #    @ib.received?(:OpenOrder).should be_false
    #  end
    #
    #  it { @ib.received[:OrderStatus].should have_exactly(1).status_message }
    #  it { @ib.received[:Alert].should have_exactly(1).alert_message }
    #
    #  it 'receives cancellation Order Status' do
    #    status_should_be /Cancel/ # Cancelled / PendingCancel
    #  end
    #
    #  it 'receives Order cancelled Alert' do
    #    alert = @ib.received[:Alert].first
    #    alert.should be_an IB::Messages::Incoming::Alert
    #    alert.message.should =~ /Order Canceled - reason:/
    #  end
    #end # Cancelling
  end # Limit
end # Combo Orders
