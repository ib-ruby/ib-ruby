require 'ib-ruby/models/model'

module IB
  module Models
    # This is IB Order execution report.
    # Instantiate with a Hash of attributes, to be auto-set via initialize in Model.
    class Execution < Model
      attr_accessor :order_id, #      int: order id. TWS orders have a fixed order id of 0.
                    :client_id, #     int: id of the client that placed the order.
                    #                      TWS orders have a fixed client id of 0.
                    :exec_id, #       String: Unique order execution id.
                    :time, #          String: The order execution time.
                    :account_name, #String: The customer account number.
                    :exchange, #      String: Exchange that executed the order.
                    :side, #          String: Was the transaction a buy or a sale: BOT|SLD
                    :shares, #        int: The number of shares filled.
                    :price, #         double: The order execution price.
                    :perm_id, #       int: TWS id used to identify orders, remains
                    #                      the same over TWS sessions.
                    :liquidation, #   int: Identifies the position as one to be liquidated
                    #                      last should the need arise.
                    :cumulative_quantity, # int: Cumulative quantity. Used in regular
                    #                           trades, combo trades and legs of the combo
                    :average_price #  double: Average price. Used in regular trades, combo
                                   #          trades and legs of the combo.
      # Legacy
      alias account_number account_name
      alias account_number= account_name=

      def side= value
        @side = case value
                  when 'BOT'
                    :BUY
                  when 'SLD'
                    :SELL
                  else
                    value
                end
      end

      def initialize opts = {}
        @order_id = 0
        @client_id = 0
        @shares = 0
        @price = 0
        @perm_id = 0
        @liquidation = 0

        super opts
      end

      def to_s
        "<Execution #{@time}: #{@side} #{@shares} @ #{@price} on #{@exchange}, " +
            "cumulative: #{@cumulative_quantity} @ #{@average_price}, " +
            "ids: #{@order_id} order, #{@perm_id} perm, #{@exec_id} exec>"
      end
    end # Execution
  end # module Models
end # module IB
