# OpenOrder is the longest message with complex processing logics, it is isolated here
module IB
  module Messages
    module Incoming

      OpenOrder =
          def_message [5, 23],
                      [:order, :order_id, :int],

                      [:contract, :con_id, :int],
                      [:contract, :symbol, :string],
                      [:contract, :sec_type, :string],
                      [:contract, :expiry, :string],
                      [:contract, :strike, :decimal],
                      [:contract, :right, :string],
                      [:contract, :exchange, :string],
                      [:contract, :currency, :string],
                      [:contract, :local_symbol, :string],

                      [:order, :action, :string],
                      [:order, :total_quantity, :int],
                      [:order, :order_type, :string],
                      [:order, :limit_price, :decimal],
                      [:order, :aux_price, :decimal],
                      [:order, :tif, :string],
                      [:order, :oca_group, :string],
                      [:order, :account, :string],
                      [:order, :open_close, :string],
                      [:order, :origin, :int],
                      [:order, :order_ref, :string],
                      [:order, :client_id, :int],
                      [:order, :perm_id, :int],
                      [:order, :outside_rth, :boolean], # (@socket.read_int == 1)
                      [:order, :hidden, :boolean], # (@socket.read_int == 1)
                      [:order, :discretionary_amount, :decimal],
                      [:order, :good_after_time, :string],
                      [:skip, :string], # skip deprecated sharesAllocation field

                      [:order, :fa_group, :string],
                      [:order, :fa_method, :string],
                      [:order, :fa_percentage, :string],
                      [:order, :fa_profile, :string],
                      [:order, :good_till_date, :string],
                      [:order, :rule_80a, :string],
                      [:order, :percent_offset, :decimal],
                      [:order, :settling_firm, :string],
                      [:order, :short_sale_slot, :int],
                      [:order, :designated_location, :string],
                      [:order, :exempt_code, :int], # skipped in ver 51?
                      [:order, :auction_strategy, :int],
                      [:order, :starting_price, :decimal],
                      [:order, :stock_ref_price, :decimal],
                      [:order, :delta, :decimal],
                      [:order, :stock_range_lower, :decimal],
                      [:order, :stock_range_upper, :decimal],
                      [:order, :display_size, :int],
                      #@order.rth_only = @socket.read_boolean
                      [:order, :block_order, :boolean],
                      [:order, :sweep_to_fill, :boolean],
                      [:order, :all_or_none, :boolean],
                      [:order, :min_quantity, :int],
                      [:order, :oca_type, :int],
                      [:order, :etrade_only, :boolean],
                      [:order, :firm_quote_only, :boolean],
                      [:order, :nbbo_price_cap, :decimal],
                      [:order, :parent_id, :int],
                      [:order, :trigger_method, :int],
                      [:order, :volatility, :decimal],
                      [:order, :volatility_type, :int],
                      [:order, :delta_neutral_order_type, :string],
                      [:order, :delta_neutral_aux_price, :decimal],

                      [:order, :continuous_update, :int],
                      [:order, :reference_price_type, :int],
                      [:order, :trail_stop_price, :decimal],
                      [:order, :basis_points, :decimal],
                      [:order, :basis_points_type, :int],
                      [:contract, :legs_description, :string],
                      [:order, :scale_init_level_size, :int_max],
                      [:order, :scale_subs_level_size, :int_max],
                      [:order, :scale_price_increment, :decimal_max],
                      [:order, :clearing_account, :string],
                      [:order, :clearing_intent, :string],
                      [:order, :not_held, :boolean] # (@socket.read_int == 1)

      class OpenOrder

        def load
          super

          load_map [:contract, :under_comp, :boolean] # (@socket.read_int == 1)

          if @data[:contract][:under_comp]
            load_map [:contract, :under_con_id, :int],
                     [:contract, :under_delta, :decimal],
                     [:contract, :under_price, :decimal]
          end

          load_map [:order, :algo_strategy, :string]

          unless @data[:order][:algo_strategy].nil? || @data[:order][:algo_strategy].empty?
            load_map [:algo_params_count, :int]
            if @data[:algo_params_count] > 0
              @data[:order][:algo_params] = Hash.new
              @data[:algo_params_count].times do
                tag = @socket.read_string
                value = @socket.read_string
                @data[:order][:algo_params][tag] = value
              end
            end
          end

          load_map [:order, :what_if, :boolean], # (@socket.read_int == 1)
                   [:order, :status, :string],
                   [:order, :init_margin, :string],
                   [:order, :maint_margin, :string],
                   [:order, :equity_with_loan, :string],
                   [:order, :commission, :decimal_max], # May be nil!
                   [:order, :min_commission, :decimal_max], # May be nil!
                   [:order, :max_commission, :decimal_max], # May be nil!
                   [:order, :commission_currency, :string],
                   [:order, :warning_text, :string]

          @order = Models::Order.new @data[:order]
          @contract = Models::Contract.build @data[:contract]
        end

        def to_human
          "<OpenOrder: #{@contract.to_human} #{@order.to_human}>"
        end

      end # class OpenOrder
    end # module Incoming
  end # module Messages
end # module IB
