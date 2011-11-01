# Stock contracts definitions
#
# Note that the :description field is particular to ib-ruby, and is NOT part of the
# standard TWS API. It is never transmitted to IB. It's purely used clientside, and
# you can store any arbitrary string that you may find useful there.

module IB
  module Symbols

    Options =
        {:wfc20 => Models::Contract.new(:symbol => "WFC",
                                        :exchange => "SMART",
                                        :expiry => "201112",
                                        :right => "CALL",
                                        :strike => 20.0,
                                        :sec_type => SECURITY_TYPES[:option],
                                        :description => "Wells Fargo 20 Call 2011-12"),
         :z50 => Models::Contract.new(:symbol => "Z",
                                      :exchange => "LIFFE",
                                      :expiry => "201112",
                                      :right => "CALL",
                                      :strike => 50.0,
                                      :sec_type => SECURITY_TYPES[:option],
                                      :description => " FTSE-100 index 50 Call 2011-12"),

        }
  end
end
