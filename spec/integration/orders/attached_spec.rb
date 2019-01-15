require 'order_helper'
require 'combo_helper'

def define_contracts
  @contracts = {
    :stock => IB::Symbols::Stocks.wfc,
    :butterfly => butterfly('GOOG', '201903', 'CALL', 1000, 1020, 1040) # defined in Combo_helper
  }
end
## in premarket condition GTC BUY (butterfly) limit order with attached LMT SELL  fails!

describe 'Attached Orders', :connected => true, :integration => true , :us_trading_hours => true
 do

  before(:all) do
    verify_account
		ib = IB::Connection.new OPTS[:connection] do | gw| 
			gw.logger = mock_logger
			# put the most recent received OpenOrder-Message to an instance-variable
			gw.subscribe( :OpenOrder ){|msg| @the_open_order_message = msg}
		end
    define_contracts
  end

	after(:all) { remove_open_orders; close_connection }
  # Testing different combinations of Parent + Attached Orders:
  [
    [:stock, 100, 'DAY', 'LMT'], # Parent + takeprofit target
    [:stock, 100, 'DAY', 'STP'], # Parent + stoploss
    [:stock, 100, 'GTC', 'STPLMT'], # GTC Parent + target
    [:butterfly, 1, 'DAY', 'LMT'], # Combo Parent + target
    [:butterfly, 1, 'GTC', 'LMT'], # GTC Combo Parent + target
    [:butterfly, 1, 'GTC', 'STPLMT'], # GTC Combo Parent + stoplimit target
  ].each do |(contract, qty, tif, attach_type)|
    context "#{tif} BUY (#{contract}) limit order with attached #{attach_type} SELL" do

      before(:all) do
        ib = IB::Connection.current
        ib.wait_for :NextValidId
        ib.clear_received # to avoid conflict with pre-existing Orders

        #p [contract, qty, tif, attach_type ]
				@the_contract = @contracts[contract] 
				@local_id_placed = 	place_the_order contract: @the_contract do  | the_market_price |
					IB::Limit.order size: qty, price: ( the_market_price - (the_market_price * 0.05) ).round(1), 
													action: :buy,
													tif: tif, transmit: false, account: ACCOUNT
				end
      end

			context IB::Connection do

				subject { IB::Connection.current }
				it 'does not transmit original Order before attach' do
					if subject.received[:OpenOrder].size > 0
						puts subject.received[:OpenOrder].map(&:to_human)
					end
					expect( subject.received[:OpenOrder]).to  have_exactly(0).order_message
					expect( subject.received[:OrderStatus]).to  have_exactly(0).status_message
				end
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
						  the_stop_price =  the_market_price - (the_market_price * 0.08)  # 8% below market price
							IB::SimpleStop.order :price => the_stop_price.round(1), 
																	:size => qty,
																	:action => :sell,
																	:tif => tif,
																	:parent_id => @local_id_placed,
																	:account => ACCOUNT
						end  ## case

					end  # block of »place_the_order«
				end # before

				context IB::Connection do
					subject { IB::Connection.current  }
					it { 	expect( subject.received[:OpenOrder]).to have_at_least(1).open_order_message }
						#	puts  ib.received[:OpenOrder].to_human
					end
				
				context IB::Order do
					subject{ IB::Connection.current.received[:OpenOrder].last.order }
					it_behaves_like 'Placed Order'
				end

			end
			# only works if the markets are open
      context 'Cancel original Order ', if: :us_trading_hours do
        it 'attached takeprofit is cancelled implicitly' do
        ib = IB::Connection.current
					ib.clear_received :OpenOrder, :OrderStatus
          expect( ib.received[:OpenOrder]).to have_exactly(0).order_message
          expect( ib.received[:OrderStatus]).to have_exactly(0).status_message
				  ib.cancel_order @local_id_placed
					ib.wait_for :Alert
					if  ib.received[:Alert].last.message =~ /Order Canceled/
          ib.send_message :RequestOpenOrders
          ib.wait_for :OpenOrderEnd
          expect( ib.received[:OpenOrder]).to have_exactly(0).order_message
          expect( ib.received[:OrderStatus]).to have_exactly(0).status_message
					puts ib.received[:OpenOrder].inspect
					end
        end
      end

    end
  end
end # Orders
