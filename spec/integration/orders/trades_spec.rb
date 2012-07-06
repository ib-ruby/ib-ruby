require 'order_helper'

def commission_report_should_be status=:with_pnl, exec=@ib.received[:ExecutionData].last.execution
  msg = @ib.received[:CommissionReport].find { |msg| msg.exec_id == exec.exec_id }
  msg.should_not be_nil
  msg.should be_an IB::Messages::Incoming::CommissionReport

  msg.exec_id.should == exec.exec_id
  msg.commission.should == 2.5 # Fixed commission for Forex
  msg.currency.should == 'USD'
  msg.yield.should be_nil
  msg.yield_redemption_date.should == 0 # no date, YYYYMMDD format for bonds

  if status == :with_pnl
    msg.realized_pnl.should be_a Float
    msg.realized_pnl.should be < 10000 # Not Double.MAX_VALUE
  else
    msg.realized_pnl.should be_nil
  end
end

def execution_should_be side, opts={}
  msg = @ib.received[:ExecutionData][opts[:index] || -1]
  msg.request_id.should == (opts[:request_id] || -1)
  msg.contract.should == @contract

  exec = msg.execution
  exec.perm_id.should be_an Integer
  exec.perm_id.should == @ib.received[:OpenOrder].last.order.perm_id if @ib.received?(:OpenOrder)
  exec.client_id.should == OPTS[:connection][:client_id]
  exec.local_id.should be_an Integer
  exec.local_id.should == @order.local_id if @order
  exec.exec_id.should be_a String
  exec.time.should =~ /\d\d:\d\d:\d\d/
  exec.account_name.should == OPTS[:connection][:account]
  exec.exchange.should == 'IDEALPRO'
  exec.side.should == side
  exec.shares.should == 20000
  exec.cumulative_quantity.should == 20000
  exec.price.should be > 1
  exec.price.should be < 2
  exec.price.should == exec.average_price
  exec.liquidation.should == false
end

describe "Trades", :connected => true, :integration => true, :slow => true do

  before(:all) { verify_account }

  context "Trading Forex", :if => :forex_trading_hours do

    before(:all) do
      @contract = IB::Symbols::Forex[:eurusd]
      @ib = IB::Connection.new OPTS[:connection].merge(:logger => mock_logger)
      @ib.wait_for :NextValidId
    end

    after(:all) { close_connection }

    context "Placing BUY order" do

      before(:all) do
        place_order @contract,
                    :total_quantity => 20000,
                    :limit_price => 2,
                    :action => 'BUY'
        #:what_if => true

        @ib.wait_for(5, :ExecutionData, :OpenOrder) do
          @ib.received[:OpenOrder].last &&
              @ib.received[:OpenOrder].last.order.commission
        end
      end

      after(:all) do
        clean_connection # Clear logs and message collector
        @ib.cancel_order @local_id_placed # Just in case...
      end

      it 'changes client`s next_local_id' do
        @local_id_placed = @local_id_before
        @ib.next_local_id.should == @local_id_before + 1
      end

      it { @ib.received[:OpenOrder].should have_at_least(1).open_order_message }
      it { @ib.received[:OrderStatus].should have_at_least(1).status_message }
      it { @ib.received[:ExecutionData].should have_exactly(1).execution_data }
      it { @ib.received[:ExecutionDataEnd].should be_empty }

      it 'receives filled OpenOrder' do
        order_should_be 'Filled'
        msg = @ib.received[:OpenOrder].last
        msg.order.commission.should == 2.5
      end

      it 'receives Execution Data' do
        execution_should_be :buy
      end

      it 'receives OrderStatus with fill details' do
        status_should_be 'Filled'
      end

      it 'also receives Commission Reports' do
        @ib.received[:CommissionReport].should have_exactly(1).report

        commission_report_should_be :no_pnl, @ib.received[:ExecutionData].last.execution
      end
    end # Placing BUY

    context "Placing SELL order" do

      before(:all) do
        place_order @contract,
                    :total_quantity => 20000,
                    :limit_price => 1,
                    :action => 'SELL'

        @ib.wait_for(:ExecutionData, :OpenOrder, 5) do
          @ib.received[:OpenOrder].last.order.commission
        end
      end

      after(:all) do
        clean_connection # Clear logs and message collector
        @ib.cancel_order @local_id_placed # Just in case...
      end

      it 'changes client`s next_local_id' do
        @local_id_placed = @local_id_before
        @ib.next_local_id.should == @local_id_before + 1
      end

      it { @ib.received[:OpenOrder].should have_at_least(1).open_order_message }
      it { @ib.received[:OrderStatus].should have_at_least(1).status_message }
      it { @ib.received[:ExecutionData].should have_exactly(1).execution_data }

      it 'receives filled OpenOrder' do
        order_should_be 'Filled'
        msg = @ib.received[:OpenOrder].last
        msg.order.commission.should == 2.5
      end

      it 'receives Execution Data' do
        execution_should_be :sell
      end

      it 'receives OrderStatus with fill details' do
        status_should_be 'Filled'
      end

      it 'also receives Commission Reports' do
        @ib.received[:CommissionReport].should have_exactly(1).report

        commission_report_should_be :with_pnl, @ib.received[:ExecutionData].last.execution
      end
    end # Placing SELL

    context "Request executions" do
      # TODO: RequestExecutions with filters?

      before(:all) do
        @ib.send_message :RequestExecutions,
                         :request_id => 456,
                         :client_id => OPTS[:connection][:client_id],
                         :time => (Time.now-10).to_ib # Time zone problems possible
        @ib.wait_for :ExecutionData, 3 # sec
      end

      #after(:all) { clean_connection }

      it 'does not receive Order-related messages' do
        @ib.received[:OpenOrder].should be_empty
        @ib.received[:OrderStatus].should be_empty
      end

      it 'receives ExecutionData messages' do
        @ib.received[:ExecutionData].should have_at_least(1).execution_data
      end

      it 'receives Execution Data' do
        execution_should_be :buy, :index => 0, :request_id => 456
        execution_should_be :sell, :request_id => 456
      end

      it 'also receives Commission Reports' do
        @ib.received[:CommissionReport].should have_exactly(2).reports

        commission_report_should_be :no_pnl, @ib.received[:ExecutionData].first.execution
        commission_report_should_be :with_pnl, @ib.received[:ExecutionData].last.execution
      end

    end # Request executions
  end # Forex order

end # Trades

__END__

Actual message exchange for "Request executions" (TWS 925):
10:57:41:348 <- 7-3-456-1111--20120430 10:57:31-----
10:57:41:349 -> 11-9-456-1-12087792-EUR-CASH--0.0--IDEALPRO-USD-EUR.USD-0001f4e8.4f9dbb0b.01.01-20120430  10:57:36-DU118180-IDEALPRO-BOT-20000-1.32540-474073463-1111-0-20000-1.32540--
10:57:41:350 -> 11-9-456-2-12087792-EUR-CASH--0.0--IDEALPRO-USD-EUR.USD-0001f4e8.4f9dbb0c.01.01-20120430  10:57:36-DU118180-IDEALPRO-SLD-20000-1.32540-474073464-1111-0-20000-1.32540--
10:57:41:350 -> 59-1-0001f4e8.4f9dbb0b.01.01-2.5-USD-1.7976931348623157E308-1.7976931348623157E308--
10:57:41:350 -> 59-1-0001f4e8.4f9dbb0c.01.01-2.5-USD-27.7984-1.7976931348623157E308--
10:57:41:351 -> 55-1-456-

Actual message exchange for "Request executions" (TWS 923):
11:11:45:436 <- 7-3-456-1111--20120430 11:11:36-----
11:11:45:439 -> 11-8-456-1-12087792-EUR-CASH--0.0--IDEALPRO-USD-EUR.USD-0001f4e8.4f9dbc96.01.01-20120430  11:11:43-DU118180-IDEALPRO-BOT-20000-1.32485-308397342-1111-0-20000-1.32485--
11:11:45:439 -> 11-8-456-2-12087792-EUR-CASH--0.0--IDEALPRO-USD-EUR.USD-0001f4e8.4f9dbc9a.01.01-20120430  11:11:45-DU118180-IDEALPRO-SLD-20000-1.32480-308397343-1111-0-20000-1.32480--
11:11:45:439 -> 55-1-456-