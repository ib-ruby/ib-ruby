# These modules are used to facilitate referencing of most popular IB Contracts.
# Like pages in the TWS-GUI, theya can be utilised to organise trading and research.
#
# Symbol Allocations are organized as modules. They represent the contents of yaml files in
#
#		ib-ruby-root/symbols/
#
#	Any collection is represented as simple Hash, with  __key__ as qualifier and an __IB::Contract__ as value.
#	The Value is either a fully prequalified Contract  (Stock, Option, Future, Forex, CFD, BAG) or
#	a lazy qualified Contract acting as base für further calucaltions and requests.
#
#		IB::Symbols.allocate_collection :Name
#
# creates the Module and file. If a previously created file is found, its contents are read and
# the vcollection ist reestablished.
#
#		IB::Symbols::Name.add_contract :wfc, IB::Stock.new( symbol: 'WFC' )
#
#	adds the contract and stores it in the yaml file
#
#	  IB::Symbols::Name.wfc   # or  IB::Symbols::Name[:wfc]
#
#	retrieves the contract
#
#		IB::Symbols::Name.all 
#
#	returns an Array of stored contracts
#
#		IB::Symbols::Name.remove_contract :wfc
#
# deletes the contract from the list (and the file)
#
# To finish the cycle
#
#		IB::Symbols::Name.purge_collection
#
#	deletes the file and erases the collection in memory.
#
#	Additional methods can be introduced 
#		* for individual contracts on the module-level or
#		* to organize the list as methods of Array in  Module IB::SymbolExtention
#
#
# Contracts can be hardcoded in the required standard-collections as well.
# Note that the :description field is local to ib-ruby, and is NOT part of the standard TWS API.
# It is never transmitted to IB. It's purely used clientside, and you can store any arbitrary
# string that you may find useful there.

module IB
#  module SymbolExtention  # method_missing may not be refined
#    refine Array do
#      def method_missing(method, *key)
#	unless method == :to_hash || method == :to_str #|| method == :to_int
#	  return self.map{|x| x.public_send(method, *key)}
#	end
#      end
#    end
#  end 

  module Symbols
#    using SymbolExtention


		def hardcoded?
			!self.methods.include? :yml_file
		end
		def method_missing(method, *key)
			if key.empty? 
				if contracts.has_key?(method)
					contracts[method]
					elsif methods.include?(:each) && each.methods.include?(method)
							self.each.send method  				
					else
					error "contract #{method} not defined. Try »all« for a list of defined Contracts.", :symbol
				end
			else
				error "method missing"
			end
		end

		def all
			contracts.keys.sort rescue contracts.keys
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
			if c=contracts[symbol]
				return c
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
require 'ib/symbols/abstract'
