class AddIbOrders < ActiveRecord::Migration

  def change
    # OrderState represents dynamic (changeable) info about a single Order
    create_table(:ib_orders) do |t|
      t.references :contract # Optional link of Order to its contract

      t.integer :local_id #  int: Order id associated with client (volatile).
      t.integer :client_id # int: The id of the client that placed this order.
      t.integer :perm_id #   int: TWS permanent id, remains the same over TWS sessions.
      t.integer :parent_id # int: Order ID of the parent (original) order
      t.string :order_ref #       String: Order reference. Customer defined order ID tag.
      t.string :order_type, :limit => 20 #  Order type.
      t.string :tif, :limit => 3 #  Time in Force (time to market): DAY/GAT/GTD/GTC/IOC
      t.string :side, :limit => 1 # Action/side: BUY/SELL/SSHORT/SSHORTX
      t.integer :quantity # int: The order quantity.
      t.float :limit_price # double: LIMIT price, used for limit, stop-limit and relative
      t.float :aux_price #   double: STOP price for stop-limit orders, and the OFFSET amount
      t.integer :open_close # same as ComboLeg: SAME = 0; OPEN = 1; CLOSE = 2; UNKNOWN = 3
      t.integer :oca_type # int: Tells how to handle remaining orders in an OCA group
      t.string :oca_group #   String: Identifies a member of a one-cancels-all group.

      t.boolean :transmit, :limit => 1 #  If false, order will be created but not transmitted.
      t.boolean :what_if, :limit => 1 # Only return pre-trade commissions and margin info, do not place
      t.boolean :outside_rth, :limit => 1 # Order may trigger or fill outside of regular hours.
      t.boolean :not_held, :limit => 1 # Not Held
      t.boolean :hidden, :limit => 1 # Order will not be visible in market depth. ISLAND only.
      t.boolean :block_order, :limit => 1 #   This is an ISE Block order.
      t.boolean :sweep_to_fill, :limit => 1 # This is a Sweep-to-Fill order.
      t.boolean :all_or_none, :limit => 1 #     AON
      t.boolean :etrade_only, :limit => 1 #     Trade with electronic quotes.
      t.boolean :firm_quote_only, :limit => 1 # Trade with firm quotes.
      t.boolean :opt_out_smart_routing, :limit => 1 # Australian exchange only, default false
      t.boolean :override_percentage_constraints, :limit => 1

      t.integer :min_quantity # int: Identifies a minimum quantity order type.
      t.integer :display_size # int: publicly disclosed order size for Iceberg orders.
      t.integer :trigger_method # Specifies how Simulated Stop, Stop-Limit and Trailing
      t.integer :origin #          0=Customer, 1=Firm

      t.string :good_after_time # Indicates that the trade should be submitted after the
      t.string :good_till_date # Indicates that the trade should remain working until the
      t.string :rule_80a # Individual = 'I', Agency = 'A', AgentOtherMember = 'W',

      t.float :percent_offset #   double: percent offset amount for relative (REL)orders only
      t.float :trail_stop_price # double: for TRAILLIMIT orders only
      t.float :trailing_percent

      t.string :fa_group
      t.string :fa_profile
      t.string :fa_method
      t.string :fa_percentage

      t.integer :short_sale_slot # 1 - you hold the shares,
      t.string :designated_location # String: set when slot==2 only
      t.integer :exempt_code #       int
      t.string :account #  String: The account. For institutional customers only.
      t.string :settling_firm #    String: Institutional only
      t.string :clearing_account # String: For IBExecution customers: Specifies the
      t.string :clearing_intent # IBExecution customers: "", IB, Away, PTA (post trade allocation).
      t.float :discretionary_amount # double: The amount off the limit price
      t.float :nbbo_price_cap #  double: Maximum Smart order distance from the NBBO.
      t.integer :auction_strategy # For BOX exchange only. Valid values:
      t.float :starting_price #   double: Starting price. Valid on BOX orders only.
      t.float :stock_ref_price #  double: The stock reference price, used for VOL

      t.float :delta #            double: Stock delta. Valid on BOX orders only.
      t.float :stock_range_lower #   double: The lower value for the acceptable
      t.float :stock_range_upper #   double  The upper value for the acceptable
      t.float :volatility #  double: What the price is, computed via TWSs Options
      t.integer :volatility_type # int: How the volatility is calculated: 1=daily, 2=annual
      t.integer :reference_price_type # int: For dynamic management of volatility orders:
      t.integer :continuous_update # int: Used for dynamic management of volatility orders.
      t.string :delta_neutral_order_type # String: Enter an order type to instruct TWS
      t.string :delta_neutral_aux_price #  double: Use this field to enter a value if
      t.integer :delta_neutral_con_id
      t.string :delta_neutral_settling_firm
      t.string :delta_neutral_clearing_account
      t.string :delta_neutral_clearing_intent
      t.string :hedge_type # String: D = Delta, B = Beta, F = FX or P = Pair
      t.string :hedge_param # String; value depends on the hedgeType; sent from the API
      t.float :basis_points #      double: EFP orders only
      t.float :basis_points_type # double: EFP orders only
      t.string :algo_strategy

      t.text :leg_prices # Vector<OrderComboLeg> m_orderComboLegs
      t.text :algo_params # public Vector<TagValue> m_algoParams; ?!
      t.text :combo_params # not used yet

      t.integer :scale_init_level_size # int: Size of the first (initial) order component.
      t.integer :scale_subs_level_size # int: Order size of the subsequent scale order
      t.float :scale_price_increment # double: Price increment between scale components.
      t.float :scale_price_adjust_value
      t.integer :scale_price_adjust_interval
      t.float :scale_profit_offset
      t.integer :scale_init_position
      t.integer :scale_init_fill_qty
      t.boolean :scale_auto_reset, :limit => 1
      t.boolean :scale_random_percent, :limit => 1

      t.timestamp :placed_at
      t.timestamp :modified_at
      t.timestamps
    end
  end
end
