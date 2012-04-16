module IB
  module Messages
    module Incoming

      ContractDetails = ContractData =
          def_message([10, 6],
                      [:request_id, :int], # request id
                      [:contract, :symbol, :string],
                      [:contract, :sec_type, :string],
                      [:contract, :expiry, :string],
                      [:contract, :strike, :decimal],
                      [:contract, :right, :string],
                      [:contract, :exchange, :string],
                      [:contract, :currency, :string],
                      [:contract, :local_symbol, :string],

                      [:contract, :market_name, :string], # extended
                      [:contract, :trading_class, :string],
                      [:contract, :con_id, :int],
                      [:contract, :min_tick, :decimal],
                      [:contract, :multiplier, :string],
                      [:contract, :order_types, :string],
                      [:contract, :valid_exchanges, :string],
                      [:contract, :price_magnifier, :int],
                      [:contract, :under_con_id, :int],
                      [:contract, :long_name, :string],
                      [:contract, :primary_exchange, :string],
                      [:contract, :contract_month, :string],
                      [:contract, :industry, :string],
                      [:contract, :category, :string],
                      [:contract, :subcategory, :string],
                      [:contract, :time_zone, :string],
                      [:contract, :trading_hours, :string],
                      [:contract, :liquid_hours, :string])

      class ContractData

        def contract
          @contract = IB::Contract.build @data[:contract]
        end
      end # ContractData

      BondContractData =
          def_message [18, 4],
                      [:request_id, :int],
                      [:contract, :symbol, :string],
                      [:contract, :sec_type, :string],
                      [:contract, :cusip, :string],
                      [:contract, :coupon, :decimal],
                      [:contract, :maturity, :string],
                      [:contract, :issue_date, :string],
                      [:contract, :ratings, :string],
                      [:contract, :bond_type, :string],
                      [:contract, :coupon_type, :string],
                      [:contract, :convertible, :boolean],
                      [:contract, :callable, :boolean],
                      [:contract, :puttable, :boolean],
                      [:contract, :desc_append, :string],
                      [:contract, :exchange, :string],
                      [:contract, :currency, :string],
                      [:contract, :market_name, :string], # extended
                      [:contract, :trading_class, :string],
                      [:contract, :con_id, :int],
                      [:contract, :min_tick, :decimal],
                      [:contract, :order_types, :string],
                      [:contract, :valid_exchanges, :string],
                      [:contract, :valid_next_option_date, :string],
                      [:contract, :valid_next_option_type, :string],
                      [:contract, :valid_next_option_partial, :string],
                      [:contract, :notes, :string],
                      [:contract, :long_name, :string]

      class BondContractData

        def contract
          @contract = IB::Contract.build @data[:contract]
        end
      end # BondContractData

    end # module Incoming
  end # module Messages
end # module IB
