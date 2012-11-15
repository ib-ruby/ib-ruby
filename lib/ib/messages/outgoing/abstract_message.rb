require 'ib/messages/abstract_message'

module IB
  module Messages
    module Outgoing

      # Container for specific message classes, keyed by their message_ids
      Classes = {}

      class AbstractMessage < IB::Messages::AbstractMessage

        def initialize data={}
          @data = data
          @created_at = Time.now
        end

        # This causes the message to send itself over the server socket in server[:socket].
        # "server" is the @server instance variable from the IB object.
        # You can also use this to e.g. get the server version number.
        #
        # Subclasses can either override this method for precise control over how
        # stuff gets sent to the server, or else define a method encode() that returns
        # an Array of elements that ought to be sent to the server by calling to_s on
        # each one and postpending a '\0'.
        #
        def send_to socket
          self.preprocess.each {|data| socket.write_data data}
        end

        # Same message representation as logged by TWS into API messages log file
        def to_s
          self.preprocess.join('-')
        end

        # Pre-process encoded message Array before sending into socket, such as
        # changing booleans into 0/1 and stuff
        def preprocess
          self.encode.flatten.map {|data| data == true ? 1 : data == false ? 0 : data }
        end

        # Encode message content into (possibly, nested) Array of values.
        # At minimum, encoded Outgoing message contains message_id and version.
        # Most messages also contain (ticker, request or order) :id.
        # Then, content of @data Hash is encoded per instructions in data_map.
        # This method may be modified by message subclasses!
        def encode
          [self.class.message_id,
           self.class.version,
           @data[:id] || @data[:ticker_id] || @data[:request_id] ||
           @data[:local_id] || @data[:order_id] || [],
           self.class.data_map.map do |(field, default_method, args)|
             case
             when default_method.nil?
               @data[field]

             when default_method.is_a?(Symbol) # method name with args
               @data[field].send default_method, *args

             when default_method.respond_to?(:call) # callable with args
               default_method.call @data[field], *args

             else # default
               @data[field].nil? ? default_method : @data[field] # may be false still
             end
           end
           ]
          # TWS wants to receive booleans as 1 or 0
        end

      end # AbstractMessage
    end # module Outgoing
  end # module Messages
end # module IB
