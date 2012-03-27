require 'ib-ruby/models/model'

module IB
  module Models
    # This is IB Order execution report.
    # Instantiate with a Hash of attributes, to be auto-set via initialize in Model.
    class Execution < Model
      prop :order_id, #     int: order id. TWS orders have a fixed order id of 0.
           :client_id, #    int: id of the client that placed the order.
           #                     TWS orders have a fixed client id of 0.
           :perm_id, #      int: TWS id used to identify orders, remains
           :exec_id, #      String: Unique order execution id.
           #                      the same over TWS sessions.
           :time, #         String: The order execution time.
           :exchange, #     String: Exchange that executed the order.
           :price, #        double: The order execution price.
           :average_price, # double: Average price. Used in regular trades, combo
           #                         trades and legs of the combo.
           :shares, #       int: The number of shares filled.
           :cumulative_quantity, # int: Cumulative quantity. Used in regular
           #                            trades, combo trades and legs of the combo
           :liquidation, #  int: This position is liquidated last should the need arise.
           :order_ref, #  int: Same order_ref as in corresponding Order
           [:account_name, :account_number], # String: The customer account number.
           :side => #     String: Was the transaction a buy or a sale: BOT|SLD
               {:set => proc { |val| self[:side] = val.to_s.upcase[0..0] == 'B' ? :buy : :sell }}

      DEFAULT_PROPS = {:order_id => 0,
                       :client_id => 0,
                       :shares => 0,
                       :price => 0,
                       :perm_id => 0,
                       :liquidation => 0, }

      def to_s
        "<Execution #{time}: #{side} #{shares} @ #{price} on #{exchange}, " +
            "cumulative: #{cumulative_quantity} @ #{average_price}, " +
            "order: #{order_id}/#{perm_id}#{order_ref}, exec: #{exec_id}>"
      end
    end # Execution
  end # module Models
end # module IB
