require 'ib-ruby/messages/abstract_message'

# EClientSocket.java uses sendMax() rather than send() for a number of these.
# It sends an EOL rather than a number if the value == Integer.MAX_VALUE (or Double.MAX_VALUE).
# These fields are initialized to this MAX_VALUE.
# This has been implemented with nils in Ruby to represent the case where an EOL should be sent.

# TODO: Don't instantiate messages, use their classes as just namespace for .encode/decode
# TODO: realize Message#fire method that raises EWrapper events

module IB
  module Messages

    # Incoming IB messages
    module Incoming
      extend Messages # def_message macros

      Classes = Array.new

      class AbstractMessage < IB::Messages::AbstractMessage

        def self.inherited(by)
          super(by)
          Classes.push(by)
        end

        def version # Per message, received messages may have the different versions
          @data[:version]
        end

        # Read incoming message from given socket or instantiate with given data
        def initialize socket_or_data
          @created_at = Time.now
          if socket_or_data.is_a?(Hash)
            @data = socket_or_data
          else
            @data = {}
            @socket = socket_or_data
            self.load
            @socket = nil
          end
        end

        # Every message loads received message version first
        def load
          @data[:version] = @socket.read_int

          if @data[:version] != self.class.version
            raise "Unsupported version #{@data[:version]} of #{self.class} received"
          end

          load_map *self.class.data_map
        end

        # Load @data from the socket according to the given map.
        #
        # map is a series of Arrays in the format of
        #   [ [ :name, :type ],
        #     [  :group, :name, :type] ]
        # type identifiers must have a corresponding read_type method on socket (read_int, etc.).
        # group is used to lump together aggregates, such as Contract or Order fields
        def load_map(*map)
          map.each do |(m1, m2, m3)|
            group, name, type = m3 ? [m1, m2, m3] : [nil, m1, m2]

            data = @socket.__send__("read_#{type}")
            if group
              @data[group] ||= {}
              @data[group][name] = data
            else
              @data[name] = data
            end
          end
        end
      end # class AbstractMessage

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

      ### Actual message classes (short definitions):
      #:status - String: Displays the order status. Possible values include:
      # � PendingSubmit - indicates that you have transmitted the order, but
      #   have not yet received confirmation that it has been accepted by the
      #   order destination. NOTE: This order status is NOT sent back by TWS
      #   and should be explicitly set by YOU when an order is submitted.
      # � PendingCancel - indicates that you have sent a request to cancel
      #   the order but have not yet received cancel confirmation from the
      #   order destination. At this point, your order cancel is not confirmed.
      #   You may still receive an execution while your cancellation request
      #   is pending. NOTE: This order status is not sent back by TWS and
      #   should be explicitly set by YOU when an order is canceled.
      # � PreSubmitted - indicates that a simulated order type has been
      #   accepted by the IB system and that this order has yet to be elected.
      #   The order is held in the IB system until the election criteria are
      #   met. At that time the order is transmitted to the order destination
      #   as specified.
      # � Submitted - indicates that your order has been accepted at the order
      #   destination and is working.
      # � Cancelled - indicates that the balance of your order has been
      #   confirmed canceled by the IB system. This could occur unexpectedly
      #   when IB or the destination has rejected your order.
      # � Filled - indicates that the order has been completely filled.
      # � Inactive - indicates that the order has been accepted by the system
      #   (simulated orders) or an exchange (native orders) but that currently
      #   the order is inactive due to system, exchange or other issues.
      # :why_held - This field is used to identify an order held when TWS is trying to
      #      locate shares for a short sell. The value used to indicate this is 'locate'.
      OrderStatus = def_message [3, 6], [:order_id, :int],
                                [:status, :string],
                                [:filled, :int],
                                [:remaining, :int],
                                [:average_fill_price, :decimal],
                                [:perm_id, :int],
                                [:parent_id, :int],
                                [:last_fill_price, :decimal],
                                [:client_id, :int],
                                [:why_held, :string] do
        "<OrderStatus: #{status} filled: #{filled}/#{remaining + filled}" +
            " @ last/avg: #{last_fill_price}/#{average_fill_price}" +
            (parent_id > 0 ? "parent_id: #{parent_id}" : "") +
            (why_held != "" ? "why_held: #{why_held}" : "") +
            " id/perm: #{order_id}/#{perm_id}>"
      end


      AccountValue = def_message([6, 2], [:key, :string],
                                 [:value, :string],
                                 [:currency, :string],
                                 [:account_name, :string]) do
        "<AccountValue: #{account_name}, #{key}=#{value} #{currency}>"
      end

      AccountUpdateTime = def_message 8, [:time_stamp, :string]

      # This message is always sent by TWS automatically at connect.
      # The IB::Connection class subscribes to it automatically and stores
      # the order id in its @next_order_id attribute.
      NextValidID = NextValidId = def_message(9, [:order_id, :int])

      NewsBulletins =
          def_message 14, [:request_id, :int], # unique incrementing bulletin ID.
                      [:type, :int], # Type of bulletin. Valid values include:
                      #     1 = Regular news bulletin
                      #     2 = Exchange no longer available for trading
                      #     3 = Exchange is available for trading
                      [:text, :string], # The bulletin's message text.
                      [:exchange, :string] # Exchange from which this message originated.

      ManagedAccounts =
          def_message 15, [:accounts_list, :string]

      # Receives previously requested FA configuration information from TWS.
      ReceiveFA =
          def_message 16, [:type, :int], # type of Financial Advisor configuration data
                      #                    being received from TWS. Valid values include:
                      #                      1 = GROUPS
                      #                      2 = PROFILE
                      #                      3 = ACCOUNT ALIASES
                      [:xml, :string] # XML string with requested FA configuration information.

      # Receives an XML document that describes the valid parameters that a scanner
      # subscription can have (for outgoing RequestScannerSubscription message).
      ScannerParameters = def_message 19, [:xml, :string]

      # Receives the current system time on the server side.
      CurrentTime = def_message 49, [:time, :int] # long!

      # Receive Reuters global fundamental market data. There must be a subscription to
      # Reuters Fundamental set up in Account Management before you can receive this data.
      FundamentalData = def_message 50, [:request_id, :int], # request_id
                                    [:data, :string]

      ContractDataEnd = def_message 52, [:request_id, :int] # request_id

      OpenOrderEnd = def_message 53

      AccountDownloadEnd = def_message 54, [:account_name, :string]

      ExecutionDataEnd = def_message 55, [:request_id, :int] # request_id

      TickSnapshotEnd = def_message 57, [:ticker_id, :int]

      ### Actual message classes (long definitions):

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
      # TWS�s option model volatilities, prices, and deltas, along with the present
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

      MarketDepth =
          def_message 12, [:request_id, :int],
                      [:position, :int], # The row Id of this market depth entry.
                      [:operation, :int], # How it should be applied to the market depth:
                      #   0 = insert this new order into the row identified by :position
                      #   1 = update the existing order in the row identified by :position
                      #   2 = delete the existing order at the row identified by :position
                      [:side, :int], # side of the book: 0 = ask, 1 = bid
                      [:price, :decimal],
                      [:size, :int]
      class MarketDepth
        def side
          @data[:side] == 0 ? :ask : :bid
        end

        def operation
          @data[:operation] == 0 ? :insert : @data[:operation] == 1 ? :update : :delete
        end

        def to_human
          "<#{self.message_type}: #{operation} #{side} @ "+
              "#{position} = #{price} x #{size}>"
        end
      end

      MarketDepthL2 =
          def_message 13, MarketDepth, # Fields descriptions - see above
                      [:request_id, :int],
                      [:position, :int],
                      [:market_maker, :string], # The exchange hosting this order.
                      [:operation, :int],
                      [:side, :int],
                      [:price, :decimal],
                      [:size, :int]

      # Called Error in Java code, but in fact this type of messages also
      # deliver system alerts and additional (non-error) info from TWS.
      ErrorMessage = Error = Alert = def_message([4, 2],
                                                 [:error_id, :int],
                                                 [:code, :int],
                                                 [:message, :string])
      class Alert
        # Is it an Error message?
        def error?
          code < 1000
        end

        # Is it a System message?
        def system?
          code > 1000 && code < 2000
        end

        # Is it a Warning message?
        def warning?
          code > 2000
        end

        def to_human
          "TWS #{ error? ? 'Error' : system? ? 'System' : 'Warning'} #{code}: #{message}"
        end
      end # class Alert

      PortfolioValue = def_message [7, 7],
                                   [:contract, :con_id, :int],
                                   [:contract, :symbol, :string],
                                   [:contract, :sec_type, :string],
                                   [:contract, :expiry, :string],
                                   [:contract, :strike, :decimal],
                                   [:contract, :right, :string],
                                   [:contract, :multiplier, :string],
                                   [:contract, :primary_exchange, :string],
                                   [:contract, :currency, :string],
                                   [:contract, :local_symbol, :string],
                                   [:position, :int],
                                   [:market_price, :decimal],
                                   [:market_value, :decimal],
                                   [:average_cost, :decimal],
                                   [:unrealized_pnl, :decimal_max], # May be nil!
                                   [:realized_pnl, :decimal_max], #   May be nil!
                                   [:account_name, :string]
      class PortfolioValue

        def load
          super
          @contract = Models::Contract.build @data[:contract]
        end

        def to_human
          "<PortfolioValue: #{contract.to_human} (#{position}): Market #{market_price}" +
              " price #{market_value} value; PnL: #{unrealized_pnl} unrealized," +
              " #{realized_pnl} realized; account #{account_name}>"
        end
      end # PortfolioValue

      ContractDetails = ContractData =
          def_message([10, 6],
                      [:request_id, :int], # request id
                      [:contract, :symbol, :string],
                      [:contract, :sec_type, :string],
                      [:contract, :expiry, :string],
                      [:contract, :strike, :decimal],
                      [:contract, :right, :string],
                      [:contract, :exchange, :string],
                      [:contract, :currency, :string],
                      [:contract, :local_symbol, :string],

                      [:contract, :market_name, :string], # extended
                      [:contract, :trading_class, :string],
                      [:contract, :con_id, :int],
                      [:contract, :min_tick, :decimal],
                      [:contract, :multiplier, :string],
                      [:contract, :order_types, :string],
                      [:contract, :valid_exchanges, :string],
                      [:contract, :price_magnifier, :int],
                      [:contract, :under_con_id, :int],
                      [:contract, :long_name, :string],
                      [:contract, :primary_exchange, :string],
                      [:contract, :contract_month, :string],
                      [:contract, :industry, :string],
                      [:contract, :category, :string],
                      [:contract, :subcategory, :string],
                      [:contract, :time_zone, :string],
                      [:contract, :trading_hours, :string],
                      [:contract, :liquid_hours, :string])

      class ContractData
        def load
          super
          @contract = Models::Contract.build @data[:contract]
        end
      end # ContractData

      ExecutionData =
          def_message [11, 7],
                      # The reqID that was specified previously in the call to reqExecution()
                      [:request_id, :int],
                      [:execution, :order_id, :int],
                      [:contract, :con_id, :int],
                      [:contract, :symbol, :string],
                      [:contract, :sec_type, :string],
                      [:contract, :expiry, :string],
                      [:contract, :strike, :decimal],
                      [:contract, :right, :string],
                      [:contract, :exchange, :string],
                      [:contract, :currency, :string],
                      [:contract, :local_symbol, :string],

                      [:execution, :exec_id, :string], # Weird format
                      [:execution, :time, :string],
                      [:execution, :account_name, :string],
                      [:execution, :exchange, :string],
                      [:execution, :side, :string],
                      [:execution, :shares, :int],
                      [:execution, :price, :decimal],
                      [:execution, :perm_id, :int],
                      [:execution, :client_id, :int],
                      [:execution, :liquidation, :int],
                      [:execution, :cumulative_quantity, :int],
                      [:execution, :average_price, :decimal]

      class ExecutionData
        def load
          super
          @contract = Models::Contract.build @data[:contract]
          @execution = Models::Execution.new @data[:execution]
        end

        def to_human
          "<ExecutionData #{request_id}: #{contract.to_human}, #{execution}>"
        end
      end # ExecutionData

      BondContractData =
          def_message [18, 4],
                      [:request_id, :int], # request id
                      [:contract, :symbol, :string],
                      [:contract, :sec_type, :string],
                      [:contract, :cusip, :string],
                      [:contract, :coupon, :decimal],
                      [:contract, :maturity, :string],
                      [:contract, :issue_date, :string],
                      [:contract, :ratings, :string],
                      [:contract, :bond_type, :string],
                      [:contract, :coupon_type, :string],
                      [:contract, :convertible, :boolean],
                      [:contract, :callable, :boolean],
                      [:contract, :puttable, :boolean],
                      [:contract, :desc_append, :string],
                      [:contract, :exchange, :string],
                      [:contract, :currency, :string],
                      [:contract, :market_name, :string], # extended
                      [:contract, :trading_class, :string],
                      [:contract, :con_id, :int],
                      [:contract, :min_tick, :decimal],
                      [:contract, :order_types, :string],
                      [:contract, :valid_exchanges, :string],
                      [:contract, :valid_next_option_date, :string],
                      [:contract, :valid_next_option_type, :string],
                      [:contract, :valid_next_option_partial, :string],
                      [:contract, :notes, :string],
                      [:contract, :long_name, :string]

      class BondContractData
        def load
          super
          @contract = Models::Contract.build @data[:contract]
        end
      end # BondContractData

      # The server sends this message upon accepting a Delta-Neutral DN RFQ
      # - see API Reference p. 26
      DeltaNeutralValidation = def_message 56,
                                           [:request_id, :int],
                                           [:contract, :under_con_id, :int],
                                           [:contract, :under_delta, :decimal],
                                           [:contract, :under_price, :decimal]
      class DeltaNeutralValidation
        def load
          super
          @contract = Models::Contract.build @data[:contract].merge(:under_comp => true)
        end
      end # DeltaNeutralValidation

      # RealTimeBar contains following @data:
      #    :request_id - The ID of the *request* to which this is responding
      #    :time - The date-time stamp of the start of the bar. The format is offset in
      #            seconds from the beginning of 1970, same format as the UNIX epoch time
      #    :bar - received RT Bar
      RealTimeBar = def_message 50,
                                [:request_id, :int],
                                [:bar, :time, :int],
                                [:bar, :open, :decimal],
                                [:bar, :high, :decimal],
                                [:bar, :low, :decimal],
                                [:bar, :close, :decimal],
                                [:bar, :volume, :int],
                                [:bar, :wap, :decimal],
                                [:bar, :trades, :int]
      class RealTimeBar
        def load
          super
          @bar = Models::Bar.new @data[:bar]
        end

        def to_human
          "<RealTimeBar: #{request_id} #{time}, #{bar}>"
        end
      end # RealTimeBar

      ### Messages with really complicated message loading logics (cycles, conditions)

      # This method receives the requested market scanner data results.
      # ScannerData contains following @data:
      # :request_id - The ID of the request to which this row is responding
      # :count - Number of data points returned (size of :results).
      # :results - an Array of Hashes, each hash contains a set of
      #            data about one scanned Contract:
      #            :contract - a full description of the contract (details).
      #            :distance - Varies based on query.
      #            :benchmark - Varies based on query.
      #            :projection - Varies based on query.
      #            :legs - Describes combo legs when scan is returning EFP.
      ScannerData = def_message [20, 3],
                                [:request_id, :int], # request id
                                [:count, :int]
      class ScannerData
        attr_accessor :results

        def load
          super

          @results = Array.new(@data[:count]) do |index|
            {:rank => @socket.read_int,
             :contract => Contract.build(:con_id => @socket.read_int,
                                         :symbol => @socket.read_str,
                                         :sec_type => @socket.read_str,
                                         :expiry => @socket.read_str,
                                         :strike => @socket.read_decimal,
                                         :right => @socket.read_str,
                                         :exchange => @socket.read_str,
                                         :currency => @socket.read_str,
                                         :local_symbol => @socket.read_str,
                                         :market_name => @socket.read_str,
                                         :trading_class => @socket.read_str),
             :distance => @socket.read_str,
             :benchmark => @socket.read_str,
             :projection => @socket.read_str,
             :legs => @socket.read_str,
            }
          end
        end
      end # ScannerData

      # HistoricalData contains following @data:
      # General:
      #    :request_id - The ID of the request to which this is responding
      #    :count - Number of Historical data points returned (size of :results).
      #    :results - an Array of Historical Data Bars
      #    :start_date - beginning of returned Historical data period
      #    :end_date   - end of returned Historical data period
      # Each returned Bar in @data[:results] Array contains this data:
      #    :date - The date-time stamp of the start of the bar. The format is
      #       determined by the RequestHistoricalData formatDate parameter.
      #    :open -  The bar opening price.
      #    :high -  The high price during the time covered by the bar.
      #    :low -   The low price during the time covered by the bar.
      #    :close - The bar closing price.
      #    :volume - The volume during the time covered by the bar.
      #    :trades - When TRADES historical data is returned, represents number of trades
      #             that occurred during the time period the bar covers
      #    :wap - The weighted average price during the time covered by the bar.
      #    :has_gaps - Whether or not there are gaps in the data.

      HistoricalData = def_message [17, 3],
                                   [:request_id, :int],
                                   [:start_date, :string],
                                   [:end_date, :string],
                                   [:count, :int]
      class HistoricalData
        attr_accessor :results

        def load
          super

          @results = Array.new(@data[:count]) do |index|
            Models::Bar.new :time => @socket.read_string,
                            :open => @socket.read_decimal,
                            :high => @socket.read_decimal,
                            :low => @socket.read_decimal,
                            :close => @socket.read_decimal,
                            :volume => @socket.read_int,
                            :wap => @socket.read_decimal,
                            :has_gaps => @socket.read_string,
                            :trades => @socket.read_int
          end
        end

        def to_human
          "<HistoricalData: #{request_id}, #{count} items, #{start_date} to #{end_date}>"
        end
      end # HistoricalData


      OpenOrder =
          def_message [5, 23],
                      # The reqID that was specified previously in the call to reqExecution()
                      [:order, :order_id, :int],

                      [:contract, :con_id, :int],
                      [:contract, :symbol, :string],
                      [:contract, :sec_type, :string],
                      [:contract, :expiry, :string],
                      [:contract, :strike, :decimal],
                      [:contract, :right, :string],
                      [:contract, :exchange, :string],
                      [:contract, :currency, :string],
                      [:contract, :local_symbol, :string],

                      [:order, :action, :string],
                      [:order, :total_quantity, :int],
                      [:order, :order_type, :string],
                      [:order, :limit_price, :decimal],
                      [:order, :aux_price, :decimal],
                      [:order, :tif, :string],
                      [:order, :oca_group, :string],
                      [:order, :account, :string],
                      [:order, :open_close, :string],
                      [:order, :origin, :int],
                      [:order, :order_ref, :string],
                      [:order, :client_id, :int],
                      [:order, :perm_id, :int],
                      [:order, :outside_rth, :boolean], # (@socket.read_int == 1)
                      [:order, :hidden, :boolean], # (@socket.read_int == 1)
                      [:order, :discretionary_amount, :decimal],
                      [:order, :good_after_time, :string],
                      [:skip, :string], # skip deprecated sharesAllocation field

                      [:order, :fa_group, :string],
                      [:order, :fa_method, :string],
                      [:order, :fa_percentage, :string],
                      [:order, :fa_profile, :string],
                      [:order, :good_till_date, :string],
                      [:order, :rule_80a, :string],
                      [:order, :percent_offset, :decimal],
                      [:order, :settling_firm, :string],
                      [:order, :short_sale_slot, :int],
                      [:order, :designated_location, :string],
                      [:order, :exempt_code, :int], # skipped in ver 51?
                      [:order, :auction_strategy, :int],
                      [:order, :starting_price, :decimal],
                      [:order, :stock_ref_price, :decimal],
                      [:order, :delta, :decimal],
                      [:order, :stock_range_lower, :decimal],
                      [:order, :stock_range_upper, :decimal],
                      [:order, :display_size, :int],
                      #@order.rth_only = @socket.read_boolean
                      [:order, :block_order, :boolean],
                      [:order, :sweep_to_fill, :boolean],
                      [:order, :all_or_none, :boolean],
                      [:order, :min_quantity, :int],
                      [:order, :oca_type, :int],
                      [:order, :etrade_only, :boolean],
                      [:order, :firm_quote_only, :boolean],
                      [:order, :nbbo_price_cap, :decimal],
                      [:order, :parent_id, :int],
                      [:order, :trigger_method, :int],
                      [:order, :volatility, :decimal],
                      [:order, :volatility_type, :int],
                      [:order, :delta_neutral_order_type, :string],
                      [:order, :delta_neutral_aux_price, :decimal],

                      [:order, :continuous_update, :int],
                      [:order, :reference_price_type, :int],
                      [:order, :trail_stop_price, :decimal],
                      [:order, :basis_points, :decimal],
                      [:order, :basis_points_type, :int],
                      [:contract, :legs_description, :string],
                      [:order, :scale_init_level_size, :int_max],
                      [:order, :scale_subs_level_size, :int_max],
                      [:order, :scale_price_increment, :decimal_max],
                      [:order, :clearing_account, :string],
                      [:order, :clearing_intent, :string],
                      [:order, :not_held, :boolean] # (@socket.read_int == 1)

      class OpenOrder

        def load
          super

          load_map [:contract, :under_comp, :boolean] # (@socket.read_int == 1)

          if @data[:contract][:under_comp]
            load_map [:contract, :under_con_id, :int],
                     [:contract, :under_delta, :decimal],
                     [:contract, :under_price, :decimal]
          end

          load_map [:order, :algo_strategy, :string]

          unless @data[:order][:algo_strategy].nil? || @data[:order][:algo_strategy].empty?
            load_map [:algo_params_count, :int]
            if @data[:algo_params_count] > 0
              @data[:order][:algo_params] = Hash.new
              @data[:algo_params_count].times do
                tag = @socket.read_string
                value = @socket.read_string
                @data[:order][:algo_params][tag] = value
              end
            end
          end

          load_map [:order, :what_if, :boolean], # (@socket.read_int == 1)
                   [:order, :status, :string],
                   [:order, :init_margin, :string],
                   [:order, :maint_margin, :string],
                   [:order, :equity_with_loan, :string],
                   [:order, :commission, :decimal_max], # May be nil!
                   [:order, :min_commission, :decimal_max], # May be nil!
                   [:order, :max_commission, :decimal_max], # May be nil!
                   [:order, :commission_currency, :string],
                   [:order, :warning_text, :string]

          @order = Models::Order.new @data[:order]
          @contract = Models::Contract.build @data[:contract]
        end

        def to_human
          "<OpenOrder: #{@contract.to_human} #{@order.to_human}>"
        end
      end

      # OpenOrder

      Table = Hash.new
      Classes.each { |msg_class| Table[msg_class.message_id] = msg_class }

    end # module Incoming
  end # module Messages
end # module IB
__END__

    // incoming msg id's
    static final int TICK_PRICE		= 1; * TODO: realize both events
    static final int TICK_SIZE		= 2; *
    static final int ORDER_STATUS	= 3; *
    static final int ERR_MSG		= 4;   *
    static final int OPEN_ORDER         = 5;  *
    static final int ACCT_VALUE         = 6;  *
    static final int PORTFOLIO_VALUE    = 7;  *
    static final int ACCT_UPDATE_TIME   = 8;  *
    static final int NEXT_VALID_ID      = 9;  *
    static final int CONTRACT_DATA      = 10; *
    static final int EXECUTION_DATA     = 11; *
    static final int MARKET_DEPTH     	= 12; *
    static final int MARKET_DEPTH_L2    = 13; *
    static final int NEWS_BULLETINS    	= 14; *
    static final int MANAGED_ACCTS    	= 15; *
    static final int RECEIVE_FA    	    = 16; *
    static final int HISTORICAL_DATA    = 17; *
    static final int BOND_CONTRACT_DATA = 18; *
    static final int SCANNER_PARAMETERS = 19; *
    static final int SCANNER_DATA       = 20; *
    static final int TICK_OPTION_COMPUTATION = 21; *
    static final int TICK_GENERIC = 45;       *
    static final int TICK_STRING = 46;        *
    static final int TICK_EFP = 47;           *
    static final int CURRENT_TIME = 49;       *
    static final int REAL_TIME_BARS = 50;     *
    static final int FUNDAMENTAL_DATA = 51;   *
    static final int CONTRACT_DATA_END = 52;  *
    static final int OPEN_ORDER_END = 53;     *
    static final int ACCT_DOWNLOAD_END = 54;  *
    static final int EXECUTION_DATA_END = 55; *
    static final int DELTA_NEUTRAL_VALIDATION = 56; *
    static final int TICK_SNAPSHOT_END = 57;  *
