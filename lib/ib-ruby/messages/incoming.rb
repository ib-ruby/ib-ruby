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
      Classes = Array.new

      # This is just a basic generic message from the server.
      #
      # Class variables:
      # @message_id - int: message id.
      # @message_type - Symbol: message type (e.g. :OpenOrderEnd)
      #
      # Instance attributes (at least):
      # version - int: current version of message format.
      # @data - Hash of actual data read from a stream.
      #
      # Override the load(socket) method in your subclass to do actual reading into @data.
      class AbstractMessage

        def self.inherited(by)
          super(by)
          Classes.push(by)
        end

        # Class methods
        def self.data_map # Data keys (with types?)
          @data_map ||= []
        end

        def self.version # Per class, minimum message version supported
          @version || 1
        end

        def self.message_id
          @message_id
        end

        # Returns message type Symbol (e.g. :OpenOrderEnd)
        def self.message_type
          to_s.split(/::/).last.to_sym
        end

        def message_id
          self.class.message_id
        end

        def message_type
          self.class.message_type
        end

        def version # Per message, received messages may have the different versions
          @data[:version]
        end

        attr_accessor :created_at, :data

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

        def to_human
          self.inspect
        end

        # Object#id is always defined, we cannot rely on method_missing
        def id
          @data.has_key?(:id) ? @data[:id] : super
        end

        def respond_to? method
          getter = method.to_s.sub(/=$/, '').to_sym
          @data.has_key?(method) || @data.has_key?(getter) || super
        end

        protected

        # TODO: method compilation instead of method_missing
        def method_missing method, *args
          getter = method.to_s.sub(/=$/, '').to_sym
          if @data.has_key? method
            @data[method]
          elsif @data.has_key? getter
            @data[getter] = *args
          else
            super method, *args
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
        # map is a series of Arrays in the format [ [ :name, :type ] ],
        # type identifiers must have a corresponding read_type method on socket (read_int, etc.).
        # [:version, :int ] is loaded first, by default
        #
        def load_map(*map)
          map.each { |(name, type)|
            @data[name] = @socket.__send__("read_#{type}") }
        end
      end # class AbstractMessage

      class AbstractTick < AbstractMessage
        # Returns Symbol with a meaningful name for received tick type
        def type
          TICK_TYPES[@data[:tick_type]]
        end

        def to_human
          "<#{self.class.to_s.split('::').last} #{type}:" +
              @data.map do |key, value|
                " #{key} #{value}" unless [:version, :id, :tick_type].include?(key)
              end.compact.join(',') + " >"
        end
      end

      # Macro that defines short message classes using a one-liner
      def self.def_message id_version, *data_map, &to_human
        base = data_map.first.is_a?(Class) ? data_map.shift : AbstractMessage
        Class.new(base) do
          @message_id, @version = id_version
          @version ||= 1
          @data_map = data_map

          @data_map.each do |(name, type)|
            define_method(name) { @data[name] }
          end

          define_method(:to_human, &to_human) if to_human
        end
      end

      ### Actual message classes (short definitions):
      #:status - String: Displays the order status. Possible values include:
      # • PendingSubmit - indicates that you have transmitted the order, but
      #   have not yet received confirmation that it has been accepted by the
      #   order destination. NOTE: This order status is NOT sent back by TWS
      #   and should be explicitly set by YOU when an order is submitted.
      # • PendingCancel - indicates that you have sent a request to cancel
      #   the order but have not yet received cancel confirmation from the
      #   order destination. At this point, your order cancel is not confirmed.
      #   You may still receive an execution while your cancellation request
      #   is pending. NOTE: This order status is not sent back by TWS and
      #   should be explicitly set by YOU when an order is canceled.
      # • PreSubmitted - indicates that a simulated order type has been
      #   accepted by the IB system and that this order has yet to be elected.
      #   The order is held in the IB system until the election criteria are
      #   met. At that time the order is transmitted to the order destination
      #   as specified.
      # • Submitted - indicates that your order has been accepted at the order
      #   destination and is working.
      # • Cancelled - indicates that the balance of your order has been
      #   confirmed canceled by the IB system. This could occur unexpectedly
      #   when IB or the destination has rejected your order.
      # • Filled - indicates that the order has been completely filled.
      # • Inactive - indicates that the order has been accepted by the system
      #   (simulated orders) or an exchange (native orders) but that currently
      #   the order is inactive due to system, exchange or other issues.
      # :why_held - This field is used to identify an order held when TWS is trying to
      #      locate shares for a short sell. The value used to indicate this is 'locate'.
      OrderStatus = def_message [3, 6], [:id, :int],
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
            " id/perm: #{id}/#{perm_id}>"
      end


      AccountValue = def_message([6, 2], [:key, :string],
                                 [:value, :string],
                                 [:currency, :string],
                                 [:account_name, :string]) do
        "<AccountValue: #{account_name}, #{key}=#{value} #{currency}>"
      end

      AccountUpdateTime = def_message(8, [:time_stamp, :string]) do
        "<AccountUpdateTime: #{time_stamp}>"
      end

      # This message is always sent by TWS automatically at connect.
      # The IB::Connection class subscribes to it automatically and stores
      # the order id in its @next_order_id attribute.
      NextValidID = def_message(9, [:id, :int]) { "<NextValidID: #{id}>" }

      NewsBulletins =
          def_message 14, [:id, :int], # unique incrementing bulletin ID.
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
                      [:xml, :string] # XML string containing the previously requested
      #                                 FA configuration information.

      # Receives an XML document that describes the valid parameters that a scanner
      # subscription can have (for outgoing RequestScannerSubscription message).
      ScannerParameters = def_message 19, [:xml, :string]

      # Receives the current system time on the server side.
      CurrentTime = def_message 49, [:time, :int] # long!

      # Receive Reuters global fundamental market data. There must be a subscription to
      # Reuters Fundamental set up in Account Management before you can receive this data.
      FundamentalData = def_message 50, [:id, :int], # request_id
                                    [:data, :string]

      ContractDataEnd = def_message(52, [:id, :int]) { "<ContractDataEnd: #{id}>" } # request_id

      OpenOrderEnd = def_message(53) { "<OpenOrderEnd>" }

      AccountDownloadEnd = def_message(54, [:account_name, :string]) do
        "<AccountDownloadEnd: #{account_name}}>"
      end # request_id


      ExecutionDataEnd = def_message(55, [:id, :int]) { "<ExecutionDataEnd: #{id}>" } # request_id

      TickSnapshotEnd = def_message(57, [:id, :int]) { "<TickSnapshotEnd: #{id}>" } # request_id

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
                              [:id, :int], # ticker_id
                              [:tick_type, :int],
                              [:price, :decimal],
                              [:size, :int],
                              [:can_auto_execute, :int]

      TickSize = def_message [2, 6], AbstractTick,
                             [:id, :int], # ticker_id
                             [:tick_type, :int],
                             [:size, :int]

      TickGeneric = def_message 45, AbstractTick,
                                [:id, :int], # ticker_id
                                [:tick_type, :int],
                                [:value, :decimal]

      TickString = def_message 46, AbstractTick,
                               [:id, :int], # ticker_id
                               [:tick_type, :int],
                               [:value, :string]

      TickEFP = def_message 47, AbstractTick,
                            [:id, :int], # ticker_id
                            [:tick_type, :int],
                            [:basis_points, :decimal],
                            [:formatted_basis_points, :string],
                            [:implied_futures_price, :decimal],
                            [:hold_days, :int],
                            [:dividend_impact, :decimal],
                            [:dividends_to_expiry, :decimal]

      # This message is received when the market in an option or its underlier moves.
      # TWS’s option model volatilities, prices, and deltas, along with the present
      # value of dividends expected on that options underlier are received.
      # TickOption message contains following @data:
      #    :id - Ticker Id that was specified previously in the call to reqMktData()
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
      class TickOption < AbstractTick
        @message_id = 21
        @version = 6

        # Read @data[key] if it was computed (received value above limit)
        # Leave @data[key] nil if received value below limit ("not yet computed")
        def read_computed key, limit
          value = @socket.read_decimal
          # limit is the "not yet computed" indicator
          @data[key] = value <= limit ? nil : value
        end

        def load
          super

          @data[:id] = @socket.read_int # ticker_id
          @data[:tick_type] = @socket.read_int
          read_computed :implied_volatility, -1 #-1 is the "not yet computed" indicator
          read_computed :delta, -2 #             -2 is the "not yet computed" indicator
          read_computed :option_price, -1 #      -1 is the "not yet computed" indicator
          read_computed :pv_dividend, -1 #       -1 is the "not yet computed" indicator
          read_computed :gamma, -2 #             -2 is the "not yet computed" indicator
          read_computed :vega, -2 #              -2 is the "not yet computed" indicator
          read_computed :theta, -2 #             -2 is the "not yet computed" indicator
          read_computed :under_price, -1 #       -1 is the "not yet computed" indicator
        end

        def to_human
          "<TickOption #{type} for #{:id}: underlying @ #{under_price}, "+
              "option @ #{option_price}, IV #{implied_volatility}%, delta #{delta}, " +
              "gamma #{gamma}, vega #{vega}, theta #{theta}, pv_dividend #{pv_dividend}>"
        end
      end # TickOption
      TickOptionComputation = TickOption

      MarketDepth =
          def_message 12, [:id, :int],
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
          "<#{self.class.to_s.split(/::/).last}: #{operation} #{side} @ "+
              "#{position} = #{price} x #{size}>"
        end
      end

      MarketDepthL2 =
          def_message 13, MarketDepth,
                      [:id, :int],
                      [:position, :int], # The row Id of this market depth entry.
                      [:market_maker, :string], # The exchange hosting this order.
                      [:operation, :int], # How it should be applied to the market depth:
                      #   0 = insert this new order into the row identified by :position
                      #   1 = update the existing order in the row identified by :position
                      #   2 = delete the existing order at the row identified by :position
                      [:side, :int], # side of the book: 0 = ask, 1 = bid
                      [:price, :decimal],
                      [:size, :int]

      # Called Error in Java code, but in fact this type of messages also
      # deliver system alerts and additional (non-error) info from TWS.
      # It has additional accessors: #code and #message, derived from @data
      Alert = def_message [4, 2], [:id, :int], [:code, :int], [:message, :string]
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
          "TWS #{ error? ? 'Error' : system? ? 'System' : 'Warning'
          } Message #{code}: #{message}"
        end
      end # class Alert
      Error = Alert
      ErrorMessage = Alert

      class OpenOrder < AbstractMessage
        @message_id = 5
        @version = 23

        # TODO: Add id accessor to unify with OrderStatus message
        attr_accessor :order, :contract

        def load
          super

          @order = Models::Order.new :id => @socket.read_int

          @contract = Models::Contract.build :con_id => @socket.read_string,
                                             :symbol => @socket.read_string,
                                             :sec_type => @socket.read_string,
                                             :expiry => @socket.read_string,
                                             :strike => @socket.read_decimal,
                                             :right => @socket.read_string,
                                             :exchange => @socket.read_string,
                                             :currency => @socket.read_string,
                                             :local_symbol => @socket.read_string

          @order.action = @socket.read_string
          @order.total_quantity = @socket.read_int
          @order.order_type = @socket.read_string
          @order.limit_price = @socket.read_decimal
          @order.aux_price = @socket.read_decimal
          @order.tif = @socket.read_string
          @order.oca_group = @socket.read_string
          @order.account = @socket.read_string
          @order.open_close = @socket.read_string
          @order.origin = @socket.read_int
          @order.order_ref = @socket.read_string
          @order.client_id = @socket.read_int
          @order.perm_id = @socket.read_int
          @order.outside_rth = (@socket.read_int == 1)
          @order.hidden = (@socket.read_int == 1)
          @order.discretionary_amount = @socket.read_decimal
          @order.good_after_time = @socket.read_string
          @socket.read_string # skip deprecated sharesAllocation field

          @order.fa_group = @socket.read_string
          @order.fa_method = @socket.read_string
          @order.fa_percentage = @socket.read_string
          @order.fa_profile = @socket.read_string
          @order.good_till_date = @socket.read_string
          @order.rule_80a = @socket.read_string
          @order.percent_offset = @socket.read_decimal
          @order.settling_firm = @socket.read_string
          @order.short_sale_slot = @socket.read_int
          @order.designated_location = @socket.read_string
          @order.exempt_code = @socket.read_int # skipped in ver 51?
          @order.auction_strategy = @socket.read_int
          @order.starting_price = @socket.read_decimal
          @order.stock_ref_price = @socket.read_decimal
          @order.delta = @socket.read_decimal
          @order.stock_range_lower = @socket.read_decimal
          @order.stock_range_upper = @socket.read_decimal
          @order.display_size = @socket.read_int
                              #@order.rth_only = @socket.read_boolean
          @order.block_order = @socket.read_boolean
          @order.sweep_to_fill = @socket.read_boolean
          @order.all_or_none = @socket.read_boolean
          @order.min_quantity = @socket.read_int
          @order.oca_type = @socket.read_int
          @order.etrade_only = @socket.read_boolean
          @order.firm_quote_only = @socket.read_boolean
          @order.nbbo_price_cap = @socket.read_decimal
          @order.parent_id = @socket.read_int
          @order.trigger_method = @socket.read_int
          @order.volatility = @socket.read_decimal
          @order.volatility_type = @socket.read_int
          @order.delta_neutral_order_type = @socket.read_string
          @order.delta_neutral_aux_price = @socket.read_decimal

          @order.continuous_update = @socket.read_int
          @order.reference_price_type = @socket.read_int
          @order.trail_stop_price = @socket.read_decimal
          @order.basis_points = @socket.read_decimal
          @order.basis_points_type = @socket.read_int
          @contract.legs_description = @socket.read_string
          @order.scale_init_level_size = @socket.read_int_max
          @order.scale_subs_level_size = @socket.read_int_max
          @order.scale_price_increment = @socket.read_decimal_max
          @order.clearing_account = @socket.read_string
          @order.clearing_intent = @socket.read_string
          @order.not_held = (@socket.read_int == 1)

          under_comp_present = (@socket.read_int == 1)

          if under_comp_present
            @contract.under_comp = true
            @contract.under_con_id = @socket.read_int
            @contract.under_delta = @socket.read_decimal
            @contract.under_price = @socket.read_decimal
          end

          @order.algo_strategy = @socket.read_string

          unless @order.algo_strategy.nil? || @order.algo_strategy.empty?
            algo_params_count = @socket.read_int
            if algo_params_count > 0
              @order.algo_params = Hash.new
              algo_params_count.times do
                tag = @socket.read_string
                value = @socket.read_string
                @order.algo_params[tag] = value
              end
            end
          end

          @order.what_if = (@socket.read_int == 1)
          @order.status = @socket.read_string
          @order.init_margin = @socket.read_string
          @order.maint_margin = @socket.read_string
          @order.equity_with_loan = @socket.read_string
          @order.commission = @socket.read_decimal_max # May be nil!
          @order.min_commission = @socket.read_decimal_max # May be nil!
          @order.max_commission = @socket.read_decimal_max # May be nil!
          @order.commission_currency = @socket.read_string
          @order.warning_text = @socket.read_string
        end

        def to_human
          "<OpenOrder: #{@contract.to_human} #{@order.to_human}>"
        end
      end # OpenOrder

      class PortfolioValue < AbstractMessage
        @message_id = 7
        @version = 7

        attr_accessor :contract

        def load
          super

          @contract = Models::Contract.build :con_id => @socket.read_int,
                                             :symbol => @socket.read_string,
                                             :sec_type => @socket.read_string,
                                             :expiry => @socket.read_string,
                                             :strike => @socket.read_decimal,
                                             :right => @socket.read_string,
                                             :multiplier => @socket.read_string,
                                             :primary_exchange => @socket.read_string,
                                             :currency => @socket.read_string,
                                             :local_symbol => @socket.read_string
          load_map [:position, :int],
                   [:market_price, :decimal],
                   [:market_value, :decimal],
                   [:average_cost, :decimal],
                   [:unrealized_pnl, :decimal_max], # May be nil!
                   [:realized_pnl, :decimal_max], #   May be nil!
                   [:account_name, :string]
        end

        def to_human
          "<PortfolioValue: #{@contract.to_human} (#{position}): Market #{market_price}" +
              " price #{market_value} value; PnL: #{unrealized_pnl} unrealized," +
              " #{realized_pnl} realized; account #{account_name}>"
        end

      end # PortfolioValue

      class ContractData < AbstractMessage
        @message_id = 10
        @version = 6

        attr_accessor :contract

        def load
          super
          load_map [:id, :int] # request id

          @contract =
              Models::Contract.build :symbol => @socket.read_string,
                                     :sec_type => @socket.read_string,
                                     :expiry => @socket.read_string,
                                     :strike => @socket.read_decimal,
                                     :right => @socket.read_string,
                                     :exchange => @socket.read_string,
                                     :currency => @socket.read_string,
                                     :local_symbol => @socket.read_string,

                                     :market_name => @socket.read_string,
                                     :trading_class => @socket.read_string,
                                     :con_id => @socket.read_int,
                                     :min_tick => @socket.read_decimal,
                                     :multiplier => @socket.read_string,
                                     :order_types => @socket.read_string,
                                     :valid_exchanges => @socket.read_string,
                                     :price_magnifier => @socket.read_int,

                                     :under_con_id => @socket.read_int,
                                     :long_name => @socket.read_string,
                                     :primary_exchange => @socket.read_string,
                                     :contract_month => @socket.read_string,
                                     :industry => @socket.read_string,
                                     :category => @socket.read_string,
                                     :subcategory => @socket.read_string,
                                     :time_zone => @socket.read_string,
                                     :trading_hours => @socket.read_string,
                                     :liquid_hours => @socket.read_string
        end
      end # ContractData
      ContractDetails = ContractData

      class ExecutionData < AbstractMessage
        @message_id = 11
        @version = 7

        attr_accessor :contract, :execution

        def load
          super
          load_map [:id, :int], # request_id
                   [:order_id, :int]

          @contract =
              Models::Contract.build :con_id => @socket.read_int,
                                     :symbol => @socket.read_string,
                                     :sec_type => @socket.read_string,
                                     :expiry => @socket.read_string,
                                     :strike => @socket.read_decimal,
                                     :right => @socket.read_string,
                                     :exchange => @socket.read_string,
                                     :currency => @socket.read_string,
                                     :local_symbol => @socket.read_string
          @execution =
              Models::Execution.new :order_id => @data[:order_id],
                                    :exec_id => @socket.read_string,
                                    :time => @socket.read_string,
                                    :account_number => @socket.read_string,
                                    :exchange => @socket.read_string,
                                    :side => @socket.read_string,
                                    :shares => @socket.read_int,
                                    :price => @socket.read_decimal,
                                    :perm_id => @socket.read_int,
                                    :client_id => @socket.read_int,
                                    :liquidation => @socket.read_int,
                                    :cumulative_quantity => @socket.read_int,
                                    :average_price => @socket.read_decimal
        end

        def to_human
          "<ExecutionData: #{contract.to_human}, #{execution}>"
        end
      end # ExecutionData

      # HistoricalData contains following @data:
      # General:
      #    :id - The ID of the request to which this is responding
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
      class HistoricalData < AbstractMessage
        @message_id = 17
        @version = 3

        def load
          super
          load_map [:id, :int],
                   [:start_date, :string],
                   [:end_date, :string],
                   [:count, :int]

          @data[:results] = Array.new(@data[:count]) do |index|
            Models::Bar.new :date => @socket.read_string,
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
          "<HistoricalData: req: #{id}, #{item_count} items, #{start_date} to #{end_date}>"
        end
      end # HistoricalData

      class BondContractData < AbstractMessage
        @message_id = 18
        @version = 4

        attr_accessor :contract

        def load
          super
          load_map [:id, :int] # request id

          @contract =
              Models::Contract.build :symbol => @socket.read_string,
                                     :sec_type => @socket.read_string,
                                     :cusip => @socket.read_string,
                                     :coupon => @socket.read_decimal,
                                     :maturity => @socket.read_string,
                                     :issue_date => @socket.read_string,
                                     :ratings => @socket.read_string,
                                     :bond_type => @socket.read_string,
                                     :coupon_type => @socket.read_string,
                                     :convertible => @socket.read_boolean,
                                     :callable => @socket.read_boolean,
                                     :puttable => @socket.read_boolean,
                                     :desc_append => @socket.read_string,
                                     :exchange => @socket.read_string,
                                     :currency => @socket.read_string,
                                     :market_name => @socket.read_string,
                                     :trading_class => @socket.read_string,
                                     :con_id => @socket.read_int,
                                     :min_tick => @socket.read_decimal,
                                     :order_types => @socket.read_string,
                                     :valid_exchanges => @socket.read_string,
                                     :valid_next_option_date => @socket.read_string,
                                     :valid_next_option_type => @socket.read_string,
                                     :valid_next_option_partial => @socket.read_string,
                                     :notes => @socket.read_string,
                                     :long_name => @socket.read_string
        end
      end # BondContractData

      # This method receives the requested market scanner data results.
      # ScannerData contains following @data:
      # :id - The ID of the request to which this row is responding
      # :count - Number of data points returned (size of :results).
      # :results - an Array of Hashes, each hash contains a set of
      #            data about one scanned Contract:
      #            :contract - a full description of the contract (details).
      #            :distance - Varies based on query.
      #            :benchmark - Varies based on query.
      #            :projection - Varies based on query.
      #            :legs - Describes combo legs when scan is returning EFP.
      class ScannerData < AbstractMessage
        @message_id = 20
        @version = 3

        def load
          super
          load_map [:id, :int],
                   [:count, :int]

          @data[:results] = Array.new(@data[:count]) do |index|
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
            #eWrapper().scannerData(tickerId, rank, contract, distance,
            #    benchmark, projection, legsStr);

          end

          #eWrapper().scannerDataEnd(tickerId);
        end
      end # ScannerData

      # HistoricalData contains following @data:
      #    :id - The ID of the *request* to which this is responding
      #    :time - The date-time stamp of the start of the bar. The format is offset in
      #            seconds from the beginning of 1970, same format as the UNIX epoch time
      #    :bar - received RT Bar
      class RealTimeBar < AbstractMessage
        @message_id = 50

        attr_accessor :bar

        def load
          super
          load_map [:id, :int],
                   [:time, :int] # long!

          @bar = Models::Bar.new :date => Time.at(@data[:time]),
                                 :open => @socket.read_decimal,
                                 :high => @socket.read_decimal,
                                 :low => @socket.read_decimal,
                                 :close => @socket.read_decimal,
                                 :volume => @socket.read_int,
                                 :wap => @socket.read_decimal,
                                 :trades => @socket.read_int
        end

        def to_human
          "<RealTimeBar: req: #{id}, #{bar}>"
        end
      end # RealTimeBar
      RealTimeBars = RealTimeBar

      # The server sends this message upon accepting a Delta-Neutral DN RFQ
      # - see API Reference p. 26
      class DeltaNeutralValidation < AbstractMessage
        @message_id = 56

        attr_accessor :contract

        def load
          super
          load_map [:id, :int] # request id

          @contract = Models::Contract.build :under_comp => true,
                                             :under_con_id => @socket.read_int,
                                             :under_delta => @socket.read_decimal,
                                             :under_price => @socket.read_decimal
        end
      end # DeltaNeutralValidation

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
