
module IBSupport
	refine Array do

		def zero?
			false
		end
		# Returns the integer. 
		# retuns nil otherwise or if no element is left on the stack
		def read_int
			i= self.shift  rescue nil
			i = i.to_i unless i.blank?			# this includes conversion of string to zero(0)
			i.is_a?( Integer ) ?  i : nil
		end

		def read_decimal
			i= self.shift  rescue nil
			i = i.to_d unless i.blank?
			i.is_a?(Numeric)  && i < IB::TWS_MAX ?  i : nil  # return nil, if a very large number is transmitted
		end

		alias read_decimal_max read_decimal

		## Values -1 and below indicate: Not computed (TickOptionComputation)
		def read_decimal_limit_1
			i= read_decimal
			i <= -1 ? nil : i
		end

		## Values -2 and below indicate: Not computed (TickOptionComputation)
		def read_decimal_limit_2
			i= read_decimal
			i <= -2 ? nil : i
		end


		def read_string
			self.shift rescue ""
		end
		## reads a string and proofs if NULL ==  IB::TWS_MAX is present.
		## in that case: returns nil. otherwise: returns the string
		def read_string_not_null
			r = read_string
			rd = r.to_d  unless r.blank?
			rd.is_a?(Numeric) && rd >= IB::TWS_MAX ? nil : r
		end

		def read_symbol
			read_string.to_sym
		end

		# convert xml into a hash
		def read_xml
			Ox.load( read_string(), mode: :hash_no_attrs)
		end


		def read_int_date
			t= read_int
				s= Time.at(t)
	#			s.year == 1970  --> data is most likely a date-string
				s.year == 1970 ? Date.parse(t.to_s) : t
		end

		def read_parse_date
			Time.parse read_string
		end

		def read_boolean

			v = self.shift  rescue nil
			case v
			when "1"
				true
			when "0"
				false
			else nil
			end
		end


		def read_datetime
			the_string = read_string
			the_string.blank? ? nil : DateTime.parse(the_string)
		end

		def read_date
			the_string = read_string
			the_string.blank? ? nil : Date.parse(the_string)
		end
		#    def read_array
		#      count = read_int
		#    end

		## originally provided in socket.rb
		#    # Returns loaded Array or [] if count was 0#
		#
		#    Without providing a Block, the elements are treated as string
		def read_array hashmode:false,  &block
			count = read_int
			case	count 
			when  0 
				[]
			when nil
				nil
			else
				count= count + count if hashmode
				if block_given?
					Array.new(count, &block) 
				else
					Array.new( count ){ read_string }
				end
			end 
		end
		#   
		#  Returns a hash 
		#  Expected Buffer-Format: 
		#			count (of Hash-elements)
		#			count* key|Value
		#	 Key's are transformed to symbols, values are treated as string
		def read_hash
			tags = read_array( hashmode: true )  # { |_| [read_string, read_string] }
		result =   if 	tags.nil? || tags.flatten.empty?
								 tags
							 else
								 interim = if  tags.size.modulo(2).zero? 
														 Hash[*tags.flatten]
													 else 
														 Hash[*tags[0..-2].flatten]  # omit the last element
													 end
								 # symbolize Hash
								 Hash[interim.map { |k, v| [k.to_sym, v] unless k.nil? }.compact]
							 end
		end
		#

		def read_contract  # read a standard contract and return als hash
			{	 con_id: read_int,
				 symbol: read_string,
				 sec_type: read_string,
				 expiry: read_string,
				 strike: read_decimal,
				 right: read_string,
				 multiplier: read_int,		
				 exchange: read_string,
				 currency: read_string,
				 local_symbol: read_string,
				 trading_class: read_string }  # new Version 8

		end


		alias read_bool read_boolean
	end
end
