module IB

  # This is IB Order execution report.
  class Execution < IB::Model
    include BaseProperties

    belongs_to :order

    prop :local_id, #   int: order id. TWS orders have a fixed order id of 0.
      :client_id, #     int: client id. TWS orders have a fixed client id of 0.
      :perm_id, #       int: TWS id used to identify orders over TWS sessions
      :exec_id, #       String: Unique order execution id over TWS sessions.
      :time, #         # TODO: convert into Time object?
      #                 String: The order execution time.
      :exchange, #      String: Exchange that executed the order.
      :order_ref, #     String: Same order_ref as in corresponding Order
      :price, #         double: The order execution price.
      :average_price, # double: Used in regular trades, combo trades and legs of the combo.
      :ev_rule, #       String: Australian products only
      :ev_multiplier, # double: Australian products onlyA
      :model_code,
      :last_liquidity,

      [:quantity, :shares], #       int: The number of shares filled.
      :cumulative_quantity, # int: Used in regular trades, combo trades and legs of combo
      :liquidation => :bool, # This position is liquidated last should the need arise.
      [:account_name, :account_number] => :s, # The customer account number.
      [:side, :action] => PROPS[:side] # Was the transaction a buy or a sale: BOT|SLD

    # Extra validations
    validates_numericality_of :quantity, :cumulative_quantity, :price, :average_price
    validates_numericality_of :local_id, :client_id, :perm_id, :only_integer => true

    def default_attributes
      super.merge :local_id => 0,
        :client_id => 0,
        :quantity => 0,
        :price => 0,
        :perm_id => 0,
        :liquidation => false
    end

    # Comparison
    def == other
      super(other) ||
        other.is_a?(self.class) &&
        perm_id == other.perm_id &&
        local_id == other.local_id && # ((p __LINE__)||true) &&
        client_id == other.client_id &&
        exec_id == other.exec_id &&
        time == other.time &&
        exchange == other.exchange &&
        order_ref == other.order_ref &&
        side == other.side
      # TODO: || compare all attributes!
    end

    def to_human
      "<Execution: #{time} #{side} #{quantity} at #{price} on #{exchange}, " +
        "cumulative #{cumulative_quantity} at #{average_price}, " +
        "ids #{local_id}/#{perm_id}/#{exec_id}>"
    end

    alias to_s to_human

  end # Execution
end # module IB
