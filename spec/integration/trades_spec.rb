require 'integration_helper'

describe "Trades", :connected => true, :integration => true do

  before(:all) { verify_account }

  context "Trading Forex", :if => :forex_trading_hours do

    before(:all) do
      connect_and_receive :NextValidID, :Alert, :ExecutionData,
                          :OpenOrder, :OrderStatus, :OpenOrderEnd
      wait_for { received? :NextValidID }
    end

    after(:all) { close_connection }

    context "Placing BUY order" do

      before(:all) do
        place_order :eurusd,
                    :total_quantity => 20000,
                    :limit_price => 2,
                    :action => 'BUY'

        wait_for(3) { received?(:ExecutionData) &&
            @received[:OpenOrder].size > 2 &&
            @received[:OrderStatus].size > 2 }
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
        execution_should_be 'BUY'
      end

      it 'receives OrderStatus with fill details' do
        order_status_should_be 'Filled', -1
      end
    end # Placing BUY

    context "Placing SELL order" do

      before(:all) do
        place_order :eurusd,
                    :total_quantity => 20000,
                    :limit_price => 1,
                    :action => 'SELL'

        wait_for(3) { received?(:ExecutionData) &&
            @received[:OpenOrder].size > 2 &&
            @received[:OrderStatus].size > 2 }
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
  end # Forex order

end # Trades
