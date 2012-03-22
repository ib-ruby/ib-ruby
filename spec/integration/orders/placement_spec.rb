require 'order_helper'

#OPTS[:silent] = false
describe 'Orders', :connected => true, :integration => true do

  before(:all) { verify_account }

  context 'Placing wrong order', :slow => true do

    before(:all) do
      @ib = IB::Connection.new OPTS[:connection].merge(:logger => mock_logger)
      @ib.wait_for :NextValidId

      place_order IB::Symbols::Stocks[:wfc],
                  :limit_price => 9.131313 # Weird non-acceptable price
      @ib.wait_for 1 # sec
    end

    after(:all) { close_connection }

    it 'does not place new Order' do
      @ib.received[:OpenOrder].should be_empty
      @ib.received[:OrderStatus].should be_empty
    end

    it 'still changes client`s next_order_id' do
      @order_id_placed.should == @order_id_before
      @ib.next_order_id.should == @order_id_before + 1
    end

    context 'received :Alert message' do
      subject { @ib.received[:Alert].last }

      it { should be_an IB::Messages::Incoming::Alert }
      it { should be_error }
      its(:code) { should be_a Integer }
      its(:message) { should =~ /The price does not conform to the minimum price variation for this contract/ }
    end

  end # Placing wrong order

  context 'What-if order' do
    before(:all) do
      @ib = IB::Connection.new OPTS[:connection].merge(:logger => mock_logger)
      @ib.wait_for :NextValidId

      place_order IB::Symbols::Stocks[:wfc],
                  :limit_price => 9.13, # Set acceptable price
                  :what_if => true # Hypothetical
      @ib.wait_for 1
    end

    after(:all) { close_connection }

    it 'changes client`s next_order_id' do
      @order_id_placed.should == @order_id_before
      @ib.next_order_id.should == @order_id_before + 1
    end

    it { @ib.received[:OpenOrder].should have_at_least(1).open_order_message }
    it { @ib.received[:OrderStatus].should have_exactly(0).status_messages }

    it 'returns as what-if Order with margin and commission info' do
      order_should_be /PreSubmitted/
      order = @ib.received[:OpenOrder].first.order
      order.what_if.should == true
      order.equity_with_loan.should be_a Float
      order.init_margin.should be_a Float
      order.maint_margin.should be_a Float
      order.commission.should be_a Float
      order.equity_with_loan.should be > 0
      order.init_margin.should be > 0
      order.maint_margin.should be > 0
      order.commission.should be > 1
    end

    it 'is not actually opened though' do
      @ib.clear_received
      @ib.send_message :RequestOpenOrders
      @ib.wait_for :OpenOrderEnd
      @ib.received[:OpenOrder].should have_exactly(0).order_message
    end
  end

  context 'Off-market stock order' do
    before(:all) do
      @ib = IB::Connection.new OPTS[:connection].merge(:logger => mock_logger)
      @ib.wait_for :NextValidId

      place_order IB::Symbols::Stocks[:wfc],
                  :limit_price => 9.13 # Set acceptable price
      @ib.wait_for [:OpenOrder, 3], [:OrderStatus, 2]
    end

    after(:all) { close_connection }

    it_behaves_like 'Placed Order'

    context "Cancelling wrong order" do
      before(:all) do
        @ib.cancel_order rand(99999999)

        @ib.wait_for :Alert
      end

      it { @ib.received[:Alert].should have_exactly(1).alert_message }

      it 'does not increase client`s next_order_id further' do
        @ib.next_order_id.should == @order_id_after
      end

      it 'does not receive Order messages' do
        @ib.received?(:OrderStatus).should be_false
        @ib.received?(:OpenOrder).should be_false
      end

      it 'receives unable to find Order Alert' do
        alert = @ib.received[:Alert].first
        alert.should be_an IB::Messages::Incoming::Alert
        alert.message.should =~ /Can't find order with id =/
      end
    end # Cancelling
  end # Off-market order
end # Orders
