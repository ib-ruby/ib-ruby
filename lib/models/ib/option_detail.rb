module IB

  # Additional Option properties and Option-Calculations
  class OptionDetail < IB::Model
    include BaseProperties

    prop :delta,  :gamma, :vega, :theta, # greeks
         :implied_volatility,
	 :pv_dividend, # anticipated Dividend
	 :under_price,  # price of the Underlying
	 :option_price,
	 :close_price,
	 :open_tick,
	 :bid_price,
	 :ask_price,
	 :prev_strike,
	 :next_strike,
	 :prev_expiry,
	 :next_expiry,
	 :option_price
    belongs_to :option

    # returns true if all datafields are filled with reasonal data
    def complete?
     fields= [ :delta,  :gamma, :vega, :theta,
         :implied_volatility, :pv_dividend, :open_tick,
	 :under_price, :option_price, :close_price, :bid_price, :ask_price]

      !fields.detect{|y| self.send(y).nil?}

    end

    def greeks?
     fields= [ :delta,  :gamma, :vega, :theta,
         :implied_volatility, :pv_dividend]

      !fields.detect{|y| self.send(y).nil?}

    end

    def to_human
      outstr= ->( item ) { if item.nil? then "--" else  sprintf("%g" , item)  end  }
      att = " optionPrice: #{ outstr[ option_price ]}, UnderlyingPrice: #{ outstr[ under_price] } impl.Vola: #{ outstr[ implied_volatility ]} ; dividend: #{ outstr[ pv_dividend ]}; "
      greeks = "Greeks::  delta:  #{ outstr[ delta ] }; gamma: #{ outstr[ gamma ]}, vega: #{ outstr[ vega ] }; theta: #{ outstr[ theta ]}" 
      prices= " close: #{ outstr[ close_price ]}; bid: #{ outstr[ bid_price ]}; ask: #{ outstr[ ask_price ]} "
      if	complete?
	"< "+ prices + "\n" + att + "\n" + greeks + " >"
      else
	"< " + greeks + " >"
      end

    end

  end  # class
end # module
