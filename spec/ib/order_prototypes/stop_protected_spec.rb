require 'order_helper'



# works with Futures, Exchanges: ECBOT, NYMEX, GLOBEX
# not for stocks, forex, bonds, options
RSpec.describe IB::StopProtected do
	before(:all) do
		@the_open_order_message = nil
		verify_account
		ib = IB::Connection.new OPTS[:connection] do | gw| 
			gw.logger = mock_logger
			# put the most recent received OpenOrder-Message to an instance-variable
			gw.subscribe( :Alert ){|msg| puts msg.to_human }
			gw.subscribe( :OpenOrder ){|msg| @the_open_order_message = msg}
		end
		ib.wait_for :NextValidId
	end

		after(:all) { IB::Connection.current.send_message(:RequestGlobalCancel); close_connection; } 

		context "Not Supported Exchange" do

			before(:all) do

				@the_order_id = place_the_order( contract: IB::Symbols::Futures.es ) do | last_price |
					@the_order_price = ( last_price.nil? ? 2000 : last_price +2 ).round(0)   # set a stop price that 
					puts "THEORDERPIRCE #{@the_order_price}"
					IB::StopProtected.order price: @the_order_price , action: :buy, size: 1, 
						account: ACCOUNT
				end
			end


			context IB::Connection do
				subject { IB::Connection.current }
				it( "OpenOrderMessage is empty" ) { expect( subject.received[:OpenOrder]).to be_empty }
				it( "The #received? method returns false" ) { expect( subject.received?(:OpenOrder)).to  be_falsy }
				it(" An Alert Message was send") { expect( subject.received?(:Alert)).to  be_truthy }
				it(" The AlertMessage has the expected content") { expect( subject.received[:Alert].detect{|x| x.error_id == @the_order_id}.message ).to match /Unsupported order type for this exchange and security type/ }

			end
		end

		context "Supported Exchange" do

			before(:all) do

				@the_order_id = place_the_order( contract: IB::Symbols::Futures.ym ) do | last_price |
					@the_order_price = ( last_price.nil? ? 25000 : last_price +2 ).round(0)   # set a stop price that 
					puts "THEORDERPIRCE #{@the_order_price}"
					IB::StopProtected.order price: @the_order_price , action: :buy, size: 1, 
						account: ACCOUNT
				end
			end

			context  IB::Connection  do
				subject { IB::Connection.current }
				it { expect( subject.received[:OpenOrder]).to have_at_least(1).open_order_message  }
				it { expect( subject.received[:OrderStatus]).to have_exactly(1).status_messages  }
				it { expect(subject.received[:OpenOrder].last).to  eq @the_open_order_message }
			end

			context IB::Messages::Incoming::OpenOrder do
				subject{ @the_open_order_message }
				it_behaves_like 'OpenOrder message'
			end
		end
#	context IB::Order,  focus: false  do
#
#		subject{ @the_open_order_message.order }
##		subject{ IB::Connection.current.received[:OpenOrder].order.last }
#		it_behaves_like 'Placed Order' 
#		its( :aux_price ){ is_expected.not_to  be_zero }  # trigger-price => aux-price
#		its( :action ){ is_expected.to  eq( :buy ) or eq( :sell ) }
#		its( :order_type ){ is_expected.to  eq :stopi_protected }
#		its( :account ){ is_expected.to  eq ACCOUNT }
#		its( :limit_price ){ is_expected.to be_zero }
#		its( :aux_price ){ is_expected.to eq @the_order_price }
#		its( :total_quantity ){ is_expected.to eq 100 }
#
#	end
#
#	context "the returned contract" , focus: false do
#
#		subject{ @the_open_order_message.contract }
#		it 'has proper contract accessor' do
#			c = subject
#			expect(c).to be_an IB::Contract
#			expect(c.symbol).to eq  'WFC'
#			expect(c.exchange).to eq 'SMART'
#		end
#
#
#	end	

#it 'has extended order_state attributes' do
# to generate the order:
# o = ForexLimit.order action: :buy, size: 15000, cash_qty: true
# c =  Symbols::Forex.eurusd
# C.place_order o, c



end 

__END__


