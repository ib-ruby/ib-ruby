require 'order_helper'
require 'combo_helper'
### passes only during regular trading hours of the google-butterfly
RSpec.describe IB::Limit do

  let(:contract_type) { :butterfly }
	before(:all) do
		verify_account
		ib = IB::Connection.new OPTS[:connection] do | gw| 
			gw.logger = mock_logger
			# put the most recent received OpenOrder-Message to an instance-variable
			gw.subscribe( :OpenOrder ){|msg| @the_open_order_message = msg}
		end
		ib.wait_for :NextValidId
		place_the_order  contract:  butterfly('GOOG', '201901', 'CALL', 1130, 1150, 1170)  do | last_price |

			@the_order_price = last_price.nil? ? 5 : last_price -0.4    # set a limit price that 
			# is well below the actual price
			# The Order will become visible only if the market-price is below the trigger-price
			#
		  IB::Limit.order price: @the_order_price , action: :buy, size: 10, account: ACCOUNT, order_ref: 'What_if'
		end
	end
	context 'Initiate Order' , focus: true  do

			@the_open_order_message = nil

		it 'place the order' do

			ib = IB::Connection.current
			#		subject{  IB::Connection.current.received }
			expect( ib.received[:OpenOrder]).to have_at_least(1).open_order_message 
			expect( ib.received[:OrderStatus]).to have_exactly(0).status_messages 
		end
		subject{ @the_open_order_message }
		it_behaves_like 'OpenOrder message'
	end

	context "the placed order",  focus: true  do


    it 'responds with margin info' do
			ib =  IB::Connection.current
#
			#order_should_be /PreSubmitted/
#      order = ib.received[:OpenOrder].first.order
      order = @the_open_order_message.order
      expect( order.what_if).to be_truthy
      expect( order.equity_with_loan).to be_a BigDecimal
      expect( order.init_margin).to be_a BigDecimal
      expect( order.maint_margin).to be_a BigDecimal
      expect( order.equity_with_loan).to be  > 0
      expect( order.what_if).to  be_truthy
    end

    it 'responds with commission  and margininfo' do
#       :pending => 'API Bug: No commission in what_if for Combo orders' do
      o = @the_open_order_message.order
    #  o = IB::Connection.current.received[:OpenOrder].first.order
			puts o.inspect
      expect( o.max_commission).to  be_a BigDecimal
      expect( o.min_commission).to  be_a BigDecimal
      expect( o.commission).to be_zero
      expect( o.init_margin).to be > 0
      expect( o.maint_margin).to be  > 0

    end

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
