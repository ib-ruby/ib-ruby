# Stock contracts definitions
module IB
  module Symbols
    module Stocks
      extend Symbols

      def self.contracts
        @contracts ||= {
          :wfc => IB::Contract.new(:symbol => "WFC",
                                   :exchange => "NYSE",
                                   :currency => "USD",
                                   :sec_type => :stock,
                                   :description => "Wells Fargo"),

          :aapl => IB::Contract.new(:symbol => "AAPL",
                                    :currency => "USD",
                                    :sec_type => :stock,
                                    :description => "Apple Inc."),

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
