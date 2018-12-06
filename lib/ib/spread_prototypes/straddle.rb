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
											 fields[:strike] = from.strike unless fields.has_key?(:strike)
											 fields[:expiry] = from.expiry unless fields.has_key?(:expiry)
											 fields[:multiplier] = from.multiplier unless fields.has_key?(:multiplier) || from.multiplier.to_i.zero?
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
					the_spread.add_leg IB::Contract.build leg_prototype.attributes.merge( right: :put )
					the_spread.add_leg IB::Contract.build leg_prototype.attributes.merge( right: :call )
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

		



		def make  master=nil, 
										underlying: nil, 
										strike: 0, 
										expiry: IB::Symbols::Futures.next_expiry, 
										**args  # trading-class and others

			master_option, msg = if master.present? 
															if master.is_a?(IB::Option)
																[ master.essential, nil ]
															else
																[ nil, "First Argument is no IB::Option" ]
															end
														elsif underlying.present?
															if underlying.is_a?(IB::Contract)
																master = IB::Option.new underlying.attributes.slice( :currency, :symbol, :exchange ).merge(args)
																master.sec_type = 'FOP' if underlying.is_a?(IB::Future)
																master.strike, master.expiry = strike , expiry
																[master, strike.zero? ? "strike has to be specified" : nil]
															else
																[nil, "Underlying has to be an IB::Contract"]
															end
														else
															[ nil, "Required parameters: Master-Option or Underlying, strike, expiry" ]  
														end

			error msg, :args, nil  if msg.present?
			master_option.trading_class = args[:trading_class] if args[:trading_class].present?
			master_option.right = nil; master_option.con_id = 0;
			l=[] ; master_option.verify{|x| x.contract_detail= nil; l << x }
			if l.size < 2
				error "Invalid Parameters. Two legs are required, \n Verifiying the master-option exposed #{l.size} legs", :args, nil 
			elsif l.size > 2
				Connection.logger.error "ambigous contract-specification: #{l.map(&:to_human).join(';')}"
				available_trading_classes = l.map( &:trading_class ).uniq
				if available_trading_classes.size >1
					error "Refine Specification with trading_class: #{available_trading_classes.join('; ')} "
				else
					error "Respecify :: expiry, verification reveals #{l.size} contracts  (only 2 are allowed)"
				end
			end

			master_option.exchange ||= l.first.exchange
			master_option.currency ||= l.first.currency

			c_l = l.map{ |l| ComboLeg.new con_id: l.con_id, action: :buy, exchange: l.exchange, ratio: 1 }
			IB::Spread.new  exchange: master_option.exchange, 
							 symbol: master_option.symbol.to_s ,
						 currency: master_option.currency,
						 legs: l,
						 combo_legs: c_l
		end
		def to_human
			 "<Straddle #{symbol}(#{legs.first.strike})[#{Date.parse(legs.first.last_trading_day).strftime("%b %Y")}]>"
		end
      end # class
    end	# module combo
end  # module ib
