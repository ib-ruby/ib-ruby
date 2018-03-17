require 'integration_helper'

def place_the_order( contract: IB::Symbols::Stocks[:wfc])  
		ib =  IB::Connection.current
		ib.send_message :RequestMarketDataType, :market_data_type => :delayed
		the_id = ib.send_message :RequestMarketData, contract:  contract
		ib.wait_for :TickPrice
		ib.send_message :CancelMarketData, id: the_id
		last_price = ib.received[:TickPrice].price.map(&:to_f).max
		ib.clear_received :TickPrice
		last_price =  last_price.nil? ? rand(999).to_f/100 : last_price
		order =  yield(last_price)

		the_order_id = ib.place_order order, contract      
		ib.wait_for :OpenOrder, 3
		the_order_id  # return value
end
RSpec.shared_examples_for 'OpenOrder message' do
#	let( :subject ){ the_returned_message }
  it { should be_an IB::Messages::Incoming::OpenOrder }
  its(:message_type) { is_expected.to eq :OpenOrder }
  its(:message_id) { is_expected.to eq 5 }
  its(:version) { is_expected.to eq 34}
  its(:data) { is_expected.not_to  be_empty }
  its(:buffer, pending: true ) { is_expected.to be_empty }  # Work on openOrder-Message has to be finished.
  							## Integration of Conditions !
  its(:local_id) { is_expected.to be_an Integer }
  its(:status) { is_expected.to match /Submit/ }
  #its(:to_human) { is_expected.to match /<OpenOrder: <Stock: WFC USD> <Order: LMT DAY buy 100.0 49.13 .*Submit.* #\d+\/\d+ from 1111/ }


  it 'has proper order accessor' do
    o = subject.order
    expect( o.client_id ).to eq(1111) or eq(2000)
    expect( o.parent_id ).to be_zero
  end

  it 'has proper order_state accessor' do
    os = subject.order_state
    expect(os.local_id).to be_an Integer
    expect(os.perm_id).to  be_an Integer 
    expect(os.perm_id.to_s).to  match  /^\d{8,11}$/   # has 9 to 11 numeric characters
    expect(os.client_id).to eq(1111)  or eq(2000)
    expect(os.parent_id).to be_zero
    expect(os.submitted?).to be_truthy
  end
end


RSpec.shared_examples_for 'Placed Order' do

  context "returned Message" do

    #it 'sets placement-related properties' do
		it{ is_expected.to be_a IB::Order }
		it "got proper id's" do
			expect( subject.local_id ).to be_an Integer
			expect( subject.perm_id ).to be_an Integer
			expect(subject.perm_id.to_s).to  match  /^\d{8,11}$/   # has 9 to 11 numeric charactersa
		end
		it "has an adequat clearing intent" do
			expect(IB::VALUES[:clearing_intent].values). to include subject.clearing_intent
		end
		it" the Time in Force is valid" do
			expect( IB::VALUES[:tif].values ).to include subject.tif
		end
		its( :clearing_intent ){is_expected.to eq :ib }
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

def place_order contract, opts = {}
  @contract = contract
  @order = IB::Order.new({:total_quantity => 100,
                          :limit_price => 49.13,
                          :action => 'BUY',
                          :order_type => 'LMT'}.merge(opts))
  @local_id_before = @ib.next_local_id
  @local_id_placed = @ib.place_order @order, @contract
  @local_id_after = @ib.next_local_id
end

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

def order_should_be status, order=@order
  msg = @ib.received[:OpenOrder].find do |msg|
    msg.local_id == order.local_id &&
      status.is_a?(Regexp) ? msg.status =~ status : msg.status == status
  end
  msg.should_not be_nil
  msg.should be_an IB::Messages::Incoming::OpenOrder
  msg.order.should == order
  msg.contract.should == @contract
end
=end
