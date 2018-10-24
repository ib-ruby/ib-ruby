require_relative 'contract'
module IB
	class Straddle <  Bag 

=begin
Macro-Class to simplify the definition of Straddles

Initialize with

	straddle= IB::Straddle.new IB::Option.new( symbol: :estx50, strike: 3000, expiry:'201901')

or
	
	straddle =  IB::Straddle.new underlying: Symbols::Index.stoxx,
															 strike: 2000,
															 expiry: '201901'

=end

		
		has_many :legs

		def initialize  master=nil, 
										underlying: nil, 
										strike: 0, 
										expiry: IB::Symbols::Futures.next_expiry, 
										trading_class: nil

			master_option, msg = if master.present? 
															if master.is_a?(IB::Option)
																[ master, nil ]
															else
																[ nil, "First Argument is no IB::Option" ]
															end
														elsif underlying.present?
															if underlying.is_a?(IB::Contract)
																master = IB::Option.new underlying.attributes.slice( :currency, :symbol, :exchange )
																master.strike = strike 
																master.expiry = expiry
																[master, strike.zero? ? "strike has to be specified" : nil]
															else
																[nil, "Underlying has to be an IB::Contract"]
															end
														else
															[ nil, "Required parameters: Master-Option or Underlying, strike, expiry" ]  
														end

			error msg, :args, nil  if msg.present?
			master_option.trading_class = trading_class unless trading_class.nil?
			l=[] ; master_option.verify{|x| x.contract_detail= nil; l << x }
			if l.size < 2
				error "Invalid Parameters. Two legs are required, \n Verifiying the master-option exposed #{l.size} legs", :args, nil 
			elsif l.size > 2
				available_trading_classes = l.map( &:trading_class ).uniq
				if available_trading_classes.size >1
					error "Refine Specification with trading_class: #{available_trading_classes.join('; ')} "
				else
					error "Respecify expiry, verification reveals #{l.size} contracts  (only 2 are allowed)"
				end
			end

			master_option.exchange ||= l.first.exchange
			master_option.currency ||= l.first.currency

			c_l = l.map{ |l| ComboLeg.new con_id: l.con_id, action: :buy, exchange: l.exchange, ratio: 1 }
			super  exchange: master_option.exchange, 
							 symbol: master_option.symbol.to_s ,
						 currency: master_option.currency,
						 legs: l,
						 combo_legs: c_l
		end
		def to_human
			 "<Straddle #{symbol}(#{legs.first.strike})[#{Date.parse(legs.first.last_trading_day).strftime("%b %Y")}]>"
		end
	end
end
