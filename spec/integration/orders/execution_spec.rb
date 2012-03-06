require 'integration_helper'

# TODO: RequestExecutions (with filters?)

def wait_for_execution_and_commission
  wait_for(5) do
    received?(:ExecutionData) && received?(:OpenOrder) &&
        @received[:OpenOrder].last.order.commission
  end
end

describe "Trades", :connected => true, :integration => true, :slow => true do

  before(:all) { verify_account }

  context "Trading Forex", :if => :forex_trading_hours do

    before(:all) do
      @contract = IB::Symbols::Forex[:eurusd]
      connect_and_receive :NextValidID, :Alert, :ExecutionData, :ExecutionDataEnd,
                          :OpenOrder, :OrderStatus, :OpenOrderEnd
      wait_for { received? :NextValidID }
    end

    after(:all) { close_connection }

    context "Placing BUY order" do

      before(:all) do
        place_order @contract,
                    :total_quantity => 20000,
                    :limit_price => 2,
                    :action => 'BUY'

        wait_for_execution_and_commission
      end

      after(:all) do
        clean_connection # Clear logs and message collector
        @ib.cancel_order @order_id_placed # Just in case...
      end

      it 'changes client`s next_order_id' do
        @order_id_placed = @order_id_before
        @ib.next_order_id.should == @order_id_before + 1
      end

      it { @received[:OpenOrder].should have_at_least(1).open_order_message }
      it { @received[:OrderStatus].should have_at_least(1).status_message }
      it { @received[:ExecutionData].should have_exactly(1).execution_data }
      it { @received[:ExecutionDataEnd].should be_empty }

      it 'receives filled OpenOrder' do
        open_order_should_be 'Filled', -1
        msg = @received[:OpenOrder].last
        msg.order.commission.should == 2.5
      end

      it 'receives Execution Data' do
        execution_should_be 'BUY'
      end

      it 'receives OrderStatus with fill details' do
        order_status_should_be 'Filled', -1
      end
    end # Placing BUY

    context "Placing SELL order" do

      before(:all) do
        place_order @contract,
                    :total_quantity => 20000,
                    :limit_price => 1,
                    :action => 'SELL'

        wait_for_execution_and_commission
      end

      after(:all) do
        clean_connection # Clear logs and message collector
        @ib.cancel_order @order_id_placed # Just in case...
      end

      it 'changes client`s next_order_id' do
        @order_id_placed = @order_id_before
        @ib.next_order_id.should == @order_id_before + 1
      end

      it { @received[:OpenOrder].should have_at_least(1).open_order_message }
      it { @received[:OrderStatus].should have_at_least(1).status_message }
      it { @received[:ExecutionData].should have_exactly(1).execution_data }

      it 'receives filled OpenOrder' do
        open_order_should_be 'Filled', -1
        msg = @received[:OpenOrder].last
        msg.order.commission.should == 2.5
      end

      it 'receives Execution Data' do
        execution_should_be 'SELL'
      end

      it 'receives OrderStatus with fill details' do
        order_status_should_be 'Filled', -1
      end
    end # Placing SELL

    context "Request executions" do

      before(:all) do
        @ib.send_message :RequestExecutions,
                         :request_id => 456,
                         :client_id => OPTS[:connection][:client_id],
                         :time => (Time.now-10).to_ib
        wait_for(3) { received?(:ExecutionData) }
      end

      #after(:all) { clean_connection }

      it 'does not receive Order-related messages' do
        @received[:OpenOrder].should be_empty
        @received[:OrderStatus].should be_empty
      end

      it 'receives ExecutionData messages' do
        @received[:ExecutionData].should have_at_least(1).execution_data
      end

      it 'receives Execution Data' do
        execution_should_be 'SELL', :request_id => 456
      end
    end # Request executions
  end # Forex order

end # Trades
