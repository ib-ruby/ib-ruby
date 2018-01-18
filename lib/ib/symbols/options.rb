# Option contracts definitions.
# TODO: add next_expiry and other convenience from Futures module.
# Notice:  OSI-Notation is broken
module IB
  module Symbols
    module Options
      extend Symbols

      def self.contracts
        @contracts ||= {
          :ge20 => IB::Option.new(:symbol => "GE",
                                   :expiry => "201901",
                                   :right => "CALL",
                                   :strike => 20,
				   :currency => 'USD',
                                   :description => "General Electric 20 Call 2019-01"),
          :aapl200 => IB::Option.new(:symbol => "AAPL",
                                     :expiry => "201903",
                                     :right => "CALL",
                                     :strike => 200,
                                     :description => "Apple 200 Call 2019-03"),
          :z750 => IB::Option.new(:symbol => "Z",
                                 :exchange => "LIFFE",
                                 :expiry => "201903",
                                 :right => "CALL",
                                 :strike => 750.0,
                                 :description => " FTSE-100 index 750 Call 2019-03"),
          :spy75 => IB::Option.new(:symbol => 'SPY',
                                   :expiry => "201903",
                                   :right => "P",
                                   :currency => "USD",
                                   :strike => 75.0,
                                   :description => "SPY 75.0 Put 2019-03"),
#          :spy270 => IB::Option.new(:osi => 'SPY 190315P002700000'),
#          :vix20 => IB::Option.new(:osi =>  'VIX 181121C00020000'),
#          :vxx40 => IB::Option.new(:osi =>  'VXX 181117C00040000'),
        }
      end
    end
  end
end
