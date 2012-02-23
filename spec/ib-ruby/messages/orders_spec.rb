require 'message_helper'

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
        connect_and_receive :NextValidID, :Alert, :OpenOrder, :OrderStatus
        wait_for { received? :NextValidID }

        @wfc_order.limit_price = 9.13 # Set acceptable price
        @order_id_before = @ib.next_order_id
        @order_id_placed = @ib.place_order @wfc_order, @wfc

        wait_for(2) { @received[:OpenOrder].size > 1 && @received[:OpenOrder].size > 1 }
      end

      after(:all) do
        #pp @received[:OpenOrder]
        @ib.cancel_order @order_id_placed # Just in case...
        close_connection
      end

      context "Placing" do

        after(:all) { clean_connection } # Clear logs and message collector

        it 'changes client`s next_order_id' do
          @order_id_placed = @order_id_before
          @ib.next_order_id.should == @order_id_before + 1
        end

        context 'received :OpenOrder messages' do
          subject { @received[:OpenOrder] }

          it { should have_at_least(1).message }

          it 'receives (optional) Order confirmation first' do
            if subject.size > 1
              msg = subject.first
              msg.should be_an IB::Messages::Incoming::OpenOrder
              msg.contract.should == @wfc
              msg.order.should == @wfc_order
              msg.order.order_id.should == @order_id_placed
              msg.order.status.should == 'PreSubmitted'
            else
              puts 'Warning: Confirmation was skipped!'
            end
          end

          it 'receives Order submission then' do
            msg = subject.last
            msg.should be_an IB::Messages::Incoming::OpenOrder
            msg.contract.should == @wfc
            msg.order.should == @wfc_order
            msg.order.order_id.should == @order_id_placed
            msg.order.status.should == 'Submitted'
          end
        end

        context 'received :OrderStatus messages' do
          subject { @received[:OrderStatus] }

          it { should have_at_least(1).message }

          it 'receives (optional) Order confirmation first' do
            if subject.size > 1
              msg = subject.first
              msg.should be_an IB::Messages::Incoming::OrderStatus
              msg.id.should == @order_id_placed
              msg.perm_id.should be_an Integer
              msg.client_id.should == 1111
              msg.parent_id.should == 0
              #msg.order_id.should == @order_id_placed
              msg.status.should == 'PreSubmitted'
              msg.filled.should == 0
              msg.remaining.should == 100
              msg.average_fill_price.should == 0
              msg.last_fill_price.should == 0
              msg.why_held.should == ''
            else
              puts 'Warning: Confirmation was skipped!'
            end
          end

          it 'receives Order submission then' do
            msg = subject.last
            msg.should be_an IB::Messages::Incoming::OrderStatus
            msg.id.should == @order_id_placed
            #msg.order_id.should == @order_id_placed
            msg.perm_id.should be_an Integer
            msg.client_id.should == 1111
            msg.parent_id.should == 0
            msg.status.should == 'Submitted'
            msg.filled.should == 0
            msg.remaining.should == 100
            msg.average_fill_price.should == 0
            msg.last_fill_price.should == 0
            msg.why_held.should == ''
          end
        end
      end # Placing

      context "Cancelling placed order" do
        before(:all) do
          @ib.cancel_order @order_id_placed

          wait_for(2) { received?(:OrderStatus) && received?(:Alert) }
        end

        after(:all) { clean_connection } # Clear logs and message collector

        it 'does not increase client`s next_order_id further' do
          @ib.next_order_id.should == @order_id_before + 1
        end

        it { @received[:OrderStatus].should have_exactly(1).status_message }

        it { @received[:Alert].should have_exactly(1).alert_message }

        it 'receives Order cancellation status' do
          msg = @received[:OrderStatus].first
          msg.should be_an IB::Messages::Incoming::OrderStatus
          msg.id.should == @order_id_placed
          #msg.order_id.should == @order_id_placed
          msg.perm_id.should be_an Integer
          msg.client_id.should == 1111
          msg.parent_id.should == 0
          msg.status.should == 'Cancelled'
          msg.filled.should == 0
          msg.remaining.should == 100
          msg.average_fill_price.should == 0
          msg.last_fill_price.should == 0
          msg.why_held.should == ''
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
          @ib.next_order_id.should == @order_id_before + 1
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
