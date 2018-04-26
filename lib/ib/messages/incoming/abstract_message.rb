require 'ib/messages/abstract_message'
require 'ox'
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
			Time.at read_int
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
				 primary_exchange: read_string,
				 currency: read_string,
				 local_symbol: read_string,
				 trading_class: read_string }  # new Version 8

		end


		alias read_bool read_boolean
	end
end
module IB
  module Messages
    module Incoming

    using IBSupport
  

      # Container for specific message classes, keyed by their message_ids
      Classes = {}

      class AbstractMessage < IB::Messages::AbstractMessage

        attr_accessor :buffer # is an array

        def version # Per message, received messages may have the different versions
          @data[:version]
        end

        def check_version actual, expected
          unless actual == expected || expected.is_a?(Array) && expected.include?(actual)
            error "Unsupported version #{actual} received, expected #{expected}"
          end
        end

				# Create incoming message from a given source (IB Socket or data Hash)
				def initialize source
					@created_at = Time.now
					if source.is_a?(Hash)  # Source is a @data Hash
						@data = source
						@buffer =[] # initialize empty buffer, indicates a successfull initializing
					else
						@buffer = source
						#  if uncommented, the raw-input from the tws is displayed, logger does not work on this level
				#		puts "BUFFER"
				#		puts buffer.inspect #.join(" :\n ")
				#		puts "BUFFER END"
						@data = Hash.new
						self.load
					end
				end

	## more recent messages omit the transmission of a version
	## thus just load the parameter-map 
	def simple_load
            load_map *self.class.data_map
        rescue IB::Error  => e
          error "Reading #{self.class}: #{e.class}: #{e.message}", :load, e.backtrace
	end
        # Every message loads received message version first
        # Override the load method in your subclass to do actual reading into @data.
        def load
	    unless self.class.version.zero?
            @data[:version] = buffer.read_int
            check_version @data[:version], self.class.version
	    end
	    simple_load
        end

        # Load @data from the buffer according to the given data map.
        #
        # map is a series of Arrays in the format of
        #   [ :name, :type ], [  :group, :name, :type]
        # type identifiers must have a corresponding read_type method on the buffer-class (read_int, etc.).
        # group is used to lump together aggregates, such as Contract or Order fields
				def load_map(*map)
					map.each do |instruction|
						# We determine the function of the first element
						head = instruction.first
						case head
						when Integer # >= Version condition: [ min_version, [map]]
							load_map *instruction.drop(1) if version >= head

						when Proc # Callable condition: [ condition, [map]]
							load_map *instruction.drop(1) if head.call

						when true # Pre-condition already succeeded!
							load_map *instruction.drop(1)

						when nil, false # Pre-condition already failed! Do nothing...

						when Symbol # Normal map
							group, name, type, block =
								if  instruction[2].nil? || instruction[2].is_a?(Proc)  # lambda's are Proc's 
									[nil] + instruction # No group, [ :name, :type, (:block) ]
								else
									instruction # [ :group, :name, :type, (:block)]
								end
							# debug	      print "Name: #{name}   "
							begin
								data = @buffer.__send__("read_#{type}", &block)
							rescue IB::LoadError => e
								puts "TEST"
								error "Reading #{self.class}: #{e.class}: #{e.message}  --> Instruction: #{name}" , :reader, false 
							rescue NoMethodError => e
								error "Reading #{self.class}: #{e.class}: #{e.message}  --> Instruction: #{name}" , :reader, false 
							end
							# debug	      puts data.inspect
							if group
								@data[group] ||= {}
								@data[group][name] = data
							else
								@data[name] = data    
							end
						else
							error "Unrecognized instruction #{instruction}"
						end
					end
				end

      end # class AbstractMessage
    end # module Incoming
  end # module Messages
end # module IB
