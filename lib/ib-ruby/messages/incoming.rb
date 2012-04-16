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
            error "Unsupported version #{actual} received, expected #{expected}"
          end
        end

        # Create incoming message from a given source (IB server or data Hash)
        def initialize source
          @created_at = Time.now
          if source[:socket] # Source is a server
            @server = source
            @data = Hash.new
            begin
              self.load
            rescue => e
              error "Reading #{self.class}: #{e.class}: #{e.message}", :load, e.backtrace
            ensure
              @server = nil
            end
          else # Source is a @data Hash
            @data = source
          end
        end

        def socket
          @server[:socket]
        end

        # Every message loads received message version first
        # Override the load method in your subclass to do actual reading into @data.
        def load
          @data[:version] = socket.read_int

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
          map.each do |instruction|
            # We determine the function of the first element
            head = instruction.first
            case head
              when Integer # >= Version condition: [ min_version, [map]]
                load_map *instruction.drop(1) if version >= head

              when Proc # Callable condition: [ condition, [map]]
                load_map *instruction.drop(1) if head.call

              when true # Pre-condition already succeeded!
                load_map *instruction.drop(1)

              when nil, false # Pre-condition already failed! Do nothing...

              when Symbol # Normal map
                group, name, type, block =
                    if  instruction[2].nil? || instruction[2].is_a?(Proc)
                      [nil] + instruction # No group, [ :name, :type, (:block) ]
                    else
                      instruction # [ :group, :name, :type, (:block)]
                    end

                data = socket.__send__("read_#{type}", &block)
                if group
                  @data[group] ||= {}
                  @data[group][name] = data
                else
                  @data[name] = data
                end
              else
                error "Unrecognized instruction #{instruction}"
            end
          end
        end
      end

      # class AbstractMessage

      ### Actual message classes (short definitions):

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
                      #                    1 = GROUPS, 2 = PROFILE, 3 = ACCOUNT ALIASES
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

    end # module Incoming
  end # module Messages
end # module IB

# Require standalone message source files
require 'ib-ruby/messages/incoming/alert'
require 'ib-ruby/messages/incoming/contract_data'
require 'ib-ruby/messages/incoming/delta_neutral_validation'
require 'ib-ruby/messages/incoming/execution_data'
require 'ib-ruby/messages/incoming/historical_data'
require 'ib-ruby/messages/incoming/market_depths'
require 'ib-ruby/messages/incoming/open_order'
require 'ib-ruby/messages/incoming/order_status'
require 'ib-ruby/messages/incoming/portfolio_value'
require 'ib-ruby/messages/incoming/real_time_bar'
require 'ib-ruby/messages/incoming/scanner_data'
require 'ib-ruby/messages/incoming/ticks'

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
