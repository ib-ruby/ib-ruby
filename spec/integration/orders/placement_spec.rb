require 'order_helper'

describe 'Order placement'  do # :connected => true, :integration => true do
	let(:contract_type) { :stock }

	before(:all) { verify_account;  IB::Connection.new OPTS[:connection].merge(:logger => mock_logger)  }

	after(:all) do 
		remove_open_orders
		close_connection 
	end

	context 'Placing wrong order', :slow => true do

		before(:all) do
			ib = IB::Connection.current
			ib.wait_for :NextValidId
			@initial_local_id = ib.next_local_id
			ib.clear_received   # just in case ...
			place_the_order do | price |
				IB::Limit.order action: :buy, size: 100, account: ACCOUNT,
				:limit_price =>  price*2.001 #  non-acceptable price
			end
		end

		context IB::Connection do 

			subject { IB::Connection.current }

			it 'does not place new Order' do
				expect( subject.received[:OpenOrder] ).to be_empty
				expect( subject.received[:OrderStatus] ).to be_empty
			end

			it 'still changes client`s next_local_id' do
				expect( subject.current.next_local_id ).to eq @initial_local_id +1
			end

			it_has_message "Alert message" ,  /The price does not conform to the minimum price variation for this contract/ 


		end #  context IB::Connection

	end # Placing wrong order

	context 'What-if order' do
		before(:all) do
			ib = IB::Connection.current

			@initial_local_id = ib.next_local_id
			@local_id = place_the_order  do  | market_price |
				IB::Limit.order action: :buy, size: 100,  
				:limit_price => market_price - 1, # Set acceptable price
				:what_if => true, # Hypothetical
				account: ACCOUNT
			end
		end

		it 'changes client`s next_local_id' do
			expect( IB::Connection.current.next_local_id ).to eq @initial_local_id +1
		end

		it { expect( IB::Connection.current.received[:OpenOrder]).to  have_at_least(1).open_order_message }
		it { expect( IB::Connection.current.received[:OrderStatus]).to have_exactly(0).status_messages }
		context IB::Order do
			subject { IB::Connection.current.received[:OpenOrder].last.order }
			it_behaves_like 'Placed Order'
			it_behaves_like 'Presubmitted what-if Order'
		end

		context "finalize" do
			it 'is not actually being placed though' do
				ib = IB::Connection.current
				ib.clear_received
				ib.send_message :RequestOpenOrders
				ib.wait_for :OpenOrderEnd
				expect( ib.received[:OpenOrder] ).to have_exactly(0).order_message
			end
		end
	end

	context 'Off-market limit' do
		before(:all) do
			ib = IB::Connection.current
			@initial_local_id = ib.next_local_id
			place_the_order  do | market_price |
				IB::Limit.order   action: :buy, size: 100, :limit_price => market_price-1, # Acceptable price
				account: ACCOUNT
			end
		end

		context IB::Order do
			subject { IB::Connection.current.received[:OpenOrder].last.order }
			it_behaves_like 'Placed Order'
		end

		context "Cancelling wrong order" do
			before(:all) do
				ib = IB::Connection.current
				ib.clear_received
				@initial_local_id = ib.next_local_id
				ib.cancel_order rand(99999999)

				ib.wait_for :Alert
			end

			it { puts IB::Connection.current.received[:Alert].to_human }
			it { expect( IB::Connection.current.received[:Alert]).to have_at_least(1).alert_message }

			it 'does not increase client`s next_local_id further' do
				expect( IB::Connection.current.next_local_id ).to eq @initial_local_id 
			end

			it 'does not receive Order messages' do
				ib = IB::Connection.current
				puts  ib.received[:OrderStatus].to_human
				expect( ib.received?(:OrderStatus)).to be_falsy
				expect( ib.received?(:OpenOrder)).to be_falsy
			end
			it_has_message "Alert message" , /OrderId \d* that needs to be cancelled is not found/

		end
	end # Off-market limit

	context 'order with conditions', focus: true  do
		before(:all) do
			ib = IB::Connection.current

			@initial_local_id = ib.next_local_id
			@local_id = place_the_order  do  | market_price |
				
				condition1 =  IB::MarginCondition.new percent: 45, operator: '<='
				condition2 =  IB::PriceCondition.fabricate IB::Symbols::Futures.es, "<=", 2600 

				IB::Limit.order action: :buy, size: 100,  
					conditions: [condition1, condition2],
					conditions_cancel_order: true ,
				:limit_price => market_price - 1, # Set acceptable price
				account: ACCOUNT
			end
		end

		it 'changes client`s next_local_id' do
			expect( IB::Connection.current.next_local_id ).to eq @initial_local_id +1
		end

		it { expect( IB::Connection.current.received[:OpenOrder]).to  have_at_least(1).open_order_message }
#		it "display order_stauts" do
#			puts  IB::Connection.current.received[:OrderStatus].inspect
#		end
		it { expect( IB::Connection.current.received[:OrderStatus]).to have_exactly(1).status_messages }
		context IB::Order do
			subject { IB::Connection.current.received[:OpenOrder].last.order }
			it_behaves_like 'Placed Order'

			it "contains proper conditions" do
				expect( subject.conditions ).to be_an Array
				expect( subject.conditions ).to have(2).conditions
				expect( subject.conditions.first ).to be_an IB::MarginCondition
				expect( subject.conditions.last ).to be_an IB::PriceCondition
				expect( subject.conditions_cancel_order ).to be_truthy
			end
		end

	end


	context ''
end # Orders
