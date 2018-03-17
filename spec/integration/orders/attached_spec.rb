require 'order_helper'
require 'combo_helper'

def define_contracts
  @contracts = {
    :stock => IB::Symbols::Stocks.wfc,
    :butterfly => butterfly('GOOG', '201901', 'CALL', 1000, 1020, 1040)
  }
end

describe 'Attached Orders', :connected => true, :integration => true , focus: true do

  before(:all) do
    verify_account
		ib = IB::Connection.new OPTS[:connection] do | gw| 
			gw.logger = mock_logger
			# put the most recent received OpenOrder-Message to an instance-variable
			gw.subscribe( :OpenOrder ){|msg| @the_open_order_message = msg}
		end
    define_contracts
  end

	after(:all) { close_connection }
  # Testing different combinations of Parent + Attached Orders:
  [
    [:stock, 100, 'DAY', 'LMT'], # Parent + takeprofit target
    [:stock, 100, 'DAY', 'STP'], # Parent + stoploss
    [:stock, 100, 'GTC', 'LMT'], # GTC Parent + target
    [:butterfly, 10, 'DAY', 'LMT'], # Combo Parent + target
    [:butterfly, 10, 'GTC', 'LMT'], # GTC Combo Parent + target
    [:butterfly, 100, 'GTC', 'STPLMT'], # GTC Combo Parent + stoplimit target
  ].each do |(contract, qty, tif, attach_type)|
    context "#{tif} BUY (#{contract}) limit order with attached #{attach_type} SELL" do

      before(:all) do
        ib = IB::Connection.current
        ib.wait_for :NextValidId
        ib.clear_received # to avoid conflict with pre-existing Orders

        #p [contract, qty, tif, attach_type ]
				@the_contract = @contracts[contract] 
				@local_id_placed = 	place_the_order contract: @the_contract do  | the_market_price |
					IB::Limit.order size: qty, price: the_market_price, action: :buy,
													tif: tif, transmit: false, account: ACCOUNT
				end

      end


      it 'does not transmit original Order before attach' do
        ib = IB::Connection.current
        expect( ib.received[:OpenOrder]).to  have_exactly(0).order_message
        expect( ib.received[:OrderStatus]).to  have_exactly(0).status_message
      end

      context "Attaching #{attach_type} order" do
        before(:all) do
					ib = IB::Connection.current
					@local_id_attached = place_the_order contract: @the_contract do  | the_market_price |
						case attach_type
						when "STPLMT"   # StopLimit-Approach
						  the_stop_price =  the_market_price - (the_market_price * 0.1)  # 10%  below market price
							the_attach_price = the_stop_price +0.2
							IB::StopLimit.order :limit_price => the_attach_price.round(1),
																	:stop_price => the_stop_price.round(1), 
																	:size => qty,
																	:action => :sell,
																	:tif => tif,
																	:parent_id => @local_id_placed,
																	:account => ACCOUNT
																 # :order_type => attach_type,
						 when "LMT"  #  takeProfit Target

							the_attach_price = the_market_price + (the_market_price *0.1)  # 10% above market price
							IB::Limit.order :limit_price => the_attach_price.round(1),
																	:size => qty,
																	:action => :sell,
																	:tif => tif,
																	:parent_id => @local_id_placed,
																	:account => ACCOUNT
						 when "STP"		# StopLoss
						  the_stop_price =  the_market_price - (the_market_price * 0.05)  # 5% below market price
							IB::SimpleStop.order :price => the_stop_price.round(1), 
																	:size => qty,
																	:action => :sell,
																	:tif => tif,
																	:parent_id => @local_id_placed,
																	:account => ACCOUNT
						end  ## case

					end  # block of »place_the_order«
				end # before
				it  "place the order " do
						ib = IB::Connection.current
						expect( ib.received[:OpenOrder]).to have_at_least(1).open_order_message 
					#	puts  ib.received[:OpenOrder].to_human
				end
				
				subject{ IB::Connection.current.received[:OpenOrder].last.order }
        it_behaves_like 'Placed Order'
      end

			# only works if the markets are open
      context 'When original Order cancels' do
        it 'attached takeprofit is cancelled implicitly' do
        ib = IB::Connection.current
					ib.clear_received :OpenOrder, :OrderStatus
				  ib.cancel_order @local_id_placed
          ib.send_message :RequestOpenOrders
          ib.wait_for :OpenOrderEnd
					#puts ib.received[:OpenOrder].to_human
          ib.received[:OpenOrder].should have_exactly(0).order_message
          ib.received[:OrderStatus].should have_exactly(0).status_message
        end
      end

    end
  end
end # Orders
