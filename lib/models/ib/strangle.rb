require_relative 'contract'

module IB
	class Strangle <   Spread

=begin
Macro-Class to simplify the definition of Strangles

Initialize with

	strangle =  IB::Strangle.new underlying: Symbols::Index.stoxx,
															 put: 3000, call: 3200
															 expiry: '201901'

=end

		

		def initialize  underlying: , 
										p: , c: ,
										expiry: IB::Symbols::Futures.next_expiry, 
										**args  # trading-class and others

			error "Underlying has to be an IB::Contract" unless underlying.is_a? IB::Contract
			master_option = IB::Option.new underlying.attributes.slice( :currency, :symbol, :exchange ).merge(args)
			master_option.expiry = expiry
			master_option.sec_type = 'FOP' if underlying.is_a?(IB::Future)

		  leg_option = ->(strike, kind) do
				l=[];  master_option.strike =  strike; master_option.verify{|c|  c.contract_detail =  nil; l <<c if c.right== kind }
				error "Multible #{kind}-Options found for the specified Contract: #{master_option.to_human} " unless l.size==1
				l.first
				end
			my_legs = [ leg_option[p, :put], leg_option[c,:call] ]
			master_option.exchange ||= my_legs.first.exchange
			master_option.currency ||= my_legs.first.currency

			c_l = my_legs.map{ |l| ComboLeg.new con_id: l.con_id, action: :buy, exchange: l.exchange, ratio: 1 }
			super  exchange: master_option.exchange, 
							 symbol: master_option.symbol.to_s,
						 currency: master_option.currency,
						 legs: my_legs,
						 combo_legs: c_l
		end
		def to_human
			 "<Strangle #{symbol}(#{legs.map(&:strike).join(",")})[#{Date.parse(legs.first.last_trading_day).strftime("%b %Y")}]>"
		end
	end
end
