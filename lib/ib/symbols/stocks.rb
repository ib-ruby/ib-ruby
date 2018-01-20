# Frequently used stock contracts definitions
# TODO: auto-request :ContractDetails from IB if unknown symbol is requested?
module IB
  module Symbols
    module Stocks
      extend Symbols

      def self.contracts
        @contracts ||= {
          :aapl => IB::Stock.new(:symbol => "AAPL",
                                    :currency => "USD",
                                    :description => "Apple Inc."),

          :vxx => IB::Stock.new(:symbol => "VXX",
                                   :exchange => "ARCA",
                                   # :currency => "USD",
                                   :description => "iPath S&P500 VIX short term Futures ETN"),

          :wfc => IB::Stock.new(:symbol => "WFC",
                                   :exchange => "NYSE",
                                   :currency => "USD",
                                   :description => "Wells Fargo"),

          :wrong => IB::Stock.new(:symbol => "QEEUUE",
                                     :exchange => "NYSE",
                                     :currency => "USD",
                                     :description => "Non-existent stock"),
        }
      end

    end
  end
end
