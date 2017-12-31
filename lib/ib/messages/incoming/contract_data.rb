module IB
  module Messages
    module Incoming
      module ContractAccessors

      end

      ContractDetails = ContractData =
        def_message([10, [6, 8]],
                    [:request_id, :int], # request id
                    [:contract, :symbol, :string],
                    [:contract, :sec_type, :string],
                    [:contract, :expiry, :string],
                    [:contract, :strike, :decimal],
                    [:contract, :right, :string],
                    [:contract, :exchange, :string],
                    [:contract, :currency, :string],
                    [:contract, :local_symbol, :string],
                    [:contract_detail, :market_name, :string], # extended
		    [:contract, :trading_class, :string],  # new Version 8

                    [:contract, :con_id, :int],
                    [:contract_detail, :min_tick, :decimal],
                    [:contract, :multiplier, :string],
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
                    [:sec_id_list_count, :int])
# additional Fields (from python -- are actually ignored (present in array, but thrown away)
#	516             if contract.secIdListCount > 0:
#	  517                 contract.secIdList = []
#	518                 for idxSecIdList in range(contract.secIdListCount):
#	  519                     tagValue = TagValue()
#	520                     tagValue.tag = decode(str, fields)
#	521                     tagValue.value = decode(str, fields)
#	522                     contract.secIdList.append(tagValue)
#	523 
#	524         if self.serverVersion >= MIN_SERVER_VER_AGG_GROUP:
#	  525             contract.aggGroup = decode(int, fields)
#	526 
#	527         if self.serverVersion >= MIN_SERVER_VER_UNDERLYING_INFO:
#	  528             contract.underSymbol = decode(str, fields)
#	529             contract.underSecType = decode(str, fields)
#	530 
#	531         if self.serverVersion >= MIN_SERVER_VER_MARKET_RULES:
#	  532             contract.marketRuleIds = decode(str, fields)
#	533 
#	534         if self.serverVersion >= MIN_SERVER_VER_REAL_EXPIRATION_DATE:
#	  535             contract.realExpirationDate = decode(str, fields)
#
#
      class ContractData

        def contract
          @contract = IB::Contract.build @data[:contract].
            merge(:contract_detail => contract_detail)
        end

        def contract_detail
          @contract_detail = IB::ContractDetail.new @data[:contract_detail]
        end

        alias contract_details contract_detail

        def load
          super

	  #  puts "!TTTTT!"
	  #  puts @data.inspect
          @data[:contract_detail][:sec_id_list] ||= HashWithIndifferentAccess.new
          @data[:sec_id_list_count].times do
            @data[:contract_detail][:sec_id_list][socket.read_string] = socket.read_string
#	    puts "!TTTTT!"
#	    puts @data.inspect
          end
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
