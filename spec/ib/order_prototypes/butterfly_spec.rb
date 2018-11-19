require 'order_helper'
require 'combo_helper'
### passes only during regular trading hours of the google-butterfly
RSpec.describe IB::Limit , if: :us_trading_hours do

  #let(:contract_type) { :butterfly }
	before(:all) do
		@the_open_order_message = nil
		verify_account
		ib = IB::Connection.new OPTS[:connection] do | gw| 
			gw.logger = mock_logger
			# assign the most recent received OpenOrder-Message to an instance-variable
			gw.subscribe( :OpenOrder ){|msg| @the_open_order_message = msg}
			gw.subscribe( :Alert ){ |msg| puts msg.to_human }
		end
		ib.wait_for :NextValidId
		@order_id = place_the_order( contract:  butterfly('GOOG', '201901', 'CALL', 1030, 1050, 1070) ) do | last_price |

			@the_order_price = last_price.nil? ? 5 : (last_price/2).round(1)    # set a limit price that 
			puts "TheOrderPrice #{@the_order_price} "
			# is well below the actual price
			# The Order will become visible only if the market-price is below the trigger-price
			#
			IB::Limit.order price: @the_order_price , action: :buy, size: 10, account: ACCOUNT, order_ref: 'What_if', 
				what_if: true
		end
	end

	after(:all){ IB::Connection.current.cancel_order @order_id }


		context IB::Connection do
			subject { IB::Connection.current }
			it { expect( subject.received[:OpenOrder]).to have_at_least(1).open_order_message  }
			it { expect( subject.received[:OrderStatus]).to have_exactly(0).status_messages  }
		end

		context IB::Messages::Incoming::OpenOrder do
			#subject { @the_open_order_message }
			subject{ IB::Connection.current.received[:OpenOrder].last }
			it_behaves_like 'OpenOrder message'
		end

		context IB::Order do
     subject { @the_open_order_message.order }
		 it_behaves_like 'Presubmitted what-if Order', IB::Bag.new
    end

		context "finalize" do
    it 'is not actually being placed though' do
			ib = IB::Connection.current
      ib.clear_received
      ib.send_message :RequestOpenOrders
      ib.wait_for :OpenOrderEnd
      expect(  ib.received[:OpenOrder]).to have_exactly(0).order_message
    end
	end
  #context "Limit" do # , :if => :us_trading_hours
    #before(:all) do
    #  ib = IB::Connection.new OPTS[:connection].merge(:logger => mock_logger)
    #  ib.wait_for :NextValidId
    #  ib.clear_received # to avoid conflict with pre-existing Orders
	
		#	the_order = IB::Limit.order( action: :buy,
    #              :order_ref => 'Original',
    #              :limit_price => 0.06,
    #              :total_quantity => 10,
		#							account: ACCOUNT )

    #  ib.place_order the_order, the_contract

    #  ib.wait_for :OpenOrder, 6
    #end

  #  after(:all) { close_connection }

#    it_behaves_like 'Placed Order'
  #end # Limit
end # Combo Orders

__END__
