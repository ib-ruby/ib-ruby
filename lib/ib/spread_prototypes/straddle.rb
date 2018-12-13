module IB

    module  Straddle
      
      extend SpreadPrototype
      class << self


#  Fabricate a Straddle from a Master-Option
#  -----------------------------------------
#  If one Leg is known, the other is simply build by flipping the right
#
#   Call with 
#   IB::Spread::Straddle.fabricate an_option
			def fabricate master

				flip_right = ->(the_right){  the_right == :put ? :call : :put   }
				error "Argument must be a IB::Option" unless master.is_a? IB::Option


				initialize_spread( master ) do | the_spread |
					the_spread.add_leg master
					the_spread.add_leg(IB::Contract.build master.attributes.merge( right: flip_right[master.right]) )
					error "Initialisation of Legs failed" if the_spread.legs.size != 2
					the_spread.description =  the_description( the_spread )
				end
			end


#  Build  Straddle out of an Underlying
#  -----------------------------------------
#  Needed attributes: :strike, :expiry 
#  
#  Optional: :trading_class, :multiplier
#
#   Call with 
#   IB::Spread::Straddle.build from: IB::Contract, strike: a_value, expiry: yyyymmm(dd) 
			def build from:, ** fields
				underlying = if from.is_a?  IB::Option
											 fields[:strike] = from.strike unless fields.key?(:strike)
											 fields[:expiry] = from.expiry unless fields.key?(:expiry)
											 fields[:multiplier] = from.multiplier unless fields.key?(:multiplier) || from.multiplier.to_i.zero?
											 details =  nil
											 from.verify{|c| details = c.contract_detail }
											 IB::Contract.new( con_id: details.under_con_id, 
																				currency: from.currency)
																			 .verify!
																			 .essential
										 else
											 from
										 end

				initialize_spread( underlying ) do | the_spread |
					leg_prototype  = IB::Option.new underlying.attributes
															.slice( :currency, :symbol, :exchange)
															.merge(defaults)
															.merge( fields )

					leg_prototype.sec_type = 'FOP' if underlying.is_a?(IB::Future)
					the_spread.add_leg IB::Contract.build leg_prototype.attributes.merge( right: :put )
					the_spread.add_leg IB::Contract.build leg_prototype.attributes.merge( right: :call )
					error "Initialisation of Legs failed" if the_spread.legs.size != 2
					the_spread.description =  the_description( the_spread )
				end
			end

      def defaults
      super.merge expiry: IB::Symbols::Futures.next_expiry 
      end


      def requirements
				super.merge strike: "the strike of both options",
									  expiry: "Expiry expressed as »yyyymm(dd)« (String or Integer) )"
      end


			def the_description spread
			 "<Straddle #{spread.symbol}(#{spread.legs.first.strike})[#{Date.parse(spread.legs.first.last_trading_day).strftime("%b %Y")}]>"
			end


      end # class
    end	# module combo
end  # module ib
