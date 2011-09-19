module IB
  ### Widely used TWS constants:

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
      51 => :asky_ield, #               tickPrice() See Note 3 below
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
end # module IB
