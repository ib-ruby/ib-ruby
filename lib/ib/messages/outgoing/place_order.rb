module IB
  module Messages
    module Outgoing

      # Data format is { :id => int: local_id,
      #                  :contract => Contract,
      #                  :order => Order }
      PlaceOrder = def_message [3, 45]

      class PlaceOrder

        def encode

          order = @data[:order]
          contract = @data[:contract]

         [super[0..-1],
#	  [ [3,45, @data[:local_id] ],
           contract.serialize_short(:primary_exchange, :sec_id_type),

           # main order fields
           (order.side == :short ? 'SSHORT' : order.side == :short_exempt ? 'SSHORTX' : order.side.to_sup),
#           order.quantity,
	   order.total_quantity,
           order[:order_type], # Internal code, 'LMT' instead of :limit
           order.limit_price || "",				      ## position in orderstring: 20
           order.aux_price || "",
           order[:tif],
           order.oca_group,
           order.account,
           order.open_close.to_sup[0],
           order[:origin],  # translates :customer, :firm  to 0,1
           order.order_ref,
           order.transmit,
           order.parent_id,
           order.block_order || false,
           order.sweep_to_fill || false,
           order.display_size,
           order[:trigger_method],
           order.outside_rth || false, # was: ignore_rth
           order.hidden || false,
           contract.serialize_legs(:extended),


           if contract.bag?
             [
               ## Support for per-leg prices in Order
               [contract.legs.size] + contract.legs.map { |_| nil },
               ## Support for combo routing params in Order
               order.combo_params.empty? ? 0 : [order.combo_params.size] + order.combo_params.to_a
	     ]
	        else      ### has to be checked!!
	          []    ### has to be checked!!
	  end,	      ### has to be checked!!
	     

           "", # deprecated shares_allocation field
           order.discretionary_amount,	      ## position in orderstring: 37
           order.good_after_time,
           order.good_till_date,
           [ order.fa_group,
           order.fa_method,
           order.fa_percentage,
           order.fa_profile ] ,
	   order.model_code || "",
           order[:short_sale_slot] || 0 , # 0 only for retail, 1 or 2 for institution  (Institutional)
           order.designated_location, # only populate when short_sale_slot == 2    (Institutional)
           order.exempt_code,
           order[:oca_type],
           order[:rule_80a], #.to_sup[0..0],
           order.settling_firm,
           order.all_or_none || false,
           order.min_quantity || "",
           order.percent_offset || '',
           order.etrade_only || false,
           order.firm_quote_only || false,
           order.nbbo_price_cap || "",
           order[:auction_strategy],
           order.starting_price,
           order.stock_ref_price || "",
           order.delta || "",
           order.stock_range_lower || "",
           order.stock_range_upper || "",
           order.override_percentage_constraints || false,
           order.volatility || "", #              Volatility orders
           order[:volatility_type] || "", #       Volatility orders

           # Support for delta neutral orders with parameters
           if order.delta_neutral_order_type && order.delta_neutral_order_type != :none
             [order[:delta_neutral_order_type],
              order.delta_neutral_aux_price || "",
              order.delta_neutral_con_id,
              order.delta_neutral_settling_firm,
              order.delta_neutral_clearing_account,
              order[:delta_neutral_clearing_intent]
              ]
           else
             ['', '']
           end,

           order.continuous_update, #        Volatility orders
           order[:reference_price_type] || "", #   Volatility orders

           order.trail_stop_price || "", #         TRAIL_STOP_LIMIT stop price
           order.trailing_percent || "", #         Support for trailing percent

           order.scale_init_level_size || "", #    Scale Orders
           order.scale_subs_level_size || "", #    Scale Orders
           order.scale_price_increment || "", #    Scale Orders

           # Support for extended scale orders parameters
           if order.scale_price_increment && order.scale_price_increment > 0
             [order.scale_price_adjust_value || "",
              order.scale_price_adjust_interval || "",
              order.scale_profit_offset || "",
              order.scale_auto_reset, #  default: false,
              order.scale_init_position || "",
              order.scale_init_fill_qty || "",
              order.scale_random_percent # default: false,
              ]
           else
             []
           end,

	      order.scale_table,		 # v 69
	      order.active_start_time || "" ,	 # v 69
	      order.active_stop_time || "" ,	 # v 69

           # Support for hedgeType
           order.hedge_type, # MIN_SERVER_VER_HEDGE_ORDERS
           order.hedge_param || [],

           order.opt_out_smart_routing, # MIN_SERVER_VER_OPT_OUT_SMART_ROUTING

           order.clearing_account ,
           order.clearing_intent ,
           order.not_held ,
           contract.serialize_under_comp,
           order.serialize_algo(),
           order.what_if,
	   order.serialize_misc_options,      # MIN_SERVER_VER_LINKING
	   order.solicided ,		      # MIN_SERVER_VER_ORDER_SOLICITED
	   order.random_size ,		      # MIN_SERVER_VER_RANDOMIZE_SIZE_AND_PRICE
	   order.random_price ,		      # MIN_SERVER_VER_RANDOMIZE_SIZE_AND_PRICE
				  ## pegged to Benchmark
	   			  ## WE DONT SUPPORT PEGGED TO BENCHMARK NOW - these fields are suppressed:
	   # referenceContractId
	   # isPeggedChangeAmountDecrease
	   # peggedChangeAmount
	   # referenceChangeAmount
	   # referenceExchangeId
	   #
	   order.conditions.size,  ##  todo:  include conditions-serialisation

	   order.adjusted_order_type ,
	   order.trigger_price ,
	   order.lmt_price_offset ,
	   order.adjusted_stop_price ,
	   order.adjusted_stop_limit_price ,
	   order.adjusted_trailing_amount ,
	   order.adjustable_trailing_unit ,


	   order.ext_operator ,		      # MIN_SERVER_VER_EXT_OPERATOR:
	   order.serialize_soft_dollar_tier() ,	      # MIN_SERVER_VER_SOFT_DOLLAR_TIER
	   order.cash_qty ]		      # MIN_SERVER_VER_CASH_QTY
	  

        end
      end # PlaceOrder


    end # module Outgoing
  end # module Messages
end # module IB
