require 'message_helper'

describe IB::Messages do

  context "Orders", :connected => true do

    before(:all) do
      connect_and_receive :NextValidID, :Alert, :OpenOrder, :OrderStatus
      wait_for { received? :NextValidID }
    end

    after(:all) do
      @ib.send_message :RequestAccountData, :subscribe => false
      close_connection
      pp @received[:Alert]
      pp @received[:OpenOrder]
      pp @received[:OrderStatus]
    end

    context "Placing order" do

      before(:all) do
        @wfc = IB::Symbols::Stocks[:wfc]
        @eur = IB::Symbols::Forex[:eurusd]
        @buy_eur = IB::Models::Order.new :total_quantity => 20000,
                                         :limit_price => 1,
                                         :action => 'SELL',
                                         :order_type => 'LMT'
        @buy_wfc = IB::Models::Order.new :total_quantity => 100,
                                         :limit_price => 9.13,
                                         :action => 'BUY',
                                         :order_type => 'LMT'
        @order_id_before = @ib.next_order_id
        @ib.place_order @buy_eur, @eur
        #@ib.place_order @buy_wfc, @wfc
        wait_for 4
      end

      it 'changes client`s next_order_id' do
        @ib.next_order_id.should == @order_id_before + 1
      end

      context 'received :Alert message' do
        subject { @received[:Alert].last }

        it { should be_an IB::Messages::Incoming::Alert }
        it { should be_error }
        its(:code) { should be_a Integer }
        its(:message) { should =~ /The price does not conform to the minimum price variation for this contract/ }
      end


    end # Placing
  end # Orders
end # describe IB::Messages::Incomming
