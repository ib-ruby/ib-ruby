require 'message_helper'

describe IB::Messages do

  context "Orders", :connected => true do

    before(:all) do
      @wfc = IB::Symbols::Stocks[:wfc]
      @eur = IB::Symbols::Forex[:eurusd]
      @eur_order = IB::Models::Order.new :total_quantity => 20000,
                                         :limit_price => 1,
                                         :action => 'SELL',
                                         :order_type => 'LMT'
      @wfc_order = IB::Models::Order.new :total_quantity => 100,
                                         :action => 'BUY',
                                         :order_type => 'LMT'
    end

    context "Placing off-market order" do

      before(:all) do
        connect_and_receive :NextValidID, :Alert, :OpenOrder, :OrderStatus
        wait_for { received? :NextValidID }

        @order_id_before = @ib.next_order_id

        @wfc_order.limit_price = 9.13
        @order_id_placed = @ib.place_order @wfc_order, @wfc

        wait_for(2) { @received[:OpenOrder].size > 1 && @received[:OpenOrder].size > 1 }
      end

      after(:all) do
        @ib.cancel_order @order_id_placed
        close_connection
      end

      it 'changes client`s next_order_id' do
        @ib.next_order_id.should == @order_id_placed
        @ib.next_order_id.should == @order_id_before + 1
      end

      context 'received :OpenOrder messages' do
        subject { @received[:OpenOrder] }

        it { should have_exactly(2).messages }

        it 'receives Order confirmation first' do
          msg = subject.first
          msg.should be_an IB::Messages::Incoming::OpenOrder
          msg.contract.should == @wfc
          msg.order.should == @wfc_order
          msg.order.status.should == 'PreSubmitted'
        end

        it 'receives Order submission then' do
          msg = subject.last
          msg.should be_an IB::Messages::Incoming::OpenOrder
          msg.order.should == @wfc_order
          msg.contract.should == @wfc
          msg.order.status.should == 'Submitted'
        end
      end

    end # Placing off-market order

    context "Placing wrong order" do

      before(:all) do
        connect_and_receive :NextValidID, :Alert, :OpenOrder, :OrderStatus
        wait_for { received? :NextValidID }
        @order_id_before = @ib.next_order_id
        @wfc_order.limit_price = 9.131313
        @order_id_placed = @ib.place_order @wfc_order, @wfc
        wait_for 2
      end

      after(:all) do
        @ib.cancel_order @order_id_placed
        close_connection
      end

      it 'does not place new Order' do
        @received[:OpenOrder].should be_empty
        @received[:OrderStatus].should be_empty
      end

      it 'still changes client`s next_order_id' do
        @ib.next_order_id.should == @order_id_placed
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
  end # Orders
end # describe IB::Messages::Incomming
