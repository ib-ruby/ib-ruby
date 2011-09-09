# EClientSocket.java uses sendMax() rather than send() for a number of these.
# It sends an EOL rather than a number if the value == Integer.MAX_VALUE (or Double.MAX_VALUE).
# These fields are initialized to this MAX_VALUE.
# This has been implemented with nils in Ruby to represent the case where an EOL should be sent.

module IB
  module Messages
    module Outgoing

      EOL = "\0"
      BAG_SEC_TYPE = "BAG"

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
        # stuff gets sent to the server, or else define a method queue() that returns
        # an Array of elements that ought to be sent to the server by calling to_s on
        # each one and postpending a '\0'.
        #
        def send(server)
          self.queue(server).each { |datum|

            # TWS wants to receive booleans as 1 or 0... rewrite as necessary.
            datum = "1" if datum == true
            datum = "0" if datum == false

            server[:socket].syswrite(datum.to_s + "\0")
          }
        end

        # At minimum, Outgoing message contains message_id and version
        def queue(server)
          [self.class.message_id, self.class.version]
        end

        protected

        # TODO: Move this into protocol handshake phase
        #def requireVersion(server, version)
        #  raise(Exception.new("TWS version >= #{version} required.")) if server[:version] < version
        #end

        # TODO: Get rid of this, if possible
        # Returns EOL instead of datum if datum is nil, providing the same functionality
        # as sendMax() in the Java version, which uses Double.MAX_VALUE to mean "item not set"
        # in a variable, and replaces that with EOL on send.
        def nilFilter(datum)
          datum.nil? ? EOL : datum
        end
      end # AbstractMessage


      # Data format is { :ticker_id => int, :contract => Datatypes::Contract }
      #String genericTickList, boolean snapshot) {

      class RequestMarketData < AbstractMessage
        @message_id = 1
        @version = 5 # message version number

        def queue(server)
          queue = super + [@data[:ticker_id],
                           @data[:contract].serialize_long(server[:version])]


          # No idea what "BAG" means. Copied from the Java code.
          queue.concat(@data[:contract].serialize_combo_legs
          ) if server[:version] >= 8 && @data[:contract].sec_type == "BAG"

          queue
        end # queue
      end # RequestMarketData

      # Data format is { :ticker_id => int }
      class CancelMarketData < AbstractMessage
        def self.message_id
          2
        end

        def queue(server)
          [self.class.message_id,
           1, # message version number
           @data[:ticker_id]]
        end # queue
      end # CancelMarketData

      # Data format is { :order_id => int, :contract => Contract, :order => Order }
      class PlaceOrder < AbstractMessage
        def self.message_id
          3
        end

        def queue(server)
          queue = [self.class.message_id,
                   20, # version
                   @data[:order_id],
                   @data[:contract].symbol,
                   @data[:contract].sec_type,
                   @data[:contract].expiry,
                   @data[:contract].strike,
                   @data[:contract].right
          ]
          queue.push(@data[:contract].multiplier) if server[:version] >= 15
          queue.push(@data[:contract].exchange) if server[:version] >= 14
          queue.push(@data[:contract].currency)
          queue.push(@data[:contract].local_symbol) if server[:version] >= 2

          queue.concat([
                           @data[:order].tif,
                           @data[:order].oca_group,
                           @data[:order].account,
                           @data[:order].open_close,
                           @data[:order].origin,
                           @data[:order].order_ref,
                           @data[:order].transmit
                       ])

          queue.push(@data[:contract].parent_id) if server[:version] >= 4

          queue.concat([
                           @data[:order].block_order,
                           @data[:order].sweep_to_fill,
                           @data[:order].display_size,
                           @data[:order].trigger_method,
                           @data[:order].ignore_rth
                       ]) if server[:version] >= 5

          queue.push(@data[:order].hidden) if server[:version] >= 7


          queue.concat(@data[:contract].serialize_combo_legs(true)) if server[:version] >= 8 &&
              @data[:contract].sec_type.upcase == "BAG" # "BAG" is defined as a constant in EClientSocket.java, line 45

          queue.push(@data[:order].shares_allocation) if server[:version] >= 9 # EClientSocket.java says this is deprecated. No idea.
          queue.push(@data[:order].discretionary_amount) if server[:version] >= 10
          queue.push(@data[:order].good_after_time) if server[:version] >= 11
          queue.push(@data[:order].good_till_date) if server[:version] >= 12

          queue.concat([
                           @data[:order].fa_group,
                           @data[:order].fa_method,
                           @data[:order].fa_percentage,
                           @data[:order].fa_profile
                       ]) if server[:version] >= 13

          queue.concat([
                           @data[:order].short_sale_slot,
                           @data[:order].designated_location
                       ]) if server[:version] >= 18

          queue.concat([
                           @data[:order].oca_type,
                           @data[:order].rth_only,
                           @data[:order].rule_80a,
                           @data[:order].settling_firm,
                           @data[:order].all_or_none,
                           nilFilter(@data[:order].min_quantity),
                           nilFilter(@data[:order].percent_offset),
                           @data[:order].etrade_only,
                           @data[:order].firm_quote_only,
                           nilFilter(@data[:order].nbbo_price_cap),
                           nilFilter(@data[:order].auction_strategy),
                           nilFilter(@data[:order].starting_price),
                           nilFilter(@data[:order].stock_ref_price),
                           nilFilter(@data[:order].delta),

                           # Says the Java here:
                           # "// Volatility orders had specific watermark price attribs in server version 26"
                           # I have no idea what this means.

                           ((server[:version] == 26 && @data[:order].order_type.upcase == "VOL") ? EOL : @data[:order].stock_range_lower),
                           ((server[:version] == 26 && @data[:order].order_type.upcase == "VOL") ? EOL : @data[:order].stock_range_upper),

                       ]) if server[:version] >= 19

          queue.push(@data[:order].override_percentage_constraints) if server[:version] >= 22

          # Volatility orders
          if server[:version] >= 26
            queue.concat([nilFilter(@data[:order].volatility),
                          nilFilter(@data[:order].volatility_type)])

            if server[:version] < 28
              queue.push(@data[:order].delta_neutral_order_type.upcase == "MKT")
            else
              queue.concat([@data[:order].delta_neutral_order_type,
                            nilFilter(@data[:order].delta_neutral_aux_price)
                           ])
            end

            queue.push(@data[:order].continuous_update)
            queue.concat([
                             (@data[:order].order_type.upcase == "VOL" ? @data[:order].stock_range_lower : EOL),
                             (@data[:order].order_type.upcase == "VOL" ? @data[:order].stock_range_upper : EOL)
                         ]) if server[:version] == 26

            queue.push(@data[:order].reference_price_type)

          end # if version >= 26

          queue
        end # queue()

      end # PlaceOrder

      # Data format is { :id => id-to-cancel }
      class CancelOrder < AbstractMessage
        def self.message_id
          4
        end

        def queue(server)
          [
              self.class.message_id,
              1, # version
              @data[:id]
          ]
        end # queue
      end # CancelOrder

      class RequestOpenOrders < AbstractMessage
        def self.message_id
          5
        end

        def queue(server)
          [self.class.message_id,
           1 # version
          ]
        end
      end # RequestOpenOrders

      # Data is { :subscribe => boolean, :account_code => string }
      #
      # :account_code is only necessary for advisor accounts. Set it to
      # empty ('') for a standard account.
      #
      class RequestAccountData < AbstractMessage
        def self.message_id
          6
        end

        def queue(server)
          queue = [self.class.message_id,
                   2, # version
                   @data[:subscribe]
          ]
          queue.push(@data[:account_code]) if server[:version] >= 9
          queue
        end
      end # RequestAccountData


      # data = { :filter => ExecutionFilter ]
      class RequestExecutions < AbstractMessage
        def self.message_id
          7
        end

        def queue(server)
          queue = [self.class.message_id,
                   2 # version
          ]

          queue.concat([
                           @data[:filter].client_id,
                           @data[:filter].acct_code,

                           # The Java says: 'Note that the valid format for m_time is "yyyymmdd-hh:mm:ss"'
                           @data[:filter].time,
                           @data[:filter].symbol,
                           @data[:filter].sec_type,
                           @data[:filter].exchange,
                           @data[:filter].side
                       ]) if server[:version] >= 9

          queue
        end # queue
      end # RequestExecutions


      # data = { :number_of_ids => int }
      class RequestIds < AbstractMessage
        def self.message_id
          8
        end

        def queue(server)
          [self.class.message_id,
           1, # version
           @data[:number_of_ids]
          ]
        end
      end # RequestIds


      # data => { :contract => Contract }
      class RequestContractData < AbstractMessage
        def self.message_id
          9
        end

        def queue(server)
          requireVersion(server, 4)

          queue = [
              self.class.message_id,
              2, # version
              @data[:contract].symbol,
              @data[:contract].sec_type,
              @data[:contract].expiry,
              @data[:contract].strike,
              @data[:contract].right
          ]
          queue.push(@data[:contract].multiplier) if server[:version] >= 15

          queue.concat([
                           @data[:contract].exchange,
                           @data[:contract].currency,
                           @data[:contract].local_symbol,
                       ])

          queue
        end # send
      end # RequestContractData

      # data = { :ticker_id => int, :contract => Contract, :num_rows => int }
      class RequestMarketDepth < AbstractMessage
        def self.message_id
          10
        end

        def queue(server)
          requireVersion(server, 6)

          queue = [self.class.message_id,
                   3, # version
                   @data[:ticker_id]
          ]
          queue.concat(@data[:contract].serialize_short(server[:version]))
          queue.push(@data[:num_rows]) if server[:version] >= 19

          queue

        end # queue
      end # RequestMarketDepth

      # data = { :ticker_id => int }
      class CancelMarketDepth < AbstractMessage
        def self.message_id
          11
        end

        def queue(server)
          requireVersion(self, 6)

          [self.class.message_id,
           1, # version
           @data[:ticker_id]
          ]
        end
      end # CancelMarketDepth


      # data = { :all_messages => boolean }
      class RequestNewsBulletins < AbstractMessage
        def self.message_id
          12
        end

        def queue(server)
          [self.class.message_id,
           1, # version
           @data[:all_messages]
          ]
        end
      end # RequestNewsBulletins

      class CancelNewsBulletins < AbstractMessage
        def self.message_id
          13
        end

        def queue(server)
          [self.class.message_id,
           1 # version
          ]
        end
      end # CancelNewsBulletins

      # data = { :loglevel => int }
      class SetServerLoglevel < AbstractMessage
        def self.message_id
          14
        end

        def queue(server)
          [self.class.message_id,
           1, # version
           @data[:loglevel]
          ]
        end
      end # SetServerLoglevel

      # data = { :auto_bind => boolean }
      class RequestAutoOpenOrders < AbstractMessage
        def self.message_id
          15
        end

        def queue(server)
          [self.class.message_id,
           1, # version
           @data[:auto_bind]
          ]
        end
      end # RequestAutoOpenOrders


      class RequestAllOpenOrders < AbstractMessage
        def self.message_id
          16
        end

        def queue(server)
          [self.class.message_id,
           1 # version
          ]
        end
      end # RequestAllOpenOrders

      class RequestManagedAccounts < AbstractMessage
        def self.message_id
          17
        end

        def queue(server)
          [self.class.message_id,
           1 # version
          ]
        end
      end # RequestManagedAccounts

      # No idea what this is.
      # data = { :fa_data_type => int }
      class RequestFA < AbstractMessage
        def self.message_id
          18
        end

        def queue(server)
          requireVersion(server, 13)

          [self.class.message_id,
           1, # version
           @data[:fa_data_type]
          ]
        end
      end # RequestFA

      # No idea what this is.
      # data = { :fa_data_type => int, :xml => string }
      class ReplaceFA < AbstractMessage
        def self.message_id
          19
        end

        def queue(server)
          requireVersion(server, 13)

          [self.class.message_id,
           1, # version
           @data[:fa_data_type],
           @data[:xml]
          ]
        end
      end # ReplaceFA

      # data = { :ticker_id => int,
      #          :contract => Contract,
      #          :end_date_time => string,
      #          :duration => string, # this specifies an integer number of seconds
      #          :bar_size => int,
      #          :what_to_show => symbol, # one of :trades, :midpoint, :bid, or :ask
      #          :use_RTH => int,
      #          :format_date => int
      #        }
      #
      # Note that as of 4/07 there is no historical data available for forex spot.
      #
      # data[:contract] may either be a Contract object or a String. A String should be
      # in serialize_ib_ruby format; that is, it should be a colon-delimited string in
      # the format:
      #
      #    symbol:security_type:expiry:strike:right:multiplier:exchange:primary_exchange:currency:local_symbol
      #
      # Fields not needed for a particular security should be left blank (e.g. strike
      # and right are only relevant for options.)
      #
      # For example, to query the British pound futures contract trading on Globex expiring
      # in September, 2008, the correct string is:
      #
      #    GBP:FUT:200809:::62500:GLOBEX::USD:
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
      # :asked to be passed as data[:what_to_show].
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

      ALLOWED_HISTORICAL_TYPES = [:trades, :midpoint, :bid, :ask]

      class RequestHistoricalData < AbstractMessage
        # Enumeration of bar size types for convenience. These are passed to TWS as the (one-based!) index into the array.
        # Bar sizes less than 30 seconds do not work for some securities.
        BarSizes = [
            :invalid, # zero is not a valid barsize
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
            :day,
        ]


        def self.message_id
          20
        end

        def queue(server)
          requireVersion(server, 16)

          if @data.has_key?(:what_to_show) && @data[:what_to_show].is_a?(String)
            @data[:what_to_show].downcase!
            @data[:what_to_show] = @data[:what_to_show].to_sym
          end

          raise ArgumentError("RequestHistoricalData: @data[:what_to_show] must be one of #{ALLOWED_HISTORICAL_TYPES.inspect}.") unless ALLOWED_HISTORICAL_TYPES.include?(@data[:what_to_show])

          queue = [self.class.message_id,
                   3, # version
                   @data[:ticker_id]
          ]

          contract = @data[:contract].is_a?(Datatypes::Contract) ? @data[:contract] : Datatypes::Contract.from_ib_ruby(@data[:contract])
          queue.concat(contract.serialize_long(server[:version]))

          queue.concat([
                           @data[:end_date_time],
                           @data[:bar_size]
                       ]) if server[:version] > 20


          queue.concat([
                           @data[:duration],
                           @data[:use_RTH],
                           @data[:what_to_show].to_s.upcase
                       ])

          queue.push(@data[:format_date]) if server[:version] > 16

          if contract.sec_type.upcase == "BAG"
            queue.concat(contract.serialize_combo_legs)
          end

          queue
        end
      end # RequestHistoricalData

      # data = { :ticker_id => int,
      #          :contract => Contract,
      #          :exercise_action => int,
      #          :exercise_quantity => int,
      #          :account => string,
      #          :override => int } ## override? override what?
      class ExerciseOptions < AbstractMessage
        def self.message_id
          21
        end

        def queue(server)

          requireVersion(server, 21)

          q = [self.class.message_id,
               1, # version
               @data[:ticker_id]
          ]
          q.concat(@data[:contract].serialize_long(server[:version]))
          q.concat([
                       @data[:exercise_action],
                       @data[:exercise_quantity],
                       @data[:account],
                       @data[:override]
                   ])
          q
        end # queue
      end # ExerciseOptions

      # data = { :ticker_id => int,
      #          :scanner_subscription => ScannerSubscription
      #        }
      class RequestScannerSubscription < AbstractMessage
        def self.message_id
          22
        end

        def queue(server)
          requireVersion(server, 24)

          [
              self.class.message_id,
              3, # version
              @data[:ticker_id],
              @data[:subscription].number_of_rows,
              nilFilter(@data[:subscription].number_of_rows),
              @data[:subscription].instrument,
              @data[:subscription].location_code,
              @data[:subscription].scan_code,
              nilFilter(@data[:subscription].above_price),
              nilFilter(@data[:subscription].below_price),
              nilFilter(@data[:subscription].above_volume),
              nilFilter(@data[:subscription].market_cap_above),
              @data[:subscription].moody_rating_above,
              @data[:subscription].moody_rating_below,
              @data[:subscription].sp_rating_above,
              @data[:subscription].sp_rating_below,
              @data[:subscription].maturity_date_above,
              @data[:subscription].maturity_date_below,
              nilFilter(@data[:subscription].coupon_rate_above),
              nilFilter(@data[:subscription].coupon_rate_below),
              @data[:subscription].exclude_convertible,
              (server[:version] >= 25 ? [@data[:subscription].average_option_volume_above,
                                         @data[:subscription].scanner_setting_pairs] : []),

              (server[:version] >= 27 ? [@data[:subscription].stock_type_filter] : []),
          ].flatten

        end
      end # RequestScannerSubscription


      # data = { :ticker_id => int }
      class CancelScannerSubscription
        def self.message_id
          23
        end

        def queue(server)
          requireVersion(server, 24)
          [self.class.message_id,
           1, # version
           @data[:ticker_id]
          ]
        end
      end # CancelScannerSubscription


      class RequestScannerParameters
        def self.message_id
          24
        end

        def queue(server)
          requireVersion(server, 24)

          [self.class.message_id,
           1 # version
          ]
        end
      end # RequestScannerParameters


      # data = { :ticker_id => int }
      class CancelHistoricalData
        def self.message_id
          25
        end

        def queue(server)
          requireVersion(server, 24)
          [self.class.message_id,
           1, # version
           @data[:ticker_id]
          ]
        end
      end # CancelHistoricalData

    end # module Outgoing
  end # module Messages
end # module IB
