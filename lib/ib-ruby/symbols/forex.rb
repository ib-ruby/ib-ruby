# Note that the :description field is particular to ib-ruby, and is NOT part of the
# standard TWS API. It is never transmitted to IB. It's purely used clientside, and
# you can store any arbitrary string that you may find useful there.
module IB
  module Symbols
    # IDEALPRO is for orders over 25,000 and routes to the interbank quote stream.
    # IDEAL is for smaller orders, and has wider spreads/slower execution... generally
    # used for smaller currency conversions.
    Forex = {
        :audusd => IB::Contract.new(:symbol => "AUD",
                                    :exchange => "IDEALPRO",
                                    :currency => "USD",
                                    :sec_type => SECURITY_TYPES[:forex],
                                    :description => "AUDUSD"),

        :gbpusd => IB::Contract.new(:symbol => "GBP",
                                    :exchange => "IDEALPRO",
                                    :currency => "USD",
                                    :sec_type => SECURITY_TYPES[:forex],
                                    :description => "GBPUSD"),

        :euraud => IB::Contract.new(:symbol => "EUR",
                                    :exchange => "IDEALPRO",
                                    :currency => "AUD",
                                    :sec_type => SECURITY_TYPES[:forex],
                                    :description => "EURAUD"),

        :eurgbp => IB::Contract.new(:symbol => "EUR",
                                    :exchange => "IDEALPRO",
                                    :currency => "GBP",
                                    :sec_type => SECURITY_TYPES[:forex],
                                    :description => "EURGBP"),

        :eurjpy => IB::Contract.new(:symbol => "EUR",
                                    :exchange => "IDEALPRO",
                                    :currency => "JPY",
                                    :sec_type => SECURITY_TYPES[:forex],
                                    :description => "EURJPY"),

        :eurusd => IB::Contract.new(:symbol => "EUR",
                                    :exchange => "IDEALPRO",
                                    :currency => "USD",
                                    :sec_type => SECURITY_TYPES[:forex],
                                    :description => "EURUSD"),

        :eurcad => IB::Contract.new(:symbol => "EUR",
                                    :exchange => "IDEALPRO",
                                    :currency => "CAD",
                                    :sec_type => SECURITY_TYPES[:forex],
                                    :description => "EURCAD"),

        :usdchf => IB::Contract.new(:symbol => "USD",
                                    :exchange => "IDEALPRO",
                                    :currency => "CHF",
                                    :sec_type => SECURITY_TYPES[:forex],
                                    :description => "USDCHF"),

        :usdcad => IB::Contract.new(:symbol => "USD",
                                    :exchange => "IDEALPRO",
                                    :currency => "CAD",
                                    :sec_type => SECURITY_TYPES[:forex],
                                    :description => "USDCAD"),

        :usdjpy => IB::Contract.new(:symbol => "USD",
                                    :exchange => "IDEALPRO",
                                    :currency => "JPY",
                                    :sec_type => SECURITY_TYPES[:forex],
                                    :description => "USDJPY")
    }
  end
end
