require 'integration_helper'

shared_examples_for 'Placed Order' do
  context "Placing" do
    after(:all) { clean_connection } # Clear logs and message collector

    it 'changes client`s next_order_id' do
      @order_id_placed.should == @order_id_before
      @ib.next_order_id.should be >= @order_id_before
    end

    it { @ib.received[:OpenOrder].should have_at_least(1).order_message }
    it { @ib.received[:OrderStatus].should have_at_least(1).status_message }

    it 'receives confirmation of Order submission' do
      order_should_be /Submitted/ # ()Pre)Submitted
      status_should_be /Submitted/
    end
  end # Placing

  context "Retrieving placed" do
    before(:all) do
      @ib.send_message :RequestOpenOrders
      @ib.wait_for :OpenOrderEnd
    end

    after(:all) { clean_connection } # Clear logs and message collector

    it 'does not increase client`s next_order_id further' do
      @ib.next_order_id.should == @order_id_after
    end

    it { @ib.received[:OpenOrder].should have_at_least(1).order_message }
    it { @ib.received[:OrderStatus].should have_at_least(1).status_message }
    it { @ib.received[:OpenOrderEnd].should have_exactly(1).order_end_message }

    #it { @ib.received[:Alert].should have_exactly(0).alert_messages }

    it 'receives OpenOrder and OrderStatus for placed order' do
      order_should_be /Submitted/
      status_should_be /Submitted/
    end
  end # Retrieving

  context "Cancelling placed order" do
    before(:all) do
      @ib.cancel_order @order_id_placed
      @ib.wait_for [:OrderStatus, 2], :Alert
    end

    after(:all) { clean_connection } # Clear logs and message collector

    it 'does not increase client`s next_order_id further' do
      @ib.next_order_id.should == @order_id_after
    end

    it 'does not receive OpenOrder message' do
      @ib.received?(:OpenOrder).should be_false
    end

    it { @ib.received[:OrderStatus].should have_at_least(1).status_message }
    it { @ib.received[:Alert].should have_at_least(1).alert_message }

    it 'receives cancellation Order Status' do
      status_should_be /Cancel/ # Cancelled / PendingCancel
    end

    it 'receives Order cancelled Alert' do
      alert = @ib.received[:Alert].first
      alert.should be_an IB::Messages::Incoming::Alert
      alert.message.should =~ /Order Canceled - reason:/
    end
  end # Cancelling
end


### Helpers for placing and verifying orders

def place_order contract, opts
  @contract = contract
  @order = IB::Models::Order.new({:total_quantity => 100,
                                  :limit_price => 9.13,
                                  :action => 'BUY',
                                  :order_type => 'LMT'}.merge(opts))
  @order_id_before = @ib.next_order_id
  @order_id_placed = @ib.place_order @order, @contract
  @order_id_after = @ib.next_order_id
end

def status_should_be status
  msg = @ib.received[:OrderStatus].find do |msg|
    msg.order_id == @order_id_placed &&
        status.is_a?(Regexp) ? msg.status =~ status : msg.status == status
  end
  msg.should_not be_nil
  msg.should be_an IB::Messages::Incoming::OrderStatus
  msg.order_id.should == @order_id_placed
  msg.perm_id.should be_an Integer
  msg.client_id.should == OPTS[:connection][:client_id]
  msg.parent_id.should == 0
  msg.why_held.should == ''

  if @contract == IB::Symbols::Forex[:eurusd]
    msg.filled.should == 20000
    msg.remaining.should == 0
    msg.average_fill_price.should be > 1
    msg.average_fill_price.should be < 2
    msg.last_fill_price.should == msg.average_fill_price
  else
    msg.filled.should == 0
    msg.remaining.should == @order.total_quantity
    msg.average_fill_price.should == 0
    msg.last_fill_price.should == 0
  end
end

def order_should_be status
  msg = @ib.received[:OpenOrder].find do |msg|
    msg.order_id == @order_id_placed &&
        status.is_a?(Regexp) ? msg.status =~ status : msg.status == status
  end
  msg.should_not be_nil
  msg.should be_an IB::Messages::Incoming::OpenOrder
  msg.order.should == @order
  msg.contract.should == @contract
  msg.order.order_id.should == @order_id_placed
end

def execution_should_be side, opts={}
  msg = @ib.received[:ExecutionData][opts[:index] || -1]
  msg.request_id.should == (opts[:request_id] || -1)
  msg.contract.should == @contract

  exec = msg.execution
  exec.perm_id.should be_an Integer
  exec.perm_id.should == @ib.received[:OpenOrder].last.order.perm_id if @ib.received?(:OpenOrder)
  exec.client_id.should == OPTS[:connection][:client_id]
  exec.order_id.should be_an Integer
  exec.order_id.should == @order.order_id if @order
  exec.exec_id.should be_a String
  exec.time.should =~ /\d\d:\d\d:\d\d/
  exec.account_name.should == OPTS[:connection][:account_name]
  exec.exchange.should == 'IDEALPRO'
  exec.side.should == side
  exec.shares.should == 20000
  exec.cumulative_quantity.should == 20000
  exec.price.should be > 1
  exec.price.should be < 2
  exec.price.should == exec.average_price
  exec.liquidation.should == 0
end
