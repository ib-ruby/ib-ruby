require 'ib/messages/abstract_message'
require 'ox'
module IBSupport
  refine Array do

    def zero?
      false
    end
    def read_int
      self.shift.to_i rescue 0
    end

    def read_decimal
     i= self.shift.to_d  rescue 0
     i < IB::TWS_MAX ?  i : nil  # return nil, if a very large number is transmitted
    end

    alias read_decimal_max read_decimal

    def read_string
      self.shift rescue ""
    end

    # convert xml into a hash
    def read_xml
	Ox.load( read_string, mode: :hash_no_attrs)
    end

    def read_required_string
      v = read_string
      error( "requiredString not filled", :load, false)  if v.blank?
      v
    end

		def read_int_date
			Time.at read_int
		end

    def read_boolean

      v = self.shift rescue nil
      v.nil? ? false : v.to_i != 0
    end
    def read_required_boolean
	begin
	  if self.empty?
	    logger.error "End of buffer reached"
	    error "End of buffer reached", :load, false
	    return nil
	  else
	    v = self.shift
	    if ["1","0"].include? v
	      return v.to_i
	    else
	      error "bool expected, got #{v} "
	    end
	  end
	end while v.empty? 
	logger.error { "Bool required, #{v} detected instead" }
	error  "Bool required, #{v} detected instead", :load, false
    end

#    def read_array
#      count = read_int
#    end

    ## originally provided in socket.rb
     #    # Returns loaded Array or [] if count was 0
           def read_array &block
             count = read_int
# debug	     STDOUT.puts "ARRAY ----|> #{count}"
             count > 0 ? Array.new(count, &block) : []
           end
    #   
    #       # Returns loaded Hash
           def read_hash
             tags = read_array { |_| [read_string, read_string] }
             tags.empty? ? Hash.new :  Hash[*tags.flatten]
           end
    #
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
						#  if uncommented, the raw-input from the tws is displayed
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

        # Load @data from the socket according to the given data map.
        #
        # map is a series of Arrays in the format of
        #   [ :name, :type ], [  :group, :name, :type]
        # type identifiers must have a corresponding read_type method on socket (read_int, etc.).
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
              if  instruction[2].nil? || instruction[2].is_a?(Proc)
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
