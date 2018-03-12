require 'order_helper'

## Notice
## The first Test-run fails, if active OpenOrder-Messages are recieved 
## and no OpenOrder-Message is returned immideately.
## Simply repeat the Execution of the Test


def place_the_dc_order  # returns the used order-price
		ib =  IB::Connection.current
		contract =  IB::Symbols::Stocks[:wfc]
		ib.send_message :RequestMarketDataType, :market_data_type => :delayed
		ib.send_message :RequestMarketData, id: 123, contract:  contract
		ib.wait_for :TickPrice
		ib.send_message :RequestGlobalCancel
		ib.send_message :CancelMarketData, id: 123
		last_price = ib.received[:TickPrice].price.max
		the_order_price = last_price.nil? ? 56 : last_price - 4   # set a limit price that 
		# will not cause immediate filling
		# the disretionary amount adds to the limit-price, thus the real limit price is Price - 2 
		discretionary_amount = dc =2
		order = IB::Discretionary.order price: the_order_price , action: :buy, size: 100, 
																		discretionary_amount: dc , account: ACCOUNT
		ib.place_order order, contract      
		ib.wait_for :OpenOrder, 3

		[the_order_price, dc ] #  return_value

end

RSpec.describe IB::Limit do
	before(:all) do
		verify_account
		ib = IB::Connection.new OPTS[:connection] do | gw| 
			gw.logger = mock_logger
			# put the most recent received OpenOrder-Message to an instance-variable
			gw.subscribe( :OpenOrder ){|msg| @the_open_order_message = msg}
		end
		ib.wait_for :NextValidId
		@the_order_price, @the_discretionary_amount =  place_the_dc_order

	end

		
	after(:all) { IB::Connection.current.send_message(:RequestGlobalCancel); close_connection; } 

	context 'Initiate Order' , focus: true  do
		# reset open_order_message variable
		# this is done before(:all) ist triggered
		@the_open_order_message = nil
		it  'place the order' do
			expect(IB::Connection.current.received?(:OpenOrder)).to  be_truthy
			expect(IB::Connection.current.received[:OpenOrder].last).to  eq @the_open_order_message
		end

		subject{ @the_open_order_message }
		it_behaves_like 'OpenOrder message'
	end

	context "the placed order",  focus: true  do

		subject{ @the_open_order_message.order }
#		subject{ IB::Connection.current.received[:OpenOrder].order.last }
		it_behaves_like 'Placed Order' 

		it 'has the appropiate order attributes' do
			#puts subject.inspect
			o =  subject
			expect( o.action ).to eq  :buy
			expect( o.order_type ).to eq :limit
			expect( o.total_quantity  ).to eq 100
			expect( o.limit_price ).to eq @the_order_price
			expect( o.discretionary_amount ).to eq @the_discretionary_amount
			expect( o.account ).to  eq ACCOUNT
		end
	end

	context "the returned contract" do

		subject{ @the_open_order_message.contract }
		it 'has proper contract accessor' do
			c = subject
			expect(c).to be_an IB::Contract
			expect(c.symbol).to eq  'WFC'
			expect(c.exchange).to eq 'SMART'
		end


	end	

#it 'has extended order_state attributes' do
# to generate the order:
# o = ForexLimit.order action: :buy, size: 15000, cash_qty: true
# c =  Symbols::Forex.eurusd
# C.place_order o, c



end # describe IB::Messages:Incoming

__END__


