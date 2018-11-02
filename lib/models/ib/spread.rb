module IB
	class Spread   < Bag
		has_many :legs

=begin
Parameters:   front: YYYMM(DD)
							back: {n}w, {n}d or YYYYMM(DD)

Adds (or substracts) relative (back) measures to the front month, just passes absolute YYYYMM(DD) value
	
	front: 201809   back:  2m (-1m) --> 201811 (201808)
	front: 20180908 back:  1w (-1w) --> 20180918 (20180902)
=end

		def transform_distance front, back
			# Check Format of back: 201809 --> > 200.000
			#	                      20180989 ---> 20.000.000
			start_date = front.to_i < 20000000 ?  Date.strptime(front.to_s,"%Y%m") :  Date.strptime(front.to_s,"%Y%m%d") 
			nb = if back.to_i > 200000 
						 back.to_i
					 elsif back[-1] == "w" && front.to_i > 20000000
						 start_date + (back.to_i * 7)
					 elsif back[-1] == "m" && front.to_i > 200000
						 start_date >> back.to_i
					 else
						 error "Wrong date #{back} required format YYYMM, YYYYMMDD ord {n}w or {n}m"
					 end
			if nb.is_a?(Date)	
				if back[-1]=='w'
					nb.strftime("%Y%m%d")
				else
					nb.strftime("%Y%m")
				end
			else
				nb
			end 
		end # def 
	

		def calculate_spread_value( array_of_portfolio_values )
			array_of_portfolio_values.map{|x| x.send yield }.sum if block_given?
		end
	
		def fake_portfolio_position(  array_of_portfolio_values )
				calculate_spread_value= ->( array_of_portfolio_values, attribute ) do
							array_of_portfolio_values.map{|x| x.send attribute }.sum 
				end
				ar=array_of_portfolio_values
				IB::PortfolioValue.new  contract: self, 
					average_cost: 	calculate_spread_value[ar, :average_cost],
					market_price: 	calculate_spread_value[ar, :market_price],
					market_value: 	calculate_spread_value[ar, :market_value],
					unrealized_pnl: 	calculate_spread_value[ar, :unrealized_pnl],
					realized_pnl: 	calculate_spread_value[ar, :realized_pnl],
					position: 0

		end
		def essential
				legs.each{ |x| x.contract_detail =  nil }
				self
		end
		def  multiplier
			(legs.map(&:multiplier).sum/legs.size).to_i
		end
		
		# provide a negative con_id 
		def con_id
			-legs.map(&:con_id).sum
		end
	end


end
