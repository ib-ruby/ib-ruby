require 'integration_helper'

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

  unless @contract == IB::Symbols::Forex[:eurusd]
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

describe IB::Messages do

  context "Orders", :connected => true, :integration => true do

    before(:all) { verify_account }

    context "Placing wrong order", :slow => true do

      before(:all) do
        connect_and_receive :NextValidID, :Alert, :OpenOrder, :OrderStatus
        wait_for { received? :NextValidID }

        place_order :wfc, :limit_price => 9.131313 # Weird non-acceptable price
        wait_for 1
      end

      after(:all) { close_connection }

      it 'does not place new Order' do
        @received[:OpenOrder].should be_empty
        @received[:OrderStatus].should be_empty
      end

      it 'still changes client`s next_order_id' do
        @order_id_placed.should == @order_id_before
        @ib.next_order_id.should == @order_id_before + 1
      end

      context 'received :Alert message' do
        subject { @received[:Alert].last }

        it { should be_an IB::Messages::Incoming::Alert }
        it { should be_error }
        its(:code) { should be_a Integer }
        its(:message) { should =~ /The price does not conform to the minimum price variation for this contract/ }
      end

    end # Placing wrong order

    context "Off-market stock order" do
      before(:all) do
        connect_and_receive :NextValidID, :Alert, :OpenOrder, :OrderStatus, :OpenOrderEnd
        wait_for { received? :NextValidID }

        place_order :wfc, :limit_price => 9.13 # Set acceptable price
        wait_for { @received[:OpenOrder].size > 2 && @received[:OpenOrder].size > 1 }
      end

      after(:all) { close_connection }

      context "Placing" do
        after(:all) { clean_connection } # Clear logs and message collector

        it 'changes client`s next_order_id' do
          @order_id_placed.should == @order_id_before
          @ib.next_order_id.should == @order_id_before + 1
        end

        it { @received[:OpenOrder].should have_at_least(1).open_order_message }
        it { @received[:OrderStatus].should have_at_least(1).status_message }

        it 'receives confirmation of Order submission' do
          open_order_should_be /Submitted/ # ()Pre)Submitted
          order_status_should_be /Submitted/
        end
      end # Placing

      context "Retrieving placed orders" do
        before(:all) do
          @ib.send_message :RequestAllOpenOrders

          wait_for { received?(:OpenOrderEnd) }
        end

        after(:all) { clean_connection } # Clear logs and message collector

        it 'does not increase client`s next_order_id further' do
          @ib.next_order_id.should == @order_id_after
        end

        it { @received[:OpenOrder].should have_exactly(1).open_order_message }
        it { @received[:OrderStatus].should have_exactly(1).status_message }
        it { @received[:OpenOrderEnd].should have_exactly(1).order_end_message }
        it { @received[:Alert].should have_exactly(0).alert_messages }

        it 'receives OpenOrder and OrderStatus for placed order' do
          open_order_should_be 'Submitted'
          order_status_should_be 'Submitted'
        end
      end # Retrieving

      context "Cancelling placed order" do
        before(:all) do
          @ib.cancel_order @order_id_placed

          wait_for { received?(:OpenOrder) && received?(:Alert) }
        end

        after(:all) { clean_connection } # Clear logs and message collector

        it 'does not increase client`s next_order_id further' do
          @ib.next_order_id.should == @order_id_after
        end

        it 'does not receive OpenOrder message' do
          received?(:OpenOrder).should be_false
        end

        it { @received[:OrderStatus].should have_exactly(1).status_message }
        it { @received[:Alert].should have_exactly(1).alert_message }

        it 'receives cancellation Order Status' do
          order_status_should_be 'Cancelled'
        end

        it 'receives Order cancelled Alert' do
          alert = @received[:Alert].first
          alert.should be_an IB::Messages::Incoming::Alert
          alert.message.should =~ /Order Canceled - reason:/
        end
      end # Cancelling

      context "Cancelling wrong order" do
        before(:all) do
          @ib.cancel_order rand(99999999)

          wait_for { received?(:Alert) }
        end

        it { @received[:Alert].should have_exactly(1).alert_message }

        it 'does not increase client`s next_order_id further' do
          @ib.next_order_id.should == @order_id_after
        end

        it 'does not receive Order messages' do
          received?(:OrderStatus).should be_false
          received?(:OpenOrder).should be_false
        end

        it 'receives unable to find Order Alert' do
          alert = @received[:Alert].first
          alert.should be_an IB::Messages::Incoming::Alert
          alert.message.should =~ /Can't find order with id =/
        end
      end # Cancelling
    end # Off-market order

    context "Marketable Forex order", :if => :forex_trading_hours do
      before(:all) do
        connect_and_receive :NextValidID, :Alert, :OpenOrder, :OrderStatus, :OpenOrderEnd
        wait_for { received? :NextValidID }
      end

      after(:all) { close_connection }

      context "Placing BUY order" do

        before(:all) do
          place_order :eurusd,
                      :total_quantity => 20000,
                      :limit_price => 2,
                      :action => 'BUY'

          wait_for #{ @received[:OpenOrder].size > 2 && @received[:OrderStatus].size > 2 }
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

        it 'receives filled OpenOrder' do
          open_order_should_be 'Filled', -1
          msg = @received[:OpenOrder].last
          msg.order.commission.should == 2.5
        end

        it 'receives OrderStatus with fill details' do
          order_status_should_be 'Filled', -1
          msg = @received[:OrderStatus].last
          msg.filled.should == 20000
          msg.remaining.should == 0
          msg.average_fill_price.should be > 1
          msg.average_fill_price.should be < 2
          msg.last_fill_price.should == msg.average_fill_price
        end
      end # Placing BUY

      context "Placing SELL order" do

        before(:all) do
          place_order :eurusd,
                      :total_quantity => 20000,
                      :limit_price => 1,
                      :action => 'SELL'

          wait_for { @received[:OpenOrder].size > 2 && @received[:OrderStatus].size > 2 }
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

        it 'receives filled OpenOrder' do
          open_order_should_be 'Filled', -1
          msg = @received[:OpenOrder].last
          msg.order.commission.should == 2.5
        end

        it 'receives OrderStatus with fill details' do
          order_status_should_be 'Filled', -1
          msg = @received[:OrderStatus].last
          msg.filled.should == 20000
          msg.remaining.should == 0
          msg.average_fill_price.should be > 1
          msg.average_fill_price.should be < 2
          msg.last_fill_price.should == msg.average_fill_price
        end
      end # Placing SELL
    end # Marketable Forex order

  end # Orders
end # describe IB::Messages::Incomming
