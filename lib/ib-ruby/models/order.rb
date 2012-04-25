module IB
  module Models
    class Order < Model.for(:order)
      include ModelProperties

      # General Notes:
      # 1. Placing Orders by con_id - When you place an order by con_id, you must
      # provide the con_id AND the exchange. If you provide extra fields when placing
      # an order by conid, the order may not work.

      # 2. Order IDs - Each order you place must have a unique Order ID. Increment
      # your own Order IDs to avoid conflicts between orders placed from your API application.

      # Main order fields
      prop :local_id, #  int: Order id associated with client (volatile).
           :client_id, # int: The id of the client that placed this order.
           :perm_id, #   int: TWS permanent id, remains the same over TWS sessions.
           [:quantity, :total_quantity], # int: The order quantity.

           :order_type, #  String: Order type.
           # Limit Risk: MTL / MKT PRT / QUOTE / STP / STP LMT / TRAIL / TRAIL LIMIT /  TRAIL LIT / TRAIL MIT
           # Speed of Execution: MKT / MIT / MOC / MOO / PEG MKT / REL
           # Price Improvement: BOX TOP / LOC / LOO / LIT / PEG MID / VWAP
           # Advanced Trading: OCA / VOL / SCALE
           # Other (no abbreviation): Bracket, Auction, Discretionary, Sweep-to-Fill,
           # Price Improvement Auction,  Block, Hidden, Iceberg/Reserve, All-or-None, Fill-or-Kill
           # See 'ib-ruby/constants.rb' ORDER_TYPES for a complete list of valid values.

           :limit_price, # double: LIMIT price, used for limit, stop-limit and relative
           #               orders. In all other cases specify zero. For relative
           #               orders with no limit price, also specify zero.

           :aux_price, #   double: STOP price for stop-limit orders, and the OFFSET amount
           #               for relative orders. In all other cases, specify zero.

           :oca_group, #   String: Identifies a member of a one-cancels-all group.
           :oca_type, # int: Tells how to handle remaining orders in an OCA group
           #            when one order or part of an order executes. Valid values:
           #            - 1 = Cancel all remaining orders with block
           #            - 2 = Remaining orders are reduced in size with block
           #            - 3 = Remaining orders are reduced in size with no block
           #             If you use a value "with block" your order has
           #             overfill protection. This means that only one order in
           #             the group will be routed at a time to remove the
           #             possibility of an overfill.
           :parent_id, # int: The order ID of the parent (original) order, used
           #             for bracket (STP) and auto trailing stop (TRAIL) orders.
           :display_size, #   int: publicly disclosed order size for Iceberg orders.

           :trigger_method, # Specifies how Simulated Stop, Stop-Limit and Trailing
           #                  Stop orders are triggered. Valid values are:
           #      0 - Default, "double bid/ask" for OTC/US options, "last" otherswise.
           #      1 - "double bid/ask" method, stop orders are triggered based on
           #          two consecutive bid or ask prices.
           #      2 - "last" method, stops are triggered based on the last price.
           #      3 - double last method.
           #      4 - bid/ask method. For a buy order, a single occurrence of the
           #          bid price must be at or above the trigger price. For a sell
           #          order, a single occurrence of the ask price must be at or
           #          below the trigger price.
           #      7 - last or bid/ask method. For a buy order, a single bid price
           #          or the last price must be at or above the trigger price.
           #          For a sell order, a single ask price or the last price
           #          must be at or below the trigger price.
           #      8 - mid-point method, where the midpoint must be at or above
           #          (for a buy) or at or below (for a sell) the trigger price,
           #          and the spread between the bid and ask must be less than
           #          0.1% of the midpoint

           :good_after_time, # Indicates that the trade should be submitted after the
           #        time and date set, format YYYYMMDD HH:MM:SS (seconds are optional).
           :good_till_date, # Indicates that the trade should remain working until the
           #        time and date set, format YYYYMMDD HH:MM:SS (seconds are optional).
           #        You must set the :tif to GTD when using this string.
           #        Use an empty String if not applicable.

           :rule_80a, # Individual = 'I', Agency = 'A', AgentOtherMember = 'W',
           #            IndividualPTIA = 'J', AgencyPTIA = 'U', AgentOtherMemberPTIA = 'M',
           #            IndividualPT = 'K', AgencyPT = 'Y', AgentOtherMemberPT = 'N'
           :min_quantity, #     int: Identifies a minimum quantity order type.
           :percent_offset, #   double: percent offset amount for relative (REL)orders only
           :trail_stop_price, # double: for TRAILLIMIT orders only
           # As of client v.56, we receive trailing_percent in openOrder
           :trailing_percent,

           # Financial advisors only - use an empty String if not applicable.
           :fa_group, :fa_profile, :fa_method, :fa_percentage,

           # Institutional orders only!
           :origin, #          0=Customer, 1=Firm
           :order_ref, #       String: Order reference. Customer defined order ID tag.
           :short_sale_slot, # 1 - you hold the shares,
           #                   2 - they will be delivered from elsewhere.
           #                   Only for Action="SSHORT
           :designated_location, # String: set when slot==2 only
           :exempt_code, #       int

           #  Clearing info
           :account, #  String: The account. For institutional customers only.
           :settling_firm, #    String: Institutional only
           :clearing_account, # String: For IBExecution customers: Specifies the
           #                  true beneficiary of the order. This value is required
           #                  for FUT/FOP orders for reporting to the exchange.
           :clearing_intent, # IBExecution customers: "", IB, Away, PTA (post trade allocation).

           # SMART routing only
           :discretionary_amount, # double: The amount off the limit price
           #                        allowed for discretionary orders.
           :nbbo_price_cap, #  double: Maximum Smart order distance from the NBBO.

           # BOX or VOL ORDERS ONLY
           :auction_strategy, # For BOX exchange only. Valid values:
           #      1=AUCTION_MATCH, 2=AUCTION_IMPROVEMENT, 3=AUCTION_TRANSPARENT
           :starting_price, #   double: Starting price. Valid on BOX orders only.
           :stock_ref_price, #  double: The stock reference price, used for VOL
           # orders to compute the limit price sent to an exchange (whether or not
           # Continuous Update is selected), and for price range monitoring.
           :delta, #            double: Stock delta. Valid on BOX orders only.

           # Pegged to stock or VOL orders. For price improvement option orders
           # on BOX and VOL orders with dynamic management:
           :stock_range_lower, #   double: The lower value for the acceptable
           #                               underlying stock price range.
           :stock_range_upper, #   double  The upper value for the acceptable
           #                               underlying stock price range.

           # VOLATILITY ORDERS ONLY:
           # http://www.interactivebrokers.com/en/general/education/pdfnotes/PDF-VolTrader.php
           :volatility, #  double: What the price is, computed via TWSs Options
           #               Analytics. For VOL orders, the limit price sent to an
           #               exchange is not editable, as it is the output of a
           #               function. Volatility is expressed as a percentage.
           :volatility_type, # int: How the volatility is calculated: 1=daily, 2=annual
           :reference_price_type, # int: For dynamic management of volatility orders:
           #     - 1 = Average of National Best Bid or Ask,
           #     - 2 = National Best Bid when buying a call or selling a put;
           #           and National Best Ask when selling a call or buying a put.
           :continuous_update, # int: Used for dynamic management of volatility orders.
           # Determines whether TWS is supposed to update the order price as the underlying
           # moves. If selected, the limit price sent to an exchange is modified by TWS
           # if the computed price of the option changes enough to warrant doing so. This
           # is helpful in keeping the limit price up to date as the underlying price changes.
           :delta_neutral_order_type, # String: Enter an order type to instruct TWS
           #    to submit a delta neutral trade on full or partial execution of the
           #    VOL order. For no hedge delta order to be sent, specify NONE.
           #    Valid values - LMT, MKT, MTL, REL, MOC
           :delta_neutral_aux_price, #  double: Use this field to enter a value if
           #           the value in the deltaNeutralOrderType field is an order
           #           type that requires an Aux price, such as a REL order.

           # As of client v.52, we also receive delta... params in openOrder
           :delta_neutral_con_id,
           :delta_neutral_settling_firm,
           :delta_neutral_clearing_account,
           :delta_neutral_clearing_intent,

           # HEDGE ORDERS ONLY:
           # As of client v.49/50, we can now add hedge orders using the API.
           # Hedge orders are child orders that take additional fields. There are four
           # types of hedging orders supported by the API: Delta, Beta, FX, Pair.
           # All hedge orders must have a parent order submitted first. The hedge order
           # should set its :parent_id. If the hedgeType is Beta, the beta sent in the
           # hedgeParm can be zero, which means it is not used. Delta is only valid
           # if the parent order is an option and the child order is a stock.

           :hedge_type, # String: D = Delta, B = Beta, F = FX or P = Pair
           :hedge_param, # String; value depends on the hedgeType; sent from the API
           # only if hedge_type is NOT null. It is required for Pair hedge order,
           # optional for Beta hedge orders, and ignored for Delta and FX hedge orders.

           # COMBO ORDERS ONLY:
           :basis_points, #      double: EFP orders only
           :basis_points_type, # double: EFP orders only

           # ALGO ORDERS ONLY:
           :algo_strategy, # String
           :algo_params, # public Vector<TagValue> m_algoParams; ?!

           # SCALE ORDERS ONLY:
           :scale_init_level_size, # int: Size of the first (initial) order component.
           :scale_subs_level_size, # int: Order size of the subsequent scale order
           #             components. Used in conjunction with scaleInitLevelSize().
           :scale_price_increment, # double: Price increment between scale components.
           #                         This field is required for Scale orders.

           # As of client v.54, we can receive additional scale order fields:
           :scale_price_adjust_value,
           :scale_price_adjust_interval,
           :scale_profit_offset,
           :scale_init_position,
           :scale_init_fill_qty,
           :scale_auto_reset => :bool,
           :scale_random_percent => :bool

      # Properties with complex processing logics
      prop :tif, #  String: Time in Force (time to market): DAY/GAT/GTD/GTC/IOC
           :what_if => :bool, # Only return pre-trade commissions and margin info, do not place
           :not_held => :bool, # Not Held
           :outside_rth => :bool, # Order may trigger or fill outside of regular hours. (WAS: ignore_rth)
           :hidden => :bool, # Order will not be visible in market depth. ISLAND only.
           :transmit => :bool, #  If false, order will be created but not transmitted.
           :block_order => :bool, #   This is an ISE Block order.
           :sweep_to_fill => :bool, # This is a Sweep-to-Fill order.
           :override_percentage_constraints => :bool,
           # TWS Presets page constraints ensure that your price and size order values
           # are reasonable. Orders sent from the API are also validated against these
           # safety constraints, unless this parameter is set to True.
           :all_or_none => :bool, #     AON
           :etrade_only => :bool, #     Trade with electronic quotes.
           :firm_quote_only => :bool, # Trade with firm quotes.
           :opt_out_smart_routing => :bool, # Australian exchange only, default false
           :open_close => PROPS[:open_close], # Originally String: O=Open, C=Close ()
           # for ComboLeg compatibility: SAME = 0; OPEN = 1; CLOSE = 2; UNKNOWN = 3;
           [:side, :action] => PROPS[:side] # String: Action/side: BUY/SELL/SSHORT/SSHORTX

      prop :placed_at, :modified_at

      # TODO: restore!
      ## Returned in OpenOrder for Bag Contracts
      ## public Vector<OrderComboLeg> m_orderComboLegs
      #prop :algo_params, :leg_prices, :combo_params
      #
      #alias order_combo_legs leg_prices
      #alias smart_combo_routing_params combo_params
      #
      ##serialize :algo_params
      ##serialize :leg_prices
      ##serialize :combo_params

      # Order is always placed for a contract. Here, we explicitly set this link.
      belongs_to :contract

      # Order has a collection of Executions if it was filled
      has_many :executions

      # Order has a collection of OrderStates, last one is always current
      has_many :order_states

      def order_state
        order_states.last
      end

      def order_state= state
        self.order_states.push case state
                                 when IB::OrderState
                                   state
                                 when Symbol, String
                                   IB::OrderState.new :status => state
                               end
      end

      # Some properties received from IB are separated into OrderState object,
      # but they are still readable as Order properties through delegation:
      # Properties arriving via OpenOrder message:
      [:commission, # double: Shows the commission amount on the order.
       :commission_currency, # String: Shows the currency of the commission.
       :min_commission, # The possible min range of the actual order commission.
       :max_commission, # The possible max range of the actual order commission.
       :warning_text, # String: Displays a warning message if warranted.
       :init_margin, # Float: The impact the order would have on your initial margin.
       :maint_margin, # Float: The impact the order would have on your maintenance margin.
       :equity_with_loan, # Float: The impact the order would have on your equity
       :status, # String: Displays the order status. See OrderState for values
       # Properties arriving via OrderStatus message:
       :filled, #    int
       :remaining, # int
       :price, #    double
       :last_fill_price, #    double
       :average_price, # double
       :average_fill_price, # double
       :why_held, # String: comma-separated list of reasons for order to be held.
       # Testing Order state:
       :new?,
       :submitted?,
       :pending?,
       :active?,
       :inactive?,
       :complete_fill?,
      ].each { |property| define_method(property) { order_state.send(property) } }

      # Order is not valid without correct :local_id
      validates_numericality_of :local_id, :perm_id, :client_id, :parent_id,
                                :quantity, :min_quantity, :display_size,
                                :only_integer => true, :allow_nil => true

      validates_numericality_of :limit_price, :aux_price, :allow_nil => true


      def default_attributes
        super.merge :aux_price => 0.0,
                    :discretionary_amount => 0.0,
                    :parent_id => 0,
                    :tif => :day,
                    :order_type => :limit,
                    :open_close => :open,
                    :origin => :customer,
                    :short_sale_slot => :default,
                    :trigger_method => :default,
                    :oca_type => :none,
                    :auction_strategy => :none,
                    :designated_location => '',
                    :exempt_code => -1,
                    :display_size => 0,
                    :continuous_update => 0,
                    :delta_neutral_con_id => 0,
                    :algo_strategy => '',
                    :transmit => true,
                    :what_if => false,
                    :order_state => IB::OrderState.new(:status => 'New',
                                                       :filled => 0,
                                                       :remaining => 0,
                                                       :price => 0,
                                                       :average_price => 0)
      end

      #after_initialize do #opts = {}
      #                    #self.leg_prices = []
      #                    #self.algo_params = {}
      #                    #self.combo_params = {}
      #                    #self.order_state ||= IB::OrderState.new :status => 'New'
      #end

      # This returns an Array of data from the given order,
      # mixed with data from associated contract. Ugly mix, indeed.
      def serialize_with server, contract
        [contract.serialize_long(:con_id, :sec_id),
         # main order fields
         case side
           when :short
             'SSHORT'
           when :short_exempt
             'SSHORTX'
           else
             side.to_sup
         end,
         quantity,
         self[:order_type], # Internal code, 'LMT' instead of :limit
         limit_price,
         aux_price,
         self[:tif],
         oca_group,
         account,
         open_close.to_sup[0..0],
         self[:origin],
         order_ref,
         transmit,
         parent_id,
         block_order || false,
         sweep_to_fill || false,
         display_size,
         self[:trigger_method],
         outside_rth || false, # was: ignore_rth
         hidden || false,
         contract.serialize_legs(:extended),

         # This is specific to PlaceOrder v.38, NOT supported by API yet!
         #
         ## Support for per-leg prices in Order
         #if server[:server_version] >= 61 && contract.bag?
         #  leg_prices.empty? ? 0 : [leg_prices.size] + leg_prices
         #else
         #  []
         #end,
         #
         ## Support for combo routing params in Order
         #if server[:server_version] >= 57 && contract.bag?
         #  p 'Here!'
         #  combo_params.empty? ? 0 : [combo_params.size] + combo_params.to_a
         #else
         #  []
         #end,

         '', # deprecated shares_allocation field
         discretionary_amount,
         good_after_time,
         good_till_date,
         fa_group,
         fa_method,
         fa_percentage,
         fa_profile,
         self[:short_sale_slot], # 0 only for retail, 1 or 2 for institution  (Institutional)
         designated_location, # only populate when short_sale_slot == 2    (Institutional)
         exempt_code,
         self[:oca_type],
         rule_80a,
         settling_firm,
         all_or_none || false,
         min_quantity,
         percent_offset,
         etrade_only || false,
         firm_quote_only || false,
         nbbo_price_cap,
         self[:auction_strategy],
         starting_price,
         stock_ref_price,
         delta,
         stock_range_lower,
         stock_range_upper,
         override_percentage_constraints || false,
         volatility, #                      Volatility orders
         self[:volatility_type], #
         self[:delta_neutral_order_type],
         delta_neutral_aux_price, #

         # Support for delta neutral orders with parameters
         if server[:server_version] >= 58 && delta_neutral_order_type
           [delta_neutral_con_id,
            delta_neutral_settling_firm,
            delta_neutral_clearing_account,
            self[:delta_neutral_clearing_intent]
           ]
         else
           []
         end,

         continuous_update, #               Volatility orders
         self[:reference_price_type], #     Volatility orders

         trail_stop_price, #         TRAIL_STOP_LIMIT stop price

         # Support for trailing percent
         server[:server_version] >= 62 ? trailing_percent : [],

         scale_init_level_size, #    Scale Orders
         scale_subs_level_size, #    Scale Orders
         scale_price_increment, #    Scale Orders

         # Support extended scale orders parameters
         if server[:server_version] >= 60 &&
             scale_price_increment && scale_price_increment > 0
           [scale_price_adjust_value,
            scale_price_adjust_interval,
            scale_profit_offset,
            scale_auto_reset || false,
            scale_init_position,
            scale_init_fill_qty,
            scale_random_percent || false
           ]
         else
           []
         end,

         # TODO: Need to add support for hedgeType, not working ATM - beta only
         # if (m_serverVersion >= MIN_SERVER_VER_HEDGE_ORDERS) {
         #    send (order.m_hedgeType);
         #    if (!IsEmpty(order.m_hedgeType)) send (order.m_hedgeParam); }
         #
         # if (m_serverVersion >= MIN_SERVER_VER_OPT_OUT_SMART_ROUTING) {
         #    send (order.m_optOutSmartRouting) ; || false }

         clearing_account,
         clearing_intent,
         not_held || false,
         contract.serialize_under_comp,
         serialize_algo(),
         what_if]
      end

      def serialize_algo
        if algo_strategy.nil? || algo_strategy.empty?
          ''
        else
          [algo_strategy,
           algo_params.size,
           algo_params.to_a]
        end
      end

      # Placement
      def place contract, connection
        error "Unable to place order, next_local_id not known" unless connection.next_local_id
        self.client_id = connection.server[:client_id]
        self.local_id = connection.next_local_id
        connection.next_local_id += 1
        self.placed_at = Time.now
        modify contract, connection, self.placed_at
      end

      # Modify Order (convenience wrapper for send_message :PlaceOrder). Returns local_id.
      def modify contract, connection, time=Time.now
        self.modified_at = time
        connection.send_message :PlaceOrder,
                                :order => self,
                                :contract => contract,
                                :local_id => local_id
        local_id
      end

      # Order comparison
      def == other
        perm_id && other.perm_id && perm_id == other.perm_id ||
            local_id == other.local_id && # ((p __LINE__)||true) &&
                (client_id == other.client_id || client_id == 0 || other.client_id == 0) &&
                parent_id == other.parent_id &&
                tif == other.tif &&
                action == other.action &&
                order_type == other.order_type &&
                quantity == other.quantity &&
                (limit_price == other.limit_price || # TODO Floats should be Decimals!
                    (limit_price - other.limit_price).abs < 0.00001) &&
                aux_price == other.aux_price &&
                origin == other.origin &&
                designated_location == other.designated_location &&
                exempt_code == other.exempt_code &&
                what_if == other.what_if &&
                algo_strategy == other.algo_strategy &&
                algo_params == other.algo_params

        # TODO: || compare all attributes!
      end

      def to_s #human
        "<Order:" + instance_variables.map do |key|
          value = instance_variable_get(key)
          " #{key}=#{value}" unless value.nil? || value == '' || value == 0
        end.compact.join(',') + " >"
      end

      def to_human
        "<Order: " + ((order_ref && order_ref != '') ? "#{order_ref} " : '') +
            "#{self[:order_type]} #{self[:tif]} #{side} #{quantity} " +
            "#{status} " + (limit_price ? "#{limit_price} " : '') +
            ((aux_price && aux_price != 0) ? "/#{aux_price}" : '') +
            "##{local_id}/#{perm_id} from #{client_id}" +
            (account ? "/#{account}" : '') +
            (commission ? " fee #{commission}" : '') + ">"
      end
    end # class Order
  end # module Models
end # module IB
