require 'ib-ruby/messages/abstract_message'

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
        def send_to server
          self.encode(server).flatten.each do |datum|
            #p datum
            server[:socket].write_data datum
          end
        end

        # At minimum, Outgoing message contains message_id and version.
        # Most messages also contain (ticker, request or order) :id.
        # Then, content of @data Hash is encoded per instructions in data_map.
        def encode server
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
          ].flatten
        end

      end # AbstractMessage
    end # module Outgoing
  end # module Messages
end # module IB
