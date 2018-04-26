require 'integration_helper'
=begin
Unified Approach placing an Order

order_id =  place_the_oder contract:{a valid IB::Contract} do | the_last_market:price |
			{ modify the price as needed }
			{ Provide a valid IB::Order, use the appropiate OrderPrototype }
end

if the order-object provides a local_id, the order is modified.
=end
def place_the_order( contract: IB::Symbols::Stocks.wfc )  
		ib =  IB::Connection.current
		raise 'Unable to place order, no connection' unless ib && ib.connected?
		order =  yield( get_contract_price( contract: contract) )

		the_order_id =  if order.local_id.present? 
			ib.modify_order order, contract      
		else
			ib.place_order order, contract      
		end
		ib.wait_for :OpenOrder, 3
		the_order_id  # return value
end

def get_contract_price contract: IB::Symbols::Stocks.wfc
	ib =  IB::Connection.current
	ib.send_message :RequestMarketDataType, :market_data_type => :delayed
	the_id = ib.send_message :RequestMarketData, contract:  contract
	ib.wait_for :TickPrice
	ib.send_message :CancelMarketData, id: the_id
	last_price = ib.received[:TickPrice].price.map(&:to_f).max
	ib.clear_received :TickPrice
	last_price =  last_price.nil? ? rand(999).to_f/100 : last_price  # use random price for testing

end
def remove_open_orders
	ib =  IB::Connection.current
		ib.send_message :RequestOpenOrders
		ib.wait_for :OpenOrderEnd
		open_order_ids =  ib.received[:OpenOrder].map{|msg| msg.order[:local_id]}
		ib.cancel_order *open_order_ids
end

RSpec.shared_examples_for "Alert message" do | the_expected_message |
	  subject { IB::Connection.current.received[:Alert] }
			it { is_expected.to have_at_least(1).error_message }
#			it { puts "ALERT: "+ subject.inspect }   # debug
			it "contains a discriptive error message" do
				expect( subject.any?{|x|  x.message =~  the_expected_message } ).to be_truthy
			end
end


RSpec.shared_examples_for 'OpenOrder message' do
#	let( :subject ){ the_returned_message }
  it { is_expected.to be_an IB::Messages::Incoming::OpenOrder }
	it "has appropiate attributes" do
		o = subject
   expect(o.message_type).to eq :OpenOrder 
   expect( o.message_id).to eq 5 
	 expect( o.version).to eq 34
	 expect( o.data).not_to  be_empty
   expect( o.buffer ).to be_empty   # Work on openOrder-Message has to be finished.
  							## Integration of Conditions !
   expect( o.local_id).to be_an Integer 
	 expect( o.order).to be_an IB::Order 
   expect( o.status).to match( /Submit/).or match( /Filled/ ) 
  #its(:to_human) { is_expected.to match /<OpenOrder: <Stock: WFC USD> <Order: LMT DAY buy 100.0 49.13 .*Submit.* #\d+\/\d+ from 1111/ }
	end
  it 'has proper order accessor' do
    o = subject.order
    expect( o.client_id ).to eq(OPTS[:connection][:client_id]).or be_zero 
    expect( o.parent_id ).to be_zero
  end

  it 'has proper order_state accessor' do
    os = subject.order_state
    expect(os.local_id).to be_an Integer
    expect(os.perm_id).to  be_an Integer 
    expect(os.perm_id.to_s).to  match  /^\d{8,11}$/   # has 9 to 11 numeric characters
    expect(os.client_id).to eq( OPTS[:connection][:client_id] ).or be_zero
    expect(os.parent_id).to be_zero
  end
end


RSpec.shared_examples_for 'Placed Order' do


		it{ is_expected.to be_a IB::Order }
		it "got proper id's" do
			expect( subject.local_id ).to be_an Integer
			expect( subject.perm_id ).to be_an Integer
			expect( subject.perm_id.to_s).to  match  /^\d{8,11}$/   # has 9 to 11 numeric characters
		end
		it "has an adequat clearing intent" do
			expect(IB::VALUES[:clearing_intent].values). to include subject.clearing_intent
		end
		it " the Time in Force is valid" do
			expect( IB::VALUES[:tif].values ).to include subject.tif
		end
		its( :clearing_intent ){is_expected.to eq :ib }
		it "mysterious trailing stop price is absent", :pending => true do
			pending "seems to be irrelevant, but needs clarification"
			expect( subject.trail_stop_price  ).to be_nil.or be_zero
		end
#	end
end

RSpec.shared_examples_for 'Presubmitted what-if Order' do | used_contract |
	its( :status ){ is_expected.to eq 'PreSubmitted' }
	if used_contract.is_a? IB::Bag  ## Combos dont have fixed commissions
		its( :commission ){ is_expected.to be_nil.or be_zero } 
	else
		its( :commission ){ is_expected.to be_a( BigDecimal ).and be > 0 } 
	end

	its( :what_if ){  is_expected.to be_truthy }
	its( :equity_with_loan  ){ is_expected.to be_a( BigDecimal ).and be > 0 } 
	its( :init_margin  ){ is_expected.to be_a( BigDecimal ).and be > 0 }
	its( :maint_margin ){ is_expected.to be_a( BigDecimal ).and be > 0 }
	it "mysterious trailing stop price is absent", pending: true do
		pending "seems to be irrelevant, but needs clarification"
		expect( subject.trail_stop_price ).to be_nil.or be_zero
	end

end

RSpec.shared_examples_for 'Filled Order' do
		its( :commission){ is_expected.to be_a( BigDecimal ).and be > 0 }
#		its( :average_fill_price ){ is_expected.not_to be_nil.or be_zero }
#		its( :average_fill_price ){is_expected.to be_a BigDecimal  }
		its( :status ) { is_expected.to eq 'Filled' }
		it "mysterious trailing stop price is absent", pending: true do
			pending "seems to be irrelevant, but needs clarification"
			expect( subject.trail_stop_price ).to be_nil.or be_zero
		end
end


RSpec.shared_examples_for "Proper Execution Record" do | side |

  its( :request_id){ is_expected.to  eq( OPTS[:connection][:request_id] ).or eq(-1) }
  its( :contract){ is_expected.to eq contract }

	it " has meaningful attributes " do
  exec = subject.execution
  expect(  exec.perm_id).to be_an Integer
  expect(  exec.client_id).to eq( OPTS[:connection][:client_id] ).or be_zero
  expect(  exec.local_id).to be_an Integer
  expect(  exec.exec_id).to be_a String
  expect(  exec.time).to match /\d\d:\d\d:\d\d/
  expect(  exec.account_name).to eq OPTS[:connection][:account]
  expect(  exec.exchange).to eq contract.exchange
  expect(  exec.side).to eq side
  expect(  exec.shares).to eq  order.total_quantity
  expect(  exec.cumulative_quantity).to eq order.total_quantity
  expect(  exec.price).to be > 1	# assuming EUR/USD stays in the range 1 --- 2
  expect(  exec.price).to be < 2
  expect(  exec.price).to eq exec.average_price
  expect(  exec.liquidation).to be_falsy
	end
end

# parameter pnl: true: there is a realized pnl
# takes the last ExecutionData-record as reference for exec_id
	RSpec.shared_examples 'Valid CommissionReport' do |  pnl |
		it{ is_expected.to be_an  IB::Messages::Incoming::CommissionReport }
		# data.keys: [:version, :exec_id, :commission, :currency, :realized_pnl, :yield, :yield_redemption_date] 
	  it " has a proper execution id" do
			e=  IB::Connection.current.received[:ExecutionData].last.execution.exec_id
			expect( subject.exec_id  ).to eq e 	
		end
		its( :commission ){is_expected.to be_a BigDecimal}
		its( :currency ){ is_expected.to eq OPTS[:connection][:base_currency] }
		its( :yield ){ is_expected.to be_nil  }
		its( :yield_redemption_date){ is_expected.to be_nil}  # no date, YYYYMMDD format for bonds
		if pnl>0
			its( :realized_pnl ){is_expected.to be_a BigDecimal}
		else
			its( :realized_pnl ){is_expected.to be_nil}
		end

	end 


=begin
      @order.modified_at.should be_a Time
      @order.placed_at.should == @order.modified_at
      @order.local_id.should be_an Integer
      @order.local_id.should == @local_id_before
    end


    it 'receives all appropriate response messages' do
			ib =  IB::Connection.current
      ib.received[:OpenOrder].should have_at_least(1).order_message
      ib.received[:OrderStatus].should have_at_least(1).status_message
    end

    it 'receives confirmation of Order submission' do
      order_should_be /Submit/ # ()Pre)Submitted
      status_should_be /Submit/

      if @attached_order
        if contract_type == :butterfly && @attached_order.tif == :good_till_cancelled
          pending 'API Bug: Attached GTC orders not working for butterflies!'
        else
          order_should_be /Submit/, @attached_order
        end
      end

    end
  end # Placing

  context "Retrieving placed" do
    before(:all) do
      @ib.send_message :RequestOpenOrders
      @ib.wait_for :OpenOrderEnd
    end

    after(:all) { clean_connection } # Clear logs and message collector

    it 'does not increase client`s next_local_id further' do
      @ib.next_local_id.should == @local_id_after
    end

    it 'receives all appropriate response messages' do
      @ib.received[:OpenOrder].should have_at_least(1).order_message
      @ib.received[:OrderStatus].should have_at_least(1).status_message
      @ib.received[:OpenOrderEnd].should have_exactly(1).order_end_message
    end

    it 'receives OpenOrder and OrderStatus for placed order(s)' do
      order_should_be /Submitted/
      status_should_be /Submitted/

      #pp @ib.received[:OpenOrder].first
      #
      if @attached_order
        if contract_type == :butterfly && @attached_order.tif == :good_till_cancelled
          pending 'API Bug: Attached GTC orders not working for butterflies!'
        else
          order_should_be /Submit/, @attached_order
        end
      end
    end
  end # Retrieving

  context "Modifying Order" do
    before(:all) do
      # Modification only works for non-attached orders
      @order.total_quantity *= 2
      @order.limit_price += 0.05
      @order.transmit = true
      @order.tif = 'GTC'
      @ib.modify_order @order, @contract

      if @attached_order
        # Modify attached order, if any
        @attached_order.limit_price += 0.05
        @attached_order.total_quantity *= 2
        @attached_order.tif = 'GTC'
        @ib.modify_order @attached_order, @contract
      end
      @ib.send_message :RequestOpenOrders
      @ib.wait_for :OpenOrderEnd, 6 #sec
    end

    after(:all) { clean_connection } # Clear logs and message collector

    it 'sets placement-related properties' do
      @order.modified_at.should be_a Time
      @order.placed_at.should_not == @order.modified_at
    end

    it 'does not increase client`s or order`s local_id any more' do
      @order.local_id.should == @local_id_before
      @ib.next_local_id.should == @local_id_after
    end

    it 'receives all appropriate response messages' do
      @ib.received[:OpenOrder].should have_at_least(1).order_message
      @ib.received[:OrderStatus].should have_at_least(1).status_message
      @ib.received[:OpenOrderEnd].should have_exactly(1).order_end_message
    end

    it 'modifies the placed order(s)' do
      @contract.should == @ib.received[:OpenOrder].first.contract
      order_should_be /Submit/
      status_should_be /Submit/

      if @attached_order
        if contract_type == :butterfly && @attached_order.tif == :good_till_cancelled
          skip 'API Bug: Attached GTC orders not working for butterflies!'
        else
          order_should_be /Submit/, @attached_order
        end
      end
    end
  end # Modifying

  context "Cancelling placed order" do
    before(:all) do
      @ib.cancel_order @local_id_placed
      @ib.wait_for [:OpenOrder, 2], :Alert, 3
    end

    after(:all) { clean_connection } # Clear logs and message collector

    it 'does not increase client`s next_local_id further' do
      @ib.next_local_id.should == @local_id_after
    end

    it 'only receives OpenOrder message with (Pending)Cancel', 
      :pending => 'Receives OrderState: PreSubmitted from previous context' do
      if @ib.received? :OpenOrder
        # p @ib.received[:OrderStatus].size
        # p @ib.received[ :OpenOrder].map {|m| m.order.limit_price.to_s+m.status}
        order_should_be /Cancel/
      end
    end

    it 'receives all appropriate response messages' do
      @ib.received[:OrderStatus].should have_at_least(1).status_message
      @ib.received[:Alert].should have_at_least(1).alert_message
    end

    it 'receives cancellation Order Status' do
      status_should_be /Cancel/ # Cancelled / PendingCancel
      if @attached_order
        if contract_type == :butterfly && @attached_order.tif == :good_till_cancelled
          pending 'API Bug: Attached GTC orders not working for butterflies!'
        else
          status_should_be /Cancel/, @attached_order
        end
      end
    end

    it 'receives Order cancelled Alert' do
      alert = @ib.received[:Alert].first
      alert.should be_an IB::Messages::Incoming::Alert
      alert.message.should =~ /Order Canceled - reason:/
    end
  end # Cancelling
end

### Helpers for placing and verifying orders

def status_should_be status, order=@order
  msg = @ib.received[:OrderStatus].find do |msg|
    msg.local_id == order.local_id &&
      status.is_a?(Regexp) ? msg.status =~ status : msg.status == status
  end
  msg.should_not be_nil
  msg.should be_an IB::Messages::Incoming::OrderStatus
  order_state = msg.order_state
  order_state.local_id.should == order.local_id
  order_state.perm_id.should be_an Integer
  order_state.client_id.should == OPTS[:connection][:client_id]
  order_state.parent_id.should == 0 unless @attached_order
  order_state.why_held.should == ''

  if @contract == IB::Symbols::Forex[:eurusd]
    # We know that this order filled for sure
    order_state.filled.should == 20000
    order_state.remaining.should == 0
    order_state.average_fill_price.should be > 1
    order_state.average_fill_price.should be < 2
    order_state.last_fill_price.should == order_state.average_fill_price
  else
    order_state.filled.should == 0
    order_state.remaining.should == order.total_quantity
    order_state.average_fill_price.should == 0
    order_state.last_fill_price.should == 0
  end
end
=end

