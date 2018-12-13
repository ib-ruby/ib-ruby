module IB

    module  Vertical
      
      extend SpreadPrototype
      class << self


#  Fabricate a Vertical from a Master-Option
#  -----------------------------------------
#  If one Leg is known, the other is build by flipping the right and adjusting the strike by distance
#
#   Call with 
#   IB::Vertical.fabricate  an_option, buy: {another_strike},  (or) , :sell{another_strike} 
			def fabricate master, buy: 0, sell: 0

				error "Argument must be a IB::Option" unless master.is_a? IB::Option
				error "Unable to fabricate Vertical. Either :buy or :sell must be specified " if buy.zero? && sell.zero?

				buy =  master.strike if buy.zero? 
				sell =  master.strike if sell.zero? 
				initialize_spread( master ) do | the_spread |
					the_spread.add_leg IB::Contract.build( master.attributes.merge(strike: sell)), action: :sell
					the_spread.add_leg IB::Contract.build( master.attributes.merge(strike: buy)), action: :buy
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
#   IB::Straddle.build from: IB::Contract, buy: a_strike,  sell: a_stike, right: {put or call}, expiry: yyyymmm(dd) 
			def build from:, **fields
				underlying = if from.is_a?  IB::Option
											 fields[:right] = from.right unless fields.key?(:right) 
											 fields[:sell] = from.strike unless fields.key(:sell)
											 fields[:buy] = from.strike unless fields.key?(:buy)
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
				kind = { :buy => fields.delete(:buy), :sell => fields.delete(:sell) }
				error "Specifiaction of :buy and :sell nessesary, got: #{kind.inspect}" if kind.values.any?(nil)
				initialize_spread( underlying ) do | the_spread |
					leg_prototype  = IB::Option.new underlying.attributes
															.slice( :currency, :symbol, :exchange)
															.merge(defaults)
															.merge( fields )
					leg_prototype.sec_type = 'FOP' if underlying.is_a?(IB::Future)
					the_spread.add_leg IB::Contract.build( leg_prototype.attributes.merge(strike: kind[:sell])), action: :sell
					the_spread.add_leg IB::Contract.build( leg_prototype.attributes.merge(strike: kind[:buy] )), action: :buy
					error "Initialisation of Legs failed" if the_spread.legs.size != 2
					the_spread.description =  the_description( the_spread )
				end
			end

      def defaults
      super.merge expiry: IB::Symbols::Futures.next_expiry, 
									right: :put
      end


			def the_description spread
				x= [ spread.combo_legs.map(&:weight) , spread.legs.map( &:strike )].transpose
				"<Vertical #{spread.symbol} #{spread.legs.first.right}(#{x.map{|w,strike| "#{w} :#{strike} "}.join( '|+|' )} )[#{Date.parse(spread.legs.first.last_trading_day).strftime("%b %Y")}]>"
			end
		 end # class
    end	# module vertical
end  # module ib
