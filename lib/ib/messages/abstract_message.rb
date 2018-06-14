module IB
  module Messages

    # This is just a basic generic message from the server.
    #
    # Class variables:
    # @message_id - int: message id.
    # @message_type - Symbol: message type (e.g. :OpenOrderEnd)
    #
    # Instance attributes (at least):
    # @version - int: current version of message format.
    # @data - Hash of actual data read from a stream.
    class AbstractMessage

      # Class methods
      def self.data_map # Map for converting between structured message and raw data
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

			def request_id
				@data[:request_id].presence || nil
			end

      def message_type
        self.class.message_type
      end

      attr_accessor :created_at, :data

			def self.properties?
				@given_arguments
			end


      def to_human
        "<#{self.message_type}:" +
        @data.map do |key, value|
          unless [:version].include?(key)
            " #{key} #{ value.is_a?(Hash) ? value.inspect : value}"
          end
        end.compact.join(',') + " >"
      end

    end # class AbstractMessage

    # Macro that defines short message classes using a one-liner.
    #   First arg is either a [message_id, version] pair or just message_id (version 1)
    #   data_map contains instructions for processing @data Hash. Format:
    #      Incoming messages: [field, type] or [group, field, type]
    #      Outgoing messages: field, [field, default] or [field, method, [args]]
    def def_message message_id_version, *data_map, &to_human
      base = data_map.first.is_a?(Class) ? data_map.shift : self::AbstractMessage
      message_id, version = message_id_version

      # Define new message class
      message_class = Class.new(base) do
        @message_id, @version = message_id, version || 1
        @data_map = data_map
				@given_arguments =[]

        @data_map.each do |(name, _, type_args)|
					dont_process = name == :request_id # [ :request_id, :local_id, :id ].include? name.to_sym 
					@given_arguments << name.to_sym
          # Avoid redefining existing accessor methods
          unless instance_methods.include?(name.to_s) || instance_methods.include?(name.to_sym) || dont_process
            if type_args.is_a?(Symbol) # This is Incoming with [group, field, type]
              attr_reader name
            else
              define_method(name) { @data[name] } 
            end
          end
        end

        define_method(:to_human, &to_human) if to_human
      end

      # Add defined message class to Classes Hash keyed by its message_id
      self::Classes[message_id] = message_class

      message_class
    end

  end # module Messages
end # module IB
