require 'ib/messages/abstract_message'
require 'ib/support'
require 'ox'
module IB
	module Messages
		module Incoming
			using IBSupport # refine Array-method for decoding of IB-Messages


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
						#  if uncommented, the raw-input from the tws is included in the logging
				#		puts "BUFFER .> #{buffer.inspect}"
#					Connection.logger.debug { "BUFFER :> #{buffer.inspect} "}
						@data = Hash.new
						self.load
					end
				end

				def valid?
					@buffer.empty? 
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
							begin
								data = @buffer.__send__("read_#{type}", &block)
							rescue IB::LoadError, NoMethodError => e
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
