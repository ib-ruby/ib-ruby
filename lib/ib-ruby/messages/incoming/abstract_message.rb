require 'ib-ruby/messages/abstract_message'

module IB
  module Messages
    module Incoming

      # Container for specific message classes, keyed by their message_ids
      Classes = {}

      class AbstractMessage < IB::Messages::AbstractMessage

        def version # Per message, received messages may have the different versions
          @data[:version]
        end

        def check_version actual, expected
          unless actual == expected || expected.is_a?(Array) && expected.include?(actual)
            error "Unsupported version #{actual} received, expected #{expected}"
          end
        end

        # Create incoming message from a given source (IB server or data Hash)
        def initialize source
          @created_at = Time.now
          if source[:socket] # Source is a server
            @server = source
            @data = Hash.new
            begin
              self.load
            rescue => e
              error "Reading #{self.class}: #{e.class}: #{e.message}", :load, e.backtrace
            ensure
              @server = nil
            end
          else # Source is a @data Hash
            @data = source
          end
        end

        def socket
          @server[:socket]
        end

        # Every message loads received message version first
        # Override the load method in your subclass to do actual reading into @data.
        def load
          @data[:version] = socket.read_int

          check_version @data[:version], self.class.version

          load_map *self.class.data_map
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

                data = socket.__send__("read_#{type}", &block)
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
