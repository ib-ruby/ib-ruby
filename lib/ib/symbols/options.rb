# Option contracts definitions
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
                                 :expiry => "201206",
                                 :right => "CALL",
                                 :strike => 50.0,
                                 :description => " FTSE-100 index 50 Call 2012-06"),
          :spy75 => IB::Option.new(:symbol => 'SPY',
                                   :expiry => "20120615",
                                   :right => "P",
                                   :currency => "USD",
                                   :strike => 75.0,
                                   :description => "SPY 75.0 Put 2012-06-16"),
          :spy100 => IB::Option.new(:osi => 'SPY 121222P00100000'),
        }
      end
    end
  end
end
