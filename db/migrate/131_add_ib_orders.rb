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

      t.boolean :transmit #  If false, order will be created but not transmitted.
      t.boolean :what_if # Only return pre-trade commissions and margin info, do not place
      t.boolean :outside_rth # Order may trigger or fill outside of regular hours.
      t.boolean :not_held # Not Held
      t.boolean :hidden # Order will not be visible in market depth. ISLAND only.
      t.boolean :block_order #   This is an ISE Block order.
      t.boolean :sweep_to_fill # This is a Sweep-to-Fill order.
      t.boolean :all_or_none #     AON
      t.boolean :etrade_only #     Trade with electronic quotes.
      t.boolean :firm_quote_only # Trade with firm quotes.
      t.boolean :opt_out_smart_routing # Australian exchange only, default false
      t.boolean :override_percentage_constraints

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
      t.boolean :scale_auto_reset
      t.boolean :scale_random_percent

      t.timestamp :placed_at
      t.timestamp :modified_at
      t.timestamps
    end
  end
end

__END__
rails generate scaffold order contract_id:integer local_id:integer client_id:integer 
 perm_id:integer parent_id:integer order_ref:string order_type:string tif:string side:string 
 quantity:integer limit_price:float aux_price:float open_close:integer oca_type:integer 
 oca_group:string transmit:boolean what_if:boolean outside_rth:boolean not_held:boolean 
 hidden:boolean block_order:boolean sweep_to_fill:boolean all_or_none:boolean etrade_only:boolean
 firm_quote_only:boolean opt_out_smart_routing:boolean override_percentage_constraints:boolean 
 min_quantity:integer display_size:integer trigger_method:integer origin:integer 
 good_after_time:string good_till_date:string rule_80a:string percent_offset:float 
 trail_stop_price:float trailing_percent:float fa_group:string fa_profile:string fa_method:string 
 fa_percentage:string short_sale_slot:integer designated_location:string exempt_code:integer 
 account:string settling_firm:string clearing_account:string clearing_intent:string 
 discretionary_amount:float nbbo_price_cap:float auction_strategy:integer starting_price:float 
 stock_ref_price:float delta:float stock_range_lower:float stock_range_upper:float 
 volatility:float volatility_type:integer reference_price_type:integer continuous_update:integer 
 delta_neutral_order_type:string delta_neutral_aux_price:string delta_neutral_con_id:integer 
 delta_neutral_settling_firm:string delta_neutral_clearing_account:string 
 delta_neutral_clearing_intent:string hedge_type:string hedge_param:string basis_points:float 
 basis_points_type:float algo_strategy:string leg_prices:text algo_params:text 
 combo_params:text scale_init_level_size:integer scale_subs_level_size:integer 
 scale_price_increment:float scale_price_adjust_value:float scale_price_adjust_interval:integer 
 scale_profit_offset:float scale_init_position:integer scale_init_fill_qty:integer 
 scale_auto_reset:boolean scale_random_percent:boolean placed_at:timestamp modified_at:timestamp
