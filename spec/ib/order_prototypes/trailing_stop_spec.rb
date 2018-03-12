require 'order_helper'

## Notice
## The first Test-run fails, if active OpenOrder-Messages are recieved 
## and no OpenOrder-Message is returned immideately.
## Simply repeat the Execution of the Test


#@the_open_order_message  = nil
RSpec.describe IB::TrailingStop do
	before(:all) do
		verify_account
		ib = IB::Connection.new OPTS[:connection] do | gw| 
			gw.logger = mock_logger
			# put the most recent received OpenOrder-Message to an instance-variable
			gw.subscribe( :OpenOrder ){|msg| @the_open_order_message = msg; puts "MSG: #{msg.inspect}"}
		end
		ib.wait_for :NextValidId

	end

		
	after(:all) { IB::Connection.current.send_message(:RequestGlobalCancel); close_connection } 
	describe :trailing_percent do
#		let( :the_Order_price ){  place_the_trailing_stop_order( use: :trailing_percent ) }
		before( :all ) do
			@the_Order_price = nil
			IB::Connection.current.clear_received :OpenOrder
			place_the_order( contract: IB::Symbols::Stocks.aapl ) do | last_price |
				trailing_percent =  1
				the_last_price =  last_price.nil? ? 56 : last_price 
				@the_Order_price = the_last_price - (the_last_price * trailing_percent / 100)    # set a stop-price
				# well below the market-price
				order = IB::TrailingStop.order price: @the_Order_price , action: :sell, size: 100, 
					trailing_percent: trailing_percent,	 account: ACCOUNT
			end
			IB::Connection.current.wait_for :OpenOrder, 10
		end

		it "displays OpenORder" do
			puts  IB::Connection.current.received[:OpenOrder].inspect
		end
		subject{ IB::Connection.current.received[:OpenOrder].last }
			it_behaves_like 'OpenOrder message'
		

		context "the placed order",  focus: true  do

#		subject{ @the_open_order_message.order }
		subject{ IB::Connection.current.received[:OpenOrder].order.last }
			it_behaves_like 'Placed Order' 
			its( :trail_stop_price ){ is_expected.to eq @the_Order_price }
			its( :aux_price ){ is_expected.to be_zero }
			its( :trailing_percent ){ is_expected.not_to be_zero }
			its( :action ){ is_expected.to  eq( :buy ).or eq( :sell ) }
			its( :order_type ){ is_expected.to  eq :trailing_stop }
			its( :account ){ is_expected.to  eq ACCOUNT }
			its( :limit_price ){ is_expected.to be_zero  }
			its( :total_quantity ){ is_expected.to eq 100 }

		end
	end

	describe :trailing_amount do
		before( :all ) do 
				@the_order_price =  nil
				@trailing_amount =  nil
				IB::Connection.current.clear_received :OpenOrder
				place_the_order do | last_price |

					@trailing_amount = 2
					@the_order_price =( last_price.nil? ? 56 : last_price ) - @trailing_amount 
					# set a stop-price
					# well below the market-price
					# return the order
					IB::TrailingStop.order price: @the_order_price , action: :sell, size: 100, 
																trailing_amount: @trailing_amount,	 account: ACCOUNT
					
				end
				IB::Connection.current.wait_for :OpenOrder
		end	
#		let( :the_order_price ){  place_the_trailing_stop_order( use: :trailing_amount ) }

		context 'Initiate Order' , focus: true  do
			it{  expect( IB::Connection.current ).not_to be_nil }
			it{  expect(IB::Connection.current.received?(:OpenOrder)).to  be_truthy }
			end

		subject{ IB::Connection.current.received[:OpenOrder].last }
			it_behaves_like 'OpenOrder message'
		
		context "the placed order",  focus: true  do

			subject{ IB::Connection.current.received[:OpenOrder].order.first }
			it_behaves_like 'Placed Order' 
			its( :trail_stop_price ){ is_expected.to eq @the_order_price }
			its( :aux_price ){ is_expected.to eq @trailing_amount }
			its( :trailing_percent ){ is_expected.to be_zero }
			its( :action ){ is_expected.to  eq( :buy ).or eq( :sell ) }
			its( :order_type ){ is_expected.to  eq :trailing_stop }
			its( :account ){ is_expected.to  eq ACCOUNT }
			its( :limit_price ){ is_expected.to be_zero  }
			its( :total_quantity ){ is_expected.to eq 100 }

		end
	end  # describe
#it 'has extended order_state attributes' do
# to generate the order:
# o = ForexLimit.order action: :buy, size: 15000, cash_qty: true
# c =  Symbols::Forex.eurusd
# C.place_order o, c



end # describe IB::Messages:Incoming

__END__


