require 'order_helper'
require 'combo_helper'

RSpec.describe "What IF  Order",  focus: true do


  before(:all) { verify_account }
		
	after(:all) { close_connection }

		context "Butterfly" do

			before(:all) do
				ib = IB::Connection.new OPTS[:connection].merge(:logger => mock_logger)
				ib.wait_for :NextValidId
				ib.clear_received   # just in case ...

				the_contract = butterfly 'GOOG', '201901', 'CALL', 1130, 1150, 1170 
				place_the_order( contract: the_contract ) do | last_price |
					  IB::Limit.order( action: :buy,
					                  order_ref:  'What_if',
										        limit_price: last_price,
														total_quantity: 10,
														what_if: true,
														account: ACCOUNT )

				end
			end


			it 'place the order' do
				ib = IB::Connection.current
				expect( ib.received[:OpenOrder]).to have_at_least(1).open_order_message 
				expect( ib.received[:OrderStatus]).to have_exactly(0).status_messages 

			end


#    it 'changes client`s next_local_id' do
#     @local_id_placed.should == @local_id_before
#      @ib.next_local_id.should == @local_id_before + 1
#    end
		
		subject { IB::Connection.current.received[:OpenOrder].last.order }
		#		debug
#		it{ 	puts "RECIEVED"; puts  subject.inspect }
		#		does not run  
#		it_behaves_like 'Placed Order' 


    it 'responds with margin info' do
			expect( subject.status ).to match /PreSubmitted/
      expect( subject.what_if).to be_truthy
      expect( subject.equity_with_loan).to be_a BigDecimal
      expect( subject.init_margin).to be_a BigDecimal
      expect( subject.maint_margin).to be_a BigDecimal
      expect( subject.equity_with_loan).to be  > 0
      expect( subject.what_if).to  be_truthy
    end

    it 'responds with commission  and margininfo' do
#       :pending => 'API Bug: No commission in what_if for Combo orders' do
      expect( subject.max_commission).to  be_a BigDecimal
      expect( subject.min_commission).to  be_a BigDecimal
      expect( subject.commission).to be_nil
      expect( subject.init_margin).to be > 0
      expect( subject.maint_margin).to be  > 0

    end

    it 'is not actually being placed though' do
			ib = IB::Connection.current
      ib.clear_received
      ib.send_message :RequestOpenOrders
      ib.wait_for :OpenOrderEnd
      expect(  ib.received[:OpenOrder]).to have_exactly(0).order_message
    end
  end  # context "What if order"

end
__END__
