module IB
  ### Widely used TWS constants:

  EOL = "\0"

  # Enumeration of bar size types for convenience.
  # Bar sizes less than 30 seconds do not work for some securities.
  BAR_SIZES = {'1 sec' => :sec1,
               '5 secs' => :sec5,
               '15 secs' =>:sec15,
               '30 secs' =>:sec30,
               '1 min' => :min1,
               '2 mins' => :min2,
               '3 mins' => :min3,
               '5 mins' => :min5,
               '15 mins' =>:min15,
               '30 mins' =>:min30,
               '1 hour' =>:hour1,
               '1 day' => :day1
  }.freeze

  # Enumeration of data types.
  # Determines the nature of data being extracted. Valid values:
  DATA_TYPES = {'TRADES' => :trades,
                'MIDPOINT' => :midpoint,
                'BID' => :bid,
                'ASK' => :ask,
                'BID_ASK' => :bid_ask,
                'HISTORICAL_VOLATILITY' => :historical_volatility,
                'OPTION_IMPLIED_VOLATILITY' => :option_implied_volatility,
                'OPTION_VOLUME' => :option_volume,
                'OPTION_OPEN_INTEREST' => :option_open_interest
  }.freeze

  ### These values are typically received from TWS in incoming messages

  # Tick types as received in TickPrice and TickSize messages (enumeration)
  TICK_TYPES = {
      # int id => :Description #  Corresponding API Event/Function/Method
      0 => :bid_size, #               tickSize()
      1 => :bid_price, #              tickPrice()
      2 => :ask_price, #              tickPrice()
      3 => :ask_size, #               tickSize()
      4 => :last_price, #             tickPrice()
      5 => :last_size, #              tickSize()
      6 => :high, #                   tickPrice()
      7 => :low, #                    tickPrice()
      8 => :volume, #                 tickSize()
      9 => :close_price, #            tickPrice()
      10 => :bid_option, #            tickOptionComputation() See Note 1 below
      11 => :ask_option, #            tickOptionComputation() See => :Note 1 below
      12 => :last_option, #           tickOptionComputation()  See Note 1 below
      13 => :model_option, #          tickOptionComputation() See Note 1 below
      14 => :open_tick, #             tickPrice()
      15 => :low_13_week, #           tickPrice()
      16 => :high_13_week, #          tickPrice()
      17 => :low_26_week, #           tickPrice()
      18 => :high_26_week, #          tickPrice()
      19 => :low_52_week, #           tickPrice()
      20 => :high_52_week, #          tickPrice()
      21 => :avg_volume, #            tickSize()
      22 => :open_interest, #         tickSize()
      23 => :option_historical_vol, # tickGeneric()
      24 => :option_implied_vol, #    tickGeneric()
      25 => :option_bid_exch, #   not USED
      26 => :option_ask_exch, #   not USED
      27 => :option_call_open_interest, # tickSize()
      28 => :option_put_open_interest, #  tickSize()
      29 => :option_call_volume, #        tickSize()
      30 => :option_put_volume, #         tickSize()
      31 => :index_future_premium, #      tickGeneric()
      32 => :bid_exch, #                  tickString()
      33 => :ask_exch, #                  tickString()
      34 => :auction_volume, #    not USED
      35 => :auction_price, #     not USED
      36 => :auction_imbalance, # not USED
      37 => :mark_price, #              tickPrice()
      38 => :bid_efp_computation, #     tickEFP()
      39 => :ask_efp_computation, #     tickEFP()
      40 => :last_efp_computation, #    tickEFP()
      41 => :open_efp_computation, #    tickEFP()
      42 => :high_efp_computation, #    tickEFP()
      43 => :low_efp_computation, #     tickEFP()
      44 => :close_efp_computation, #   tickEFP()
      45 => :last_timestamp, #          tickString()
      46 => :shortable, #               tickGeneric()
      47 => :fundamental_ratios, #      tickString()
      48 => :rt_volume, #               tickGeneric()
      49 => :halted, #           see Note 2 below.
      50 => :bid_yield, #               tickPrice() See Note 3 below
      51 => :ask_yield, #               tickPrice() See Note 3 below
      52 => :last_yield, #              tickPrice() See Note 3 below
      53 => :cust_option_computation, # tickOptionComputation()
      54 => :trade_count, #             tickGeneric()
      55 => :trade_rate, #              tickGeneric()
      56 => :volume_rate, #             tickGeneric()
      57 => :last_rth_trade, #            ?
      #   Note 1: Tick types BID_OPTION, ASK_OPTION, LAST_OPTION, and MODEL_OPTION return
      #           all Greeks (delta, gamma, vega, theta), the underlying price and the
      #           stock and option reference price when requested.
      #           MODEL_OPTION also returns model implied volatility.
      #   Note 2: When trading is halted for a contract, TWS receives a special tick:
      #           haltedLast=1. When trading is resumed, TWS receives haltedLast=0.
      #           A tick type, HALTED, tick ID= 49, is now available in regular market
      #           data via the API to indicate this halted state. Possible values for
      #           this new tick type are: 0 = Not halted, 1 = Halted.
      #   Note 3: Applies to bond contracts only.
  }

  # Financial Advisor types (FaMsgTypeName)
  FA_TYPES = {
      1 => :groups,
      2 => :profiles,
      3 => :aliases}.freeze

  # Received in new MarketDataType (58 incoming) message
  MARKET_DATA_TYPES = {
      0 => :unknown,
      1 => :real_time,
      2 => :frozen,
  }

  # Market depth messages contain these "operation" codes to tell you what to do with the data.
  # See also http://www.interactivebrokers.com/php/apiUsersGuide/apiguide/java/updatemktdepth.htm
  MARKET_DEPTH_OPERATIONS = {
      0 => :insert, # New order, insert into the row identified by :position
      1 => :update, # Update the existing order at the row identified by :position
      2 => :delete # Delete the existing order at the row identified by :position
  }.freeze

  MARKET_DEPTH_SIDES = {
      0 => :ask,
      1 => :bid
  }.freeze

  ORDER_TYPES =
      {'LMT' => :limit, #                  Limit Order
       'LIT' => :limit_if_touched, #       Limit if Touched
       'LOC' => :limit_on_close, #         Limit-on-Close      LMTCLS ?
       'LOO' => :limit_on_open, #          Limit-on-Open
       'MKT' => :market, #                 Market
       'MIT' => :market_if_touched, #      Market-if-Touched
       'MOC' => :market_on_close, #        Market-on-Close     MKTCLSL ?
       'MOO' => :market_on_open, #         Market-on-Open
       'MTL' => :market_to_limit, #        Market-to-Limit
       'MKTPRT' => :market_protected, #   Market with Protection
       'QUOTE' => :request_for_quote, #    Request for Quote
       'STP' => :stop, #                   Stop
       'STPLMT' => :stop_limit, #         Stop Limit
       'TRAIL' => :trailing_stop, #        Trailing Stop
       'TRAIL LIMIT' => :trailing_limit, # Trailing Stop Limit
       'TRAIL LIT' => :trailing_limit_if_touched, #  Trailing Limit if Touched
       'TRAIL MIT' => :trailing_market_if_touched, # Trailing Market If Touched
       'PEG MKT' => :pegged_to_market, #   Pegged-to-Market
       'REL' => :relative, #               Relative
       'BOX TOP' => :box_top, #            Box Top
       'PEG MID' => :pegged_to_midpoint, # Pegged-to-Midpoint
       'VWAP' => :vwap, #                  VWAP-Guaranteed
       'OCA' => :one_cancels_all, #        One-Cancels-All
       'VOL' => :volatility, #             Volatility
       'SCALE' => :scale, #                Scale
       'NONE' => :no_order # Used to indicate no hedge in :delta_neutral_order_type
      }.freeze

  # Valid security types (sec_type attribute of IB::Contract)
  SECURITY_TYPES =
      {'STK' => :stock,
       'OPT' => :option,
       'FUT' => :future,
       'IND' => :index,
       'FOP' => :futures_option,
       'CASH' => :forex,
       'BOND' => :bond,
       'WAR' => :warrant,
       'FUND' => :fund, # ETF?
       'BAG' => :bag}.freeze

  # Obtain symbolic value from given property code:
  # VALUES[:side]['B'] -> :buy
  VALUES = {
      :sec_type => SECURITY_TYPES,
      :order_type => ORDER_TYPES,
      :delta_neutral_order_type => ORDER_TYPES,

      :origin => {0 => :customer, 1 => :firm},
      :volatility_type => {1 => :daily, 2 => :annual},
      :reference_price_type => {1 => :average, 2 => :bid_or_ask},

      # This property encodes differently for ComboLeg and Order objects,
      # we use ComboLeg codes and transcode for Order codes as needed
      :open_close =>
          {0 => :same, # Default for Legs, same as the parent (combo) security.
           1 => :open, #  Open. For Legs, this value is only used by institutions.
           2 => :close, # Close. For Legs, this value is only used by institutions.
           3 => :unknown}, # WTF

      :right =>
          {'' => :none, # Not an option
           'P' => :put,
           'C' => :call},

      :side => # AKA action
          {'B' => :buy, # or BOT
           'S' => :sell, # or SLD
           'T' => :short, # short
           'X' => :short_exempt # Short Sale Exempt action. This allows some orders
           # to be exempt from the SEC recent changes to Regulation SHO, which
           # eliminated the old uptick rule and replaced it with a new "circuit breaker"
           # rule, and allows some orders to be exempt from the new rule.
          },

      :short_sale_slot =>
          {0 => :default, #      The only valid option for retail customers
           1 => :broker, #       Shares are at your clearing broker, institutions
           2 => :third_party}, # Shares will be delivered from elsewhere, institutions

      :oca_type =>
          {0 => :none, # Not a member of OCA group
           1 => :cancel_with_block, # Cancel all remaining orders with block
           2 => :reduce_with_block, # Remaining orders are reduced in size with block
           3 => :reduce_no_block}, # Remaining orders are reduced in size with no block

      :auction_strategy =>
          {0 => :none, # Not a BOX order
           1 => :match,
           2 => :improvement,
           3 => :transparent},

      :trigger_method =>
          {0 => :default, # "double bid/ask" used for OTC/US options, "last" otherswise.
           1 => :double_bid_ask, # stops are triggered by 2 consecutive bid or ask prices.
           2 => :last, # stops are triggered based on the last price.
           3 => :double_last,
           4 => :bid_ask, # bid >= trigger price for buy orders, ask <= trigger for sell orders
           7 => :last_or_bid_ask, # bid OR last price >= trigger price for buy orders
           8 => :mid_point}, # midpoint >= trigger price for buy orders and the
      #      spread between the bid and ask must be less than 0.1% of the midpoint

      :hedge_type =>
          {'D' => :delta, # parent order is an option and the child order is a stock
           'B' => :beta, # offset market risk by entering into a position with
           #               another contract based on the system or user-defined beta
           'F' => :forex, # offset risk with currency different from your base currency
           'P' => :pair}, # trade a mis-valued pair of contracts and provide the
      #                     ratio between the parent and hedging child order

      :clearing_intent =>
          {'' => :none,
           'IB' => :ib,
           'AWAY' => :away,
           'PTA' => :post_trade_allocation},

      :delta_neutral_clearing_intent =>
          {'' => :none,
           'IB' => :ib,
           'AWAY' => :away,
           'PTA' => :post_trade_allocation},

      :tif =>
          {'DAY' => :day,
           'GAT' => :good_after_time,
           'GTD' => :good_till_date,
           'GTC' => :good_till_cancelled,
           'IOC' => :immediate_or_cancel},

      :rule_80a =>
          {'I' => :individual,
           'A' => :agency,
           'W' => :agent_other_member,
           'J' => :individual_ptia,
           'U' => :agency_ptia,
           'M' => :agent_other_member_ptia,
           'K' => :individual_pt,
           'Y' => :agency_pt,
           'N' => :agent_other_member_pt},

      :opt? => # TODO: unknown Order property, like OPT_BROKER_DEALER... in Order.java
          {'?' => :unknown,
           'b' => :broker_dealer,
           'c' => :customer,
           'f' => :firm,
           'm' => :isemm,
           'n' => :farmm,
           'y' => :specialist},

  }.freeze

  # Obtain property code from given symbolic value:
  # CODES[:side][:buy] -> 'B'
  CODES = Hash[VALUES.map { |property, hash| [property, hash.invert] }].freeze

  # Most common property processors
  PROPS = {:side =>
               {:set => proc { |val| # BUY(BOT)/SELL(SLD)/SSHORT/SSHORTX
                 self[:side] = case val.to_s.upcase
                                 when /SHORT.*X|^X$/
                                   'X'
                                 when /SHORT|^T$/
                                   'T'
                                 when /^B/
                                   'B'
                                 when /^S/
                                   'S'
                               end },
                :validate =>
                    {:format =>
                         {:with => /^buy$|^sell$|^short$|^short_exempt$/,
                          :message => "should be buy/sell/short"}
                    }
               },

           :open_close =>
               {:set => proc { |val|
                 self[:open_close] = case val.to_s.upcase[0..0]
                                       when 'S', '0' # SAME
                                         0
                                       when 'O', '1' # OPEN
                                         1
                                       when 'C', '2' # CLOSE
                                         2
                                       when 'U', '3' # Unknown
                                         3
                                     end
               },
                :validate =>
                    {:format =>
                         {:with => /^same$|^open$|^close$|^unknown$/,
                          :message => "should be same/open/close/unknown"}
                    },
               }
  }.freeze

end # module IB
