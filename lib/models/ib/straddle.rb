module IB
	class Straddle < Bag

=begin
Macro-Class to simplify the definition of Straddles

Initialize with

	straddle= IB::Straddle.new IB::Option.new( symbol: :estx50, strike: 3000, expiry:'201901')

or
	
	straddle =  IB::Straddle.new underlying: Symbols::Index.stoxx,
															 strike: 2000,
															 expiry: '201901'

=end

		attr_reader :legs				# expose legs (IB::Contracts) to the outside
		
		def initialize  master=nil, 
										underlying: nil, 
										strike: 0, 
										expiry: IB::Symbols::Futures.next_expiry 


			@master_option, msg = if master.present? 
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
		end
		def verify
			@legs = []; 	@master_option.verify{|x| @legs << x }  # we need that to assign portfolio-position to the structure
			error "Invalid Parameters. Two legs are required, \n Verifiying the master-option exposed #{@legs.size} legs", :args, nil unless @legs.size == 2
			@master_option.exchange ||= @legs.first.exchange
			@master_option.currency ||= @legs.first.currency
			yield bag if block_given?
			bag   # return_value
		end

		alias verify! verify
		def bag action: :buy  # this is the default-operation.
																	# To establish a short-straddle, just sell the long-straddle
			verify if @legs.nil? || @legs.empty?
			combo_legs = @legs.map{ |l| ComboLeg.new con_id: l.con_id, action: action, exchange: l.exchange, ratio: 1 }
			# lets create a static bag upon initialisation  --> legs cannot be changed after IB::Straddle.new
			Bag.new symbol: @master_option.symbol, description: to_human[1..-2], 
							currency: @master_option.currency, exchange: @master_option.exchange, legs: combo_legs
			## alternative:  
			# depend class on bag and call super 


		end
		def to_human
			 "<Straddle #{@master_option.symbol}(#{@master_option.strike})[#{Date.parse(@legs.first.last_trading_day).strftime("%b %Y")}]>"
		end
	end
end
