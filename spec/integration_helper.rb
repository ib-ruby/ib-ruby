require 'message_helper'

# Make sure integration tests are only run against the pre-configured PAPER ACCOUNT
def verify_account
  return OPTS[:account_verified] if OPTS[:account_verified]

  puts
  puts 'WARNING: MAKE SURE TO RUN INTEGRATION TESTS AGAINST IB PAPER ACCOUNT ONLY!'
  puts 'WARNING: FINANCIAL LOSSES MAY RESULT IF YOU RUN TESTS WITH REAL IB ACCOUNT!'
  puts 'WARNING: YOU HAVE BEEN WARNED!'
  puts
  puts 'Configure your connection to IB PAPER ACCOUNT in spec/spec_helper.rb'
  puts

  account = OPTS[:connection][:account] || OPTS[:connection][:account_name]
  raise "Please configure IB PAPER ACCOUNT in spec/spec_helper.rb" unless account

  connect_and_receive :AccountValue
  @ib.send_message :RequestAccountData, :subscribe => true

  wait_for { received? :AccountValue }
  raise "Unable to verify IB PAPER ACCOUNT" unless received? :AccountValue

  received = @received[:AccountValue].first.account_name
  raise "Connected to wrong account #{received}, expected #{account}" if account != received

  close_connection
  OPTS[:account_verified] = true
end

### Helpers for placing and verifying orders

def place_order ticker, opts
  @contract = ticker == :wfc ? IB::Symbols::Stocks[ticker] : IB::Symbols::Forex[ticker]
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
  msg.client_id.should == 1111
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


def execution_should_be side, index=-1
  msg = @received[:ExecutionData][index]
  msg.request_id.should == -1 # Not specialy requested, fresh execution
  msg.contract.should == @contract

  exec = msg.execution
  exec.perm_id.should == @received[:OpenOrder].last.order.perm_id
  exec.client_id.should == 1111
  exec.order_id.should == @order.order_id
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


