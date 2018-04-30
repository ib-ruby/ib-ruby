module IB
  module Messages
    module Incoming
      module ContractAccessors

      end

      ContractDetails = ContractData =
        def_message([10, [6, 8]],
                    [:request_id, :int], # request id 
                    [:contract, :symbol, :string],								## next the major contract-fields
                    [:contract, :sec_type, :string],							## are transmitted
                    [:contract, :last_trading_day, :date],				## difference to the array.get_contract
                    [:contract, :strike, :decimal],								## method: con_id is transmitted
                    [:contract, :right, :string],									## AFTER the main fields
                    [:contract, :exchange, :string],							##
                    [:contract, :currency, :string],							## thus we have to read the fields separately
                    [:contract, :local_symbol, :string],
                    [:contract_detail, :market_name, :string], # extended
										[:contract, :trading_class, :string],  # new Version 8
                    [:contract, :con_id, :int],
                    [:contract_detail, :min_tick, :decimal],
                    [:contract_detail, :md_size_multiplier, :int],
                    [:contract, :multiplier, :int],
                    [:contract_detail, :order_types, :string],
                    [:contract_detail, :valid_exchanges, :string],
                    [:contract_detail, :price_magnifier, :int],
                    [:contract_detail, :under_con_id, :int],
                    [:contract_detail, :long_name, :string],
                    [:contract, :primary_exchange, :string],
                    [:contract_detail, :contract_month, :string],
                    [:contract_detail, :industry, :string],
                    [:contract_detail, :category, :string],
                    [:contract_detail, :subcategory, :string],
                    [:contract_detail, :time_zone, :string],
                    [:contract_detail, :trading_hours, :string],
                    [:contract_detail, :liquid_hours, :string],
                    [:contract_detail, :ev_rule, :decimal],
                    [:contract_detail, :ev_multipler, :string],
										[:contract_detail, :sec_id_list,:hash],
										[:contract_detail, :agg_group, :int ],
										[:contract_detail, :under_symbol, :string ],
										[:contract_detail, :under_sec_type, :string ],
										[:contract_detail, :market_rule_ids, :string ],
										[:contract_detail, :real_expiration_date, :date ]
									 )
#
#
      class ContractData
				using IBSupport   # defines tws-method for Array  (socket.rb)
        def contract
          @contract = IB::Contract.build @data[:contract].merge(:contract_detail => contract_detail)
        end

        def contract_detail
          @contract_detail = IB::ContractDetail.new @data[:contract_detail]
        end

        alias contract_details contract_detail

				def to_human
					"<Contract #{contract.to_human}   #{contract_detail.to_human}>"
				end

      end # ContractData

      BondContractData =
        def_message [18, [4, 6]], ContractData,
        [:request_id, :int],
        [:contract, :symbol, :string],
        [:contract, :sec_type, :string],
        [:contract_detail, :cusip, :string],
        [:contract_detail, :coupon, :decimal],
        [:contract_detail, :maturity, :string],
        [:contract_detail, :issue_date, :string],
        [:contract_detail, :ratings, :string],
        [:contract_detail, :bond_type, :string],
        [:contract_detail, :coupon_type, :string],
        [:contract_detail, :convertible, :boolean],
        [:contract_detail, :callable, :boolean],
        [:contract_detail, :puttable, :boolean],
        [:contract_detail, :desc_append, :string],
        [:contract, :exchange, :string],
        [:contract, :currency, :string],
        [:contract_detail, :market_name, :string], # extended
        [:contract_detail, :trading_class, :string],
        [:contract, :con_id, :int],
        [:contract_detail, :min_tick, :decimal],
        [:contract_detail, :order_types, :string],
        [:contract_detail, :valid_exchanges, :string],
        [:contract_detail, :valid_next_option_date, :string],
        [:contract_detail, :valid_next_option_type, :string],
        [:contract_detail, :valid_next_option_partial, :string],
        [:contract_detail, :notes, :string],
        [:contract_detail, :long_name, :string],
        [:contract_detail, :ev_rule, :decimal],
        [:contract_detail, :ev_multipler, :string],
        [:sec_id_list_count, :int]

    end # module Incoming
  end # module Messages
end # module IB
