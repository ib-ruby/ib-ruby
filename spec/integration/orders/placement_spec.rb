require 'order_helper'

describe 'Order placement' , focus: true do # :connected => true, :integration => true do
  let(:contract_type) { :stock }

  before(:all) { verify_account }

  context 'Placing wrong order', :slow => true, focus: true do

    before(:all) do
      ib = IB::Connection.new OPTS[:connection].merge(:logger => mock_logger)
      ib.wait_for :NextValidId
			@initial_local_id = ib.next_local_id
			ib.clear_received   # just in case ...
      place_the_order do
					IB::Limit.order action: :buy, size: 100,
											:limit_price => 9.131313 # Weird non-acceptable price
			end
    end

    after(:all) { close_connection }

    it 'does not place new Order' do
			ib = IB::Connection.current
      expect( ib.received[:OpenOrder] ).to be_empty
      expect( ib.received[:OrderStatus] ).to be_empty
    end

    it 'still changes client`s next_local_id' do
      expect( IB::Connection.current.next_local_id ).to eq @initial_local_id +1
    end

		it_has_message "Alert message" ,  /The price does not conform to the minimum price variation for this contract/ 
#    context 'received :Alert message' do
 #     subject { IB::Connection.current.received[:Alert] }
	#		it { is_expected.to have_at_least(1).error_message }
	#		it "contains a discriptive error message" do
	#			## expected error-message: 
	#			#TWS Error 110: The price does not conform to the minimum price variation for this contract.
	#			expect( subject.map &:code ).to include 110  
	#			expect( subject.any?{|x| x.message =~  /The price does not conform to the minimum price variation for this contract/ } ).to be_truthy
	#		end
	#		it { puts  subject.to_human }   # debug


  #  end

  end # Placing wrong order

  context 'What-if order' do
    before(:all) do
      ib = IB::Connection.new OPTS[:connection].merge(:logger => mock_logger)
      ib.wait_for :NextValidId

			@initial_local_id = ib.next_local_id
      @local_id = place_the_order  do  | market_price |
          IB::Limit.order action: :buy, size: 100,  
												 :limit_price => market_price - 1, # Set acceptable price
											   :what_if => true, # Hypothetical
													account: ACCOUNT
			end
    end

    after(:all) { close_connection }

    it 'changes client`s next_local_id' do
      expect( IB::Connection.current.next_local_id ).to eq @initial_local_id +1
    end

    it { expect( IB::Connection.current.received[:OpenOrder]).to  have_at_least(1).open_order_message }
    it { expect( IB::Connection.current.received[:OrderStatus]).to have_exactly(0).status_messages }
		subject { IB::Connection.current.received[:OpenOrder].last.order }
#    it_behaves_like 'Placed Order'

    it 'responds with margin and commission info' do
#      order_should_be /PreSubmitted/
      expect( subject.what_if ).to be_truthy
      expect( subject.equity_with_loan ).to be_a  BigDecimal
      expect( subject.init_margin ).to be_a BigDecimal
      expect( subject.maint_margin ).to be_a BigDecimal
      expect( subject.commission ).to be_a BigDecimal
      expect( subject.equity_with_loan ).to  be > 0
      expect( subject.init_margin ).to be > 0
      expect( subject.maint_margin ).to be > 0
      expect( subject.commission ).to be > 0
    end

    it 'is not actually being placed though' do
			ib = IB::Connection.current
      ib.clear_received
      ib.send_message :RequestOpenOrders
      ib.wait_for :OpenOrderEnd
      expect( ib.received[:OpenOrder] ).to have_exactly(0).order_message
    end
  end

  context 'Off-market limit' do
    before(:all) do
      ib = IB::Connection.new OPTS[:connection].merge(:logger => mock_logger)
      ib.wait_for :NextValidId
			@initial_local_id = ib.next_local_id
      place_the_order  do | market_price |
				IB::Limit.order   action: :buy, size: 100, :limit_price => market_price-1, # Acceptable price
													account: ACCOUNT
			end
    end

    after(:all) { close_connection }

		subject { IB::Connection.current.received[:OpenOrder].last.order }
    it_behaves_like 'Placed Order'

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
end # Orders
