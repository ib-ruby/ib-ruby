
module IB
    module SimpleStop
      extend OrderPrototype
      class << self

      def defaults
	  super.merge order_type: :stop 
      end

      def aliases
	super.merge  aux_price: :price 
      end

      def requirements
	super.merge aux_price: 'Price where the action is triggert. Aliased as :price'
      end


      def summary
	<<-HERE
	A Stop order is an instruction to submit a buy or sell market order if and when the 
	user-specified stop trigger price is attained or penetrated. A Stop order is not guaranteed 
	a specific execution price and may execute significantly away from its stop price. 
	
	A Sell Stop order is always placed below the current market price and is typically used 
	to limit a loss or protect a profit on a long stock position. 
	
	A Buy Stop order is always placed above the current market price. It is typically used 
	to limit a loss or help protect a profit on a short sale. 
	HERE
      end
      end
    end
    module StopLimit
      extend OrderPrototype
      class << self

      def defaults
	  super.merge order_type: :stop_limit 
      end

      def aliases
	Limit.aliases.merge  aux_price: :stop_price
      end

      def requirements
	Limit.requirements.merge aux_price: 'Price where the action is triggert. Aliased as :stop_price'
      end


      def summary
	<<-HERE
	A Stop-Limit order is an instruction to submit a buy or sell limit order when 
	the user-specified stop trigger price is attained or penetrated. The order has 
	two basic components: the stop price and the limit price. When a trade has occurred 
	at or through the stop price, the order becomes executable and enters the market 
	as a limit order, which is an order to buy or sell at a specified price or better. 
	HERE
      end
      end
    end
    module  StopProtected
      extend OrderPrototype
      class << self

      def defaults
	  super.merge order_type: :stop_protected 
      end

      def aliases
	SimpleStop.aliases
      end

      def requirements
	SimpleStop.requirements
      end


      def summary
	<<-HERE
	US-Futures only
	----------------------------
	A Stop with Protection order combines the functionality of a stop limit order 
	with a market with protection order. The order is set to trigger at a specified 
	stop price. When the stop price is penetrated, the order is triggered as a 
	market with protection order, which means that it will fill within a specified 
	protected price range equal to the trigger price +/- the exchange-defined protection 
	point range. Any portion of the order that does not fill within this protected 
	range is submitted as a limit order at the exchange-defined trigger price +/- 
	the protection points.
	HERE
      end
    end
		end
#  module OrderPrototype
		module  TrailingStop
			extend OrderPrototype
			class << self


				def defaults
					super.merge order_type: :trailing_stop , tif: :day
				end

				def aliases
					super.merge trail_stop_price: :price,
											aux_price: :trailing_amount
				end

				def requirements
					## usualy the trail_stop_price is the market-price minus(plus) the trailing_amount
					super.merge trail_stop_price: 'Price to trigger the action, aliased as :price'

				end

				def alternative_parameters
					{ aux_price: 'Trailing distance in absolute terms, aliased as :trailing_amount',
			 trailing_percent: 'Trailing distance in relative terms'}
				end

				def summary
					<<-HERE
	A "Sell" trailing stop order sets the stop price at a fixed amount below the market 
	price with an attached "trailing" amount. As the market price rises, the stop price 
	rises by the trail amount, but if the stock price falls, the stop loss price doesn't 
	change, and a market order is submitted when the stop price is hit. This technique 
	is designed to allow an investor to specify a limit on the maximum possible loss, 
	without setting a limit on the maximum possible gain. 

	"Buy" trailing stop orders are the mirror image of sell trailing stop orders, and 
	are most appropriate for use in falling markets.

	Note that Trailing Stop orders can have the trailing amount specified as a percent, 
	or as an absolute amount which is specified in the auxPrice field. 

					HERE
				end  # summary
			end	   # class self
		end			# module

		module TrailingStopLimit
			extend OrderPrototype
			class << self


				def defaults
					super.merge order_type: :trailing_limit , tif: :day
				end

				def aliases
					Limit.aliases 
				end

				def requirements
					super.merge trail_stop_price: 'Price to trigger the action',
											limit_price_offset: 'a pRICE'

				end

				def alternative_parameters
					{ aux_price: 'Trailing distance in absolute terms',
			 trailing_percent: 'Trailing distance in relative terms'}
				end

				def summary
					<<-HERE
		 A trailing stop limit order is designed to allow an investor to specify a
		 limit on the maximum possible loss, without setting a limit on the maximum
		 possible gain. A SELL trailing stop limit moves with the market price, and
		 continually recalculates the stop trigger price at a fixed amount below
		 the market price, based on the user-defined "trailing" amount. The limit
		 order price is also continually recalculated based on the limit offset. As
		 the market price rises, both the stop price and the limit price rise by
		 the trail amount and limit offset respectively, but if the stock price
		 falls, the stop price remains unchanged, and when the stop price is hit a
		 limit order is submitted at the last calculated limit price. A "Buy"
		 trailing stop limit order is the mirror image of a sell trailing stop
		 limit, and is generally used in falling markets.

     Products: BOND, CFD, CASH, FUT, FOP, OPT, STK, WAR
					HERE
				end
			end

#    def TrailingStopLimit(action:str, quantity:float, lmtPriceOffset:float, 
#                          trailingAmount:float, trailStopPrice:float):
#    
#        # ! [trailingstoplimit]
#        order = Order()
#        order.action = action
#        order.orderType = "TRAIL LIMIT"
#        order.totalQuantity = quantity
#        order.trailStopPrice = trailStopPrice
#        order.lmtPriceOffset = lmtPriceOffset
#        order.auxPrice = trailingAmount
#        # ! [trailingstoplimit]
#        return order
#
#
		end
end
