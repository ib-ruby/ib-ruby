
module IB
#  module OrderPrototype
    module  Market
      extend OrderPrototype
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
      extend OrderPrototype
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
      extend OrderPrototype
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
      extend OrderPrototype
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
end
