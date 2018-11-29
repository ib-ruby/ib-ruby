require_relative 'contract'


module IB
	class Calendar <   Spread

=begin
Macro-Class to simplify the definition of Calendar-Spreads

Initialize with

	calendar =  IB::Calendar.new underlying: Symbols::Index.stoxx,
															 strike: 3000, right: :put
															 front: 201901, back: 291903
	or
 
	master = IB::Option.new symbol: :Estx50, right: :put, multiplier: 10, exchange: 'DTB', currency: 'EUR'
													strike: 3000, expiry: 201812
	calendar =  IB::Calendar.new master, back: 201903


	In »master-mode« futures may be underlyings, too, ie
  
	calendar =  IB::Calendar.new IB::Symbols::Futures.zn, back: '3m'

		calendar.to_human 

		"<Calendar ZN none(0.0)[-1 :Dec 2018 |+|1 :Mar 2019  >" 
	
	or
		calendar =  IB::Calendar.new IB::Symbols::Futures.zn, front: 201903, back: '3m'
=end
		def initialize  master=nil,   # provides strike, front-month, right, trading-class
										underlying: nil, 
										strike: 0, 
										right: :put,
										front: nil,   # has to be specified as "YYYMM(DD)" String or Numeric
										back: ,   # has to be specified either as "YYYYMM(DD)" String or Numeric
															# or relative "1m" "3m" "2w" "-1w" 
										**args # trading_class and others

	
			the_master, msg = if master.present? 
															if master.is_a?(IB::Option)
																front =  master.expiry unless master.expiry.nil?
																[ master.essential, nil ]
															elsif master.is_a? IB::Future
																front ||=  master.expiry
																[ master.essential, nil ]
															else
																[ nil, "First Argument is no IB::Option" ]
															end
														elsif underlying.present?
															if underlying.is_a?(IB::Contract)
																master = IB::Option.new underlying.attributes.slice( :currency, :symbol, :exchange ).merge(args)
																master.sec_type = 'FOP' if underlying.is_a?(IB::Future)
																master.strike, master.right, master.expiry = strike, right, front
																[master, strike.zero? ? "strike has to be specified" : nil]
															else
																[nil, "Underlying has to be an IB::Contract"]
															end
														else
															[ nil, "Required parameters: Master-Option or Underlying, strike" ]  
														end

			error msg, :args, nil  if msg.present?
			the_master.trading_class = args[:trading_class] if args[:trading_class].present?
			the_master.expiry =  front if front.present?
			the_master.expiry =  IB::Symbols::Futures.next_expiry if master_option.expiry.blank? 

			#if the_master.is_a?(IB::Option) && ( master_option.expiry.nil? || master_option.expiry == '')
			l=[] ; the_master.verify{|x| x.contract_detail = nil; l << x }
			if l.empty?
				error "Invalid Parameters. No Contract found #{the_master.to_human}"
			elsif l.size > 2
				available_trading_classes = l.map( &:trading_class ).uniq
				Connection.logger.error "ambigous contract-specification: #{l.map(&:to_human).join(';')}"
				if available_trading_classes.size >1
					error "Refine Specification with trading_class: #{available_trading_classes.join('; ')} (details in log)"
				else
					error "Respecify expiry, verification reveals #{l.size} contracts  (only 2 are allowed) #{the_master.to_human}"
				end
			end

			the_master.expiry =  transform_distance(front, back)
			the_master.verify{|x| x.contract_detail =  nil; l << x }
			error "Two legs are required, \n Verifiying the master-option exposed #{l.size} legs" unless l.size ==2

			the_master.exchange ||= l.first.exchange
			the_master.currency ||= l.first.currency

			# default is to sell the front month
			c_l = l.map.with_index{ |l,i| ComboLeg.new con_id: l.con_id, action: i.zero? ? :sell : :buy, exchange: l.exchange, ratio:  1 }

			super  exchange: the_master.exchange, 
							 symbol: the_master.symbol.to_s,
						 currency: the_master.currency,
						 legs: l,
						 combo_legs: c_l
		end
		def to_human
			x= [ combo_legs.map(&:weight) , legs.map( &:last_trading_day )].transpose
			 "<Calendar #{symbol} #{legs.first.right}(#{legs.first.strike})[#{x.map{|w,l_t_d| "#{w} :#{Date.parse(l_t_d).strftime("%b %Y")} "}.join( '|+|' )} >"
		end

	end  # class 
end  # module
