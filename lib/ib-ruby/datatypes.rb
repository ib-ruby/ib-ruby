#
# Copyright (C) 2006 Blue Voodoo Magic LLC.
#
# This library is free software; you can redistribute it and/or modify
# it under the terms of the GNU Lesser General Public License as
# published by the Free Software Foundation; either version 2.1 of the
# License, or (at your option) any later version.
#
# This library is distributed in the hope that it will be useful, but
# WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU
# Lesser General Public License for more details.
#
# You should have received a copy of the GNU Lesser General Public
# License along with this library; if not, write to the Free Software
# Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA
# 02110-1301 USA
#

#
# TODO: Implement equals() according to the criteria in IB's Java client.
#

module IB

  module Datatypes
    attr_reader :created_at

    class AbstractDatum

      def init
        @created_at = Time.now
      end

      # If a hash is given, keys are taken as attribute names, values as data.
      # The attrs of the instance are set automatically from the attributeHash.
      #
      # If no hash is given, #init is called in the instance. #init
      # should set the datum up in a generic state.
      #
      def initialize(attributeHash=nil)
        if attributeHash.nil?
          init
        else
          raise ArgumentError.new("Argument must be a Hash") unless attributeHash.is_a?(Hash)
          attributeHash.keys.each { |key|
            self.send((key.to_s + "=").to_sym, attributeHash[key])
          }
        end
      end
    end # AbstractDatum


    # This is used within HistoricData messages.
    # Instantiate with a Hash of attributes, to be auto-set via initialize in AbstractDatum.
    class Bar < AbstractDatum
      attr_accessor :date, :open, :high, :low, :close, :volume, :wap, :has_gaps
      # :bar_count => @socket.read_int

      def to_s
        "<Bar: #{@date}; OHLC: #{@open.to_s}, #{@high.to_s}, #{@low.to_s}, #{@close.to_s}; volume: #{@volume}; wap: #{@wap.to_s}; has_gaps: #{@has_gaps}>"
      end
    end # Bar


    class Order < AbstractDatum
      # Constants used in Order objects. Drawn from Order.java
      Origin_Customer = 0
      Origin_Firm = 1

      Opt_Unknown = '?'
      Opt_Broker_Dealer = 'b'
      Opt_Customer = 'c'
      Opt_Firm = 'f'
      Opt_Isemm = 'm'
      Opt_Farmm = 'n'
      Opt_Specialist = 'y'

      OCA_Cancel_with_block = 1
      OCA_Reduce_with_block = 2
      OCA_Reduce_non_block = 3

      # Box orders consts:
      Box_Auction_Match = 1
      Box_Auction_Improvement = 2
      Box_Auction_Transparent = 3

      # Volatility orders consts:
      Volatility_Type_Daily = 1
      Volatility_Type_Annual = 2
      Volatility_Ref_Price_Average = 1
      Volatility_Ref_Price_BidOrAsk = 2

      # No idea why IB uses a large number as the default for some fields
      Max_Value = 99999999

      # Main order fields
      attr_accessor :id, #              int 		m_orderId; ?
                    :client_id, #       int
                    :perm_id, #         int
                    :action, #          String
                    :total_quantity, #  int
                    :order_type, #      String
                    :limit_price, #     double
                    :aux_price, #       double
                    #:shares_allocation, # deprecated sharesAllocation field

                    # Extended order fields
                    :tif, #         String: Time in Force - DAY, GTC, etc.
                    :oca_group, #   String: one cancels all group name
                    :oca_type, #    1 = CANCEL_WITH_BLOCK, 2 = REDUCE_WITH_BLOCK, 3 = REDUCE_NON_BLOCK
                    :order_ref, #   String
                    :transmit, #    bool:if false, order will be created but not transmitted.
                    :parent_id, #   int: Parent order id, to associate auto STP or TRAIL orders with the original order.
                    :block_order, #    bool
                    :sweep_to_fill, #  bool
                    :display_size, #   int
                    :trigger_method, # 0=Default, 1=Double_Bid_Ask, 2=Last, 3=Double_Last,
                    #                  4=Bid_Ask, 7=Last_or_Bid_Ask, 8=Mid-point
                    :outside_rth, #    bool: WAS ignore_rth
                    :hidden, #         bool
                    :good_after_time, # FORMAT: 20060505 08:00:00 {time zone}
                    :good_till_date, #  FORMAT: 20060505 08:00:00 {time zone}
                    :override_percentage_constraints, # bool
                    :rule_80a, # Individual = 'I', Agency = 'A', AgentOtherMember = 'W',
                    #            IndividualPTIA = 'J', AgencyPTIA = 'U', AgentOtherMemberPTIA = 'M',
                    #            IndividualPT = 'K', AgencyPT = 'Y', AgentOtherMemberPT = 'N'
                    :all_or_none, #      bool
                    :min_quantity, #     int
                    :percent_offset, #   double: REL orders only
                    :trail_stop_price, # double: for TRAILLIMIT orders only

                    # Financial advisors only, all Strings
                    :fa_group, :fa_profile, :fa_method, :fa_percentage,

                    # Institutional orders only
                    :open_close, #          String: O=Open, C=Close
                    :origin, #              int: 0=Customer, 1=Firm
                    :short_sale_slot, # 1 - you hold the shares, 2 - they will be delivered from elsewhere.  Only for Action="SSHORT
                    :designated_location, # String: set when slot==2 only
                    :exempt_code, #         int

                    # SMART routing only
                    :discretionary_amount, #  double
                    :etrade_only, #           bool
                    :firm_quote_only, #       bool
                    :nbbo_price_cap, #        double

                    # BOX or VOL ORDERS ONLY
                    :auction_strategy, # 1=AUCTION_MATCH, 2=AUCTION_IMPROVEMENT, 3=AUCTION_TRANSPARENT
                    :starting_price, #   double, BOX ORDERS ONLY
                    :stock_ref_price, #  double, BOX ORDERS ONLY
                    :delta, #            double, BOX ORDERS ONLY

                    # Pegged to stock or VOL orders
                    :stock_range_lower, #   double
                    :stock_range_upper, #   double

                    # VOLATILITY ORDERS ONLY
                    :volatility, #               double
                    :volatility_type, #          int: 1=daily, 2=annual
                    :continuous_update, #        int
                    :reference_price_type, #     int: 1=Average, 2 = BidOrAsk
                    :delta_neutral_order_type, # String
                    :delta_neutral_aux_price, #  double

                    # COMBO ORDERS ONLY
                    :basis_points, #      double: EFP orders only
                    :basis_points_type, # double: EFP orders only

                    # SCALE ORDERS ONLY
                    :scale_init_level_size, # int
                    :scale_subs_level_size, # int
                    :scale_price_increment, # double

                    #  Clearing info
                    :account, #          String: IB account
                    :settling_firm, #    String
                    :clearing_account, # String: True beneficiary of the order
                    :clearing_intent, #   "" (Default), "IB", "Away", "PTA" (PostTrade)

                    # ALGO ORDERS ONLY
                    :algo_strategy, # String
                    :algo_params, # public Vector<TagValue> m_algoParams; ?!

                    # WTF?!
                    :what_if, #public boolean  m_whatIf; // What-if
                    :not_held #public boolean  m_notHeld; // Not Held

      def init
        super

        @open_close = "0"
        @origin = Origin_Customer
        @transmit = true
        @primary_exchange = ''
        @designated_location = ''
        @min_quantity = Max_Value # TODO: Initialize with nil instead of Max_Value, or change
                                  # Order sending code in IB::Messages::Outgoing::PlaceOrder
        @percent_offset = Max_Value # -"-
        @nbba_price_cap = Max_Value # -"-
        @starting_price = Max_Value # -"-
        @stock_ref_price = Max_Value # -"-
        @delta = Max_Value
        @delta_neutral_order_type = ''
        @delta_neutral_aux_price = Max_Value # -"-
        @reference_price_type = Max_Value # -"-
      end # init

    end # class Order


    class Contract < AbstractDatum

      # Valid security types (sec_type attribute)
      SECURITY_TYPES =
          {
              :stock => "STK",
              :option => "OPT",
              :future => "FUT",
              :index => "IND",
              :futures_option => "FOP",
              :forex => "CASH",
              :bag => "BAG"
          }

      # note that the :description field is entirely local to ib-ruby, and not part of TWS.
      # You can use it to store whatever arbitrary data you want.
      attr_accessor :symbol, :strike, :multiplier, :exchange, :currency,
                    :local_symbol, :combo_legs, :description

      # Bond values
      attr_accessor(:cusip, :ratings, :desc_append, :bond_type, :coupon_type, :callable,
                    :puttable, :coupon, :convertible, :maturity, :issue_date)

      attr_reader :sec_type, :expiry, :right, :primary_exchange


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

      def init
        super

        @combo_legs = Array.new
        @strike = 0
        @sec_type = ''
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

    class ContractDetails < AbstractDatum
      attr_accessor :summary, :market_name, :trading_class, :con_id, :min_tick,
                    :multiplier, :price_magnifier, :order_types, :valid_exchanges

      def init
        super

        @summary = Contract.new
        @con_id = 0
        @min_tick = 0
      end
    end # class ContractDetails

    class Execution < AbstractDatum
      attr_accessor :order_id, :client_id, :exec_id, :time, :account_number, :exchange,
                    :side, :shares, :price, :perm_id, :liquidation

      def init
        super

        @order_id = 0
        @client_id = 0
        @shares = 0
        @price = 0
        @perm_id = 0
        @liquidation =0
      end
    end # Execution

    # From EClientSocket.java: Note that the valid format for m_time is "yyyymmdd-hh:mm:ss"
    class ExecutionFilter < AbstractDatum
      attr_accessor :client_id, :acct_code, :time, :symbol, :sec_type, :exchange, :side

      def init
        super

        @client_id = 0
      end

    end # ExecutionFilter


    class ComboLeg < AbstractDatum
      attr_accessor :con_id, :ratio, :action, :exchange, :open_close

      def init
        super

        @con_id = 0
        @ratio = 0
        @open_close = 0
      end

      # Some messages include open_close, some don't. wtf.
      def serialize(include_open_close = false)
        self.map { |leg|
          [leg.con_id,
           leg.ratio,
           leg.action,
           leg.exchange,
           (include_open_close ? leg.open_close : [])]
        }.flatten
      end
    end # ComboLeg


    class ScannerSubscription < AbstractDatum

      attr_accessor :number_of_rows, :instrument, :location_code, :scan_code, :above_price,
                    :below_price, :above_volume, :average_option_volume_above,
                    :market_cap_above, :market_cap_below, :moody_rating_above,
                    :moody_rating_below, :sp_rating_above, :sp_rating_below,
                    :maturity_date_above, :maturity_date_below, :coupon_rate_above,
                    :coupon_rate_below, :exclude_convertible, :scanner_setting_pairs,
                    :stock_type_filter

      def init
        super

        @coupon_rate_above = @coupon_rate_below = @market_cap_below = @market_cap_above =
            @average_option_volume_above = @above_volume = @below_price = @above_price = nil
        @number_of_rows = -1 # none specified, per ScannerSubscription.java
      end
    end # ScannerSubscription


    # Just like a Hash, but throws an exception if you try to access a key that doesn't exist.
    class StringentHash < Hash
      def initialize(hash)
        super() { |hash, key| raise Exception.new("key #{key.inspect} not found!") }
        self.merge!(hash) unless hash.nil?
      end
    end

  end # module Datatypes
  Models = Datatypes

end # module
