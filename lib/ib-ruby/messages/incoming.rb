require 'ib-ruby/messages/abstract_message'

# EClientSocket.java uses sendMax() rather than send() for a number of these.
# It sends an EOL rather than a number if the value == Integer.MAX_VALUE (or Double.MAX_VALUE).
# These fields are initialized to this MAX_VALUE.
# This has been implemented with nils in Ruby to represent the case where an EOL should be sent.

# TODO: Don't instantiate messages, use their classes as just namespace for .encode/decode
# TODO: realize Message#fire method that raises EWrapper events

module IB
  module Messages

    # Incoming IB messages (received from TWS/Gateway)
    module Incoming
      extend Messages # def_message macros

      # Container for specific message classes, keyed by their message_ids
      Classes = {}

      class AbstractMessage < IB::Messages::AbstractMessage

        def version # Per message, received messages may have the different versions
          @data[:version]
        end

        def check_version actual, expected
          unless actual == expected || expected.is_a?(Array) && expected.include?(actual)
            error "Unsupported version #{actual} of #{self.class} received"
          end
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
        # Override the load method in your subclass to do actual reading into @data.
        def load
          @data[:version] = @socket.read_int

          check_version @data[:version], self.class.version

          load_map *self.class.data_map
        end

        # Load @data from the socket according to the given data map.
        #
        # map is a series of Arrays in the format of
        #   [ :name, :type ], [  :group, :name, :type]
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

      ### Actual message classes (short definitions):

      # :status - String: Displays the order status. Possible values include:
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
      FundamentalData = def_message 50, [:request_id, :int], [:data, :string]

      ContractDataEnd = def_message 52, [:request_id, :int]

      OpenOrderEnd = def_message 53

      AccountDownloadEnd = def_message 54, [:account_name, :string]

      ExecutionDataEnd = def_message 55, [:request_id, :int]

      MarketDataType = def_message 58, [:request_id, :int], [:market_data_type, :int]

      CommissionReport =
          def_message 59, [:exec_id, :int],
                      [:commission, :decimal], # Commission amount.
                      [:currency, :int], #       Commission currency
                      [:realized_pnl, :decimal],
                      [:yield, :decimal],
                      [:yield_redemption_date, :int]

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
          def_message [11, 8],
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
                      [:execution, :average_price, :decimal],
                      [:execution, :order_ref, :string]

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
                      [:request_id, :int],
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

    end # module Incoming
  end # module Messages
end # module IB

# Require standalone message source files
require 'ib-ruby/messages/incoming/ticks'
require 'ib-ruby/messages/incoming/open_order'

__END__
    // incoming msg id's
    static final int TICK_PRICE		= 1; *
    static final int TICK_SIZE		= 2; *
    static final int ORDER_STATUS	= 3; *
    static final int ERR_MSG		= 4;   *
    static final int OPEN_ORDER         = 5;  *
    static final int ACCT_VALUE         = 6;  *
    static final int PORTFOLIO_VALUE    = 7;  *
    static final int ACCT_UPDATE_TIME   = 8;  *
    static final int NEXT_VALID_ID      = 9;  *
    static final int CONTRACT_DATA      = 10; *
    static final int EXECUTION_DATA     = 11; ?
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
    static final int MARKET_DATA_TYPE = 58;   ?
    static final int COMMISSION_REPORT = 59;  ?
