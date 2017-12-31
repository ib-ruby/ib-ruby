require 'ib/messages/abstract_message'

module IB
  module Messages
    module Incoming

      # Container for specific message classes, keyed by their message_ids
      Classes = {}

      class AbstractMessage < IB::Messages::AbstractMessage

        attr_accessor :socket
        attr_accessor :raw_data  # is an array

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
	  else
	    if source.is_a?(Array)
	      @raw_data = source
	    else # Source is a Socket
	      @socket = source
	    end
	    @data = Hash.new
	    self.load
          end
        end

        # Every message loads received message version first
        # Override the load method in your subclass to do actual reading into @data.
        def load
          if socket
            @data[:version] = socket.read_int
	  elsif @raw_data.is_a? Array
	    @data[:version] = @raw_data.shift.to_i
	  else
            raise "Unable to load, no socket/buffer"
	    return
	  end
            check_version @data[:version], self.class.version
            load_map *self.class.data_map
        rescue => e
          error "Reading #{self.class}: #{e.class}: #{e.message}", :load, e.backtrace
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

              data = if socket
		       socket.__send__("read_#{type}", &block)
		     else
		       case type
		       when :int
			 @raw_data.shift.to_i
		       when :string
			 @raw_data.shift
		       when :decimal, :decimal_max
			 @raw_data.shift.to_d 

		       else
		       puts "READ -->  #{type}, #{type.class}."
		       puts "raw-data: #{@raw_data}"
		       nil
		       end
		     end
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
