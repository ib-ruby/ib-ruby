module IB
  module Messages
    module Incoming

      # :status - String: Displays the order status. Possible values include:
      # - PendingSubmit - indicates that you have transmitted the order, but
      #   have not yet received confirmation that it has been accepted by the
      #   order destination. NOTE: This order status is NOT sent back by TWS
      #   and should be explicitly set by YOU when an order is submitted.
      # - PendingCancel - indicates that you have sent a request to cancel
      #   the order but have not yet received cancel confirmation from the
      #   order destination. At this point, your order cancel is not confirmed.
      #   You may still receive an execution while your cancellation request
      #   is pending. NOTE: This order status is not sent back by TWS and
      #   should be explicitly set by YOU when an order is canceled.
      # - PreSubmitted - indicates that a simulated order type has been
      #   accepted by the IB system and that this order has yet to be elected.
      #   The order is held in the IB system until the election criteria are
      #   met. At that time the order is transmitted to the order destination
      #   as specified.
      # - Submitted - indicates that your order has been accepted at the order
      #   destination and is working.
      # - Cancelled - indicates that the balance of your order has been
      #   confirmed canceled by the IB system. This could occur unexpectedly
      #   when IB or the destination has rejected your order.
      # - ApiCancelled - canceled via API
      # - Filled - indicates that the order has been completely filled.
      # - Inactive - indicates that the order has been accepted by the system
      #   (simulated orders) or an exchange (native orders) but that currently
      #   the order is inactive due to system, exchange or other issues.
      # :why_held - This property contains the comma-separated list of reasons for
      #      order to be held. For example, when TWS is trying to locate shares for
      #      a short sell, the value used to indicate this is 'locate'.
      OrderStatus = def_message [3, 6],
                                [:order_state, :local_id, :int],
                                [:order_state, :status, :string],
                                [:order_state, :filled, :int],
                                [:order_state, :remaining, :int],
                                [:order_state, :average_fill_price, :decimal],
                                [:order_state, :perm_id, :int],
                                [:order_state, :parent_id, :int],
                                [:order_state, :last_fill_price, :decimal],
                                [:order_state, :client_id, :int],
                                [:order_state, :why_held, :string]
      class OrderStatus

        def order_state
          @order_state ||= IB::OrderState.new @data[:order_state]
        end

        # Accessors to make OpenOrder and OrderStatus messages API-compatible
        def local_id
          order_state.local_id
        end

        alias order_id local_id

        def status
          order_state.status
        end

        def to_human
          "<OrderStatus: #{order_state}>"
        end

      end # class OrderStatus
    end # module Incoming
  end # module Messages
end # module IB
