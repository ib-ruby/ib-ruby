module IB
#  module OrderPrototype
    module AtAuction
      extend OrderPrototype
      class << self

      def defaults
	{ order_type: 'MTL' , tif: "AUC"}
      end

      def aliases
	super.merge  limit_price: :price 
      end

      def requirements
	super.merge limit_price: :decimal 
      end


      def summary
	<<-HERE
	An auction order is entered into the electronic trading system during the pre-market
	opening period for execution at the Calculated Opening Price (COP).
	If your order is not filled on the open, the order is re-submitted as a
	limit order with the limit price set to the COP or the best bid/ask after the market opens.
	Products: FUT, STK
	HERE
      end
      end
    end
end
