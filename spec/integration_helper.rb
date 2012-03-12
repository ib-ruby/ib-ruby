require 'message_helper'
require 'account_helper'

shared_examples_for 'Received Market Data' do
  context "received :Alert message " do
    subject { @ib.received[:Alert].first }

    it { should be_an IB::Messages::Incoming::Alert }
    it { should be_warning }
    it { should_not be_error }
    its(:code) { should be_an Integer }
    its(:message) { should =~ /Market data farm connection is OK/ }
    its(:to_human) { should =~ /TWS Warning/ }
  end

  context "received :TickPrice message" do
    subject { @ib.received[:TickPrice].first }

    it { should be_an IB::Messages::Incoming::TickPrice }
    its(:tick_type) { should be_an Integer }
    its(:type) { should be_a Symbol }
    its(:price) { should be_a Float }
    its(:size) { should be_an Integer }
    its(:data) { should be_a Hash }
    its(:ticker_id) { should == 456 } # ticker_id
    its(:to_human) { should =~ /TickPrice/ }
  end

  context "received :TickSize message", :if => :us_trading_hours do
    before(:all) do
      @ib.wait_for 3, :TickSize
    end

    subject { @ib.received[:TickSize].first }

    it { should be_an IB::Messages::Incoming::TickSize }
    its(:type) { should_not be_nil }
    its(:data) { should be_a Hash }
    its(:tick_type) { should be_an Integer }
    its(:type) { should be_a Symbol }
    its(:size) { should be_an Integer }
    its(:ticker_id) { should == 456 }
    its(:to_human) { should =~ /TickSize/ }
  end
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

def check_status item, status
  case status
    when Regexp
      item.status.should =~ status
    when String
      item.status.should == status
  end
end

def order_status_should_be status, index=0
  msg = @ib.received[:OrderStatus][index]
  msg.should be_an IB::Messages::Incoming::OrderStatus
  msg.order_id.should == @order_id_placed
  msg.perm_id.should be_an Integer
  msg.client_id.should == OPTS[:connection][:client_id]
  msg.parent_id.should == 0
  msg.why_held.should == ''
  check_status msg, status

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

def open_order_should_be status, index=0
  msg = @ib.received[:OpenOrder][index]
  msg.should be_an IB::Messages::Incoming::OpenOrder
  msg.order.should == @order
  msg.contract.should == @contract
  msg.order.order_id.should == @order_id_placed
  check_status msg.order, status
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
