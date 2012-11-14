# Frequently used stock contracts definitions
# TODO: auto-request :ContractDetails from IB if unknown symbol is requested?
module IB
  module Symbols
    module Stocks
      extend Symbols

      def self.contracts
        @contracts ||= {
          :aapl => IB::Contract.new(:symbol => "AAPL",
                                    :currency => "USD",
                                    :sec_type => :stock,
                                    :description => "Apple Inc."),

          :vxx => IB::Contract.new(:symbol => "VXX",
                                   :exchange => "ARCA",
                                   # :currency => "USD",
                                   :sec_type => :stock,
                                   :description => "iPath S&P500 VIX short term Futures ETN"),

          :wfc => IB::Contract.new(:symbol => "WFC",
                                   :exchange => "NYSE",
                                   :currency => "USD",
                                   :sec_type => :stock,
                                   :description => "Wells Fargo"),

          :wrong => IB::Contract.new(:symbol => "QEEUUE",
                                     :exchange => "NYSE",
                                     :currency => "USD",
                                     :sec_type => :stock,
                                     :description => "Non-existent stock"),
        }
      end

    end
  end
end
