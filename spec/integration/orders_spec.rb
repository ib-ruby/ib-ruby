require 'integration_helper'

def order_status_should_be status, index=0
  msg = @received[:OrderStatus][index]
  msg.should be_an IB::Messages::Incoming::OrderStatus
  msg.order_id.should == @order_id_placed
  msg.perm_id.should be_an Integer
  msg.client_id.should == 1111
  msg.parent_id.should == 0
  msg.status.should == status # order_status_should_be 'Submitted', -1
  msg.filled.should == 0
  msg.remaining.should == 100
  msg.average_fill_price.should == 0
  msg.last_fill_price.should == 0
  msg.why_held.should == ''
end

def open_order_should_be status, index=0
  msg = @received[:OpenOrder][index]
  msg.should be_an IB::Messages::Incoming::OpenOrder
  msg.contract.should == @wfc
  msg.order.should == @wfc_order
  msg.order.order_id.should == @order_id_placed
  msg.order.status.should == status
end

describe IB::Messages do

  context "Orders", :connected => true do

    before(:all) do
      @eur = IB::Symbols::Forex[:eurusd]
      @eur_order = IB::Models::Order.new :total_quantity => 20000,
                                         :limit_price => 1,
                                         :action => 'SELL',
                                         :order_type => 'LMT'
      @wfc = IB::Symbols::Stocks[:wfc]
      @wfc_order = IB::Models::Order.new :total_quantity => 100,
                                         :action => 'BUY',
                                         :order_type => 'LMT'
    end

    context "Placing wrong order" do

      before(:all) do
        connect_and_receive :NextValidID, :Alert, :OpenOrder, :OrderStatus
        wait_for { received? :NextValidID }

        @wfc_order.limit_price = 9.131313 # Set weird non-acceptable price
        @order_id_before = @ib.next_order_id
        @order_id_placed = @ib.place_order @wfc_order, @wfc
        @order_id_after = @ib.next_order_id

        wait_for 2
      end

      after(:all) do
        @ib.cancel_order @order_id_placed # Just in case...
        close_connection
      end

      it 'does not place new Order' do
        @received[:OpenOrder].should be_empty
        @received[:OrderStatus].should be_empty
      end

      it 'still changes client`s next_order_id' do
        @order_id_placed = @order_id_before
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

    context "Off-market order" do
      before(:all) do
        connect_and_receive :NextValidID, :Alert, :OpenOrder, :OrderStatus, :OpenOrderEnd
        wait_for { received? :NextValidID }

        @wfc_order.limit_price = 9.13 # Set acceptable price
        @order_id_before = @ib.next_order_id
        @order_id_placed = @ib.place_order @wfc_order, @wfc
        @order_id_after = @ib.next_order_id

        wait_for(2) { @received[:OpenOrder].size > 1 && @received[:OpenOrder].size > 1 }
      end

      after(:all) do
        @ib.cancel_order @order_id_placed # Just in case...
        close_connection
      end

      context "Placing" do
        after(:all) { clean_connection } # Clear logs and message collector

        it 'changes client`s next_order_id' do
          @order_id_placed = @order_id_before
          @ib.next_order_id.should == @order_id_before + 1
        end

        it { @received[:OpenOrder].should have_at_least(1).open_order_message }
        it { @received[:OrderStatus].should have_at_least(1).status_message }

        it 'receives (optional) Order confirmation first' do
          if @received[:OpenOrder].size > 1
            open_order_should_be 'PreSubmitted'
            order_status_should_be 'PreSubmitted'
          else
            puts 'Warning: Confirmation was skipped!'
          end
        end

        it 'receives Order submission after that' do
          open_order_should_be 'Submitted', -1
          order_status_should_be 'Submitted', -1
        end
      end # Placing

      context "Retrieving placed orders" do
        before(:all) do
          @ib.send_message :RequestAllOpenOrders

          wait_for(2) { received?(:OpenOrderEnd) }
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

          wait_for(2) { received?(:OpenOrder) && received?(:Alert) }
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

          wait_for(2) { received?(:Alert) }
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


  end # Orders
end # describe IB::Messages::Incomming
