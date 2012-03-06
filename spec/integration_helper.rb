require 'message_helper'
require 'account_helper'

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
  msg = @received[:OrderStatus][index]
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
  msg = @received[:OpenOrder][index]
  msg.should be_an IB::Messages::Incoming::OpenOrder
  msg.order.should == @order
  msg.contract.should == @contract
  msg.order.order_id.should == @order_id_placed
  check_status msg.order, status
end

def execution_should_be side, opts={}
  msg = @received[:ExecutionData][opts[:index] || -1]
  msg.request_id.should == (opts[:request_id] || -1)
  msg.contract.should == @contract

  exec = msg.execution
  exec.perm_id.should be_an Integer
  exec.perm_id.should == @received[:OpenOrder].last.order.perm_id if @received[:OpenOrder].last
  exec.client_id.should == OPTS[:connection][:client_id]
  exec.order_id.should be_an Integer
  exec.order_id.should == @order.order_id if @order
  exec.exec_id.should be_a String
  exec.time.should =~ /\d\d:\d\d:\d\d/
  exec.account_name.should == OPTS[:connection][:account_name]
  exec.exchange.should == 'IDEALPRO'
  exec.side.to_s.should == side
  exec.shares.should == 20000
  exec.cumulative_quantity.should == 20000
  exec.price.should be > 1
  exec.price.should be < 2
  exec.price.should == exec.average_price
  exec.liquidation.should == 0
end


