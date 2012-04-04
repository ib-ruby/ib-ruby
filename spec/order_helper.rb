require 'integration_helper'

shared_examples_for 'Placed Order' do
  context "Placing" do
    after(:all) { clean_connection } # Clear logs and message collector

    it 'changes client`s next_order_id' do
      @order_id_placed.should == @order_id_before
      @ib.next_order_id.should be >= @order_id_before
    end

    it 'receives all appropriate response messages' do
      @ib.received[:OpenOrder].should have_at_least(1).order_message
      @ib.received[:OrderStatus].should have_at_least(1).status_message
    end

    it 'receives confirmation of Order submission' do
      order_should_be /Submit/ # ()Pre)Submitted
      status_should_be /Submit/
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

    it 'receives all appropriate response messages' do
      @ib.received[:OpenOrder].should have_at_least(1).order_message
      @ib.received[:OrderStatus].should have_at_least(1).status_message
      @ib.received[:OpenOrderEnd].should have_exactly(1).order_end_message
    end

    it 'receives OpenOrder and OrderStatus for placed order(s)' do
      order_should_be /Submitted/
      status_should_be /Submitted/

      if @attached_order
        if contract_type == :butterfly && @attached_order.tif == 'GTC'
          pending 'API Bug: Attached DAY orders not working for butterflies!'
        else
          order_should_be /Submit/, @attached_order
        end
      end
    end
  end # Retrieving

  context "Modifying Order" do
    before(:all) do
      if defined?(contract_type) && contract_type == :butterfly
        pending 'API Bug: Order modification not working for butterflies!'
      else
        # Modification only works for non-attached, non-combo orders
        @order.total_quantity = 200
        @order.limit_price += 0.05
        @order.transmit = true
        @ib.modify_order @order, @contract

        if @attached_order
          # Modify attached order, if any
          @attached_order.limit_price *= 1.5
          @attached_order.tif = 'GTC'
          @ib.modify_order @attached_order, @contract
        end
      end
      @ib.send_message :RequestOpenOrders
      @ib.wait_for :OpenOrderEnd, 6 #sec
    end

    after(:all) { clean_connection } # Clear logs and message collector

    it 'does not increase client`s next_order_id further' do
      @ib.next_order_id.should == @order_id_after
    end

    it 'receives all appropriate response messages' do
      @ib.received[:OpenOrder].should have_at_least(1).order_message
      @ib.received[:OrderStatus].should have_at_least(1).status_message
      @ib.received[:OpenOrderEnd].should have_exactly(1).order_end_message
    end

    it 'modifies the placed order(s)' do
      @contract.should == @ib.received[:OpenOrder].first.contract
      order_should_be /Submit/
      status_should_be /Submit/

      if @attached_order
        if contract_type == :butterfly && @attached_order.tif == 'GTC'
          pending 'API Bug: Attached DAY orders not working for butterflies!'
        else
          order_should_be /Submit/, @attached_order
        end
      end
    end
  end # Modifying

  context "Cancelling placed order" do
    before(:all) do
      @ib.cancel_order @order_id_placed
      @ib.wait_for [:OrderStatus, 3], :Alert
    end

    after(:all) { clean_connection } # Clear logs and message collector

    it 'does not increase client`s next_order_id further' do
      @ib.next_order_id.should == @order_id_after
    end

    it 'only receives OpenOrder message with PendingCancel' do
      if @ib.received? :OpenOrder
        order_should_be /PendingCancel/
      end
    end

    it 'receives all appropriate response messages' do
      @ib.received[:OrderStatus].should have_at_least(1).status_message
      @ib.received[:Alert].should have_at_least(1).alert_message
    end

    it 'receives cancellation Order Status' do
      status_should_be /Cancel/ # Cancelled / PendingCancel
      if @attached_order
        if contract_type == :butterfly && @attached_order.tif == 'GTC'
          pending 'API Bug: Attached DAY orders not working for butterflies!'
        else
          status_should_be /Cancel/, @attached_order
        end
      end
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
  @order = IB::Order.new({:total_quantity => 100,
                          :limit_price => 9.13,
                          :action => 'BUY',
                          :order_type => 'LMT'}.merge(opts))
  @order_id_before = @ib.next_order_id
  @order_id_placed = @ib.place_order @order, @contract
  @order_id_after = @ib.next_order_id
end

def status_should_be status, order=@order
  msg = @ib.received[:OrderStatus].find do |msg|
    msg.order_id == order.order_id &&
        status.is_a?(Regexp) ? msg.status =~ status : msg.status == status
  end
  msg.should_not be_nil
  msg.should be_an IB::Messages::Incoming::OrderStatus
  msg.order_id.should == order.order_id
  msg.perm_id.should be_an Integer
  msg.client_id.should == OPTS[:connection][:client_id]
  msg.parent_id.should == 0 unless @attached_order
  msg.why_held.should == ''

  if @contract == IB::Symbols::Forex[:eurusd]
    # We know that this order filled for sure
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

def order_should_be status, order=@order
  msg = @ib.received[:OpenOrder].find do |msg|
    msg.order_id == order.order_id &&
        status.is_a?(Regexp) ? msg.status =~ status : msg.status == status
  end
  msg.should_not be_nil
  msg.should be_an IB::Messages::Incoming::OpenOrder
  msg.order.should == order
  msg.contract.should == @contract
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
