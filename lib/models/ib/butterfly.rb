require_relative 'contract'
module IB
	class Butterfly <   Spread

=begin
Macro-Class to simplify the definition of Butterflies

Initialize with

	butterfly = IB::Butterfly.new IB::Option.new( symbol: :estx50, strike: 3000, expiry:'201901'), front: 2850, back: 3150

or
	
	straddle =  IB::Butterfly.new underlying: Symbols::Index.stoxx,
															 strike: 2000,
															 expiry: '201901', front: 2850, back: 3150

	where :strike defines the center of the Spread.

=end

		

		def initialize  master=nil, 
										underlying: nil, 
										strike: 0, 
										expiry: IB::Symbols::Futures.next_expiry,		
										right: :put,
										front: 0, back: 0,
										**args  #  trading-class, multiplier and others

			master_option, msg = if master.present? 
															if master.is_a?(IB::Option)
																[ master.essential, nil ]
															else
																[ nil, "First Argument is no IB::Option" ]
															end
														elsif underlying.present?
															if underlying.is_a?(IB::Contract)
																master = IB::Option.new underlying.attributes
																	.slice( :currency, :symbol, :exchange, :strike, :right, :expiry )
																	.merge(args)
																master.sec_type = 'FOP' if underlying.is_a?(IB::Future)
																master.strike, master.expiry, master.right = strike , expiry, right  unless underlying.is_a? IB::Option
																[master, master.strike.zero? ? "strike has to be specified" : nil]
															else
																[nil, "Underlying has to be an IB::Contract"]
															end
														else
															[ nil, "Required parameters: Master-Option or Underlying, strike, expiry, front, back" ]  
														end

			error msg, :args, nil  if msg.present?
			master_option.trading_class = args[:trading_class] if args[:trading_class].present?
			l=[] ; master_option.verify{|x| x.contract_detail= nil; l << x }
			if l.empty?
				error "Invalid Parameters. No Contract found #{master.to_human}" 
			elsif l.size > 1
				Connection.logger.error "ambigous contract-specification: #{l.map(&:to_human).join(';')}"
				available_trading_classes = l.map( &:trading_class ).uniq
				if available_trading_classes.size >1
					error "Refine Specification with trading_class: #{available_trading_classes.join('; ')} "
				else
					error "Respecify expiry, verification reveals #{l.size} contracts  (only 1 is allowed)"
				end
			end

			master_option.exchange ||= l.first.exchange
			master_option.currency ||= l.first.currency

			l = [] ; c_l = []
			strikes = [front, master.strike, back]
		  strikes.zip([1, -2, 1]).each do |strike, weight|
				master_option.strike = strike
				master_option.verify do |c| 
					l << c.essential
					c_l << ComboLeg.new( con_id: c.con_id, weight: weight, exchange: c.exchange )
				end
			end

			super  exchange: master_option.exchange, 
							 symbol: master_option.symbol.to_s ,
						 currency: master_option.currency,
						 legs: l,
						 combo_legs: c_l
		end

		def to_human
			x= [ combo_legs.map(&:weight) , legs.map( &:strike )].transpose
			 "<Butterfly #{symbol} #{legs.first.right}(#{x.map{|w,strike| "#{w} :#{strike} "}.join( '|+|' )} )[#{Date.parse(legs.first.last_trading_day).strftime("%b %Y")}]>"
		end
	end
end
