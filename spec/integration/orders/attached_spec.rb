require 'order_helper'
require 'combo_helper'

OPTS[:silent] = false

def define_contracts
  @ib = IB::Connection.new OPTS[:connection].merge(:logger => mock_logger)
  @contracts = {
      :stock => IB::Symbols::Stocks[:wfc],
      :butterfly => butterfly('GOOG', '201301', 'CALL', 500, 510, 520)
  }
  close_connection
end

describe 'Attached Orders', :connected => true, :integration => true do

  before(:all) do
    verify_account
    define_contracts
  end

  [
      [:stock, 100, 'DAY', 'LMT', 9.13, 20.0],
      #[:stock, 100, 'GTC', 'LMT', 9.13, 20.0],
      #[:butterfly, 100, 'DAY', 'LMT', 0.05, 1.0],
      #[:butterfly, 10, 'GTC', 'LMT', 0.05, 1.0],
  #[:butterfly, 100, 'GTC', 'STPLMT', 0.05, 0.05, 1.0],

  ].each do |(contract, qty, tif, attach_type, limit_price, attach_price, aux_price)|
    context "#{tif} BUY (#{contract}) limit order with attached #{attach_type} SELL" do
      # Needed to pend Modifying Order context (in order_helper.rb) specially for Combos
      let(:contract_type) { contract }

      before(:all) do
        @ib = IB::Connection.new OPTS[:connection].merge(:logger => mock_logger)
        @ib.wait_for :NextValidId
        @ib.clear_received # to avoid conflict with pre-existing Orders

        @contract = @contracts[contract]
        place_order @contract,
                    :limit_price => limit_price,
                    :tif => tif,
                    :transmit => false

        @ib.wait_for :OpenOrder, :OrderStatus, 2
      end

      after(:all) { close_connection }

      it 'does not transmit original Order before attach' do
        @ib.received[:OpenOrder].should have_exactly(0).order_message
        @ib.received[:OrderStatus].should have_exactly(0).status_message
      end

      context "Attaching #{attach_type} takeprofit" do
        before(:all) do
          @attached_order = IB::Order.new :total_quantity => qty,
                                          :limit_price => attach_price,
                                          :aux_price => aux_price || 0,
                                          :action => 'SELL',
                                          :tif => tif,
                                          :order_type => attach_type,
                                          :parent_id => @order_id_placed

          @order_id_attached = @ib.place_order @attached_order, @contract
          @order_id_after = @ib.next_order_id
          @ib.wait_for [:OpenOrder, 2], [:OrderStatus, 2], 5
        end

        it_behaves_like 'Placed Order'
      end

      context 'When original Order cancels' do
        it 'attached takeprofit is cancelled implicitly' do
          @ib.send_message :RequestOpenOrders
          @ib.wait_for :OpenOrderEnd
          @ib.received[:OpenOrder].should have_exactly(0).order_message
          @ib.received[:OrderStatus].should have_exactly(0).status_message
        end
      end

    end
  end
end # Orders
