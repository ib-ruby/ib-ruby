module IB
  module Models
    module Contracts
      class Contract < Model

        # This returns a Contract initialized from the serialize_ib_ruby format string.
        def self.build opts = {}
          Contracts::TYPES[opts[:sec_type]].new opts
        end

        # This returns a Contract initialized from the serialize_ib_ruby format string.
        def self.from_ib_ruby string
          keys = [:symbol, :sec_type, :expiry, :strike, :right, :multiplier,
                  :exchange, :primary_exchange, :currency, :local_symbol]
          props = Hash[keys.zip(string.split(":"))]
          props.delete_if { |k, v| v.nil? || v.empty? }
          Contract.new props
        end

        # Fields are Strings unless noted otherwise
        prop :con_id, # int: The unique contract identifier.
             :symbol, # This is the symbol of the underlying asset.
             :sec_type, # Security type. Valid values are: SECURITY_TYPES
             :strike, # double: The strike price.
             :exchange, # The order destination, such as Smart.
             :currency, # Only needed if there is an ambiguity, e.g. when SMART exchange
             #            and IBM is being requested (IBM can trade in GBP or USD).

             :local_symbol, # Local exchange symbol of the underlying asset
             :include_expired, # When true, contract details requests and historical
             #         data queries can be performed pertaining to expired contracts.
             #         Note: Historical data queries on expired contracts are
             #         limited to the last year of the contracts life, and are
             #         only supported for expired futures contracts.
             #         This field can NOT be set to true for orders.

             :sec_id_type, # Security identifier, when querying contract details or
             #               when placing orders. Supported identifiers are:
             #               -  ISIN (Example: Apple: US0378331005)
             #               -  CUSIP (Example: Apple: 037833100)
             #               -  SEDOL (6-AN + check digit. Example: BAE: 0263494)
             #               -  RIC (exchange-independent RIC Root and exchange-
             #                  identifying suffix. Ex: AAPL.O for Apple on NASDAQ.)
             :sec_id, # Unique identifier of the given secIdType.

             # COMBOS
             :legs_description, # received in OpenOrder for all combos

             :multiplier => :i,
             # Future/option contract multiplier (only needed when multiple possibilities exist)

             :primary_exchange =>
                 # non-aggregate (ie not the SMART) exchange that the contract trades on.
                 proc { |val|
                   val.upcase! if val.is_a?(String)
                   error "Don't set primary_exchange to smart", :args if val == 'SMART'
                   self[:primary_exchange] = val
                 },

             :right => # Specifies a Put or Call. Valid input values are: P, PUT, C, CALL
                 proc { |val|
                   self[:right] =
                       case val.to_s.upcase
                         when '', '0', '?'
                           nil
                         when 'PUT', 'P'
                           'PUT'
                         when 'CALL', 'C'
                           'CALL'
                         else
                           error "Right must be one of PUT, CALL, P, C - not '#{val}'", :args
                       end
                 },

             :expiry => # The expiration date. Use the format YYYYMM.
                 proc { |val|
                   self[:expiry] =
                       case val.to_s
                         when /\d{6,8}/
                           val.to_s
                         when nil, ''
                           nil
                         else
                           error "Invalid expiry '#{val}' (must be in format YYYYMM or YYYYMMDD)", :args
                       end
                 },

             :sec_type => # Security type. Valid values are: SECURITY_TYPES
                 proc { |val|
                   val = nil if !val.nil? && val.empty?
                   unless val.nil? || SECURITY_TYPES.values.include?(val)
                     error "Invalid security type '#{val}' (must be one of #{SECURITY_TYPES.values}", :args
                   end
                   self[:sec_type] = val
                 }

        # ContractDetails fields are bundled into Contract proper, as it should be
        # All fields Strings, unless specified otherwise:
        prop :market_name, # The market name for this contract.
             :trading_class, # The trading class name for this contract.
             :min_tick, # double: The minimum price tick.
             :price_magnifier, # int: Allows execution and strike prices to be
             #     reported consistently with market data, historical data and the
             #     order price: Z on LIFFE is reported in index points, not GBP.

             :order_types, #     The list of valid order types for this contract.
             :valid_exchanges, # The list of exchanges this contract is traded on.
             :under_con_id, # int: The underlying contract ID.
             :long_name, #         Descriptive name of the asset.
             :contract_month, # The contract month of the underlying for a futures contract.

             # The industry classification of the underlying/product:
             :industry, #    Wide industry. For example, Financial.
             :category, #    Industry category. For example, InvestmentSvc.
             :subcategory, # Subcategory. For example, Brokerage.
             :time_zone, # Time zone for the trading hours of the product. For example, EST.
             :trading_hours, # The trading hours of the product. For example:
             #                 20090507:0700-1830,1830-2330;20090508:CLOSED.
             :liquid_hours, #  The liquid trading hours of the product. For example,
             #                 20090507:0930-1600;20090508:CLOSED.

             # Bond values:
             :cusip, # The nine-character bond CUSIP or the 12-character SEDOL.
             :ratings, # Credit rating of the issuer. Higher rating is less risky investment.
             #           Bond ratings are from Moody's and S&P respectively.
             :desc_append, # Additional descriptive information about the bond.
             :bond_type, #   The type of bond, such as "CORP."
             :coupon_type, # The type of bond coupon.
             :callable, # bool: Can be called by the issuer under certain conditions.
             :puttable, # bool: Can be sold back to the issuer under certain conditions
             :coupon, # double: The interest rate used to calculate the amount you
             #          will receive in interest payments over the year. default 0
             :convertible, # bool: Can be converted to stock under certain conditions.
             :maturity, # The date on which the issuer must repay bond face value
             :issue_date, # The date the bond was issued.
             :next_option_date, # only if bond has embedded options.
             :next_option_type, # only if bond has embedded options.
             :next_option_partial, # bool: # only if bond has embedded options.
             :notes # Additional notes, if populated for the bond in IB's database

        # Used for Delta-Neutral Combo contracts only!
        # UnderComp fields are bundled into Contract proper, as it should be.
        prop :under_comp, # if not nil, attributes below are sent to server
             #:under_con_id is is already defined in ContractDetails section
             :under_delta, # double: The underlying stock or future delta.
             :under_price #  double: The price of the underlying.

        # Legs arriving via OpenOrder message, need to define them here
        attr_accessor :legs # leg definitions for this contract.
        alias combo_legs legs
        alias combo_legs= legs=
        alias combo_legs_description legs_description
        alias combo_legs_description= legs_description=

        attr_accessor :description # NB: local to ib-ruby, not part of TWS.

        DEFAULT_PROPS = {:con_id => 0,
                         :strike => 0,
                         :exchange => 'SMART',
                         :include_expired => false,

                         # These properties are from ContractDetails
                         :under_con_id => 0,
                         :min_tick => 0,
                         :callable => false,
                         :puttable => false,
                         :coupon => 0,
                         :convertible => false,
                         :next_option_partial => false, }

        # NB: ContractDetails reference - to self!
        def summary
          self
        end

        # This returns an Array of data from the given contract.
        # Different messages serialize contracts differently. Go figure.
        # Note that it does NOT include the combo legs.
        def serialize *fields
          [(fields.include?(:con_id) ? [con_id] : []),
           symbol,
           sec_type,
           (fields.include?(:option) ? [expiry, strike, right, multiplier] : []),
           exchange,
           (fields.include?(:primary_exchange) ? [primary_exchange] : []),
           currency,
           local_symbol,
           (fields.include?(:sec_id) ? [sec_id_type, sec_id] : []),
           (fields.include?(:include_expired) ? [include_expired] : []),
          ].flatten
        end

        def serialize_long *fields
          serialize :option, :primary_exchange, *fields
        end

        def serialize_short *fields
          serialize :option, *fields
        end

        # Serialize under_comp parameters
        def serialize_under_comp *args
          # EClientSocket.java, line 471:
          if under_comp
            [true,
             under_con_id,
             under_delta,
             under_price]
          else
            [false]
          end
        end

        # Redefined in BAG subclass
        def serialize_legs *fields
          []
        end

        # This produces a string uniquely identifying this contract, in the format used
        # for command line arguments in the IB-Ruby examples. The format is:
        #
        #    symbol:security_type:expiry:strike:right:multiplier:exchange:primary_exchange:currency:local_symbol
        #
        # Fields not needed for a particular security should be left blank
        # (e.g. strike and right are only relevant for options.)
        #
        # For example, to query the British pound futures contract trading on Globex
        # expiring in September, 2008, the string is:
        #
        #    GBP:FUT:200809:::62500:GLOBEX::USD:
        def serialize_ib_ruby
          serialize_long.join(":")
        end

        # Contract comparison
        def == other
          return false unless other.is_a?(self.class)

          # Different sec_id_type
          return false if sec_id_type && other.sec_id_type && sec_id_type != other.sec_id_type

          # Different sec_id
          return false if sec_id && other.sec_id && sec_id != other.sec_id

          # Different under_comp
          return false if under_comp && other.under_comp && under_comp != other.under_comp

          # Different symbols
          return false if symbol && other.symbol && symbol != other.symbol

          # Different currency
          return false if currency && other.currency && currency != other.currency

          # Same con_id for all Bags, but unknown for new Contracts...
          # 0 or nil con_id  matches any
          return false if con_id != 0 && other.con_id != 0 &&
              con_id && other.con_id && con_id != other.con_id

          # SMART or nil exchange matches any
          return false if exchange != 'SMART' && other.exchange != 'SMART' &&
              exchange && other.exchange && exchange != other.exchange

          # Comparison for Bonds and Options
          if sec_type == SECURITY_TYPES[:bond] || sec_type == SECURITY_TYPES[:option]
            return false if right != other.right || strike != other.strike
            return false if multiplier && other.multiplier && multiplier != other.multiplier
            return false if expiry[0..5] != other.expiry[0..5]
            return false unless expiry[6..7] == other.expiry[6..7] ||
                expiry[6..7].empty? || other.expiry[6..7].empty?
          end

          # All else being equal...
          sec_type == other.sec_type
        end

        def to_s
          "<Contract: " + instance_variables.map do |key|
            value = send(key[1..-1])
            " #{key}=#{value}" unless value.nil? || value == '' || value == 0
          end.compact.join(',') + " >"
        end

        def to_human
          "<Contract: " + [symbol, sec_type, expiry, strike, right, exchange, currency].join("-") + ">"
        end

        def to_short
          "#{symbol}#{expiry}#{strike}#{right}#{exchange}#{currency}"
        end

      end # class Contract
    end # module Contracts
  end # module Models
end # module IB
