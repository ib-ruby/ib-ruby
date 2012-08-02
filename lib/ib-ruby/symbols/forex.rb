module IB
  module Symbols
    module Forex
      extend Symbols

      # IDEALPRO is for orders over 25,000 and routes to the interbank quote stream.
      # IDEAL is for smaller orders, and has wider spreads/slower execution... generally
      # used for smaller currency conversions.
      def self.contracts
        @contracts ||= {
          :audchf => IB::Contract.new(:symbol => "AUD",
                                      :exchange => "IDEALPRO",
                                      :currency => "CHF",
                                      :sec_type => :forex,
                                      :description => "AUDCHF"),

          :audjpy => IB::Contract.new(:symbol => "AUD",
                                      :exchange => "IDEALPRO",
                                      :currency => "JPY",
                                      :sec_type => :forex,
                                      :description => "AUDJPY"),

          :audnzd => IB::Contract.new(:symbol => "AUD",
                                      :exchange => "IDEALPRO",
                                      :currency => "NZD",
                                      :sec_type => :forex,
                                      :description => "AUDNZD"),

          :audusd => IB::Contract.new(:symbol => "AUD",
                                      :exchange => "IDEALPRO",
                                      :currency => "USD",
                                      :sec_type => :forex,
                                      :description => "AUDUSD"),

          :chfjpy => IB::Contract.new(:symbol => "CHF",
                                      :exchange => "IDEALPRO",
                                      :currency => "JPY",
                                      :sec_type => :forex,
                                      :description => "CHFJPY"),

          :euraud => IB::Contract.new(:symbol => "EUR",
                                      :exchange => "IDEALPRO",
                                      :currency => "AUD",
                                      :sec_type => :forex,
                                      :description => "EURAUD"),
                                      
          :eurcad => IB::Contract.new(:symbol => "EUR",
                                      :exchange => "IDEALPRO",
                                      :currency => "CAD",
                                      :sec_type => :forex,
                                      :description => "EURCAD"),
                                      
          :eurchf => IB::Contract.new(:symbol => "EUR",
                                      :exchange => "IDEALPRO",
                                      :currency => "CHF",
                                      :sec_type => :forex,
                                      :description => "EURCHF"),

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
                                      
          :gbpjpy => IB::Contract.new(:symbol => "GBP",
                                      :exchange => "IDEALPRO",
                                      :currency => "JPY",
                                      :sec_type => :forex,
                                      :description => "GBPJPY"),
                                      
          :gbpusd => IB::Contract.new(:symbol => "GBP",
                                      :exchange => "IDEALPRO",
                                      :currency => "USD",
                                      :sec_type => :forex,
                                      :description => "GBPUSD"),

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
