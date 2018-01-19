
module IB
#  module UseOrder
    module  Market
      extend UseOrder
      class << self

      def defaults
	  super.merge order_type: 'MKT' , tif: :day
      end

      def aliases
	super 
      end

      def requirements
	super 
      end


      def summary
	<<-HERE
	 A Market order is an order to buy or sell at the market bid or offer price.
	 A market order may increase the likelihood of a fill and the speed of execution,
	 but unlike the Limit order a Market order provides no price protection and
	 may fill at a price far lower/higher than the current displayed bid/ask.
	HERE
      end
      end
    end
    module  MarketIfTouched
      extend UseOrder
      class << self

      def defaults
	  super.merge order_type: 'MIT' , tif: :day
      end

      def aliases
	super 
      end

      def requirements
	super 
      end


      def summary
	<<-HERE
	A Market if Touched (MIT) is an order to buy (or sell) a contract below (or above) the market.
	Its purpose is to take advantage of sudden or unexpected changes in share or other prices and
	rovides investors with a trigger price to set an order in motion.
	Investors may be waiting for excessive strength (or weakness) to cease, which might be represented
	by a specific price point.
	MIT orders can be used to determine whether or not to enter the market once a specific price level 
	has been achieved. This order is held in the system until the trigger price is touched, and
	is then submitted as a market order. An MIT order is similar to a stop order, except that an MIT 
	sell order is placed above the current market price, and a stop sell order is placed below.
	HERE
      end
      end
    end


    module  MarketOnClose
      extend UseOrder
      class << self

      def defaults
	  super.merge order_type: 'MOC' , tif: :day
      end

      def aliases
	super 
      end

      def requirements
	super 
      end


      def summary
	<<-HERE
	A Market-on-Close (MOC) order is a market order that is submitted to execute as close
	to the closing price as possible.
	HERE
      end
      end
    end
    
    module  MarketOnOpen
      extend UseOrder
      class << self

      def defaults
	  super.merge order_type: 'MOC' , tif: :opening_price
      end

      def aliases
	super 
      end

      def requirements
	super 
      end


      def summary
	<<-HERE
	A Market-on-Close (MOC) order is a market order that is submitted to execute as close
	to the closing price as possible.
	HERE
      end
      end
    end
    module Limit
      extend UseOrder
      class << self

      def defaults
	  super.merge order_type: 'LMT' 
      end

      def aliases
	super.merge  limit_price: :price 
      end

      def requirements
	super.merge limit_price: :decimal 
      end


      def summary
	<<-HERE
	A Limit order is an order to buy or sell at a specified price or better. 
	The Limit order ensures that if the order fills, it will not fill at a price less favorable than 
	your limit price, but it does not guarantee a fill. 
	It appears in the orderbook.
	HERE
      end
      end
    end
    module  Discretionary
      extend UseOrder
      class << self

    def defaults
     Limit.defaults 
    end

      def aliases
	Limit.aliases.merge  discretionary_amount: :dc
      end

      def requirements
	Limit.requirements
      end

      def optional
	 super.merge discretionary_amount: :decimal 
      end

      def summary
	<<-HERE
	A Discretionary order is a Limitorder submitted with a hidden, 
	specified 'discretionary' amount off the limit price which  may be used
	to increase the price range over which the limit order is eligible to execute.
	The market sees only the limit price.
	The discretionary amount adds to the given limit price. The main effort is
	to hide your real intentions from the public.
	HERE
      end
      end
    end
 # end
end
