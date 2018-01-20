# These modules are used to facilitate referencing of most common Ordertypes

module IB
=begin
UseOrder is the root for Order-Prototypes.

It provides a wrapper for easy defining even complex ordertypes.

The Order is build by 

IB::<UseOrder>.order

A description is available through
  
  puts IB::<UseOrder>.summary

Nessesary and optional arguments are printed by
    
  puts IB::<UseOrder>.parameters

Orders can be setup interactively

    2.5.0 :001 > d =  Discretionary.order
    Traceback (most recent call last): (..)
    IB::ArgumentError (IB::Discretionary.order -> A nessesary field is missing: 
		      action: --> {"B"=>:buy, "S"=>:sell, "T"=>:short, "X"=>:short_exempt})
    2.5.0 :002 > d =  Discretionary.order action: :buy
    IB::ArgumentError (IB::Discretionary.order -> A nessesary field is missing: 
		      total_quantity: --> also aliased as :size)
    2.5.0 :004 > d =  Discretionary.order action: :buy, size: 100
		      Traceback (most recent call last):
    IB::ArgumentError (IB::Discretionary.order -> A nessesary field is missing: limit_price: --> decimal)
  


The prototypes are defined as module. They extend UseOrder and establish singleton methods, which
can adress and extend similar methods from UseOrder. 


=end

  module UseOrder


      def order **fields
  
	# change aliases  to the original. We are modifying the fields-hash.
	fields.keys.each{|x| fields[aliases.key(x)] = fields.delete(x) if aliases.has_value?(x)}
	# inlcude defaults (arguments override defaults)
	the_arguments = defaults.merge fields
	# check if requirements are fullfilled
	nessesary = requirements.keys.detect{|y| the_arguments[y].nil?}
	if nessesary.present?
	  msg =self.name + ".order -> A nessesary field is missing: #{nessesary}: --> #{requirements[nessesary]}"
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

require 'ib/order_samples/forex'
require 'ib/order_samples/market'
require 'ib/order_samples/limit'
require 'ib/order_samples/stop'
require 'ib/order_samples/volatility'
require 'ib/order_samples/premarket'
require 'ib/order_samples/pegged'
