require 'order_helper'

## Notice
## The first Test-run fails, if active OpenOrder-Messages are recieved 
## and no OpenOrder-Message is returned immideately.
## Simply repeat the Execution of the Test


RSpec.describe IB::Limit do
	before(:all) do
		@the_open_order_message = nil
		verify_account
		ib = IB::Connection.new OPTS[:connection] do | gw| 
			gw.logger = mock_logger
			# put the most recent received OpenOrder-Message to an instance-variable
			gw.subscribe( :OpenOrder ){|msg| @the_open_order_message = msg}
		end
		ib.wait_for :NextValidId
		place_the_order do | last_price |

			@the_order_price = last_price.nil? ? 56 : last_price -2    # set a limit price that 
			# is well below the actual price
			#
		  IB::Limit.order price: @the_order_price , action: :buy, size: 100, account: ACCOUNT
		end

	end

		
	after(:all) { IB::Connection.current.send_message(:RequestGlobalCancel); close_connection; } 

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

	context IB::Order do
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
			expect( o.account ).to  eq ACCOUNT
		end
	end

	context IB::Contract do

		subject{ @the_open_order_message.contract }
		it{ is_expected.to be_an IB::Contract }
			its( :symbol ){ is_expected.to eq  'WFC' }
			its( :exchange ){ is_expected.to eq 'SMART' }


	end	

#it 'has extended order_state attributes' do
# to generate the order:
# o = ForexLimit.order action: :buy, size: 15000, cash_qty: true
# c =  Symbols::Forex.eurusd
# C.place_order o, c



end # describe IB::Messages:Incoming

__END__


