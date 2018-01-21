module IB
#  module OrderPrototype
    module Volatility
      ### todo : check  again. Order is  siently accepted, but not acknowledged
      extend OrderPrototype
      class << self

      def defaults
	{ order_type: :volatility, volatility_type: 2 }  #default is annual volatility
      end


      def requirements
	super.merge volatility:  "the desired Option implied Vola (in %)"
      end

      def aliases
	super.merge volatility: :volatility_percent
      end

      def summary
	<<-HERE
	Investors are able to create and enter Volatility-type orders for options and combinations 
	rather than price orders. Option traders may wish to trade and position for movements in the 
	price of the option determined by its implied volatility. Because implied volatility is a key
	determinant of the premium on an option, traders position in specific contract months in an 
	effort to take advantage of perceived changes in implied volatility arising before, during or 
	after earnings or when company specific or broad market volatility is predicted to change. 
	In order to create a Volatility order, clients must first create a Volatility Trader page from 
	the Trading Tools menu and as they enter option contracts, premiums will display in percentage 
	terms rather than premium. The buy/sell process is the same as for regular orders priced in 
	premium terms except that the client can limit the volatility level they are willing to pay or receive.
	--------
	Products: FOP, OPT
	HERE
      end
      end
    end
end
