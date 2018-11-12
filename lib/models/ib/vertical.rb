require_relative 'contract'


module IB
	class Vertical <   Spread

=begin
Macro-Class to simplify the definition of Vertical-Spreads

Initialize with

	calendar =  IB::Vertical.new underlying: Symbols::Index.stoxx,
															 buy: 3000, sell: 2900,  right: :put
															 expiry: 201901, back: 291903
	or
 
	master = IB::Option.new symbol: :Estx50, right: :put, multiplier: 10, exchange: 'DTB', currency: 'EUR'
													strike: 3000, expiry: 201812
	calendar =  IB::Vertical.new sell: master, buy: 3100

=end

		

		def initialize  master=nil,   # provides strike, front-month, right, trading-class
										underlying: nil, 
										right: :put,
										expiry: IB::Symbols::Futures.next_expiry, 
										buy: 0 ,   # has to be specified
										sell: 0,
							#			trading_class: nil,
										**args  # trading-class and others

			master_option, side, msg = if master.present? 
															if master.is_a?(IB::Option) 
																[ master.essential,-1, nil ]
															else
																[ nil, 0,"First Argument is no IB::Option" ]
															end
														elsif  buy.is_a?(IB::Option) && !sell.zero?  
															 [ buy.essentail,1, nil ]
														elsif  sell.is_a?(IB::Option) && !buy.zero? 
															 [ sell.essential, -1, nil  ]
														elsif	underlying.present?
															if underlying.is_a?(IB::Contract)
																master = IB::Option.new underlying.attributes.slice( :currency, :symbol, :exchange ).merge(args) 
																master.sec_type = 'FOP' if underlying.is_a?(IB::Future)
																master.strike, master.expiry, master.right = buy, expiry, right
																[master, 1, buy.to_i >0 && sell.to_i >0 ? nil : "buy and sell strikes have to be specified"]
															else
																[nil, 0, "Underlying has to be an IB::Contract"]
															end
														else
															[ nil, 0,  "Required parameters: Master-Option or Underlying, buy and sell-strikes" ]  
														end

			error msg, :args, nil  if msg.present?
			master_option.trading_class = args[:trading_class] if args[:trading_class].present?
			l=[] ; master_option.verify{|x| x.contract_detail = nil; l << x }
			if l.empty?
				error "Invalid Parameters. No Contract found #{master_option.to_human}"
			elsif l.size > 2
				Connection.logger.error "ambigous contract-specification: #{l.map(&:to_human).join(';')}"
				available_trading_classes = l.map( &:trading_class ).uniq
				if available_trading_classes.size >1
					error "Refine Specification with trading_class: #{available_trading_classes.join('; ')}  (details in log)"
				else
					error "Respecify expiry, verification reveals #{l.size} contracts  (only 2 are allowed) #{master_option.to_human}"
				end
			end

			master_option.strike =  side ==1 ?  sell : buy
			master_option.verify{|x| x.contract_detail =  nil; l << x }
			error "Two legs are required, \n Verifiying the master-option exposed #{l.size} legs" unless l.size ==2

			master_option.exchange ||= l.first.exchange
			master_option.currency ||= l.first.currency

			# i=0 + side = -1 --> -1   sell
			# i=0 + side =  1 -->  1   buy
			# i=1 + side = -1 -->  0   buy
			# i.1 + side =  1 -->  2   sell
			c_l = l.map.with_index{ |l,i| ComboLeg.new con_id: l.con_id, action: i+side ==2 || i+side <0  ? :sell : :buy , exchange: l.exchange, ratio:  1 }

			super  exchange: master_option.exchange, 
							 symbol: master_option.symbol.to_s,
						 currency: master_option.currency,
						 legs: l,
						 combo_legs: c_l
		end
		def to_human
			x= [ combo_legs.map(&:weight) , legs.map( &:strike )].transpose
			 "<Vertical #{symbol} #{legs.first.right}(#{x.map{|w,strike| "#{w} :#{strike} "}.join( '|+|' )} )[#{Date.parse(legs.first.last_trading_day).strftime("%b %Y")}]>"
		end
	end
end
