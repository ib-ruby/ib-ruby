
# These modules are used to facilitate referencing of most common Spreads 

# Spreads are created in  two ways:
#	
#	(1) IB::Spread::{prototype}.build  from: {underlying},
#																		 trading_class: (optional)
#																		 {other specific attributes}
#
#	(2) IB::Stpread::{prototype}.fabcricate master: [one leg},
#																			{other specific attributes}
#
#	They return a freshly instantiated Spread-Object
#
module IB
	module SpreadPrototype
	

		def build from: , **fields
			
		end


		def initialize_spread ref_contract = nil, **attributes
			attributes =  ref_contract.attributes.merge attributes if ref_contract.is_a?(IB::Contract)
			the_spread = nil
			IB::Contract.new(attributes).verify do| c|	
				the_spread= IB::Spread.new  c.attributes.slice( :exchange, :symbol, :currency )
			end
			error "Initializing of Spread failed – Underling is no Contract" if the_spread.nil?
			yield the_spread if block_given?  # yield outside mutex controlled verify-environment
			the_spread  # return_value
		end

		def requirements
			{}
		end

		def defaults
			{}
		end

		def optional
			{ }
		end

		def parameters
			the_output = ->(var){ var.empty? ? "none" : var.map{|x| x.join(" --> ") }.join("\n\t: ")}

			"Required : " + the_output[requirements] + "\n --------------- \n" +
				"Optional : " + the_output[optional] + "\n --------------- \n" 

		end
	end

end
require 'ib/spread_prototypes/straddle'
require 'ib/spread_prototypes/strangle'
require 'ib/spread_prototypes/vertical'
require 'ib/spread_prototypes/calendar'
