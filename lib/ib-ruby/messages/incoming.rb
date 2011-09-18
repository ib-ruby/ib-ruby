# EClientSocket.java uses sendMax() rather than send() for a number of these.
# It sends an EOL rather than a number if the value == Integer.MAX_VALUE (or Double.MAX_VALUE).
# These fields are initialized to this MAX_VALUE.
# This has been implemented with nils in Ruby to represent the case where an EOL should be sent.

# TODO: Don't instantiate messages, use their classes as just namespace for .encode/decode

module IB
  module Messages

    # Incoming IB messages
    module Incoming
      Classes = Array.new

      #
      # This is just a basic generic message from the server.
      #
      # Class variables:
      # @message_id - integer message id.
      #
      # Instance attributes:
      # @data - Hash of actual data read from a stream.
      #
      # Override the load(socket) method in your subclass to do actual reading into @data.
      #
      class AbstractMessage
        attr_accessor :created_at, :data

        def self.inherited(by)
          super(by)
          Classes.push(by)
        end

        def self.message_id
          @message_id
        end

        def initialize(socket, server_version)
          raise Exception.new("Don't use AbstractMessage directly; use the subclass for your specific message type") if self.class.name == "AbstractMessage"
          @created_at = Time.now
          @data = Hash.new
          @socket = socket
          @server_version = server_version

          self.load()

          @socket = nil
        end

        def to_human
          self.inspect
        end

        protected

        # Every message loads received message version first
        def load
          @data[:version] = @socket.read_int
        end

        # Load @data from the socket according to the given map.
        #
        # map is a series of Arrays in the format [ [ :name, :type ] ],
        # type identifiers must have a corresponding read_type method on socket (read_int, etc.).
        # [:version, :int ] is loaded first, by default
        #
        #
        def load_map(*map)
          ##logger.debug("load_maping map: " + map.inspect)
          map.each { |spec|
            @data[spec[0]] = @socket.__send__(("read_" + spec[1].to_s).to_sym)
          }
        end
      end # class AbstractMessage

      # Macro that defines short message classes using a one-liner
      def self.def_message message_id, *keys
        Class.new(AbstractMessage) do
          @message_id = message_id

          define_method(:load) do
            super()
            load_map *keys
          end
        end
      end

      # Tick types received in TickPrice and TickSize messages (enumeration)
      TICK_TYPES = {
          # int id => :Description #  Corresponding API Event/Function/Method
          0 => :BID_SIZE, #               tickSize()
          1 => :BID_PRICE, #              tickPrice()
          2 => :ASK_PRICE, #              tickPrice()
          3 => :ASK_SIZE, #               tickSize()
          4 => :LAST_PRICE, #             tickPrice()
          5 => :LAST_SIZE, #              tickSize()
          6 => :HIGH, #                   tickPrice()
          7 => :LOW, #                    tickPrice()
          8 => :VOLUME, #                 tickSize()
          9 => :CLOSE_PRICE, #            tickPrice()
          10 => :BID_OPTION_COMPUTATION, #  tickOptionComputation() See Note 1 below
          11 => :ASK_OPTION_COMPUTATION, #  tickOptionComputation() See => :Note 1 below
          12 => :LAST_OPTION_COMPUTATION, # tickOptionComputation()  See Note 1 below
          13 => :MODEL_OPTION_COMPUTATION, #tickOptionComputation() See Note 1 below
          14 => :OPEN_TICK, #             tickPrice()
          15 => :LOW_13_WEEK, #           tickPrice()
          16 => :HIGH_13_WEEK, #          tickPrice()
          17 => :LOW_26_WEEK, #           tickPrice()
          18 => :HIGH_26_WEEK, #          tickPrice()
          19 => :LOW_52_WEEK, #           tickPrice()
          20 => :HIGH_52_WEEK, #          tickPrice()
          21 => :AVG_VOLUME, #            tickSize()
          22 => :OPEN_INTEREST, #         tickSize()
          23 => :OPTION_HISTORICAL_VOL, # tickGeneric()
          24 => :OPTION_IMPLIED_VOL, #    tickGeneric()
          25 => :OPTION_BID_EXCH, #   NOT USED
          26 => :OPTION_ASK_EXCH, #   NOT USED
          27 => :OPTION_CALL_OPEN_INTEREST, # tickSize()
          28 => :OPTION_PUT_OPEN_INTEREST, #  tickSize()
          29 => :OPTION_CALL_VOLUME, #        tickSize()
          30 => :OPTION_PUT_VOLUME, #         tickSize()
          31 => :INDEX_FUTURE_PREMIUM, #      tickGeneric()
          32 => :BID_EXCH, #                  tickString()
          33 => :ASK_EXCH, #                  tickString()
          34 => :AUCTION_VOLUME, #    NOT USED
          35 => :AUCTION_PRICE, #     NOT USED
          36 => :AUCTION_IMBALANCE, # NOT USED
          37 => :MARK_PRICE, #              tickPrice()
          38 => :BID_EFP_COMPUTATION, #     tickEFP()
          39 => :ASK_EFP_COMPUTATION, #     tickEFP()
          40 => :LAST_EFP_COMPUTATION, #    tickEFP()
          41 => :OPEN_EFP_COMPUTATION, #    tickEFP()
          42 => :HIGH_EFP_COMPUTATION, #    tickEFP()
          43 => :LOW_EFP_COMPUTATION, #     tickEFP()
          44 => :CLOSE_EFP_COMPUTATION, #   tickEFP()
          45 => :LAST_TIMESTAMP, #          tickString()
          46 => :SHORTABLE, #               tickGeneric()
          47 => :FUNDAMENTAL_RATIOS, #      tickString()
          48 => :RT_VOLUME, #               tickGeneric()
          49 => :HALTED, #      See Note 2 below.
          50 => :BIDYIELD, #                tickPrice() See Note 3 below
          51 => :ASKYIELD, #                tickPrice() See Note 3 below
          52 => :LASTYIELD, #               tickPrice() See Note 3 below
          53 => :CUST_OPTION_COMPUTATION, # tickOptionComputation()
          54 => :TRADE_COUNT, #             tickGeneric()
          55 => :TRADE_RATE, #              tickGeneric()
          56 => :VOLUME_RATE, #             tickGeneric()
          #   Note 1: Tick types BID_OPTION_COMPUTATION, ASK_OPTION_COMPUTATION,
          #           LAST_OPTION_COMPUTATION, and MODEL_OPTION_COMPUTATION return all
          #           Greeks (delta, gamma, vega, theta), the underlying price and the
          #           stock and option reference price when requested.
          #           MODEL_OPTION_COMPUTATION also returns model implied volatility.
          #   Note 2: When trading is halted for a contract, TWS receives a special tick:
          #           haltedLast=1. When trading is resumed, TWS receives haltedLast=0.
          #           A tick type, HALTED, tick ID= 49, is now available in regular market
          #           data via the API to indicate this halted state. Possible values for
          #           this new tick type are: 0 = Not halted, 1 = Halted.
          #   Note 3: Applies to bond contracts only.
      }

      ### Actual message classes

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
      TickPrice = def_message 1, [:id, :int], # ticker_id
                              [:tick_type, :int],
                              [:price, :decimal],
                              [:size, :int],
                              [:can_auto_execute, :int]
      class TickPrice
        def to_human
          "<Tick #{TICK_TYPES[@data[:tick_type]]}: price #{@data[:price]} size #{@data[:size]}>"
        end
      end


      TickSize = def_message 2, [:id, :int], # ticker_id
                             [:tick_type, :int],
                             [:size, :int]
      class TickSize
        def to_human
          "<TickSize #{TICK_TYPES[@data[:tick_type]]}: size #{@data[:size]}>"
        end
      end

      OrderStatus = def_message 3, [:id, :int],
                                [:status, :string],
                                [:filled, :int],
                                [:remaining, :int],
                                [:average_fill_price, :decimal],
                                [:perm_id, :int],
                                [:parent_id, :int],
                                [:last_fill_price, :decimal],
                                [:client_id, :int],
                                [:why_held, :string]

      AccountValue = def_message 6, [:key, :string],
                                 [:value, :string],
                                 [:currency, :string],
                                 [:account_name, :string]
      class AccountValue
        def to_human
          "<AccountValue: #{@data[:account_name]}, #{@data[:key]}=#{@data[:value]} #{@data[:currency]}>"
        end
      end

      AccountUpdateTime = def_message 8, [:time_stamp, :string]
      class AccountUpdateTime
        def to_human
          "<AccountUpdateTime: #{@data[:time_stamp]}>"
        end
      end

      # This message is always sent by TWS automatically at connect.
      # The IB class subscribes to it automatically and stores the order id in
      # its :next_order_id attribute.
      NextValidID = def_message 9, [:id, :int]

      MarketDepth = def_message 12, [:id, :int],
                                [:position, :int],
                                [:operation, :int],
                                [:side, :int],
                                [:price, :decimal],
                                [:size, :int]

      MarketDepthL2 = def_message 13, [:id, :int],
                                  [:position, :int],
                                  [:market_maker, :string],
                                  [:operation, :int],
                                  [:side, :int],
                                  [:price, :decimal],
                                  [:size, :int]

      NewsBulletins = def_message 14, [:news_message_id, :int],
                                  [:news_message_type, :int],
                                  [:news_message, :string],
                                  [:originating_exchange, :string]

      ManagedAccounts = def_message 15, [:accounts_list, :string]

      ReceiveFA = def_message 16, [:fa_data_type, :int], [:xml, :string]

      ScannerParameters = def_message 19, [:xml, :string]

      ContractDataEnd = def_message 52, [:id, :int] # request_id

      OpenOrderEnd = def_message 53

      AccountDownloadEnd = def_message 54, [:account_name, :string]

      ExecutionDataEnd = def_message 55, [:id, :int] # request_id

      TickSnapshotEnd = def_message 57, [:id, :int] # request_id

      # Called Error in Java code, but in fact this type of messages also
      # deliver system alerts and additional (non-error) info from TWS.
      # It has additional accessors: #code and #message, derived from @data
      Alert = def_message 4, [:id, :int], [:code, :int], [:message, :string]
      class Alert < AbstractMessage
        def code
          @data && @data[:code]
        end

        def message
          @data && @data[:message]
        end

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
          } Message #{@data[:code]}: #{@data[:message]}"
        end
      end # class ErrorMessage
      Error = Alert
      ErrorMessage = Alert

      class OpenOrder < AbstractMessage
        @message_id = 5

        attr_accessor :order, :contract

        def load
          super

          @order = Models::Order.new :id => @socket.read_int

          @contract = Models::Contract.new :symbol => @socket.read_string,
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
          @order.rule_80A = @socket.read_string
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
          @order.combo_legs_description = @socket.read_string
          @order.scale_init_level_size = @socket.read_int_max
          @order.scale_subs_level_size = @socket.read_int_max
          @order.scale_price_increment = @socket.read_decimal_max
          @order.clearing_account = @socket.read_string
          @order.clearing_intent = @socket.read_string
          @order.not_held = (@socket.read_int == 1)

          under_comp_present = (@socket.read_int == 1)

          if under_comp_present
            @contract.under_comp =
                Models::Contract::UnderComp.new :con_id => @socket.read_int,
                                                :delta => @socket.read_decimal,
                                                :price => @socket.read_decimal
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
          @order.commission = @socket.read_decimal_max
          @order.min_commission = @socket.read_decimal_max
          @order.max_commission = @socket.read_decimal_max
          @order.commission_currency = @socket.read_string
          @order.warning_text = @socket.read_string
        end
      end # OpenOrder

      class PortfolioValue < AbstractMessage
        @message_id = 7

        attr_accessor :contract

        def load
          super

          @contract = Models::Contract.new :con_id => @socket.read_int,
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
                   [:unrealized_pnl, :decimal],
                   [:realized_pnl, :decimal],
                   [:account_name, :string]
        end

        def to_human
          "<PortfolioValue: #{@contract.to_human} (#{@data[:position]}): Market #{@data[:market_price]}" +
              " price #{@data[:market_value]} value; PnL: #{@data[:unrealized_pnl]} unrealized," +
              " #{@data[:realized_pnl]} realized; account #{@data[:account_name]}>"
        end

      end # PortfolioValue

      class ContractData < AbstractMessage
        @message_id = 10

        attr_accessor :contract

        def load
          super
          load_map [:id, :int] # request id

          @contract =
              Models::Contract.new :symbol => @socket.read_string,
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

      class ExecutionData < AbstractMessage
        @message_id = 11

        attr_accessor :contract, :execution

        def load
          super
          load_map [:id, :int] # request_id

          @contract =
              Models::Contract.new :con_id => @socket.read_int,
                                   :symbol => @socket.read_string,
                                   :sec_type => @socket.read_string,
                                   :expiry => @socket.read_string,
                                   :strike => @socket.read_decimal,
                                   :right => @socket.read_string,
                                   :exchange => @socket.read_string,
                                   :currency => @socket.read_string,
                                   :local_symbol => @socket.read_string

          @execution =
              Models::Execution.new :order_id => @data[:id],
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
      end # ExecutionData

      class HistoricalData < AbstractMessage
        @message_id = 17

        def load
          super
          load_map [:id, :int],
                   [:start_date_str, :string],
                   [:end_date_str, :string],
                   [:item_count, :int]

          @data[:completed_indicator] =
              "finished-#{@data[:start_date_str]}-#{@data[:end_date_str]}"

          @data[:results] = Array.new(@data[:item_count]) do |index|
            Models::Bar.new :date => @socket.read_string,
                            :open => @socket.read_decimal,
                            :high => @socket.read_decimal,
                            :low => @socket.read_decimal,
                            :close => @socket.read_decimal,
                            :volume => @socket.read_int,
                            :wap => @socket.read_decimal,
                            :has_gaps => @socket.read_string,
                            :count => @socket.read_int
          end
        end

        def to_human
          "<HistoricalData: req id #{@data[:id]}, #{@data[:item_count]} items, from #{@data[:start_date_str]} to #{@data[:end_date_str]}>"
        end
      end # HistoricalData

      class BondContractData < AbstractMessage
        @message_id = 18

        attr_accessor :contract

        def load
          super
          load_map [:id, :int] # request id

          @contract =
              Models::Contract.new :symbol => @socket.read_string,
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

      # ScannerData contains following @data:
      # :id - The ID of the request to which this row is responding
      # :number_of_elements - Number of data points returnes (size of :results).
      # :results - an Array of Hashes, each hash contains a set of
      #            data about one scanned Contract:
      #            :contract - a full description of the contract (details).
      #            :distance - Varies based on query.
      #            :benchmark - Varies based on query.
      #            :projection - Varies based on query.
      #            :legs - Describes combo legs when scan is returning EFP.
      class ScannerData < AbstractMessage
        @message_id = 20

        def load
          super
          load_map [:id, :int],
                   [:number_of_elements, :int]

          @data[:results] = Array.new(@data[:number_of_elements]) do |index|
            {:rank => @socket.read_int,
             :contract => Contract.new(:con_id => @socket.read_int,
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

      Table = Hash.new
      Classes.each { |msg_class|
        Table[msg_class.message_id] = msg_class
      }

      #logger.debug("Incoming message class table is #{Table.inspect}")

    end # module Incoming
  end # module Messages

  IncomingMessages = Messages::Incoming # Legacy alias

end # module IB

__END__

    // incoming msg id's
    static final int TICK_PRICE		= 1; * TODO: realize both events
    static final int TICK_SIZE		= 2; *
    static final int ORDER_STATUS	= 3; *
    static final int ERR_MSG		= 4; *
    static final int OPEN_ORDER         = 5;  *
    static final int ACCT_VALUE         = 6;  *
    static final int PORTFOLIO_VALUE    = 7;  *
    static final int ACCT_UPDATE_TIME   = 8;  *
    static final int NEXT_VALID_ID      = 9;  *
    static final int CONTRACT_DATA      = 10; *
    static final int EXECUTION_DATA     = 11; *
    static final int MARKET_DEPTH     	= 12;
    static final int MARKET_DEPTH_L2    = 13;
    static final int NEWS_BULLETINS    	= 14;
    static final int MANAGED_ACCTS    	= 15;
    static final int RECEIVE_FA    	    = 16;
    static final int HISTORICAL_DATA    = 17;
    static final int BOND_CONTRACT_DATA = 18; *
    static final int SCANNER_PARAMETERS = 19;
    static final int SCANNER_DATA       = 20;
    --------- ALREADY IMLEMENTED -----------
    static final int TICK_OPTION_COMPUTATION = 21;
    static final int TICK_GENERIC = 45;
    static final int TICK_STRING = 46;
    static final int TICK_EFP = 47;
    static final int CURRENT_TIME = 49;
    static final int REAL_TIME_BARS = 50;
    static final int FUNDAMENTAL_DATA = 51;
    static final int CONTRACT_DATA_END = 52;
    static final int OPEN_ORDER_END = 53;   *
    static final int ACCT_DOWNLOAD_END = 54; *
    static final int EXECUTION_DATA_END = 55; *
    static final int DELTA_NEUTRAL_VALIDATION = 56;
    static final int TICK_SNAPSHOT_END = 57; *
