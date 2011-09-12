require 'ib-ruby/models/model'

# TODO: Implement equals() according to the criteria in IB's Java client.

module IB::Models
  class Contract < Model

    # Valid security types (sec_type attribute)
    SECURITY_TYPES = {:stock => "STK",
                      :option => "OPT",
                      :future => "FUT",
                      :index => "IND",
                      :futures_option => "FOP",
                      :forex => "CASH",
                      :bag => "BAG"}

    # Fields are Strings unless noted otherwise
    attr_accessor :con_id, # int
                  :symbol,
                  :sec_type,
                  :expiry,
                  :strike, # double
                  :right,
                  :multiplier,
                  :exchange,
                  :currency,
                  :local_symbol,
                  :primary_exchange, # pick a non-aggregate (ie not the SMART) exchange
                  #                    that the contract trades on.  DO NOT SET TO SMART.
                  :include_expired, # can not be set to true for orders

                  :sec_id_type, #  CUSIP;SEDOL;ISIN;RIC
                  :sec_id,

                  # COMBOS
                  :combo_legs_description, # received in open order for all combos
                  :combo_legs, # public Vector m_comboLegs = new Vector()


                  :under_comp # public UnderComp m_underComp // delta neutral


    ## Bond values: WTF?! Where did it come from into original ib-ruby?
    #attr_accessor(:cusip, :ratings, :desc_append, :bond_type, :coupon_type, :callable,
    #              :puttable, :coupon, :convertible, :maturity, :issue_date)

    # NB :description field is entirely local to ib-ruby, and not part of TWS.
    # You can use it to store whatever arbitrary data you want.
    attr_accessor :description

    def initialize opts = {}
      # Assign defaults to properties first!
      @con_id = 0
      @strike = 0
      @sec_type = ''
      @include_expired = false
      @combo_legs = Array.new

      super opts
    end

    # some protective filters
    def primary_exchange=(x)
      x.upcase! if x.is_a?(String)

      # per http://chuckcaplan.com/twsapi/index.php/Class%20Contract
      raise(ArgumentError.new("Don't set primary_exchange to smart")) if x == "SMART"

      @primary_exchange = x
    end

    def right=(x)
      x.upcase! if x.is_a?(String)
      x = nil if !x.nil? && x.empty?
      raise(ArgumentError.new("Invalid right \"#{x}\" (must be one of PUT, CALL, P, C)")) unless x.nil? || ["PUT", "CALL", "P", "C", "0"].include?(x)
      @right = x
    end

    def expiry=(x)
      x = x.to_s
      if (x.nil? || !(x =~ /\d{6,8}/)) and !x.empty? then
        raise ArgumentError.new("Invalid expiry \"#{x}\" (must be in format YYYYMM or YYYYMMDD)")
      end
      @expiry = x
    end

    def sec_type=(x)
      x = nil if !x.nil? && x.empty?
      raise(ArgumentError.new("Invalid security type \"#{x}\" (see SECURITY_TYPES constant in Contract class for valid types)")) unless x.nil? || SECURITY_TYPES.values.include?(x)
      @sec_type = x
    end

    def reset
      @combo_legs = Array.new
      @strike = 0
    end

    # This returns an Array of data from the given contract, in standard format.
    # Different messages serialize contracts differently. Go figure.
    # Note that it does not include the combo legs.
    def serialize(type = :long)
      [self.symbol,
       self.sec_type,
       self.expiry,
       self.strike,
       self.right,
       self.multiplier,
       self.exchange] +
          (type == :long ? [self.primary_exchange] : []) +
          [self.currency,
           self.local_symbol]
    end

    # @Legacy
    def serialize_long(version)
      serialize(:long)
    end

    # @Legacy
    def serialize_short(version)
      serialize(:short)
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
    def serialize_ib_ruby(version)
      serialize.join(":")
    end

    # This returns a Contract initialized from the serialize_ib_ruby format string.
    def self.from_ib_ruby(string)
      c = Contract.new
      c.symbol, c.sec_type, c.expiry, c.strike, c.right, c.multiplier,
          c.exchange, c.primary_exchange, c.currency, c.local_symbol = string.split(":")
      c
    end

    def serialize_under_comp(*args)
      raise "Unimplemented"
      # EClientSocket.java, line 471:
      #if (m_serverVersion >= MIN_SERVER_VER_UNDER_COMP) {
      # 	   if (contract.m_underComp != null) {
      # 		   UnderComp underComp = contract.m_underComp;
      # 		   send( true);
      # 		   send( underComp.m_conId);
      # 		   send( underComp.m_delta);
      # 		   send( underComp.m_price);
      # 	   }
    end

    def serialize_algo(*args)
      raise "Unimplemented"
      #if (m_serverVersion >= MIN_SERVER_VER_ALGO_ORDERS) {
      #  send( order.m_algoStrategy);
      #  if( !IsEmpty(order.m_algoStrategy)) {
      #    java.util.Vector algoParams = order.m_algoParams;
      #    int algoParamsCount = algoParams == null ? 0 : algoParams.size();
      #    send( algoParamsCount);
      #    if( algoParamsCount > 0) {
      #      for( int i = 0; i < algoParamsCount; ++i) {
      #        TagValue tagValue = (TagValue)algoParams.get(i);
      #        send( tagValue.m_tag);
      #        send( tagValue.m_value);
      #      }
      #    }
      #  }
      #}
    end

    # Some messages send open_close too, some don't. WTF.
    def serialize_combo_legs(include_open_close = false)
      if self.combo_legs.nil?
        [0]
      else
        [self.combo_legs.size].concat(self.combo_legs.serialize(include_open_close))
      end
    end

    def to_human
      "<IB-Contract: " + [symbol, expiry, sec_type, strike, right, exchange, currency].join("-") + "}>"
    end

    def to_short
      "#{symbol}#{expiry}#{strike}#{right}#{exchange}#{currency}"
    end

    def to_s
      to_human
    end

  end # class Contract
end # module IB::Models
