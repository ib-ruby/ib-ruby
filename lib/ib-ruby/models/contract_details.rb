require 'ib-ruby/models/model'

# TODO: Implement equals() according to the criteria in IB's Java client.

module IB::Models
  class ContractDetails < Model

    # All fields Strings, unless specified otherwise
    attr_accessor :summary, # Contract!
                  :market_name,
                  :trading_class,
                  :min_tick, # double
                  :price_magnifier, # int
                  :order_types,
                  :valid_exchanges,
                  :under_con_id, # int
                  :long_name,
                  :contract_month,
                  :industry,
                  :category,
                  :subcategory,
                  :time_zone,
                  :trading_hours,
                  :liquid_hours,

                  # Bond values:
                  :cusip,
                  :ratings,
                  :desc_append,
                  :bond_type,
                  :coupon_type,
                  :callable, # bool, default false
                  :puttable, # bool, default false
                  :coupon, # double, default 0
                  :convertible, # bool, default false
                  :maturity,
                  :issue_date,
                  :next_option_date,
                  :next_option_type,
                  :next_option_partial, # bool, default false
                  :notes;

    def initialize opts = {}
      @summary = Contract.new
      @under_con_id = 0
      @min_tick = 0
      @callable = false
      @puttable = false
      @coupon = 0
      @convertible = false
      @next_option_partial = false

      super opts
    end
  end # class ContractDetails
end

