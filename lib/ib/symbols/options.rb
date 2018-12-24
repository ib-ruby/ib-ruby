# Option contracts definitions.
# TODO: add next_expiry and other convenience from Futures module.
# Notice:  OSI-Notation is broken
module IB
  module Symbols
    module Options
      extend Symbols

      def self.contracts
        @contracts ||= {
					stoxx_3000:  IB::Option.new(  symbol: :Estx50, strike: 3000, 
																			  expiry: IB::Symbols::Futures.next_expiry , 
																				right: :put, 
																				trading_class: 'OESX', 
																				currency: 'EUR', exchange: 'DTB',
																		 description: "ESTX50 3000 Put quarterly"),
					:ge20 => IB::Option.new(:symbol => "GE",
																	:expiry => "20190118",  # use fully qualified expiry, to cover contract-info integration test
																	:right => "CALL",
																	:strike => 13,
																	:multiplier => 100,
																	:currency => 'USD',
																	:description => "General Electric 20 Call 2019-01"),
					:aapl200 => IB::Option.new(:symbol => "AAPL", exchange: 'SMART',
																		 :expiry => "20190118",
																		 :right => "C",
																		 :strike => 180,
																		 :currency => 'USD',
																		 :description => "Apple 200 Call 2019-01"),
          :z750 => IB::Option.new(:symbol => "Z",
                                 :exchange => "ICEEU",
                                 :expiry => "201903",
                                 :right => "CALL",
                                 :strike => 7000.0,
																 :description => " FTSE-100 index 750 Call 2019-03"),
			:ibm_lazy_expiry => IB::Option.new( symbol: 'IBM', right: :put, strike: 140,
																				 description: 'IBM-Option Chain with strike 140'),
			:ibm_lazy_strike => IB::Option.new( symbol: 'IBM', right: :put, expiry: IB::Symbols::Futures.next_expiry ,
																				 description: 'IBM-Option Chain ( quarterly expiry)'),

	    :goog1100 => IB::Option.new( symbol: 'GOOG',
				  strike: 1100,
				  multiplier: 100,
				  right: :call,
				  expiry:  IB::Symbols::Futures.next_expiry,
				  description: 'Google Call Option with quarterly expiry'),
	  :argo_ise => Option.new( symbol: 'ARGO',
				  currency: "USD",
				  exchange: "ISE",
				  expiry:  IB::Symbols::Futures.next_expiry,
				  right: :call,
				  strike: 10,
				  multiplier: 100,
				  description: 'Adecoagro Options @ ISE'),
		:san_eu => IB::Option.new(  symbol: 'SAN1',
					exchange: "MEFFRV",
					currency: "EUR",
					expiry:  IB::Symbols::Futures.next_expiry,
					strike: 4.5,
					right: :call,
#					multiplier: 100,  ## non standard multiplier: 102
					trading_class: "SANEU",
					description: 'Santanter Option specified via Trading-Class'),
			:spy75 => IB::Option.new(:symbol => 'SPY',
                                   :expiry => IB::Symbols::Futures.next_expiry,
                                   :right => "P",
                                   :currency => "USD",
                                   :strike => 75.0,
                                   :description => "SPY 75.0 Put next expiration"),
#          :spy270 => IB::Option.new(:osi => 'SPY 190315P002700000'),
#          :vix20 => IB::Option.new(:osi =>  'VIX 181121C00020000'),
#          :vxx40 => IB::Option.new(:osi =>  'VXX 181117C00040000'),
        }
      end
    end
  end
end
