module IB
  module Symbols
    module Forex
      extend Symbols

      # IDEALPRO is for orders over 25,000 and routes to the interbank quote stream.
      # IDEAL is for smaller orders, and has wider spreads/slower execution... generally
      # used for smaller currency conversions.
      def self.contracts
        @contracts ||= {
          :audusd => IB::Contract.new(:symbol => "AUD",
                                      :exchange => "IDEALPRO",
                                      :currency => "USD",
                                      :sec_type => :forex,
                                      :description => "AUDUSD"),

          :gbpusd => IB::Contract.new(:symbol => "GBP",
                                      :exchange => "IDEALPRO",
                                      :currency => "USD",
                                      :sec_type => :forex,
                                      :description => "GBPUSD"),

          :euraud => IB::Contract.new(:symbol => "EUR",
                                      :exchange => "IDEALPRO",
                                      :currency => "AUD",
                                      :sec_type => :forex,
                                      :description => "EURAUD"),

          :eurgbp => IB::Contract.new(:symbol => "EUR",
                                      :exchange => "IDEALPRO",
                                      :currency => "GBP",
                                      :sec_type => :forex,
                                      :description => "EURGBP"),

          :eurjpy => IB::Contract.new(:symbol => "EUR",
                                      :exchange => "IDEALPRO",
                                      :currency => "JPY",
                                      :sec_type => :forex,
                                      :description => "EURJPY"),

          :eurusd => IB::Contract.new(:symbol => "EUR",
                                      :exchange => "IDEALPRO",
                                      :currency => "USD",
                                      :sec_type => :forex,
                                      :description => "EURUSD"),

          :eurcad => IB::Contract.new(:symbol => "EUR",
                                      :exchange => "IDEALPRO",
                                      :currency => "CAD",
                                      :sec_type => :forex,
                                      :description => "EURCAD"),

          :usdchf => IB::Contract.new(:symbol => "USD",
                                      :exchange => "IDEALPRO",
                                      :currency => "CHF",
                                      :sec_type => :forex,
                                      :description => "USDCHF"),

          :usdcad => IB::Contract.new(:symbol => "USD",
                                      :exchange => "IDEALPRO",
                                      :currency => "CAD",
                                      :sec_type => :forex,
                                      :description => "USDCAD"),

          :usdjpy => IB::Contract.new(:symbol => "USD",
                                      :exchange => "IDEALPRO",
                                      :currency => "JPY",
                                      :sec_type => :forex,
                                      :description => "USDJPY")
        }
      end
    end
  end
end
