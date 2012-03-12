require 'ib-ruby/models/model'

module IB
  module Models
    # This is IB Order execution report.
    # Instantiate with a Hash of attributes, to be auto-set via initialize in Model.
    class Execution < Model
      attr_accessor :order_id, #     int: order id. TWS orders have a fixed order id of 0.
                    :client_id, #    int: id of the client that placed the order.
                    #                     TWS orders have a fixed client id of 0.
                    :perm_id, #      int: TWS id used to identify orders, remains
                    :exec_id, #      String: Unique order execution id.
                    #                      the same over TWS sessions.
                    :time, #         String: The order execution time.
                    :exchange, #     String: Exchange that executed the order.
                    :side, #         String: Was the transaction a buy or a sale: BOT|SLD
                    :account_name, # String: The customer account number.
                    :price, #        double: The order execution price.
                    :average_price, # double: Average price. Used in regular trades, combo
                    #                         trades and legs of the combo.
                    :shares, #       int: The number of shares filled.
                    :cumulative_quantity, # int: Cumulative quantity. Used in regular
                    #                            trades, combo trades and legs of the combo
                    :liquidation #  int: This position is liquidated last should the need arise.

      alias account_number account_name # Legacy
      alias account_number= account_name= # Legacy

      def side= value
        self[:side] = value == 'BOT' ? :BUY : :SELL
      end

      def initialize opts = {}
        self[:order_id] = 0
        self[:client_id] = 0
        self[:shares] = 0
        self[:price] = 0
        self[:perm_id]= 0
        self[:liquidation] = 0

        super opts
      end

      def to_s
        "<Execution #{time}: #{side} #{shares} @ #{price} on #{exchange}, " +
            "cumulative: #{cumulative_quantity} @ #{average_price}, " +
            "ids: #{order_id} order, #{perm_id} perm, #{exec_id} exec>"
      end
    end # Execution
  end # module Models
end # module IB
