
module IB
    module Limit
      extend OrderPrototype
      class << self

      def defaults
	  super.merge order_type: :limit 
      end

      def aliases
	super.merge  limit_price: :price 
      end

      def requirements
	super.merge limit_price: "also aliased as :price"
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
      extend OrderPrototype
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
#  module OrderPrototype
    module  Sweep2Fill
      extend OrderPrototype
      class << self

      def defaults
	  super.merge order_type: ':limit' , tif: :day, sweep_to_fill: true
      end

      def aliases
	Limit.aliases 
      end

      def requirements
	Limit.requirements
      end


      def summary
	<<-HERE
	Sweep-to-fill orders are useful when a trader values speed of execution over price. A sweep-to-fill
	order identifies the best price and the exact quantity offered/available at that price, and 
	transmits the corresponding portion of your order for immediate execution. Simultaneously it 
	identifies the next best price and quantity offered/available, and submits the matching quantity 
	of your order for immediate execution.

	------------------------
        Products: CFD, STK, WAR (SMART only)

	HERE
      end
      end
    end
    module  LimitIfTouched
      extend OrderPrototype
      class << self

      def defaults
	  Limit.defaults.merge order_type: :limit_if_touched
      end

      def aliases
	Limit.aliases.merge  aux_price: :trigger_price 
      end

      def requirements
	Limit.requirements.merge aux_price: 'also aliased as :trigger_price ' 
      end


      def summary
	<<-HERE
	A Limit if Touched is an order to buy (or sell) a contract at a specified price or better, 
	below (or above) the market. This order is held in the system until the trigger price is touched. 
	An LIT order is similar to a stop limit order, except that an LIT sell order is placed above 
	the current market price, and a stop limit sell order is placed below. 
	HERE
      end
      end
    end


    module  LimitOnClose
      extend OrderPrototype
      class << self

      def defaults
	  Limit.defaults.merge order_type: :limit_on_close 
      end

      def aliases
	Limit.aliases 
      end

      def requirements
	Limit.requirements 
      end


      def summary
	<<-HERE
	A Limit-on-close (LOC) order will be submitted at the close and will execute if the 
	closing price is at or better than the submitted limit price. 
	HERE
      end
      end
    end
    
    module  LimitOnOpen
      extend OrderPrototype
      class << self

      def defaults
	  super.merge order_type: :limit_on_open , tif: :opening_price
      end

      def aliases
	Limit.aliases 
      end

      def requirements
	Limit.requirements
      end


      def summary
	<<-HERE
	A Limit-on-Open (LOO) order combines a limit order with the OPG time in force to create an 
	order that is submitted at the market's open, and that will only execute at the specified 
	limit price or better. Orders are filled in accordance with specific exchange rules. 
	HERE
      end
      end
    end
 # end
end
