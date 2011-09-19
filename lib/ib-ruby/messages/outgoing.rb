# EClientSocket.java uses sendMax() rather than send() for a number of these.
# It sends an EOL rather than a number if the value == Integer.MAX_VALUE (or Double.MAX_VALUE).
# These fields are initialized to this MAX_VALUE.
# This has been implemented with nils in Ruby to represent the case where an EOL should be sent.

# TODO: Don't instantiate messages, use their classes as just namespace for .encode/decode

module IB
  module Messages
    module Outgoing

      class AbstractMessage
        # Class methods
        def self.message_id
          @message_id
        end

        def self.version
          @version
        end

        attr_reader :created_at, :data

        # data is a Hash
        def initialize(data = {})
          @data = data
          @created_at = Time.now
        end

        def to_human
          self.inspect
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
        def send(server)
          self.encode.flatten.each do |datum|
            # TWS wants to receive booleans as 1 or 0... rewrite as necessary.
            datum = "1" if datum == true
            datum = "0" if datum == false

            #print 'SENDING: '
            #p datum
            server[:socket].syswrite(datum.to_s + EOL)
          end
        end

        # At minimum, Outgoing message contains message_id and version.
        # Most messages also contain (ticker, request or order) :id.
        def encode
          [self.class.message_id,
           self.class.version,
           @data[:id] || []]
        end
      end # AbstractMessage

      # Macro that defines short message classes using a one-liner
      def self.def_message message_id, version=1, *keys
        Class.new(AbstractMessage) do
          @message_id = message_id
          @version = version

          define_method :encode do
            [super(), keys.map { |key| @data[key] }]
          end unless keys.empty?
        end
      end

      ### Defining (short) Outgoing Message classes for IB:

      # Empty messages (no data)
      RequestOpenOrders = def_message 5
      CancelNewsBulletins = def_message 13
      RequestAllOpenOrders = def_message 16
      RequestManagedAccounts = def_message 17
      RequestScannerParameters = def_message 24
      RequestCurrentTime = def_message 49
      RequestGlobalCancel = def_message 58

      # Data format is: @data = { :id => ticker_id}
      CancelScannerSubscription = def_message 23
      CancelMarketData = def_message 2
      CancelHistoricalData = def_message 25
      CancelRealTimeBars = def_message 51
      CancelMarketDepth = def_message 11

      # Data format is: @data = { :id => request_id }
      CancelFundamentalData = def_message 53
      CancelImpliedVolatility = def_message 56
      CancelCalculateImpliedVolatility = CancelImpliedVolatility
      CancelOptionPrice = def_message 57
      CancelCalculateOptionPrice = CancelOptionPrice

      # Data format is: @data ={ :id => order-id-to-cancel }
      CancelOrder = def_message 4

      # These messages contain just one or two keys, shown in the end of definition
      # @data = { :number_of_ids => int }
      RequestIds = def_message 8, 1, :number_of_ids
      # data = { :all_messages => boolean }
      RequestNewsBulletins = def_message 12, 1, :all_messages
      # data = { :log_level => int }
      SetServerLoglevel = def_message 14, 1, :log_level
      # data = { :auto_bind => boolean }
      RequestAutoOpenOrders = def_message 15, 1, :auto_bind
      # data = { :fa_data_type => int }
      RequestFA = def_message 18, 1, :fa_data_type
      # data = { :fa_data_type => int, :xml => String }
      ReplaceFA = def_message 19, 1, :fa_data_type, :xml

      # Data is { :subscribe => boolean,
      #           :account_code => String: only necessary for advisor accounts. Set it
      #                            to empty ('') for a standard account. }
      class RequestAccountData < AbstractMessage
        @message_id = 6
        @version = 2

        def encode
          [super,
           @data[:subscribe],
           @data[:account_code] || '']
        end
      end
      RequestAccountUpdates = RequestAccountData


      ### Defining (complex) Outgoing Message classes for IB:

      # data = { :id => ticker_id (int), :subscription => ScannerSubscription}
      class RequestScannerSubscription < AbstractMessage
        @message_id = 22
        @version = 3

        def encode
          [super,
           @data[:subscription].number_of_rows || EOL,
           @data[:subscription].instrument,
           @data[:subscription].location_code,
           @data[:subscription].scan_code,
           @data[:subscription].above_price || EOL,
           @data[:subscription].below_price || EOL,
           @data[:subscription].above_volume || EOL,
           @data[:subscription].market_cap_above || EOL,
           @data[:subscription].market_cap_below || EOL,
           @data[:subscription].moody_rating_above,
           @data[:subscription].moody_rating_below,
           @data[:subscription].sp_rating_above,
           @data[:subscription].sp_rating_below,
           @data[:subscription].maturity_date_above,
           @data[:subscription].maturity_date_below,
           @data[:subscription].coupon_rate_above || EOL,
           @data[:subscription].coupon_rate_below || EOL,
           @data[:subscription].exclude_convertible,
           @data[:subscription].average_option_volume_above,
           @data[:subscription].scanner_setting_pairs,
           @data[:subscription].stock_type_filter
          ]
        end
      end # RequestScannerSubscription

      # @data={:id => int: ticker_id - Must be a unique value. When the market data
      #                                returns, it will be identified by this tag,
      #        :contract => Datatypes::Contract, requested contract.
      #        :tick_list => String: comma delimited list of requested tick groups:
      #           Group ID - Description - Requested Tick Types
      #           100 - Option Volume (currently for stocks) - 29, 30
      #           101 - Option Open Interest (currently for stocks) - 27, 28
      #           104 - Historical Volatility (currently for stocks) - 23
      #           106 - Option Implied Volatility (currently for stocks) - 24
      #           162 - Index Future Premium - 31
      #           165 - Miscellaneous Stats - 15, 16, 17, 18, 19, 20, 21
      #           221 - Mark Price (used in TWS P&L computations) - 37
      #           225 - Auction values (volume, price and imbalance) - 34, 35, 36
      #           233 - RTVolume - 48
      #           236 - Shortable - 46
      #           256 - Inventory - ?
      #           258 - Fundamental Ratios - 47
      #           411 - Realtime Historical Volatility - 58
      #        :snapshot => bool: Check to return a single snapshot of market data and
      #                     have the market data subscription canceled. Do not enter any
      #                     :tick_list values if you use snapshot. }
      class RequestMarketData < AbstractMessage
        @message_id = 1
        @version = 9 # message version number

        def encode
          tick_list = case @data[:tick_list]
                        when nil
                          ''
                        when Array
                          @data[:tick_list].join ','
                        when String
                          @data[:tick_list]
                      end
          [super,
           @data[:contract].con_id, # part of serialize?
           @data[:contract].serialize,
           @data[:contract].serialize_combo_legs,
           @data[:contract].serialize_under_comp,
           tick_list,
           @data[:snapshot] || false]
        end
      end # RequestMarketData

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
      #          :what_to_show => Symbol: one of :trades, :midpoint, :bid, or :ask -
      #                           converts to "TRADES," "MIDPOINT," "BID," or "ASK."
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

        def encode
          if @data.has_key?(:what_to_show) && @data[:what_to_show].is_a?(String)
            @data[:what_to_show] = @data[:what_to_show].downcase.to_sym
          end

          raise ArgumentError(":what_to_show must be one of #{DATA_TYPES}.") unless DATA_TYPES.include?(@data[:what_to_show])
          raise ArgumentError(":bar_size must be one of #{BAR_SIZES}.") unless BAR_SIZES.include?(@data[:bar_size])

          contract = @data[:contract].is_a?(Models::Contract) ?
              @data[:contract] : Models::Contract.from_ib_ruby(@data[:contract])

          [super,
           contract.serialize,
           contract.include_expired,
           @data[:end_date_time],
           @data[:bar_size],
           @data[:duration],
           @data[:use_rth],
           @data[:what_to_show].to_s.upcase,
           @data[:format_date],
           contract.serialize_combo_legs]
        end
      end # RequestHistoricalData

      #  data = { :id => ticker_id (int),
      #           :contract => Contract ,
      #           :bar_size => int/Symbol? Currently only 5 second bars (2?) are supported,
      #                        if any other value is used, an exception will be thrown.,
      #          :what_to_show => Symbol: one of :trades, :midpoint, :bid, or :ask -
      #                           converts to "TRADES," "MIDPOINT," "BID," or "ASK."
      #          :use_rth => int: 0 - all data available during the time span requested
      #                     is returned, even data bars covering time intervals where the
      #                     market in question was illiquid. 1 - only data within the
      #                     "Regular Trading Hours" of the product in question is returned,
      #                     even if the time span requested falls partially or completely
      #                     outside of them.
      class RequestRealTimeBars < AbstractMessage
        @message_id = 50

        def encode
          if @data.has_key?(:what_to_show) && @data[:what_to_show].is_a?(String)
            @data[:what_to_show] = @data[:what_to_show].downcase.to_sym
          end

          raise ArgumentError(":what_to_show must be one of #{DATA_TYPES}.") unless DATA_TYPES.include?(@data[:what_to_show])
          raise ArgumentError(":bar_size must be one of #{BAR_SIZES}.") unless BAR_SIZES.include?(@data[:bar_size])

          contract = @data[:contract].is_a?(Models::Contract) ?
              @data[:contract] : Models::Contract.from_ib_ruby(@data[:contract])

          [super,
           contract.serialize,
           @data[:bar_size],
           @data[:what_to_show].to_s.upcase,
           @data[:use_rth]]
        end
      end # RequestRealTimeBars

      # data => { :id => request_id (int), :contract => Contract }
      class RequestContractData < AbstractMessage
        @message_id = 9
        @version = 6

        def encode
          [super,
           @data[:contract].con_id, # part of serialize?
           @data[:contract].serialize(:short),
           @data[:contract].include_expired,
           @data[:contract].sec_id_type,
           @data[:contract].sec_id]
        end
      end # RequestContractData
      RequestContractDetails = RequestContractData # alias

      # data = { :id => ticker_id (int), :contract => Contract, :num_rows => int }
      class RequestMarketDepth < AbstractMessage
        @message_id = 10
        @version = 3

        def encode
          [super,
           @data[:contract].serialize(:short),
           @data[:num_rows]]
        end
      end # RequestMarketDepth

      # data = { :id => ticker_id (int),
      #          :contract => Contract,
      #          :exercise_action => int,
      #          :exercise_quantity => int,
      #          :account => string,
      #          :override => int } ## override? override what?
      class ExerciseOptions < AbstractMessage
        @message_id = 21

        def encode
          [super,
           @data[:contract].serialize(:short),
           @data[:exercise_action],
           @data[:exercise_quantity],
           @data[:account],
           @data[:override]]
        end
      end # ExerciseOptions

      # Data format is { :id => order_id (int), :contract => Contract, :order => Order }
      class PlaceOrder < AbstractMessage
        @message_id = 3
        @version = 31
        # int VERSION = (m_serverVersion < MIN_SERVER_VER_NOT_HELD) ? 27 : 31;

        def encode
          [super,
           @data[:contract].serialize,
           @data[:contract].sec_id_type, # Unimplemented?
           @data[:contract].sec_id, # Unimplemented?
           @data[:order].action, # send main order fields
           @data[:order].total_quantity,
           @data[:order].order_type,
           @data[:order].limit_price,
           @data[:order].aux_price,
           @data[:order].tif, # send extended order fields
           @data[:order].oca_group,
           @data[:order].account,
           @data[:order].open_close,
           @data[:order].origin,
           @data[:order].order_ref,
           @data[:order].transmit,
           @data[:order].parent_id,
           @data[:order].block_order,
           @data[:order].sweep_to_fill,
           @data[:order].display_size,
           @data[:order].trigger_method,
           @data[:order].outside_rth, # was: ignore_rth
           @data[:order].hidden,
           @data[:contract].serialize_combo_legs(:long),
           '', # send deprecated shares_allocation field
           @data[:order].discretionary_amount,
           @data[:order].good_after_time,
           @data[:order].good_till_date,
           @data[:order].fa_group,
           @data[:order].fa_method,
           @data[:order].fa_percentage,
           @data[:order].fa_profile,
           #                                    Institutional short sale slot fields:
           @data[:order].short_sale_slot, #     0 only for retail, 1 or 2 for institution
           @data[:order].designated_location, # only populate when short_sale_slot == 2
           @data[:order].oca_type,
           @data[:order].rule_80a,
           @data[:order].settling_firm,
           @data[:order].all_or_none,
           @data[:order].min_quantity || EOL,
           @data[:order].percent_offset || EOL,
           @data[:order].etrade_only,
           @data[:order].firm_quote_only,
           @data[:order].nbbo_price_cap || EOL,
           @data[:order].auction_strategy || EOL,
           @data[:order].starting_price || EOL,
           @data[:order].stock_ref_price || EOL,
           @data[:order].delta || EOL,
           @data[:order].stock_range_lower || EOL,
           @data[:order].stock_range_upper || EOL,
           @data[:order].override_percentage_constraints,
           @data[:order].volatility || EOL, #              Volatility orders
           @data[:order].volatility_type || EOL, #         Volatility orders
           @data[:order].delta_neutral_order_type, #       Volatility orders
           @data[:order].delta_neutral_aux_price || EOL, # Volatility orders
           @data[:order].continuous_update, #              Volatility orders
           @data[:order].reference_price_type || EOL, #    Volatility orders
           @data[:order].trail_stop_price || EOL, # TRAIL_STOP_LIMIT stop price
           @data[:order].scale_init_level_size || EOL, # Scale Orders
           @data[:order].scale_subs_level_size || EOL, # Scale Orders
           @data[:order].scale_price_increment || EOL, # Scale Orders
           @data[:order].clearing_account,
           @data[:order].clearing_intent,
           @data[:order].not_held,
           @data[:contract].serialize_under_comp,
           @data[:contract].serialize_algo,
           @data[:order].what_if]
        end
      end # PlaceOrder

      # data = { :filter => ExecutionFilter ]
      class RequestExecutions < AbstractMessage
        @message_id = 7
        @version = 3

        def encode
          [super,
           @data[:filter].client_id,
           @data[:filter].acct_code,
           @data[:filter].time, # Valid format for time is "yyyymmdd-hh:mm:ss"
           @data[:filter].symbol,
           @data[:filter].sec_type,
           @data[:filter].exchange,
           @data[:filter].side]
        end # encode
      end # RequestExecutions

      # data = { :request_id => int, :contract => Contract, :report_type => String }
      class RequestFundamentalData < AbstractMessage
        @message_id = 52

        def encode
          [super,
           @data[:request_id],
           @data[:contract].symbol, # Yet another Contract serialization!
           @data[:contract].sec_type,
           @data[:contract].exchange,
           @data[:contract].primary_exchange,
           @data[:contract].currency,
           @data[:contract].local_symbol,
           @data[:report_type]]
        end
      end # RequestFundamentalData

      # data = { :request_id => int, :contract => Contract,
      #          :option_price => double, :under_price => double }
      class RequestImpliedVolatility < AbstractMessage
        @message_id = 54

        def encode
          [super,
           @data[:request_id],
           @data[:contract].con_id, # part of serialize?
           @data[:contract].serialize,
           @data[:option_price],
           @data[:under_price]]
        end
      end # RequestImpliedVolatility
      CalculateImpliedVolatility = RequestImpliedVolatility
      RequestCalculateImpliedVolatility = RequestImpliedVolatility

      # data = { :request_id => int, :contract => Contract,
      #          :volatility => double, :under_price => double }
      class RequestOptionPrice < AbstractMessage
        @message_id = 55

        def encode
          [super,
           @data[:request_id],
           @data[:contract].con_id, # part of serialize?
           @data[:contract].serialize,
           @data[:volatility],
           @data[:under_price]]
        end
      end # RequestOptionPrice
      CalculateOptionPrice = RequestOptionPrice
      RequestCalculateOptionPrice = RequestOptionPrice

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
