# Option contracts definitions.
# TODO: add next_expiry and other convenience from Futures module.
module IB
  module Symbols
    module Options
      extend Symbols

      def self.contracts
        @contracts ||= {
          :wfc20 => IB::Option.new(:symbol => "WFC",
                                   :expiry => "201301",
                                   :right => "CALL",
                                   :strike => 20.0,
                                   :description => "Wells Fargo 20 Call 2013-01"),
          :aapl500 => IB::Option.new(:symbol => "AAPL",
                                     :expiry => "201301",
                                     :right => "CALL",
                                     :strike => 500,
                                     :description => "Apple 500 Call 2013-01"),
          :z50 => IB::Option.new(:symbol => "Z",
                                 :exchange => "LIFFE",
                                 :expiry => "201301",
                                 :right => "CALL",
                                 :strike => 50.0,
                                 :description => " FTSE-100 index 50 Call 2013-03"),
          :spy75 => IB::Option.new(:symbol => 'SPY',
                                   :expiry => "201301",
                                   :right => "P",
                                   :currency => "USD",
                                   :strike => 75.0,
                                   :description => "SPY 75.0 Put 2014-01"),
          :spy100 => IB::Option.new(:osi => 'SPY 140118P00100000'),
          :vix20 => IB::Option.new(:osi =>  'VIX 121121C00020000'),
          :vxx40 => IB::Option.new(:osi =>  'VXX 121117C00040000'),
        }
      end
    end
  end
end
