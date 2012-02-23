module IB
  ### Widely used TWS constants:

  EOL = "\0"

  # Enumeration of bar size types for convenience.
  # Bar sizes less than 30 seconds do not work for some securities.
  BAR_SIZES = {:sec1 => '1 sec',
               :sec5 => '5 secs',
               :sec15 => '15 secs',
               :sec30 => '30 secs',
               :min1 => '1 min',
               :min2 => '2 mins',
               :min3 => '3 mins',
               :min5 => '5 mins',
               :min15 => '15 mins',
               :min30 => '30 mins',
               :hour1 => '1 hour',
               :day1 => '1 day'}

  # Enumeration of data types.
  # Determines the nature of data being extracted. Valid values:
  DATA_TYPES = {:trades => 'TRADES',
                :midpoint => 'MIDPOINT',
                :bid => 'BID',
                :ask => 'ASK',
                :bid_ask => 'BID_ASK',
                :historical_volatility => 'HISTORICAL_VOLATILITY',
                :option_implied_volatility => 'OPTION_IMPLIED_VOLATILITY',
                :option_volume => 'OPTION_VOLUME',
                :option_open_interest => 'OPTION_OPEN_INTEREST',
  }

  # Valid security types (sec_type attribute of IB::Contract)
  SECURITY_TYPES = {:stock => "STK",
                    :option => "OPT",
                    :future => "FUT",
                    :index => "IND",
                    :futures_option => "FOP",
                    :forex => "CASH",
                    :bond => "BOND",
                    :bag => "BAG"}

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
  FA_TYPES = {1 => 'GROUPS',
              2 => 'PROFILES',
              3 =>'ALIASES'}

  # Market depth messages contain these "operation" codes to tell you what to do with the data.
  # See also http://www.interactivebrokers.com/php/apiUsersGuide/apiguide/java/updatemktdepth.htm
  MARKET_DEPTH_OPERATIONS = {
      0 => :insert, # New order, insert into the row identified by :position
      1 => :update, # Update the existing order at the row identified by :position
      2 => :delete # Delete the existing order at the row identified by :position
  }

  MARKET_DEPTH_SIDES = {
      0 => :ask,
      1 => :bid
  }
end # module IB
