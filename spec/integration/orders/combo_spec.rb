require 'order_helper'
require 'combo_helper'

RSpec.describe "What IF  Order"   do


  before(:all) { verify_account;  IB::Connection.new OPTS[:connection].merge(:logger => mock_logger)  }
		
	after(:all) {  remove_open_orders; close_connection }

	context "Butterfly" do
    before(:all) do
      ib = IB::Connection.current
      ib.wait_for :NextValidId
			@initial_order_id =  ib.next_local_id

				ib.clear_received   # just in case ...

				the_contract = butterfly 'GOOG', '202001', 'CALL', 1130, 1150, 1170 
				@local_id_placed = place_the_order( contract: the_contract ) do | last_price |
					  IB::Limit.order( action: :buy,
					                  order_ref:  'What_if',
										        limit_price: last_price,
														total_quantity: 10,
														what_if: true,
														account: ACCOUNT )

				end
		end

		context IB::Connection  do
			subject{  IB::Connection.current  }
			its( :next_local_id ){ is_expected.to eq @initial_order_id +1 }
			it { expect( subject.received[:OpenOrder]).to have_at_least(1).open_order_message }
			it { expect( subject.received[:OrderStatus]).to have_at_least(0).status_message }
			it { expect( subject.received[:OrderStatus]).to be_empty }
			it { expect( subject.received[:ExecutionData]).to be_empty }
			it { expect( subject.received[:CommissionReport]).to be_empty }

		end


		context IB::Messages::Incoming::OpenOrder do
			subject{ IB::Connection.current.received[:OpenOrder].last }
			it_behaves_like 'OpenOrder message'
		end

		context IB::Order do
			subject{ IB::Connection.current.received[:OpenOrder].last.order }
			it_behaves_like 'Placed Order' 
			it_behaves_like 'Presubmitted what-if Order',  IB::Bag.new
		end

		## separated from  context IB::Order
		#. ib.clear_received is evaluated before shared_examples are run, thus 
		#	 makes it impossibe to load the order from the received-hash..
		context "finalize" do
			it 'is not actually being placed though' do
				ib = IB::Connection.current
				ib.clear_received
				ib.send_message :RequestOpenOrders
				ib.wait_for :OpenOrderEnd
				expect(  ib.received[:OpenOrder]).to have_exactly(0).order_message
			end
		end  # context "What if order"
	end
end
__END__
