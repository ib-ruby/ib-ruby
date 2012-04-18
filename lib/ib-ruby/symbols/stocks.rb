# Stock contracts definitions
#
# Note that the :description field is particular to ib-ruby, and is NOT part of the
# standard TWS API. It is never transmitted to IB. It's purely used clientside, and
# you can store any arbitrary string that you may find useful there.

module IB
  module Symbols

    Stocks =
        {:wfc => IB::Contract.new(:symbol => "WFC",
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
