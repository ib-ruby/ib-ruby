require 'ib-ruby/messages/abstract_message'

# EClientSocket.java uses sendMax() rather than send() for a number of these.
# It sends an EOL rather than a number if the value == Integer.MAX_VALUE (or Double.MAX_VALUE).
# These fields are initialized to this MAX_VALUE.
# This has been implemented with nils in Ruby to represent the case where an EOL should be sent.

# TODO: Don't instantiate messages, use their classes as just namespace for .encode/decode

module IB
  module Messages
    module Outgoing
      extend Messages # def_message macros

      class AbstractMessage < IB::Messages::AbstractMessage

        def initialize data={}
          @data = data
          @created_at = Time.now
        end

        # This causes the message to send itself over the server socket in server[:socket].
        # "server" is the @server instance variable from the IB object.
        # You can also use this to e.g. get the server version number.
        #
        # Subclasses can either override this method for precise control over how
        # stuff gets sent to the server, or else define a method encode() that returns
        # an Array of elements that ought to be sent to the server by calling to_s on
        # each one and postpending a '\0'.
        #
        def send_to(server)
          self.encode.flatten.each do |datum|
            # TWS wants to receive booleans as 1 or 0... rewrite as necessary.
            datum = "1" if datum == true
            datum = "0" if datum == false

            #p datum.to_s + EOL
            server[:socket].syswrite(datum.to_s + EOL)
          end
        end

        # At minimum, Outgoing message contains message_id and version.
        # Most messages also contain (ticker, request or order) :id.
        # Then, content of @data Hash is encoded per instructions in data_map.
        def encode
          [self.class.message_id,
           self.class.version,
           @data[:id] || @data[:ticker_id] || @data[:request_id]|| @data[:order_id] || [],
           self.class.data_map.map do |(field, default_method, args)|
             case
               when default_method.nil?
                 @data[field]

               when default_method.is_a?(Symbol) # method name with args
                 @data[field].send default_method, *args

               when default_method.respond_to?(:call) # callable with args
                 default_method.call @data[field], *args

               else # default
                 @data[field].nil? ? default_method : @data[field] # may be false still
             end
           end
          ].flatten
        end
      end # AbstractMessage

      ### Defining (short) Outgoing Message classes for IB:

      ## Empty messages (no data)

      # Request the open orders that were placed from THIS client. Each open order
      # will be fed back through the OpenOrder and OrderStatus messages.
      # NB: Client with a client_id of 0 will also receive the TWS-owned open orders.
      # These orders will be associated with the client and a new orderId will be
      # generated. This association will persist over multiple API and TWS sessions.
      RequestOpenOrders = def_message 5

      # Request the open orders placed from all clients and also from TWS. Each open
      # order will be fed back through the OpenOrder and OrderStatus messages.
      RequestAllOpenOrders = def_message 16

      # Requests an XML document that describes the valid parameters that a scanner
      # subscription can have (for outgoing RequestScannerSubscription message).
      RequestScannerParameters = def_message 24

      CancelNewsBulletins = def_message 13
      RequestManagedAccounts = def_message 17
      RequestCurrentTime = def_message 49
      RequestGlobalCancel = def_message 58

      ## Data format is: @data = { :id => ticker_id}
      CancelMarketData = def_message 2
      CancelMarketDepth = def_message 11
      CancelScannerSubscription = def_message 23
      CancelHistoricalData = def_message 25
      CancelRealTimeBars = def_message 51

      ## Data format is: @data = { :id => request_id }
      CancelFundamentalData = def_message 53
      CancelCalculateImpliedVolatility = CancelImpliedVolatility = def_message(56)
      CancelCalculateOptionPrice = CancelOptionPrice = def_message(57)

      ## Data format is: @data ={ :id => order_id to cancel }
      CancelOrder = def_message 4

      ## These messages contain just one or two extra fields:

      # Request the next valid ID that can be used when placing an order. Responds with
      # NextValidId message, and the id returned is that next valid Id for orders.
      # That ID will reflect any autobinding that has occurred (which generates new
      # IDs and increments the next valid ID therein).
      # @data = { :number of ids requested => int } NB: :number option is ignored by TWS!
      RequestIds = def_message 8, [:number, 1]
      # data = { :all_messages => boolean }
      RequestNewsBulletins = def_message 12, :all_messages
      # data = { :log_level => int }
      SetServerLoglevel = def_message 14, :log_level
      # data = { :auto_bind => boolean }
      RequestAutoOpenOrders = def_message 15, :auto_bind
      # data = { :fa_data_type => int }
      RequestFA = def_message 18, :fa_data_type
      # data = { :fa_data_type => int, :xml => String }
      ReplaceFA = def_message 19, :fa_data_type, :xml

      # @data = { :subscribe => boolean,
      #           :account_code => Advisor accounts only. Empty ('') for a standard account. }
      RequestAccountUpdates = RequestAccountData = def_message([6, 2],
                                                               [:subscribe, true],
                                                               :account_code)

      # data => { :id => request_id (int), :contract => Contract }
      RequestContractDetails = RequestContractData =
          def_message([9, 6],
                      [:contract, :serialize_short, [:con_id, :include_expired, :sec_id]])

      # data = { :id => ticker_id (int), :contract => Contract, :num_rows => int }
      RequestMarketDepth = def_message([10, 3],
                                       [:contract, :serialize_short, []],
                                       :num_rows)

      ### Defining (complex) Outgoing Message classes for IB:

      # When this message is sent, TWS responds with ExecutionData messages, each
      # containing the execution report that meets the specified criteria.
      # @data={:id =>         int: :request_id,
      #        :client_id => int: Filter the results based on the clientId.
      #        :acct_code => Filter the results based on based on account code.
      #                      Note: this is only relevant for Financial Advisor accts.
      #        :sec_type =>  Filter the results based on the order security type.
      #        :time =>      Filter the results based on execution reports received
      #                      after the specified time - format "yyyymmdd-hh:mm:ss"
      #        :symbol   =>  Filter the results based on the order symbol.
      #        :exchange =>  Filter the results based on the order exchange
      #        :side =>  Filter the results based on the order action: BUY/SELL/SSHORT
      RequestExecutions = def_message(7,
                                      :client_id,
                                      :acct_code,
                                      :time, # Format "yyyymmdd-hh:mm:ss"
                                      :symbol,
                                      :sec_type,
                                      :exchange,
                                      :side)

      # data = { :id => ticker_id (int),
      #          :contract => Contract,
      #          :exercise_action => int, 1 = exercise, 2 = lapse
      #          :exercise_quantity => int, The number of contracts to be exercised
      #          :account => string,
      #          :override => int: Specifies whether your setting will override the
      #                       system's natural action. For example, if your action
      #                       is "exercise" and the option is not in-the-money, by
      #                       natural action the option would not exercise. If you
      #                       have override set to "yes" the natural action would be
      #                       overridden and the out-of-the money option would be
      #                       exercised. Values are:
      #                              • 0 = do not override
      #                              • 1 = override
      ExerciseOptions = def_message(21,
                                    [:contract, :serialize_short],
                                    :exercise_action,
                                    :exercise_quantity,
                                    :account,
                                    :override)

      # @data={:id => int: ticker_id - Must be a unique value. When the market data
      #                                returns, it will be identified by this tag,
      #      :contract => Models::Contract, requested contract.
      #      :tick_list => String: comma delimited list of requested tick groups:
      #        Group ID - Description - Requested Tick Types
      #        100 - Option Volume (currently for stocks) - 29, 30
      #        101 - Option Open Interest (currently for stocks) - 27, 28
      #        104 - Historical Volatility (currently for stocks) - 23
      #        106 - Option Implied Volatility (currently for stocks) - 24
      #        162 - Index Future Premium - 31
      #        165 - Miscellaneous Stats - 15, 16, 17, 18, 19, 20, 21
      #        221 - Mark Price (used in TWS P&L computations) - 37
      #        225 - Auction values (volume, price and imbalance) - 34, 35, 36
      #        233 - RTVolume - 48
      #        236 - Shortable - 46
      #        256 - Inventory - ?
      #        258 - Fundamental Ratios - 47
      #        411 - Realtime Historical Volatility - 58
      #      :snapshot => bool: Check to return a single snapshot of market data and
      #                   have the market data subscription canceled. Do not enter any
      #                   :tick_list values if you use snapshot. }
      RequestMarketData =
          def_message([1, 9],
                      [:contract, :serialize_long, [:con_id]],
                      [:contract, :serialize_legs, []],
                      [:contract, :serialize_under_comp, []],
                      [:tick_list, lambda do |tick_list|
                        tick_list.is_a?(Array) ? tick_list.join(',') : (tick_list || '')
                      end, []],
                      [:snapshot, false])

      # Send this message to receive Reuters global fundamental data. There must be
      # a subscription to Reuters Fundamental set up in Account Management before
      # you can receive this data.
      # data = { :id => int: :request_id,
      #          :contract => Contract,
      #          :report_type => String: one of the following:
      #                          'Estimates', 'Financial Statements', 'Summary'   }
      RequestFundamentalData =
          def_message(52,
                      [:contract, :serialize, [:primary_exchange]],
                      :report_type)

      # data = { :request_id => int, :contract => Contract,
      #          :option_price => double, :under_price => double }
      RequestCalculateImpliedVolatility = CalculateImpliedVolatility =
          RequestImpliedVolatility =
              def_message(54,
                          [:contract, :serialize_long, [:con_id]],
                          :option_price,
                          :under_price)

      # data = { :request_id => int, :contract => Contract,
      #          :volatility => double, :under_price => double }
      RequestCalculateOptionPrice = CalculateOptionPrice = RequestOptionPrice =
          def_message(55,
                      [:contract, :serialize_long, [:con_id]],
                      :volatility,
                      :under_price)

      # Start receiving market scanner results through the ScannerData messages.
      # @data = { :id => ticker_id (int),
      #  :number_of_rows => int: number of rows of data to return for a query.
      #  :instrument => The instrument type for the scan. Values include
      #                                'STK', - US stocks
      #                                'STOCK.HK' - Asian stocks
      #                                'STOCK.EU' - European stocks
      #  :location_code => Legal Values include:
      #                           • STK.US - US stocks
      #                           • STK.US.MAJOR - US stocks (without pink sheet)
      #                           • STK.US.MINOR - US stocks (only pink sheet)
      #                           • STK.HK.SEHK - Hong Kong stocks
      #                           • STK.HK.ASX - Australian Stocks
      #                           • STK.EU - European stocks
      #  :scan_code => The type of the scan, such as HIGH_OPT_VOLUME_PUT_CALL_RATIO.
      #  :above_price => double: Only contracts with a price above this value.
      #  :below_price => double: Only contracts with a price below this value.
      #  :above_volume => int: Only contracts with a volume above this value.
      #  :market_cap_above => double: Only contracts with a market cap above this
      #  :market_cap_below => double: Only contracts with a market cap below this value.
      #  :moody_rating_above => Only contracts with a Moody rating above this value.
      #  :moody_rating_below => Only contracts with a Moody rating below this value.
      #  :sp_rating_above => Only contracts with an S&P rating above this value.
      #  :sp_rating_below => Only contracts with an S&P rating below this value.
      #  :maturity_date_above => Only contracts with a maturity date later than this
      #  :maturity_date_below => Only contracts with a maturity date earlier than this
      #  :coupon_rate_above => double: Only contracts with a coupon rate above this
      #  :coupon_rate_below => double: Only contracts with a coupon rate below this
      #  :exclude_convertible => Exclude convertible bonds.
      #  :scanner_setting_pairs => Used with the scan_code to help further narrow your query.
      #                            Scanner Setting Pairs are delimited by slashes, making
      #                            this parameter open ended. Example is "Annual,true" -
      #                            when used with 'Top Option Implied Vol % Gainers' scan
      #                            would return annualized volatilities.
      #  :average_option_volume_above =>  int: Only contracts with average volume above this
      #  :stock_type_filter => Valid values are:
      #                          'ALL' (excludes nothing)
      #                          'STOCK' (excludes ETFs)
      #                          'ETF' (includes ETFs) }
      # ------------
      # To learn all valid parameter values that a scanner subscription can have,
      # first subscribe to ScannerParameters and send RequestScannerParameters message.
      # Available scanner parameters values will be listed in received XML document.
      RequestScannerSubscription =
          def_message([22, 3],
                      [:number_of_rows, -1], # was: EOL,
                      :instrument,
                      :location_code,
                      :scan_code,
                      [:above_price, EOL],
                      [:below_price, EOL],
                      [:above_volume, EOL],
                      [:market_cap_above, EOL],
                      [:market_cap_below, EOL],
                      :moody_rating_above,
                      :moody_rating_below,
                      :sp_rating_above,
                      :sp_rating_below,
                      :maturity_date_above,
                      :maturity_date_below,
                      [:coupon_rate_above, EOL],
                      [:coupon_rate_below, EOL],
                      :exclude_convertible,
                      [:average_option_volume_above, EOL], # ?
                      :scanner_setting_pairs,
                      :stock_type_filter)

      ### Even more complex Outgoing Message classes, overriding #encode method:

      # Data format is { :id => order_id (int),
      #                  :contract => Contract,
      #                  :order => Order }
      class PlaceOrder < AbstractMessage
        @message_id = 3
        @version = 31

        def encode
          [super,
           @data[:order].serialize_with(@data[:contract])].flatten
        end
      end # PlaceOrder

      module DataParser
        # Preprocessor for some data fields
        def parse data
          data_type = DATA_TYPES[data[:what_to_show]] || data[:what_to_show]
          unless  DATA_TYPES.values.include?(data_type)
            raise ArgumentError.new(":what_to_show must be one of #{DATA_TYPES.inspect}.")
          end

          bar_size = BAR_SIZES[data[:bar_size]] || data[:bar_size]
          unless  BAR_SIZES.values.include?(bar_size)
            raise ArgumentError.new(":bar_size must be one of #{BAR_SIZES.inspect}.")
          end

          contract = data[:contract].is_a?(Models::Contract) ?
              data[:contract] : Models::Contract.from_ib_ruby(data[:contract])

          [data_type, bar_size, contract]
        end
      end

      #  data = { :id => ticker_id (int),
      #           :contract => Contract ,
      #           :bar_size => int/Symbol? Currently only 5 second bars (2?) are supported,
      #                        if any other value is used, an exception will be thrown.,
      #          :what_to_show => Symbol: Determines the nature of data being extracted.
      #                           Valid values:
      #                             :trades, :midpoint, :bid, :ask, :bid_ask,
      #                             :historical_volatility, :option_implied_volatility,
      #                             :option_volume, :option_open_interest
      #                              - converts to "TRADES," "MIDPOINT," "BID," etc...
      #          :use_rth => int: 0 - all data available during the time span requested
      #                     is returned, even data bars covering time intervals where the
      #                     market in question was illiquid. 1 - only data within the
      #                     "Regular Trading Hours" of the product in question is returned,
      #                     even if the time span requested falls partially or completely
      #                     outside of them.
      class RequestRealTimeBars < AbstractMessage
        @message_id = 50
        @version = 1 # ?

        include DataParser

        def encode
          data_type, bar_size, contract = parse @data

          [super,
           contract.serialize_long,
           bar_size,
           data_type.to_s.upcase,
           @data[:use_rth]].flatten
        end
      end # RequestRealTimeBars

      # data = { :id => int: Ticker id, needs to be different than the reqMktData ticker
      #                 id. If you use the same ticker ID you used for the symbol when
      #                 you did ReqMktData, nothing comes back for the historical data call
      #          :contract => Contract: requested ticker description
      #          :end_date_time => String: "yyyymmdd HH:mm:ss", with optional time zone
      #                            allowed after a space: "20050701 18:26:44 GMT"
      #          :duration => String, time span the request will cover, and is specified
      #                  using the format: <integer> <unit>, eg: '1 D', valid units are:
      #                        '1 S' (seconds, default if no unit is specified)
      #                        '1 D' (days)
      #                        '1 W' (weeks)
      #                        '1 M' (months)
      #                        '1 Y' (years, currently limited to one)
      #          :bar_size => String: Specifies the size of the bars that will be returned
      #                       (within IB/TWS limits). Valid values include:
      #                             '1 sec'
      #                             '5 secs'
      #                             '15 secs'
      #                             '30 secs'
      #                             '1 min'
      #                             '2 mins'
      #                             '3 mins'
      #                             '5 mins'
      #                             '15 mins'
      #                             '30 min'
      #                             '1 hour'
      #                             '1 day'
      #          :what_to_show => Symbol: Determines the nature of data being extracted.
      #                           Valid values:
      #                             :trades, :midpoint, :bid, :ask, :bid_ask,
      #                             :historical_volatility, :option_implied_volatility,
      #                             :option_volume, :option_open_interest
      #                              - converts to "TRADES," "MIDPOINT," "BID," etc...
      #          :use_rth => int: 0 - all data available during the time span requested
      #                     is returned, even data bars covering time intervals where the
      #                     market in question was illiquid. 1 - only data within the
      #                     "Regular Trading Hours" of the product in question is returned,
      #                     even if the time span requested falls partially or completely
      #                     outside of them.
      #          :format_date => int: 1 - text format, like "20050307 11:32:16".
      #                               2 - offset in seconds from the beginning of 1970,
      #                                   which is the same format as the UNIX epoch time.
      #         }
      #
      # Note that as of 4/07 there is no historical data available for forex spot.
      #
      # data[:contract] may either be a Contract object or a String. A String should be
      # in serialize_ib_ruby format; that is, it should be a colon-delimited string in
      # the format (e.g. for Globex British pound futures contract expiring in Sep-2008):
      #
      #    symbol:security_type:expiry:strike:right:multiplier:exchange:primary_exchange:currency:local_symbol
      #    GBP:FUT:200809:::62500:GLOBEX::USD:
      #
      # Fields not needed for a particular security should be left blank (e.g. strike
      # and right are only relevant for options.)
      #
      # A Contract object will be automatically serialized into the required format.
      #
      # See also http://chuckcaplan.com/twsapi/index.php/void%20reqIntradayData%28%29
      # for general information about how TWS handles historic data requests, whence
      # the following has been adapted:
      #
      # The server providing historical prices appears to not always be
      # available outside of market hours. If you call it outside of its
      # supported time period, or if there is otherwise a problem with
      # it, you will receive error #162 "Historical Market Data Service
      # query failed.:HMDS query returned no data."
      #
      # For backfill on futures data, you may need to leave the Primary
      # Exchange field of the Contract structure blank; see
      # http://www.interactivebrokers.com/discus/messages/2/28477.html?1114646754
      class RequestHistoricalData < AbstractMessage
        @message_id = 20
        @version = 4

        include DataParser

        def encode
          data_type, bar_size, contract = parse @data

          [super,
           contract.serialize_long(:include_expired),
           @data[:end_date_time],
           bar_size,
           @data[:duration],
           @data[:use_rth],
           data_type.to_s.upcase,
           @data[:format_date],
           contract.serialize_legs].flatten
        end
      end # RequestHistoricalData


    end # module Outgoing
  end # module Messages
end # module IB

__END__
    // outgoing msg id's
    private static final int REQ_MKT_DATA = 1;
    private static final int CANCEL_MKT_DATA = 2;
    private static final int PLACE_ORDER = 3;
    private static final int CANCEL_ORDER = 4;
    private static final int REQ_OPEN_ORDERS = 5;
    private static final int REQ_ACCOUNT_DATA = 6;
    private static final int REQ_EXECUTIONS = 7;
    private static final int REQ_IDS = 8;
    private static final int REQ_CONTRACT_DATA = 9;
    private static final int REQ_MKT_DEPTH = 10;
    private static final int CANCEL_MKT_DEPTH = 11;
    private static final int REQ_NEWS_BULLETINS = 12;
    private static final int CANCEL_NEWS_BULLETINS = 13;
    private static final int SET_SERVER_LOGLEVEL = 14;
    private static final int REQ_AUTO_OPEN_ORDERS = 15;
    private static final int REQ_ALL_OPEN_ORDERS = 16;
    private static final int REQ_MANAGED_ACCTS = 17;
    private static final int REQ_FA = 18;
    private static final int REPLACE_FA = 19;
    private static final int REQ_HISTORICAL_DATA = 20;
    private static final int EXERCISE_OPTIONS = 21;
    private static final int REQ_SCANNER_SUBSCRIPTION = 22;
    private static final int CANCEL_SCANNER_SUBSCRIPTION = 23;
    private static final int REQ_SCANNER_PARAMETERS = 24;
    private static final int CANCEL_HISTORICAL_DATA = 25;
    private static final int REQ_CURRENT_TIME = 49;
    private static final int REQ_REAL_TIME_BARS = 50;
    private static final int CANCEL_REAL_TIME_BARS = 51;
    private static final int REQ_FUNDAMENTAL_DATA = 52;
    private static final int CANCEL_FUNDAMENTAL_DATA = 53;
    private static final int REQ_CALC_IMPLIED_VOLAT = 54;
    private static final int REQ_CALC_OPTION_PRICE = 55;
    private static final int CANCEL_CALC_IMPLIED_VOLAT = 56;
    private static final int CANCEL_CALC_OPTION_PRICE = 57;
    private static final int REQ_GLOBAL_CANCEL = 58;
