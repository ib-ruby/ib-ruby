require 'order_helper'
require 'combo_helper'

RSpec.describe "Combo Order",  focus: true do

  let(:contract_type) { :butterfly }

  before(:all) { verify_account }

  context 'What-if order' do
    before(:all) do
      ib = IB::Connection.new OPTS[:connection].merge(:logger => mock_logger)
      ib.wait_for :NextValidId
		end
    after(:all) { close_connection }
	let( :the_contract ){  butterfly 'GOOG', '201901', 'CALL', 1130, 1150, 1170 }
  let( :the_order) do |_|  IB::Limit.order(
									action: :buy,
                  order_ref:  'What_if',
                  limit_price: 0.06,
                  total_quantity: 10,
                  what_if: true,
									account: ACCOUNT)
	end

		it 'place the order' do
			place_the_order( contract: the_contract ) do
				the_order
			end
			ib = IB::Connection.current
    expect( ib.received[:OpenOrder]).to have_at_least(1).open_order_message 
    expect( ib.received[:OrderStatus]).to have_exactly(0).status_messages 
    end


#    it 'changes client`s next_local_id' do
#     @local_id_placed.should == @local_id_before
#      @ib.next_local_id.should == @local_id_before + 1
#    end
		

    it 'responds with margin info' do
			ib =  IB::Connection.current
#
			#order_should_be /PreSubmitted/
      order = ib.received[:OpenOrder].first.order
      expect( order.what_if).to be_truthy
      expect( order.equity_with_loan).to be_a BigDecimal
      expect( order.init_margin).to be_a BigDecimal
      expect( order.maint_margin).to be_a BigDecimal
      expect( order.equity_with_loan).to be  > 0
      expect( order.what_if).to  be_truthy
    end

    it 'responds with commission  and margininfo' do
#       :pending => 'API Bug: No commission in what_if for Combo orders' do
      o = IB::Connection.current.received[:OpenOrder].first.order
			#puts o.inspect
      expect( o.max_commission).to  be_a BigDecimal
      expect( o.min_commission).to  be_a BigDecimal
      expect( o.commission).to be_zero
      expect( o.init_margin).to be > 0
      expect( o.maint_margin).to be  > 0

    end

    it 'is not actually being placed though' do
			ib = IB::Connection.current
      ib.clear_received
      ib.send_message :RequestOpenOrders
      ib.wait_for :OpenOrderEnd
      expect(  ib.received[:OpenOrder]).to have_exactly(0).order_message
    end
  end

end # Combo Orders

__END__
