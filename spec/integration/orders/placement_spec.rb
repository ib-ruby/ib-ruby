require 'integration_helper'

describe "Orders", :connected => true, :integration => true do

  before(:all) { verify_account }

  context "Placing wrong order", :slow => true do

    before(:all) do
      connect_and_receive :NextValidID, :Alert, :OpenOrder, :OrderStatus
      wait_for { received? :NextValidID }

      place_order IB::Symbols::Stocks[:wfc],
                  :limit_price => 9.131313 # Weird non-acceptable price
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

      place_order IB::Symbols::Stocks[:wfc],
                  :limit_price => 9.13 # Set acceptable price
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
        open_order_should_be /Submitted/
        order_status_should_be /Submitted/
      end
    end # Retrieving

    context "Cancelling placed order" do
      before(:all) do
        @ib.cancel_order @order_id_placed

        wait_for { received?(:OrderStatus) && received?(:Alert) }
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
        order_status_should_be /Cancel/ # Cancelled / PendingCancel
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
end # Orders
