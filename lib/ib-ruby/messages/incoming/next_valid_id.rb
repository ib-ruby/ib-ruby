module IB
  module Messages
    module Incoming

      # This message is always sent by TWS automatically at connect.
      # The IB::Connection class subscribes to it automatically and stores
      # the order id in its @next_local_id attribute.
      NextValidID = NextValidId = def_message(9, [:local_id, :int])

      class NextValidId

        # Legacy accessor
        alias order_id local_id

      end # class NextValidId
    end # module Incoming
  end # module Messages
end # module IB
