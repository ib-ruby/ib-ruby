module IB

    module  Calendar
      
      extend SpreadPrototype
      class << self


#  Fabricate a Calendar-Spread from a Master-Option
#  -----------------------------------------
#  If one Leg is known, the other is build by just changing the expiry
#  The second leg is always SOLD !
#
#   Call with 
#   IB::Calendar.fabricate  an_option, the_other_expiry
			def fabricate master, the_other_expiry

				error "Argument must be a IB::Future or IB::Option" unless master.is_a? IB::Future || master.is_a?( IB::Future )

				initialize_spread( master ) do | the_spread |
					the_spread.add_leg master, action: :buy
					
					the_other_expiry =  the_other_expiry.values.first if the_other_expiry.is_a?(Hash)
					back = the_spread.transform_distance master.expiry, the_other_expiry
					the_spread.add_leg IB::Contract.build( master.attributes.merge(expiry: back )), action: :sell
					error "Initialisation of Legs failed" if the_spread.legs.size != 2
					the_spread.description =  the_description( the_spread )
				end
			end


#  Build  Vertical out of an Underlying
#  -----------------------------------------
#  Needed attributes: :strikes, :expiry, right
#  
#  Optional: :trading_class, :multiplier
#
#   Call with 
#   IB::Calendar.build from: IB::Contract,	front: an_expiry,  back: an_expiry, 
#																						right: {put or call}, strike: a_strike 
			def build from:, **fields
				underlying = if from.is_a?  IB::Option
											 fields[:right] = from.right unless fields.key?(:right) 
											 fields[:front] = from.expiry unless fields.key(:front)
											 fields[:strike] = from.strike unless fields.key?(:strike)
											 fields[:expiry] = from.expiry unless fields.key?(:expiry)
											 fields[:trading_class] = from.trading_class unless fields.key?(:trading_class) || from.trading_class.empty?
											 fields[:multiplier] = from.multiplier unless fields.key?(:multiplier) || from.multiplier.to_i.zero?
											 details =  nil; from.verify{|c| details = c.contract_detail }
											 IB::Contract.new( con_id: details.under_con_id, 
																				currency: from.currency)
																			 .verify!
																			 .essential
										 else
											 from
										 end
				kind = { :front => fields.delete(:front), :back => fields.delete(:back) }
				error "Specifiaction of :front and :back expiries nessesary, got: #{kind.inspect}" if kind.values.any?(nil)
				initialize_spread( underlying ) do | the_spread |
					leg_prototype  = IB::Option.new underlying.attributes
															.slice( :currency, :symbol, :exchange)
															.merge(defaults)
															.merge( fields )
					kind[:back] = the_spread.transform_distance kind[:front], kind[:back]
					leg_prototype.sec_type = 'FOP' if underlying.is_a?(IB::Future)
					the_spread.add_leg IB::Contract.build( leg_prototype.attributes.merge(expiry: kind[:front] )), action: :buy
					the_spread.add_leg IB::Contract.build( leg_prototype.attributes.merge(expiry: kind[:back])), action: :sell
					error "Initialisation of Legs failed" if the_spread.legs.size != 2
					the_spread.description =  the_description( the_spread )
				end
			end

      def defaults
      super.merge expiry: IB::Symbols::Futures.next_expiry, 
									right: :put
      end


			def the_description spread
			x= [ spread.combo_legs.map(&:weight) , spread.legs.map( &:last_trading_day )].transpose
			 "<Calendar #{spread.symbol} #{spread.legs.first.right}(#{spread.legs.first.strike})[#{x.map{|w,l_t_d| "#{w} :#{Date.parse(l_t_d).strftime("%b %Y")} "}.join( '|+|' )} >"
			end
		 end # class
    end	# module vertical
end  # module ib
