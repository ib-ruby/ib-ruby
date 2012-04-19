module IB
  module Messages
    module Outgoing

      # Data format is { :id => int: local_id,
      #                  :contract => Contract,
      #                  :order => Order }
      PlaceOrder = def_message [3, 31] # v.38 is NOT properly supported by API yet

      class PlaceOrder

        def encode server
          # Old server version supports no enhancements
          @version = 31 if server[:server_version] <= 60

          [super,
           @data[:order].serialize_with(server, @data[:contract])].flatten
        end
      end # PlaceOrder


    end # module Outgoing
  end # module Messages
end # module IB
