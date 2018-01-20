
module IB
    module SimpleStop
      extend UseOrder
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
      extend UseOrder
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
      extend UseOrder
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
#  module UseOrder
    module  TrailingStop
      extend UseOrder
      class << self


      def defaults
	  super.merge order_type: :trailing_stop , tif: :day
      end

      def aliases
	Limit.aliases 
      end

      def requirements
	 super.merge trail_stop_price: 'Price to trigger the action'
		     
      end
    
      def alternative_parameters
	{ aux_price: 'Trailing distance in absolute terms',
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
      end
      end
    end
end
