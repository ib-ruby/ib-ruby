# These modules are used to facilitate referencing of most popular IB Contracts.
# For example, suppose you're explicitely creating such Contract in all your scripts:
#    wfc = IB::Contract.new(:symbol => "WFC",
#                           :exchange => "NYSE",
#                           :currency => "USD",
#                           :sec_type => :stock,
#                           :description => "Wells Fargo Stock"),
#
# Instead, you can put this contract definition into 'ib/symbols/stocks' and just reference
# it as IB::Symbols::Stock[:wfc] anywhere you need it.
#
# Note that the :description field is local to ib-ruby, and is NOT part of the standard TWS API.
# It is never transmitted to IB. It's purely used clientside, and you can store any arbitrary 
# string that you may find useful there.

module IB
  module Symbols
    def [] symbol
      raise "SYMBOL ':#{symbol}' IS NOT DEFINED!!  Please define it in lib/ib/symbols/" if contracts[symbol].nil?
      contracts[symbol]
    end
  end
end

require 'ib/symbols/forex'
require 'ib/symbols/futures'
require 'ib/symbols/stocks'
require 'ib/symbols/options'
