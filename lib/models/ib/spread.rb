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
	end
end
