# EClientSocket.java uses sendMax() rather than send() for a number of these.
# It sends an EOL rather than a number if the value == Integer.MAX_VALUE (or Double.MAX_VALUE).
# These fields are initialized to this MAX_VALUE.
# This has been implemented with nils in Ruby to represent the case where an EOL should be sent.

module IB
  module Messages
    module Outgoing

      EOL = "\0"

      FaMsgTypeName = {1 => "GROUPS",
                       2 => "PROFILES",
                       3 =>"ALIASES"}

      class AbstractMessage
        # Class methods
        def self.message_id
          @message_id
        end

        def self.version
          @version
        end

        attr_reader :created_at

        # data is a Hash?
        def initialize(data=nil)
          @created_at = Time.now
          @data = Datatypes::StringentHash.new(data)
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

            server[:socket].syswrite(datum.to_s + "\0")
          end
        end

        # At minimum, Outgoing message contains message_id and version (default version is 1)
        def encode
          [self.class.message_id, self.class.version || 1]
        end

        protected

        # TODO: Get rid of this, if possible
        # Returns EOL instead of datum if datum is nil, providing the same functionality
        # as sendMax() in the Java version, which uses Double.MAX_VALUE to mean "item not set"
        # in a variable, and replaces that with EOL on send.
        def nilFilter(datum)
          datum.nil? ? EOL : datum
        end
      end # AbstractMessage

      # Most IB Cancel... messages follow the same format
      # data = { :ticker_id => int }
      class CancelMessage < AbstractMessage
        def encode
          [super, @data[:ticker_id]]
        end
      end # CancelMessage

      class CancelScannerSubscription < CancelMessage
        @message_id = 23
      end # CancelScannerSubscription

      class CancelMarketData < CancelMessage
        @message_id = 2
      end # CancelMarketData

      class CancelHistoricalData < CancelMessage
        @message_id = 25
      end # CancelHistoricalData

      class CancelRealTimeBars < CancelMessage
        @message_id = 51
      end # CancelRealTimeBars

      # data = { :ticker_id => int }
      class CancelMarketDepth < CancelMessage
        @message_id = 11
      end # CancelMarketDepth

      # Data format is { :id => id-to-cancel }
      # TODO: Use :id instead of :order_id, :ticker_id?
      class CancelOrder < AbstractMessage
        @message_id = 4

        def encode
          super << @data[:id]
        end
      end # CancelOrder

      # data = { :request_id => int}
      class CancelFundamentalData < AbstractMessage
        @message_id = 53

        def encode
          super << @data[:request_id]
        end
      end # CancelFundamentalData

      # data = { :request_id => int}
      class CancelImpliedVolatility < AbstractMessage
        @message_id = 56

        def encode
          super << @data[:request_id]
        end
      end # CancelImpliedVolatility
      CancelCalculateImpliedVolatility = CancelImpliedVolatility

      # data = { :request_id => int}
      class CancelOptionPrice < AbstractMessage
        @message_id = 57

        def encode
          super << @data[:request_id]
        end
      end # CancelOptionPrice
      CancelCalculateOptionPrice = CancelOptionPrice

      class RequestGlobalCancel
        @message_id = 58
      end # RequestGlobalCancel

      class RequestScannerParameters
        @message_id = 24
      end # RequestScannerParameters

      # data = { :ticker_id => int, :subscription => ScannerSubscription}
      class RequestScannerSubscription < AbstractMessage
        @message_id = 22
        @version = 3

        def encode
          [super,
           @data[:ticker_id],
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

      # Data format is { :ticker_id => int, :contract => Datatypes::Contract,
      #                  :generic_tick_list => String, :snapshot =>  boolean }
      class RequestMarketData < AbstractMessage
        @message_id = 1
        @version = 9 # message version number

        def encode
          [super,
           @data[:ticker_id],
           @data[:contract].con_id, # part of serialize?
           @data[:contract].serialize,
           @data[:contract].serialize_combo_legs,
           @data[:contract].serialize_under_comp]
        end
      end # RequestMarketData

      # data = { :ticker_id => int,
      #          :contract => Contract,
      #          :end_date_time => string,
      #          :duration => string, # this specifies an integer number of seconds
      #          :bar_size => int,
      #          :what_to_show => symbol, # one of :trades, :midpoint, :bid, or :ask
      #          :use_RTH => int,
      #          :format_date => int    }
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
      # The "endDateTime" parameter accepts a string in the form
      # "yyyymmdd HH:mm:ss", with a time zone optionally allowed after a
      # space at the end of the string; e.g. "20050701 18:26:44 GMT"
      #
      # The ticker id needs to be different than the reqMktData ticker
      # id. If you use the same ticker ID you used for the symbol when
      # you did ReqMktData, nothing comes back for the historical data call.
      #
      # Possible :bar_size values:
      # 1 = 1 sec
      # 2 = 5 sec
      # 3 = 15 sec
      # 4 = 30 sec
      # 5 = 1 minute
      # 6 = 2 minutes
      # 7 = 5 minutes
      # 8 = 15 minutes
      # 9 = 30 minutes
      # 10 = 1 hour
      # 11 = 1 day
      #
      # Values less than 4 do not appear to work for certain securities.
      #
      # The nature of the data extracted is governed by sending a string
      # having a value of "TRADES," "MIDPOINT," "BID," or "ASK." Here,
      # we require a symbol argument of :trades, :midpoint, :bid, or
      # :ask to be passed as data[:what_to_show].
      #
      # If data[:use_RTH] is set to 0, all data available during the time
      # span requested is returned, even data bars covering time
      # intervals where the market in question was illiquid. If useRTH
      # has a non-zero value, only data within the "Regular Trading
      # Hours" of the product in question is returned, even if the time
      # span requested falls partially or completely outside of them.
      #
      # Using a :format_date of 1 will cause the dates in the returned
      # messages with the historic data to be in a text format, like
      # "20050307 11:32:16". If you set :format_date to 2 instead, you
      # will get an offset in seconds from the beginning of 1970, which
      # is the same format as the UNIX epoch time.
      #
      # For backfill on futures data, you may need to leave the Primary
      # Exchange field of the Contract structure blank; see
      # http://www.interactivebrokers.com/discus/messages/2/28477.html?1114646754
      # [This message does not appear to exist anymore as of 4/07.]

      HISTORICAL_TYPES = [:trades, :midpoint, :bid, :ask]

      # Enumeration of bar size types for convenience. These are passed to TWS as the
      # (one-based!) index into the array.
      # Bar sizes less than 30 seconds do not work for some securities.
      BAR_SIZES = [:invalid, # zero is not a valid barsize
                   :second,
                   :five_seconds,
                   :fifteen_seconds,
                   :thirty_seconds,
                   :minute,
                   :two_minutes,
                   :five_minutes,
                   :fifteen_minutes,
                   :thirty_minutes,
                   :hour,
                   :day]

      class RequestHistoricalData < AbstractMessage
        @message_id = 20
        @version = 4

        def encode
          if @data.has_key?(:what_to_show) && @data[:what_to_show].is_a?(String)
            @data[:what_to_show] = @data[:what_to_show].downcase.to_sym
          end

          if @data.has_key?(:bar_size) && @data[:bar_size].is_a?(Symbol)
            @data[:bar_size] = BAR_SIZES[@data[:bar_size]]
          end

          raise ArgumentError("@data[:what_to_show] must be one of #{HISTORICAL_TYPES}.") unless HISTORICAL_TYPES.include?(@data[:what_to_show])
          raise ArgumentError("@data[:bar_size] must be one of #{BAR_SIZES}.") unless BAR_SIZES.include?(@data[:bar_size])

          contract = @data[:contract].is_a?(Datatypes::Contract) ?
              @data[:contract] : Datatypes::Contract.from_ib_ruby(@data[:contract])

          [super,
           @data[:ticker_id],
           contract.serialize,
           contract.include_expired,
           @data[:end_date_time],
           @data[:bar_size],
           @data[:duration],
           @data[:use_RTH],
           @data[:what_to_show].to_s.upcase,
           @data[:format_date],
           contract.serialize_combo_legs]
        end
      end # RequestHistoricalData

      #  data = { :tickerId => int,
      #           :contract => Contract ,
      #           :bar_size => int/Symbol,
      #           :what_to_show => String/Symbol,
      #           :use_RTH => bool }
      class RequestRealTimeBars < AbstractMessage
        @message_id = 50

        def encode
          if @data.has_key?(:what_to_show) && @data[:what_to_show].is_a?(String)
            @data[:what_to_show] = @data[:what_to_show].downcase.to_sym
          end

          if @data.has_key?(:bar_size) && @data[:bar_size].is_a?(Symbol)
            @data[:bar_size] = BAR_SIZES[@data[:bar_size]]
          end

          raise ArgumentError("@data[:what_to_show] must be one of #{HISTORICAL_TYPES}.") unless HISTORICAL_TYPES.include?(@data[:what_to_show])
          raise ArgumentError("@data[:bar_size] must be one of #{BAR_SIZES}.") unless BAR_SIZES.include?(@data[:bar_size])

          contract = @data[:contract].is_a?(Datatypes::Contract) ?
              @data[:contract] : Datatypes::Contract.from_ib_ruby(@data[:contract])

          [super,
           @data[:ticker_id],
           contract.serialize,
           @data[:bar_size],
           @data[:what_to_show].to_s.upcase,
           @data[:use_RTH]]
        end
      end # RequestRealTimeBars

      # data => { :req_id => int, :contract => Contract }
      class RequestContractData < AbstractMessage
        @message_id = 9
        @version = 6

        def encode
          [super,
           @data[:req_id],
           @data[:contract].con_id, # part of serialize?
           @data[:contract].serialize(:short),
           @data[:contract].include_expired,
           @data[:contract].sec_id_type,
           @data[:contract].sec_id]
        end
      end # RequestContractData
      RequestContractDetails = RequestContractData # alias

      # data = { :ticker_id => int, :contract => Contract, :num_rows => int }
      class RequestMarketDepth < AbstractMessage
        @message_id = 10
        @version = 3

        def encode
          [super,
           @data[:ticker_id],
           @data[:contract].serialize(:short),
           @data[:num_rows]]
        end
      end # RequestMarketDepth

      # data = { :ticker_id => int,
      #          :contract => Contract,
      #          :exercise_action => int,
      #          :exercise_quantity => int,
      #          :account => string,
      #          :override => int } ## override? override what?
      class ExerciseOptions < AbstractMessage
        @message_id = 21

        def encode
          [super,
           @data[:ticker_id],
           @data[:contract].serialize(:short),
           @data[:exercise_action],
           @data[:exercise_quantity],
           @data[:account],
           @data[:override]]
        end
      end # ExerciseOptions

      # Data format is { :order_id => int, :contract => Contract, :order => Order }
      class PlaceOrder < AbstractMessage
        @message_id = 3
        @version = 31
        # int VERSION = (m_serverVersion < MIN_SERVER_VER_NOT_HELD) ? 27 : 31;

        def encode
          [super,
           @data[:order_id],
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

      # Data is { :subscribe => boolean, :account_code => string }
      #
      # :account_code is only necessary for advisor accounts. Set it to
      # empty ('') for a standard account.
      #
      class RequestAccountData < AbstractMessage
        @message_id = 6
        @version = 2

        def encode
          [super,
           @data[:subscribe],
           @data[:account_code]] # \\ '' TODO: Get rid of StringentHash
        end
      end # RequestAccountData
      RequestAccountUpdates = RequestAccountData

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

      class RequestOpenOrders < AbstractMessage # TODO: ShortMessage ?
        @message_id = 5
      end # RequestOpenOrders

      # data = { :number_of_ids => int }
      class RequestIds < AbstractMessage # TODO: ShortMessage ?
        @message_id = 8

        def encode
          super << @data[:number_of_ids]
        end
      end # RequestIds

      # data = { :all_messages => boolean }
      class RequestNewsBulletins < AbstractMessage
        @message_id = 12

        def encode
          super << @data[:all_messages]
        end
      end # RequestNewsBulletins

      class CancelNewsBulletins < AbstractMessage # TODO: ShortMessage ?
        @message_id = 13
      end # CancelNewsBulletins

      # data = { :log_level => int }
      class SetServerLoglevel < AbstractMessage # TODO: ShortMessage ?
        @message_id = 14

        def encode
          super << @data[:log_level]
        end
      end # SetServerLoglevel

      # data = { :auto_bind => boolean }
      class RequestAutoOpenOrders < AbstractMessage # TODO: ShortMessage ?
        @message_id = 15

        def encode
          super << @data[:auto_bind]
        end
      end # RequestAutoOpenOrders


      class RequestAllOpenOrders < AbstractMessage # TODO: ShortMessage ?
        @message_id = 16
      end # RequestAllOpenOrders

      class RequestManagedAccounts < AbstractMessage # TODO: ShortMessage ?
        @message_id = 17
      end # RequestManagedAccounts

      # No idea what this is.
      # data = { :fa_data_type => int }
      class RequestFA < AbstractMessage # TODO: ShortMessage ?
        @message_id = 18

        def encode
          super << @data[:fa_data_type]
        end
      end # RequestFA

      # No idea what this is.
      # data = { :fa_data_type => int, :xml => string }
      class ReplaceFA < AbstractMessage
        @message_id = 19

        def encode
          [super,
           @data[:fa_data_type],
           @data[:xml]]
        end
      end # ReplaceFA

      class RequestCurrentTime < AbstractMessage # TODO: ShortMessage ?
        @message_id = 49
      end

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
  OutgoingMessages = Messages::Outgoing # Legacy alias

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
