# These modules are used to facilitate referencing of most common Ordertypes

module IB
	module OrderPrototype


#The Module OrderPrototypes provides a wrapper to define even complex ordertypes.
#
#The Order is build by 
#
#	IB::<OrderPrototye>.order
#
#A description is available through
#
#	puts IB::<OrderPrototype>.summary
#
#Nessesary and optional arguments are printed by
#
#	puts IB::<OrderPrototype>.parameters
#
#Orders can be setup interactively
#
#		> d =  Discretionary.order
#		Traceback (most recent call last): (..)
#		IB::ArgumentError (IB::Discretionary.order -> A necessary field is missing: 
#					action: --> {"B"=>:buy, "S"=>:sell, "T"=>:short, "X"=>:short_exempt})
#		> d =  Discretionary.order action: :buy
#		IB::ArgumentError (IB::Discretionary.order -> A necessary field is missing: 
#					total_quantity: --> also aliased as :size)
#		> d =  Discretionary.order action: :buy, size: 100
#					Traceback (most recent call last):
#		IB::ArgumentError (IB::Discretionary.order -> A necessary field is missing: limit_price: --> decimal)
#
#
#
#Prototypes are defined as module. They extend OrderPrototype and establish singleton methods, which
#can adress and extend similar methods from OrderPrototype. 
#
#



		def order **fields

			# special treatment of size:  positive numbers --> buy order, negative: sell 
			if fields[:size].present? && fields[:action].blank?
				error "Size = 0 is not possible" if fields[:size].zero?
				fields[:action] = fields[:size] >0 ? :buy  : :sell
				fields[:size] = fields[:size].abs
			end
			# change aliases  to the original. We are modifying the fields-hash.
			fields.keys.each{|x| fields[aliases.key(x)] = fields.delete(x) if aliases.has_value?(x)}
			# inlcude defaults (arguments override defaults)
			the_arguments = defaults.merge fields
			# check if requirements are fullfilled
			necessary = requirements.keys.detect{|y| the_arguments[y].nil?}
			if necessary.present?
				msg =self.name + ".order -> A necessary field is missing: #{necessary}: --> #{requirements[necessary]}"
				error msg, :args, nil
			end
			if alternative_parameters.present?
				unless ( alternative_parameters.keys  & the_arguments.keys ).size == 1
					msg =self.name + ".order -> One of the alternative fields needs to be specified: \n\t:" +
						"#{alternative_parameters.map{|x| x.join ' => '}.join(" or \n\t:")}"
					error msg, :args, nil
				end
			end

			# initialise order with given attributes	
			IB::Order.new the_arguments
		end

		def alternative_parameters
			{}
		end
		def requirements
			{ action: IB::VALUES[:side], total_quantity: 'also aliased as :size' }
		end

		def defaults
			{  tif: :good_till_cancelled }
		end

		def optional
			{ account: 'Account(number) to trade on' }
		end

		def aliases
			{  total_quantity: :size }
		end

		def parameters
			the_output = ->(var){ var.map{|x| x.join(" --> ") }.join("\n\t: ")}

			"Required : " + the_output[requirements] + "\n --------------- \n" +
				"Optional : " + the_output[optional] + "\n --------------- \n" 

		end

	end
end

require 'ib/order_prototypes/forex'
require 'ib/order_prototypes/market'
require 'ib/order_prototypes/limit'
require 'ib/order_prototypes/stop'
require 'ib/order_prototypes/volatility'
require 'ib/order_prototypes/premarket'
require 'ib/order_prototypes/pegged'
require 'ib/order_prototypes/combo'
