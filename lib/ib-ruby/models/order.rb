require 'ib-ruby/models/model'

# TODO: Implement equals() according to the criteria in IB's Java client.

module IB::Models
  class Order < Model

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

    def initialize opts = {}
      # Assign defaults first!
      @outside_rth = false
      @open_close = "O"
      @origin = Origin_Customer
      @transmit = true
      @designated_location = ''
      @exempt_code = -1
      @delta_neutral_order_type = ''
      @what_if = false
      @not_held = false

      # TODO: Initialize with nil instead of Max_Value, or change
      #       Order sending code in IB::Messages::Outgoing::PlaceOrder
      #@min_quantity = Max_Value
      #@percent_offset = Max_Value # -"-
      #@nbbo_price_cap = Max_Value # -"-
      #@starting_price = Max_Value # -"-
      #@stock_ref_price = Max_Value # -"-
      #@delta = Max_Value
      #@stock_range_lower = Max_Value # -"-
      #@stock_range_upper = Max_Value # -"-
      #@volatility = Max_Value # -"-
      #@volatility_type = Max_Value # -"-
      #@delta_neutral_aux_price = Max_Value # -"-
      #@reference_price_type = Max_Value # -"-
      #@trail_stop_price = Max_Value # -"-
      #@basis_points = Max_Value # -"-
      #@basis_points_type = Max_Value # -"-
      #@scale_init_level_size = Max_Value # -"-
      #@scale_subs_level_size = Max_Value # -"-
      #@scale_price_increment = Max_Value # -"-
      #@reference_price_type = Max_Value # -"-
      #@reference_price_type = Max_Value # -"-
      #@reference_price_type = Max_Value # -"-
      #@reference_price_type = Max_Value # -"-

      super opts
    end

  end # class Order
end # module IB::Models
