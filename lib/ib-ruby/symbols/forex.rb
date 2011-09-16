
# Note that the :description field is particular to ib-ruby, and is NOT part of the standard TWS API.
# It is never transmitted to IB. It's purely used clientside, and you can store any arbitrary string that
# you may find useful there.
module IB
  module Symbols
    Forex = {
        :audusd => Models::Contract.new(:symbol => "AUD",
                                           :exchange => "IDEALPRO",
                                           :currency => "USD",
                                           :sec_type => Models::Contract::SECURITY_TYPES[:forex],
                                           :description => "AUDUSD"),

        :gbpusd => Models::Contract.new(:symbol => "GBP",
                                           :exchange => "IDEALPRO",
                                           :currency => "USD",
                                           :sec_type => Models::Contract::SECURITY_TYPES[:forex],
                                           :description => "GBPUSD"),

        :euraud => Models::Contract.new(:symbol => "EUR",
                                           :exchange => "IDEALPRO",
                                           :currency => "AUD",
                                           :sec_type => Models::Contract::SECURITY_TYPES[:forex],
                                           :description => "EURAUD"),

        :eurgbp => Models::Contract.new(:symbol => "EUR",
                                           :exchange => "IDEALPRO",
                                           :currency => "GBP",
                                           :sec_type => Models::Contract::SECURITY_TYPES[:forex],
                                           :description => "EURGBP"),

        :eurjpy => Models::Contract.new(:symbol => "EUR",
                                           :exchange => "IDEALPRO",
                                           :currency => "JPY",
                                           :sec_type => Models::Contract::SECURITY_TYPES[:forex],
                                           :description => "EURJPY"),

        :eurusd => Models::Contract.new(:symbol => "EUR",
                                           :exchange => "IDEALPRO",
                                           :currency => "USD",
                                           :sec_type => Models::Contract::SECURITY_TYPES[:forex],
                                           :description => "EURUSD"),

        :eurcad => Models::Contract.new(:symbol => "EUR",
                                           :exchange => "IDEALPRO",
                                           :currency => "CAD",
                                           :sec_type => Models::Contract::SECURITY_TYPES[:forex],
                                           :description => "EURCAD"),

        :usdchf => Models::Contract.new(:symbol => "USD",
                                           :exchange => "IDEALPRO",
                                           :currency => "CHF",
                                           :sec_type => Models::Contract::SECURITY_TYPES[:forex],
                                           :description => "USDCHF"),

        :usdcad => Models::Contract.new(:symbol => "USD",
                                           :exchange => "IDEALPRO",
                                           :currency => "CAD",
                                           :sec_type => Models::Contract::SECURITY_TYPES[:forex],
                                           :description => "USDCAD"),

        :usdjpy => Models::Contract.new(:symbol => "USD",
                                           :exchange => "IDEALPRO",
                                           :currency => "JPY",
                                           :sec_type => Models::Contract::SECURITY_TYPES[:forex],
                                           :description => "USDJPY")
    }
  end # Contracts
end
