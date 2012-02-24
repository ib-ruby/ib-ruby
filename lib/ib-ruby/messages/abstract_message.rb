# EClientSocket.java uses sendMax() rather than send() for a number of these.
# It sends an EOL rather than a number if the value == Integer.MAX_VALUE (or Double.MAX_VALUE).
# These fields are initialized to this MAX_VALUE.
# This has been implemented with nils in Ruby to represent the case where an EOL should be sent.

# TODO: Don't instantiate messages, use their classes as just namespace for .encode/decode
# TODO: realize Message#fire method that raises EWrapper events

module IB
  module Messages

    # This is just a basic generic message from the server.
    #
    # Class variables:
    # @message_id - int: message id.
    # @message_type - Symbol: message type (e.g. :OpenOrderEnd)
    #
    # Instance attributes (at least):
    # version - int: current version of message format.
    # @data - Hash of actual data read from a stream.
    #
    # Override the load(socket) method in your subclass to do actual reading into @data.
    class AbstractMessage

      # Class methods
      def self.data_map # Data keys (with types?)
        @data_map ||= []
      end

      def self.version # Per class, minimum message version supported
        @version || 1
      end

      def self.message_id
        @message_id
      end

      # Returns message type Symbol (e.g. :OpenOrderEnd)
      def self.message_type
        to_s.split(/::/).last.to_sym
      end

      def message_id
        self.class.message_id
      end

      def message_type
        self.class.message_type
      end

      attr_accessor :created_at, :data

      def to_human
        "<#{self.message_type}:" +
            @data.map do |key, value|
              " #{key} #{value}" unless [:version].include?(key)
            end.compact.join(',') + " >"
      end

    end # class AbstractMessage

    # Macro that defines short message classes using a one-liner
    def def_message id_version, *data_map, &to_human
      base = data_map.first.is_a?(Class) ? data_map.shift : self::AbstractMessage
      Class.new(base) do
        @message_id, @version = id_version
        @version ||= 1
        @data_map = data_map

        @data_map.each do |(m1, m2, m3)|
          group, name = m3 ? [m1, m2] : [nil, m1]
          define_method(name) { @data[name] }
          attr_reader group if group
        end

        define_method(:to_human, &to_human) if to_human
      end
    end

  end # module Messages
end # module IB
