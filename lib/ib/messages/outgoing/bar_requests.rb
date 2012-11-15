module IB
  module Messages
    module Outgoing

      # Messages that request bar data have special processing of @data

      class BarRequestMessage < AbstractMessage
        # Preprocessor for some data fields
        def parse data
          type = data[:data_type] || data[:what_to_show]
          data_type = DATA_TYPES.invert[type] || type
          unless  DATA_TYPES.keys.include?(data_type)
            error ":data_type must be one of #{DATA_TYPES.inspect}", :args
          end

          size = data[:bar_size] || data[:size]
          bar_size = BAR_SIZES.invert[size] || size
          unless  BAR_SIZES.keys.include?(bar_size)
            error ":bar_size must be one of #{BAR_SIZES.inspect}", :args
          end

          contract = data[:contract].is_a?(IB::Contract) ?
              data[:contract] : IB::Contract.from_ib_ruby(data[:contract])

          [data_type, bar_size, contract]
        end
      end

      #  data = { :id => ticker_id (int),
      #           :contract => Contract ,
      #           :bar_size => int/Symbol? Currently only 5 second bars are supported,
      #                        if any other value is used, an exception will be thrown.,
      #           :data_type => Symbol: Determines the nature of data being extracted.
      #                       :trades, :midpoint, :bid, :ask, :bid_ask,
      #                       :historical_volatility, :option_implied_volatility,
      #                       :option_volume, :option_open_interest
      #                       - converts to "TRADES," "MIDPOINT," "BID," etc...
      #          :use_rth => int: 0 - all data available during the time span requested
      #                     is returned, even data bars covering time intervals where the
      #                     market in question was illiquid. 1 - only data within the
      #                     "Regular Trading Hours" of the product in question is returned,
      #                     even if the time span requested falls partially or completely
      #                     outside of them.
      RequestRealTimeBars = def_message 50, BarRequestMessage

      class RequestRealTimeBars
        def encode
          data_type, bar_size, contract = parse @data

          [super,
           contract.serialize_long,
           bar_size,
           data_type.to_s.upcase,
           @data[:use_rth]]
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
      #                               2 - offset from 1970-01-01 in sec (UNIX epoch)
      #         }
      #
      # NB: using the D :duration only returns bars in whole days, so requesting "1 D"
      # for contract ending at 08:05 will only return 1 bar, for 08:00 on that day.
      # But requesting "86400 S" gives 86400/barlengthsecs bars before the end Time.
      #
      # Note also that the :duration for any request must be such that the start Time is not
      # more than one year before the CURRENT-Time-less-one-day (not 1 year before the end
      # Time in the Request)
      #
      # Bar Size Max Duration
      # -------- ------------
      # 1 sec        2000 S
      # 5 sec       10000 S
      # 15 sec      30000 S
      # 30 sec      86400 S
      # 1 minute    86400 S, 6 D
      # 2 minutes   86400 S, 6 D
      # 5 minutes   86400 S, 6 D
      # 15 minutes  86400 S, 6 D, 20 D, 2 W
      # 30 minutes  86400 S, 34 D, 4 W, 1 M
      # 1 hour      86400 S, 34 D, 4 w, 1 M
      # 1 day       60 D, 12 M, 52 W, 1 Y
      #
      # NB: as of 4/07 there is no historical data available for forex spot.
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
      RequestHistoricalData = def_message [20, 4], BarRequestMessage

      class RequestHistoricalData
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
           contract.serialize_legs]
        end
      end # RequestHistoricalData

    end # module Outgoing
  end # module Messages
end # module IB
