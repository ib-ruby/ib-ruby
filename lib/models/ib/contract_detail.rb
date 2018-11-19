module IB

  # Additional Contract properties (volatile, therefore extracted)
  class ContractDetail < IB::Model
    include BaseProperties

    # All fields Strings, unless specified otherwise:
    prop :market_name, # The market name for this contract.
      :trading_class, # The trading class name for this contract.
      :min_tick, # double: The minimum price tick.
      :price_magnifier, # int: Allows execution and strike prices to be reported
      #                 consistently with market data, historical data and the
      #                 order price: Z on LIFFE is reported in index points, not GBP.

      :order_types, #       The list of valid order types for this contract.
      :valid_exchanges, #   The list of exchanges this contract is traded on.
      :under_con_id, # int: The underlying contract ID.
      :long_name, #         Descriptive name of the asset.
      :contract_month, #    The contract month of the underlying futures contract.

			:agg_group,
			:under_symbol,
			:under_sec_type,
			:market_rule_ids,
			:real_expiration_date,


      # For Bonds only
      :valid_next_option_date,
      :valid_next_option_type,
      :valid_next_option_partial,

      # The industry classification of the underlying/product:
      :industry, #    Wide industry. For example, Financial.
      :category, #    Industry category. For example, InvestmentSvc.
      :subcategory, # Subcategory. For example, Brokerage.
      [:time_zone, :time_zone_id], # Time zone for the trading hours (e.g. EST)
      :trading_hours, # The trading hours of the product. For example:
      #                 20090507:0700-1830,1830-2330;20090508:CLOSED.
      :liquid_hours, #  The liquid trading hours of the product. For example,
      #                 20090507:0930-1600;20090508:CLOSED.

      # To support products in Australia which trade in non-currency units, the following
      # attributes have been added to Execution and Contract Details objects:
      :ev_rule, # evRule - String contains the Economic Value Rule name and optional argument,
      #          separated by a colon. Examle: aussieBond:YearsToExpiration=3.
      #          When the optional argument not present, the value will be followed by a colon.
      [:ev_multiplier, :ev_multipler], # evMultiplier - double, tells you approximately
      #          how much the market value of a contract would change if the price were
      #          to change by 1. It cannot be used to get market value by multiplying
      #          the price by the approximate multiplier.

      :sec_id_list, # Array with multiple Security ids
      # MD Size Multiplier. Returns the size multiplier for values returned to tickSize from a market data request. Generally 100 for US stocks and 1 for other instruments.
      :md_size_multiplier,
#
      # BOND values:
      :cusip, # The nine-character bond CUSIP or the 12-character SEDOL.
      :ratings, # Credit rating of the issuer. Higher rating is less risky investment.
      #           Bond ratings are from Moody's and S&P respectively.
      :desc_append, # Additional descriptive information about the bond.
      :bond_type, #   The type of bond, such as "CORP."
      :coupon_type, # The type of bond coupon.
      :coupon, # double: The interest rate used to calculate the amount you
      #          will receive in interest payments over the year. default 0
      :maturity, # The date on which the issuer must repay bond face value
      :issue_date, # The date the bond was issued.
      :next_option_date, # only if bond has embedded options.
      :next_option_type, # only if bond has embedded options.
      :notes, # Additional notes, if populated for the bond in IB's database
      :callable => :bool, # Can be called by the issuer under certain conditions.
      :puttable => :bool, # Can be sold back to the issuer under certain conditions
      :convertible => :bool, # Can be converted to stock under certain conditions.
      :next_option_partial => :bool # # only if bond has embedded options.

      # Extra validations
      validates_format_of :time_zone, :with => /\A\w{3}\z/, :message => 'should be XXX'

    serialize :sec_id_list, Hash

    belongs_to :contract
    alias summary contract
    alias summary= contract=

    def default_attributes
      super.merge :coupon => 0.0,
        :under_con_id => 0,
        :min_tick => 0,
        :ev_multipler => 0,
        :sec_id_list => Hash.new,
        :callable => false,
        :puttable => false,
        :convertible => false,
        :next_option_partial => false
    end

		def to_human
			ret = "<ContractDetails  #{long_name}, market-name:#{market_name}, "
			ret << "category:#{category}, industry:#{industry} / #{subcategory}, " if category.present?
			ret << "underlying: con_id:#{under_con_id} , sec_type:#{under_sec_type}, symbol:#{under_symbol} " unless under_con_id.zero?
      ret << "ev_multiplier:#{ev_multiplier}, convertible:#{convertible}, cupon:#{coupon}, "
			ret << "md_size_multiplier:#{md_size_multiplier}, min_tick:#{min_tick}, next_option_partial:#{next_option_partial} "
			ret <<"price_magnifier:#{price_magnifier}, puttable:#{puttable}, sec_id-list:#{sec_id_list}, "
			ret <<"valid exchanges: #{ valid_exchanges}, order types: #{order_types} >"
		end

  end # class ContractDetail
end # module IB
