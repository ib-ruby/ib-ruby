require 'ib/messages/abstract_message'

module IB
  module Messages
    module Incoming

      # Container for specific message classes, keyed by their message_ids
      Classes = {}

      class AbstractMessage < IB::Messages::AbstractMessage

        attr_accessor :socket

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
          else # Source is a Socket
            @socket = source
            @data = Hash.new
            self.load
          end
        end

        # Every message loads received message version first
        # Override the load method in your subclass to do actual reading into @data.
        def load
          if socket
            @data[:version] = socket.read_int

            check_version @data[:version], self.class.version

            load_map *self.class.data_map
          else
            raise "Unable to load, no socket"
          end

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

        # Convert an array of message class identifiers to IncomingMessage
        # classes.  Accepts any combination of Array, symbol, or regex.
        # Returns an array of class objects.
        def self.resolve_message_classes(args)
          message_classes = []
          args = [args] unless args.is_a?(Array)
          args.flatten.each do |what|
            message_classes <<
              case
              when what.is_a?(Class) && what < Messages::Incoming::AbstractMessage
                what
              when what.is_a?(Symbol)
                Messages::Incoming.const_get(what)
              when what.is_a?(Regexp)
                Messages::Incoming::Classes.values.find_all { |klass| klass.to_s =~ what }
              else
                error "#{what} must represent incoming IB message class", :args
              end
          end
          message_classes.flatten
        end

      end # class AbstractMessage
    end # module Incoming
  end # module Messages
end # module IB
