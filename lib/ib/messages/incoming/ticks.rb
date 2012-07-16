# All message classes related to ticks located here
module IB
  module Messages
    module Incoming

      class AbstractTick < AbstractMessage
        # Returns Symbol with a meaningful name for received tick type
        def type
          TICK_TYPES[@data[:tick_type]]
        end

        def to_human
          "<#{self.message_type} #{type}:" +
              @data.map do |key, value|
                " #{key} #{value}" unless [:version, :ticker_id, :tick_type].include?(key)
              end.compact.join(',') + " >"
        end
      end

      # The IB code seems to dispatch up to two wrapped objects for this message, a tickPrice
      # and sometimes a tickSize, which seems to be identical to the TICK_SIZE object.
      #
      # Important note from
      # http://chuckcaplan.com/twsapi/index.php/void%20tickPrice%28%29 :
      #
      # "The low you get is NOT the low for the day as you'd expect it
      # to be. It appears IB calculates the low based on all
      # transactions after 4pm the previous day. The most inaccurate
      # results occur when the stock moves up in the 4-6pm aftermarket
      # on the previous day and then gaps open upward in the
      # morning. The low you receive from TWS can be easily be several
      # points different from the actual 9:30am-4pm low for the day in
      # cases like this. If you require a correct traded low for the
      # day, you can't get it from the TWS API. One possible source to
      # help build the right data would be to compare against what Yahoo
      # lists on finance.yahoo.com/q?s=ticker under the "Day's Range"
      # statistics (be careful here, because Yahoo will use anti-Denial
      # of Service techniques to hang your connection if you try to
      # request too many bytes in a short period of time from them). For
      # most purposes, a good enough approach would start by replacing
      # the TWS low for the day with Yahoo's day low when you first
      # start watching a stock ticker; let's call this time T. Then,
      # update your internal low if the bid or ask tick you receive is
      # lower than that for the remainder of the day. You should check
      # against Yahoo again at time T+20min to handle the occasional
      # case where the stock set a new low for the day in between
      # T-20min (the real time your original quote was from, taking into
      # account the delay) and time T. After that you should have a
      # correct enough low for the rest of the day as long as you keep
      # updating based on the bid/ask. It could still get slightly off
      # in a case where a short transaction setting a new low appears in
      # between ticks of data that TWS sends you.  The high is probably
      # distorted in the same way the low is, which would throw your
      # results off if the stock traded after-hours and gapped down. It
      # should be corrected in a similar way as described above if this
      # is important to you."
      #
      # IB then emits at most 2 events on eWrapper:
      #          tickPrice( tickerId, tickType, price, canAutoExecute)
      #          tickSize( tickerId, sizeTickType, size)
      TickPrice = def_message [1, 6], AbstractTick,
                              [:ticker_id, :int],
                              [:tick_type, :int],
                              [:price, :decimal],
                              [:size, :int],
                              [:can_auto_execute, :int]

      TickSize = def_message [2, 6], AbstractTick,
                             [:ticker_id, :int],
                             [:tick_type, :int],
                             [:size, :int]

      TickGeneric = def_message [45, 6], AbstractTick,
                                [:ticker_id, :int],
                                [:tick_type, :int],
                                [:value, :decimal]

      TickString = def_message [46, 6], AbstractTick,
                               [:ticker_id, :int],
                               [:tick_type, :int],
                               [:value, :string]

      TickEFP = def_message [47, 6], AbstractTick,
                            [:ticker_id, :int],
                            [:tick_type, :int],
                            [:basis_points, :decimal],
                            [:formatted_basis_points, :string],
                            [:implied_futures_price, :decimal],
                            [:hold_days, :int],
                            [:dividend_impact, :decimal],
                            [:dividends_to_expiry, :decimal]

      # This message is received when the market in an option or its underlier moves.
      # TWS option model volatilities, prices, and deltas, along with the present
      # value of dividends expected on that options underlier are received.
      # TickOption message contains following @data:
      #    :ticker_id - Id that was specified previously in the call to reqMktData()
      #    :tick_type - Specifies the type of option computation (see TICK_TYPES).
      #    :implied_volatility - The implied volatility calculated by the TWS option
      #                          modeler, using the specified :tick_type value.
      #    :delta - The option delta value.
      #    :option_price - The option price.
      #    :pv_dividend - The present value of dividends expected on the options underlier
      #    :gamma - The option gamma value.
      #    :vega - The option vega value.
      #    :theta - The option theta value.
      #    :under_price - The price of the underlying.
      TickOptionComputation = TickOption =
          def_message([21, 6], AbstractTick,
                      [:ticker_id, :int],
                      [:tick_type, :int],
                      #                       What is the "not yet computed" indicator:
                      [:implied_volatility, :decimal_limit_1], # -1 and below
                      [:delta, :decimal_limit_2], #              -2 and below
                      [:option_price, :decimal_limit_1], #       -1   -"-
                      [:pv_dividend, :decimal_limit_1], #        -1   -"-
                      [:gamma, :decimal_limit_2], #              -2   -"-
                      [:vega, :decimal_limit_2], #               -2   -"-
                      [:theta, :decimal_limit_2], #              -2   -"-
                      [:under_price, :decimal_limit_1]) do

            "<TickOption #{type} for #{:ticker_id}: underlying @ #{under_price}, "+
                "option @ #{option_price}, IV #{implied_volatility}%, delta #{delta}, " +
                "gamma #{gamma}, vega #{vega}, theta #{theta}, pv_dividend #{pv_dividend}>"
          end

      TickSnapshotEnd = def_message 57, [:ticker_id, :int]

    end # module Incoming
  end # module Messages
end # module IB
