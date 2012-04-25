module IB
  module Models

    # Additional Contract properties (volatile, therefore extracted)
    class ContractDetail < Model.for(:contract_detail)
      include ModelProperties

      belongs_to :contract
      alias summary contract
      alias summary= contract=

      # All fields Strings, unless specified otherwise:
      prop :market_name, # The market name for this contract.
           :trading_class, # The trading class name for this contract.
           :min_tick, # double: The minimum price tick.
           :price_magnifier, # int: Allows execution and strike prices to be
           #     reported consistently with market data, historical data and the
           #     order price: Z on LIFFE is reported in index points, not GBP.

           :order_types, #       The list of valid order types for this contract.
           :valid_exchanges, #   The list of exchanges this contract is traded on.
           :under_con_id, # int: The underlying contract ID.
           :long_name, #         Descriptive name of the asset.
           :contract_month, #    The contract month of the underlying futures contract.

           # The industry classification of the underlying/product:
           :industry, #    Wide industry. For example, Financial.
           :category, #    Industry category. For example, InvestmentSvc.
           :subcategory, # Subcategory. For example, Brokerage.
           [:time_zone, :time_zone_id], # Time zone for the trading hours (e.g. EST)
           :trading_hours, # The trading hours of the product. For example:
           #                 20090507:0700-1830,1830-2330;20090508:CLOSED.
           :liquid_hours, #  The liquid trading hours of the product. For example,
           #                 20090507:0930-1600;20090508:CLOSED.

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
      validates_format_of :time_zone, :with => /^\w{3}$/, :message => 'should be XXX'

      def default_attributes
        super.merge :coupon => 0.0,
                    :under_con_id => 0,
                    :min_tick => 0,
                    :callable => false,
                    :puttable => false,
                    :convertible => false,
                    :next_option_partial => false
      end

    end # class ContractDetail
  end # module Models
end # module IB
