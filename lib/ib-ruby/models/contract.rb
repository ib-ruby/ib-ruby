require 'ib-ruby/models/contract_detail'

module IB
  module Models
    class Contract < Model.for(:contract)
      include ModelProperties

      has_one :contract_detail

      # Fields are Strings unless noted otherwise
      prop :con_id, # int: The unique contract identifier.
           :sec_type, # Security type. Valid values are: SECURITY_TYPES
           :strike, # double: The strike price.
           :currency, # Only needed if there is an ambiguity, e.g. when SMART exchange
           #            and IBM is being requested (IBM can trade in GBP or USD).

           :sec_id_type, # Security identifier, when querying contract details or
           #               when placing orders. Supported identifiers are:
           #               -  ISIN (Example: Apple: US0378331005)
           #               -  CUSIP (Example: Apple: 037833100)
           #               -  SEDOL (6-AN + check digit. Example: BAE: 0263494)
           #               -  RIC (exchange-independent RIC Root and exchange-
           #                  identifying suffix. Ex: AAPL.O for Apple on NASDAQ.)
           :sec_id, # Unique identifier of the given secIdType.

           :legs_description, # received in OpenOrder for all combos

           :symbol => :s, # This is the symbol of the underlying asset.

           :local_symbol => :s, # Local exchange symbol of the underlying asset

           # Future/option contract multiplier (only needed when multiple possibilities exist)
           :multiplier => :i,

           :expiry => :s, # The expiration date. Use the format YYYYMM or YYYYMMDD
           :exchange => :sup, # The order destination, such as Smart.
           :primary_exchange => :sup, # Non-SMART exchange where the contract trades.
           :include_expired => :bool, # When true, contract details requests and historical
           #         data queries can be performed pertaining to expired contracts.
           #         Note: Historical data queries on expired contracts are
           #         limited to the last year of the contracts life, and are
           #         only supported for expired futures contracts.
           #         This field can NOT be set to true for orders.


           # Specifies a Put or Call. Valid input values are: P, PUT, C, CALL
           :right =>
               {:set => proc { |val|
                 self[:right] =
                     case val.to_s.upcase
                     when 'NONE', '', '0', '?'
                       ''
                     when 'PUT', 'P'
                       'P'
                     when 'CALL', 'C'
                       'C'
                     else
                       val
                     end },
                :validate => {:format => {:with => /^put$|^call$|^none$/,
                                          :message => "should be put, call or none"}}
               }

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

      # Extra validations
      validates_inclusion_of :sec_type, :in => CODES[:sec_type].keys,
                             :message => "should be valid security type"

      validates_format_of :expiry, :with => /^\d{6}$|^\d{8}$|^$/,
                          :message => "should be YYYYMM or YYYYMMDD"

      validates_format_of :primary_exchange, :without => /SMART/,
                          :message => "should not be SMART"

      validates_numericality_of :multiplier, :allow_nil => true

      def default_attributes
        {:con_id => 0,
         :strike => 0.0,
         :right => :none, # Not an option
         :exchange => 'SMART',
         :include_expired => false, }.merge super
      end

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
         self[:sec_type],
         (fields.include?(:option) ?
             [expiry,
              strike,
              self[:right],
              multiplier] : []),
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

      # Defined in Contract, not BAG subclass to keep code DRY
      def serialize_legs *fields
        case
        when !bag?
          []
        when legs.empty?
          [0]
        else
          [legs.size, legs.map { |leg| leg.serialize *fields }].flatten
        end
      end

      # This produces a string uniquely identifying this contract, in the format used
      # for command line arguments in the IB-Ruby examples. The format is:
      #
      #    symbol:sec_type:expiry:strike:right:multiplier:exchange:primary_exchange:currency:local_symbol
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
        if bond? || option?
          return false if right != other.right || strike != other.strike
          return false if multiplier && other.multiplier && multiplier != other.multiplier
          return false if expiry && expiry[0..5] != other.expiry[0..5]
          return false unless expiry && (expiry[6..7] == other.expiry[6..7] ||
              expiry[6..7].empty? || other.expiry[6..7].empty?)
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
        "<Contract: " +
            [symbol,
             sec_type,
             (expiry == '' ? nil : expiry),
             (right == :none ? nil : right),
             (strike == 0 ? nil : strike),
             exchange,
             currency
            ].compact.join(" ") + ">"
      end

      def to_short
        "#{symbol}#{expiry}#{strike}#{right}#{exchange}#{currency}"
      end

      # Testing for type of contract:

      def bag?
        self[:sec_type] == 'BAG'
      end

      def bond?
        self[:sec_type] == 'BOND'
      end

      def stock?
        self[:sec_type] == 'STK'
      end

      def option?
        self[:sec_type] == 'OPT'
      end

    end # class Contract


    ## Now let's deal with Contract subclasses

    require 'ib-ruby/models/option'
    require 'ib-ruby/models/bag'

    class Contract
      # Specialized Contract subclasses representing different security types
      Subclasses = Hash.new(Contract)
      Subclasses[:bag] = IB::Models::Bag
      Subclasses[:option] = IB::Models::Option

      # This returns a Contract initialized from the serialize_ib_ruby format string.
      def self.build opts = {}
        Contract::Subclasses[VALUES[:sec_type][opts[:sec_type]]].new opts
      end

      # This returns a Contract initialized from the serialize_ib_ruby format string.
      def self.from_ib_ruby string
        keys = [:symbol, :sec_type, :expiry, :strike, :right, :multiplier,
                :exchange, :primary_exchange, :currency, :local_symbol]
        props = Hash[keys.zip(string.split(":"))]
        props.delete_if { |k, v| v.nil? || v.empty? }
        Contract.build props
      end
    end # class Contract
  end # module Models
end # module IB
