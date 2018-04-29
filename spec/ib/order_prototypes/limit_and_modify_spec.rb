require 'order_helper'
require 'message_helper'

## Notice
## The first Test-run fails, if active OpenOrder-Messages are recieved 
## and no OpenOrder-Message is returned immideately.
## If this happens simply repeat the Execution of the Test

RSpec.describe IB::Limit do
	before(:all) do
		verify_account
		ib = IB::Connection.new OPTS[:connection] do | gw| 
			gw.logger = mock_logger
			gw.subscribe( :Alert ){| m | puts m.to_human  }
		end
		ib.wait_for :NextValidId

	end
		
	after(:all) { IB::Connection.current.send_message(:RequestGlobalCancel); close_connection; } 

		let( :the_order_price ){  ( get_contract_price.round(1)  || 50 ) - 2 }
		let( :the_submitted_order ) do 
				 IB::Limit.order price:   the_order_price ,
												 action: :buy, size: 100, account: ACCOUNT
		end

	context "Placement section" do

		it "successful placed the order"  do
			expect( the_submitted_order  ).to be_an IB::Order 
			expect( the_submitted_order.local_id  ).to be_zero.or be_nil
			the_local_id =  place_the_order{ the_submitted_order }
			expect( the_submitted_order.local_id  ).to be_an( Integer ).and eq( the_local_id ) 
			puts "SUBMITTED ORDER: #{the_submitted_order.to_human}"
		end
		context  IB::Connection  do
			subject { IB::Connection.current }
			it { expect( subject.received[:OpenOrder]).to have_at_least(1).open_order_message  }
			it { expect( subject.received[:OrderStatus]).to have_exactly(1).status_messages  }
		end

		context IB::Messages::Incoming::OpenOrder do
			subject{  IB::Connection.current.received[:OpenOrder].first } 
			it_behaves_like 'OpenOrder message'
		end

		context IB::Contract do
			subject{  IB::Connection.current.received[:OpenOrder].first.contract } 
			it{ is_expected.to be_an IB::Contract }
			its( :symbol ){ is_expected.to eq  'WFC' }
			its( :exchange ){ is_expected.to eq 'SMART' }
		end	
		context IB::Order do
			subject{  IB::Connection.current.received[:OpenOrder].first.order } 
			it_behaves_like 'Placed Order' 

			it 'has  appropiate order attributes' do
				o =  subject
				puts "RECEIVED ORDER #{subject.to_human}"
				expect( o.action ).to eq  :buy
				expect( o.order_type ).to eq :limit
				expect( o.total_quantity  ).to eq 100
#				expect( o.limit_price ).to eq the_order_price
				expect( o.account ).to  eq ACCOUNT
			end
			its( :limit_price ){ is_expected.to eq the_order_price }
			its( :local_id ){ is_expected.to eq IB::Connection.current.next_local_id - 1 }
			it 'is basicly the same then the transmitted order' , pending: true do
				pending "a proper method to compare a received order with on created localy is absent"
				expect(subject).to be ==the_submitted_order
			end
		end  # IB::Order
	end # placement

	context "Modifing the provided Order" do
		before(:all) do 
			#IB::Connection.current.received[:OpenOrder].first.order 
			IB::Connection.current.clear_received :OpenOrder
		end  # before
		it "place the modified order " do
		  the_modified_order_price = the_order_price - 1
			the_modified_order = the_submitted_order
			the_modified_order.local_id = IB::Connection.current.next_local_id - 1
			the_modified_order.limit_price = the_modified_order_price
			expect{ place_the_order{ the_modified_order} }.not_to change {  IB::Connection.current.next_local_id }
			the_received_open_order = IB::Connection.current.received[:OpenOrder].first 
			puts "RECEIVED MODIFIED: #{the_received_open_order.order.to_human}"
		end
#
		context IB::Messages::Incoming::OpenOrder do
			subject{ IB::Connection.current.received[:OpenOrder].first }
#			subject{ @the_received_open_order }
			it_behaves_like 'OpenOrder message'

		end
#
		context IB::Order do
			subject{ IB::Connection.current.received[:OpenOrder].first.order }
#		subject{@the_received_open_order.order }
#			#		subject{ IB::Connection.current.received[:OpenOrder].order.last }
			it{ puts "RECEIVED: #{ subject.to_human}" }
			it_behaves_like 'Placed Order' 

			its( :limit_price ){ is_expected.not_to eq the_order_price }
		end
	end  # modifing I

	context "Modifing the received OpenOrderMessage-Order"  do
		before(:all) do 
			@the_received_order = IB::Connection.current.received[:OpenOrder].first.order 
			IB::Connection.current.clear_received :OpenOrder
		end  # before

	context IB::Order do
		subject{ @the_received_order }
		#		subject{ IB::Connection.current.received[:OpenOrder].order.last }
		it_behaves_like 'Placed Order' 

#		its( :limit_price ){ is_expected.not_to eq the_order_price }  # we changed it before
	end


	it " modify the price, submit and receive the modified order" do
		# initial price
		expect( @the_received_order.limit_price ).not_to eq the_order_price
		ib = IB::Connection.current
		modified_order = @the_received_order
		modified_order.limit_price = the_order_price
		expect do
			ib.modify_order modified_order, IB::Symbols::Stocks.wfc
			ib.wait_for :OpenOrder
		end.not_to change { ib.next_local_id }    # this proofs that no additional order is created

		expect( ib.received[:OpenOrder]).to have_at_least(1).open_order_message  
		recieved_order =  ib.received[:OpenOrder].first.order
		expect( recieved_order).to be == modified_order
		expect( recieved_order.limit_price ).to eq the_order_price
		puts "RECEIVED: #{ recieved_order.to_human}" 
	end 

	it " modify the amount, submit and receive the modified order" do
		# initial price
		IB::Connection.current.clear_received :OpenOrder
		original_amount =   @the_received_order.total_quantity
		ib = IB::Connection.current
		modified_order = @the_received_order
		modified_order.total_quantity = 123
		expect do
			ib.modify_order modified_order, IB::Symbols::Stocks.wfc
			ib.wait_for :OpenOrder
		end.not_to change { ib.next_local_id }    # this proofs that no additional order is created

		expect( ib.received[:OpenOrder]).to have_at_least(1).open_order_message  
		recieved_order =  ib.received[:OpenOrder].first.order
		expect( recieved_order).to be == modified_order
		expect( recieved_order.limit_price ).to eq @the_received_order.limit_price
		expect( recieved_order.total_quantity ).to eq @the_received_order.total_quantity
		puts "RECEIVED: #{ recieved_order.to_human}" 
	end 
	it " modify  amount and price, submit and receive the modified order" do
		# initial price
		IB::Connection.current.clear_received :OpenOrder
		ib = IB::Connection.current
		modified_order = @the_received_order
		modified_order.total_quantity = 23
		modified_order.limit_price = 5.5
		expect do
			ib.modify_order modified_order, IB::Symbols::Stocks.wfc
			ib.wait_for :OpenOrder
		end.not_to change { ib.next_local_id }    # this proofs that no additional order is created

		expect( ib.received[:OpenOrder]).to have_at_least(1).open_order_message  
		recieved_order =  ib.received[:OpenOrder].first.order
		expect( recieved_order).to be == modified_order
		expect( recieved_order.limit_price ).to eq @the_received_order.limit_price
		expect( recieved_order.total_quantity ).to eq @the_received_order.total_quantity
		puts "RECEIVED: #{ recieved_order.to_human}" 
	end 
	it " modifying  action is not supported"  do
		# initial price
		IB::Connection.current.clear_received :OpenOrder, :Alert
		ib = IB::Connection.current
		modified_order = @the_received_order
		modified_order.action = :sell
		expect do
			ib.modify_order modified_order, IB::Symbols::Stocks.wfc
			ib.wait_for :OpenOrder
		end.not_to change { ib.next_local_id }    # this proofs that no additional order is created

		expect( ib.received[:OpenOrder]).to be_empty  # no OpenOrderRecord created
		expect( ib.received[:Alert]).to have_at_least(1).alert_message
		expect( ib.received[:Alert].first.to_human).to  match /TWS Error 105/
	end 

	end
#it 'has extended order_state attributes' do
# to generate the order:
# o = ForexLimit.order action: :buy, size: 15000, cash_qty: true
# c =  Symbols::Forex.eurusd
# C.place_order o, c


end # describe IB::Messages:Incoming

__END__


