require_relative 'contract'
module IB
	class StockSpread <   Spread

=begin
Macro-Class to simplify the definition of Stock-Spreads, ie. buy some equity and sell another at the same time

Initialize with

	spread= IB::StockSpread.new IB::Stock.new( symbol: 'T' ), IB::Stock.new( symbol: 'GE' ),  ratio:[ 1,-2 ]

or
	
=end

		

		def initialize  *underlying,  ratio: [1,-1]

			are_stocks =  ->{ underlying.all?{|y| y.is_a? IB::Stock} }
			error "only spreads with two underyings of type »IB::Stock« are supported" unless underlying.size==2 && are_stocks[]
			verified_legs = underlying.map{|c| c.verify!.essential} # ensure, that con_id is present

			c_l = verified_legs.zip(ratio).map do |l,r| 
				action = r >0 ?  :buy : :sell
				ComboLeg.new con_id: l.con_id, action: action, exchange: l.exchange, ratio: r.abs 
			end
			super  exchange: verified_legs.first.exchange,
						 currency: verified_legs.first.currency,
#							 symbol: verified_legs.map( &:symbol ).zip(ratio).sort{|x,y| x.last <=> y.last}.map{|c,_| c }.join(","),  # alphabetical order
							 symbol: verified_legs.map( &:symbol ).sort.join(","),  # alphabetical order
						 legs: verified_legs,
						 combo_legs: c_l
		end

		def to_human
			info=  legs.map( &:symbol ).zip(combo_legs.map( &:weight ))
			 "<StockSpread #{symbol}(#{info.map{|c| c.join(":")}.join(" , ")})>"
		end
		# always route a order as NonGuaranteed 
		def order_requirements
		 super.merge		combo_params: [ ['NonGuaranteed', true] ]
		end
	end
end
