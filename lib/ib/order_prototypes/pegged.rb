module IB
    module  Pegged2Primary
      extend OrderPrototype
      class << self

    def defaults
	  super.merge order_type: 'REL' , tif: :day
    end

      def aliases
	super.merge  limit_price: :price_cap, aux_price: :offset_amount
      end

      def requirements
	super.merge aux_price: 'also aliased as :offset_amount',
		    limit_price: 'aliased as :price_cap'
      end

      def optional
	 super
      end

      def summary
	<<-HERE
	Relative (a.k.a. Pegged-to-Primary) orders provide a means for traders
	to seek a more aggressive price than the National Best Bid and Offer
	(NBBO). By acting as liquidity providers, and placing more aggressive
	bids and offers than the current best bids and offers, traders increase
	their odds of filling their order. Quotes are automatically adjusted as
	the markets move, to remain aggressive. For a buy order, your bid is
	pegged to the NBB by a more aggressive offset, and if the NBB moves up,
	your bid will also move up. If the NBB moves down, there will be no
	adjustment because your bid will become even more aggressive and
	execute. For sales, your offer is pegged to the NBO by a more
	aggressive offset, and if the NBO moves down, your offer will also move
	down. If the NBO moves up, there will be no adjustment because your
	offer will become more aggressive and execute. In addition to the
	offset, you can define an absolute cap, which works like a limit price,
	and will prevent your order from being executed above or below a
	specified level. 
	Supported Products:  Stocks, Options and Futures
	------ 
	not available on paper trading 
	HERE
      end
      end
    end
    module  Pegged2Market
      extend OrderPrototype
      class << self

    def defaults
	  super.merge order_type: 'PEG MKT' , tif: :day
    end

      def aliases
	Limit.aliases.merge  aux_price: :market_offset
      end

      def requirements
	super.merge aux_price: :decimal
      end

      def optional
	 super
      end

      def summary
	<<-HERE
	A pegged-to-market order is designed to maintain a purchase price relative to the
	national best offer (NBO) or a sale price relative to the national best bid (NBB).
	Depending on the width of the quote, this order may be passive or aggressive.
	The trader creates the order by entering a limit price which defines the worst limit
	price that they are willing to accept.
	Next, the trader enters an offset amount which computes the active limit price as follows:
	   Sell order price = Bid price + offset amount
	   Buy order price = Ask price - offset amount
	HERE
      end
      end
    end

    module  Pegged2Stock
      extend OrderPrototype
      class << self

    def defaults
	  super.merge order_type: 'PEG STK' 
    end

      def aliases
	Limit.aliases.merge  limit_price: :stock_reference_price
      end

      def requirements
	super.merge total_quantity: :decimal, 
		    delta: 'required Delta of the Option', 
		    starting_price: 'initial Limit-Price for the Option' 
      end

      def optional
	 super.merge limit_price: 'Stock Reference Price',
	   stock_ref_price: '',
	   stock_range_lower: 'Lowest acceptable Stock Price',
	   stock_range_upper: 'Highest accepable Stock Price'
      end

      def summary
	<<-HERE
	Options ONLY
	------------
	A Pegged to Stock order continually adjusts the option order price by the product of a signed user-
	defined delta and the change of the option's underlying stock price. 
	The delta is entered as an absolute and assumed to be positive for calls and negative for puts.
	A buy or sell call order price is determined by adding the delta times a change in an underlying stock
	price to a specified starting price for the call.
	To determine the change in price, the stock reference price is subtracted from the current NBBO 
	midpoint. The Stock Reference Price can be defined by the user, or defaults to the 
	the NBBO midpoint at the time of the order if no reference price is entered.
	You may also enter a high/low stock price range which cancels the order when reached. The 
	delta times the change in stock price will be rounded to the nearest penny in favor of the order.
	------------
	Supported Exchanges: (as of Jan 2018):  BOX, NASDAQOM, PHLX
	HERE
      end
      end
    end

    module  Pegged2Benchmark
      extend OrderPrototype
      class << self

    def defaults
	  super.merge order_type: 'PEG BENCH' 
    end





      def requirements
	super.merge total_quantity: :decimal, 
		    delta: 'required Delta of the Option', 
		    starting_price: 'initial Limit-Price for the Option' ,
		    is_pegged_change_amount_decrease: 'increase(true) / decrease(false) Price',
		    pegged_change_amount: ' (increase/decrceas) by... (and likewise for price moving in opposite direction)',
		    reference_change_amount: ' ... whenever there is a price change of...',
		    reference_contract_id: 'the conid of the reference contract',
		    reference_exchange: "Exchange of the reference contract"


		  


      end

      def optional
	 super.merge stock_ref_price: 'starting price of the reference contract',
	   stock_range_lower: 'Lowest acceptable  Price of the reference contract',
	   stock_range_upper: 'Highest accepable  Price of the reference contract'
      end

      def summary
	<<-HERE
	The Pegged to Benchmark order is similar to the Pegged to Stock order for options, 
	except that the Pegged to Benchmark allows you to specify any asset type as the 
	reference (benchmark) contract for a stock or option order. Both the primary and 
	reference contracts must use the same currency. 
	HERE
      end
      end
    end
end
