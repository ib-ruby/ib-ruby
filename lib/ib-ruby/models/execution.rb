module IB
  module Models
    # This is IB Order execution report.
    # Instantiate with a Hash of attributes, to be auto-set via initialize in Model.
    class Execution < Model.for(:execution)
      include ModelProperties

      prop :order_id, #     int: order id. TWS orders have a fixed order id of 0.
           :client_id, #    int: client id. TWS orders have a fixed client id of 0.
           :perm_id, #      int: TWS id used to identify orders over TWS sessions
           :exec_id, #      String: Unique order execution id over TWS sessions.
           :time, #         # TODO: convert into Time object?
           #                String: The order execution time.
           :exchange, #     String: Exchange that executed the order.
           :order_ref, #  int: Same order_ref as in corresponding Order
           [:account_name, :account_number], # String: The customer account number.
           :price, #        double: The order execution price.
           :average_price, # double: Average price. Used in regular trades, combo
           #                         trades and legs of the combo.
           :shares, #       int: The number of shares filled.
           :cumulative_quantity, # int: Cumulative quantity. Used in regular
           #                            trades, combo trades and legs of the combo
           :liquidation => :bool, #  int: This position is liquidated last should the need arise.
           [:side, :action] => PROPS[:side] # String: Was the transaction a buy or a sale: BOT|SLD

      # Extra validations
      validates_numericality_of :shares, :cumulative_quantity, :price, :average_price

      DEFAULT_PROPS = {:order_id => 0,
                       :client_id => 0,
                       :shares => 0,
                       :price => 0,
                       :perm_id => 0,
                       :liquidation => 0, }
      # Comparison
      def == other
        perm_id == other.perm_id &&
            order_id == other.order_id && # ((p __LINE__)||true) &&
            client_id == other.client_id &&
            exec_id == other.exec_id &&
            time == other.time &&
            exchange == other.exchange &&
            order_ref == other.order_ref &&
            side == other.side
        # TODO: || compare all attributes!
      end

      def to_human
        "<Execution: #{time} #{side} #{shares} at #{price} on #{exchange}, " +
            "cumulative #{cumulative_quantity} at #{average_price}, " +
            "ids #{order_id}/#{perm_id}/#{exec_id}>"
      end

      alias to_s to_human

    end # Execution
  end # module Models
end # module IB
