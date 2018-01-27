# These modules are used to facilitate referencing of most popular IB Contracts.
# For example, suppose you're explicitly creating such Contract in all your scripts:
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
  module SymbolExtention
    refine Array do
      def method_missing(method, *key)
	unless method == :to_hash || method == :to_str #|| method == :to_int
	  return self.map{|x| x.public_send(method, *key)}
	end
      end
    end
  end 

  module Symbols
    using SymbolExtention

  #  def contracts
  #    if @contracts.present? 
  #        @contracts
  #    else
  #       @contrats= HashWithindifferentAccess.new
  #    end
  #  end
      def method_missing(method, *key)
	if key.empty? 
	  if contracts.has_key?(method)
	    contracts[method]
	  else
	    error "contract #{method} not defined. Try »all« for a list of defined Contracts."
	  end
	else
	  error "method missing"
	end
      end

      def all
	contracts.keys.sort
      end
      def print_all
	puts contracts.sort.map{|x,y| [x,y.description].join(" -> ")}.join "\n"
      end
      def contracts
	if @contracts.present?
	  @contracts
	else
	  @contracts = Hash.new
	end
      end
    def [] symbol
      if contracts[symbol]
        return contracts[symbol]
      else
        # symbol probably has not been predefined, tell user about it
        file = self.to_s.split(/::/).last.downcase
        msg = "Unknown symbol :#{symbol}, please pre-define it in lib/ib/symbols/#{file}.rb"
        error msg, :symbol
      end
    end
  end
end

require 'ib/symbols/forex'
require 'ib/symbols/futures'
require 'ib/symbols/stocks'
require 'ib/symbols/index'
require 'ib/symbols/cfd'
require 'ib/symbols/commodity'
require 'ib/symbols/options'
require 'ib/symbols/combo'
require 'ib/symbols/bonds'
