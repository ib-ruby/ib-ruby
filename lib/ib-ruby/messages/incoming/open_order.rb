# OpenOrder is the longest message with complex processing logics, it is isolated here
module IB
  module Messages
    module Incoming

      OpenOrder =
          def_message [5, [23, 28]],
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
                      [:order, :limit_price, :decimal_max],
                      [:order, :aux_price, :decimal_max],
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
                      [:order, :percent_offset, :decimal_max],
                      [:order, :settling_firm, :string],
                      [:order, :short_sale_slot, :int],
                      [:order, :designated_location, :string],
                      [:order, :exempt_code, :int], # skipped in ver 51?
                      [:order, :auction_strategy, :int],
                      [:order, :starting_price, :decimal_max],
                      [:order, :stock_ref_price, :decimal_max],
                      [:order, :delta, :decimal_max],
                      [:order, :stock_range_lower, :decimal_max],
                      [:order, :stock_range_upper, :decimal_max],
                      [:order, :display_size, :int],
                      #@order.rth_only = @socket.read_boolean
                      [:order, :block_order, :boolean],
                      [:order, :sweep_to_fill, :boolean],
                      [:order, :all_or_none, :boolean],
                      [:order, :min_quantity, :int_max],
                      [:order, :oca_type, :int],
                      [:order, :etrade_only, :boolean],
                      [:order, :firm_quote_only, :boolean],
                      [:order, :nbbo_price_cap, :decimal_max],
                      [:order, :parent_id, :int],
                      [:order, :trigger_method, :int],
                      [:order, :volatility, :decimal_max],
                      [:order, :volatility_type, :int],
                      [:order, :delta_neutral_order_type, :string],
                      [:order, :delta_neutral_aux_price, :decimal_max]


      class OpenOrder

        # Returns loaded Array or [] if count was 0
        def load_array &block
          count = @socket.read_int
          count > 0 ? Array.new(count, &block) : []
        end

        # Returns loaded Hash
        def load_hash
          tags = load_array { |_| [@socket.read_read_string, @socket.read_read_string] }
          p tags
          tags.empty? ? Hash.new : Hash.new[*tags.flatten]
        end

        def load
          super

          # As of client v.52, we receive delta... params in openOrder
          if version >= 27 && !@data[:order][:delta_neutral_order_type].empty?
            load_map [:order, :delta_neutral_con_id, :int],
                     [:order, :delta_neutral_settling_firm, :string],
                     [:order, :delta_neutral_clearing_account, :string],
                     [:order, :delta_neutral_clearing_intent, :string]
          end

          load_map [:order, :continuous_update, :int],
                   [:order, :reference_price_type, :int],
                   [:order, :trail_stop_price, :decimal_max]

          # Never happens! 28 is the max supported version currently
          # As of client v.56, we receive trailing_percent in openOrder
          load_map [:order, :trailing_percent, :decimal_max] if version >= 30

          load_map [:order, :basis_points, :decimal_max],
                   [:order, :basis_points_type, :int_max],
                   [:contract, :legs_description, :string]

          # Never happens! 28 is the max supported version currently
          # As of client v.55, we receive orderComboLegs (price) in openOrder
          if version >= 29
            @data[:contract][:legs] = load_array do |_|
              Models::ComboLeg.new :con_id => @socket.read_int,
                                   :ratio => @socket.read_int,
                                   :action => @socket.read_string,
                                   :exchange => @socket.read_string,
                                   :open_close => @socket.read_int,
                                   :short_sale_slot => @socket.read_int,
                                   :designated_location => @socket.read_string,
                                   :exempt_code => @socket.read_int
            end

            # Order keeps received leg prices in a separate Array for some reason ?!
            @data[:order][:leg_prices] = load_array { |_| @socket.read_decimal_max }
          end

          # As of client v.51, we can receive smartComboRoutingParams in openOrder
          @data[:smart_combo_routing_params] = load_hash if version >= 26

          load_map [:order, :scale_init_level_size, :int_max],
                   [:order, :scale_subs_level_size, :int_max],
                   [:order, :scale_price_increment, :decimal_max]

          # As of client v.54, we can receive scale order fields
          if version >= 28 &&
              @data[:order][:scale_price_increment] &&
              @data[:order][:scale_price_increment] > 0

            load_map [:order, :scale_price_adjust_value, :decimal_max],
                     [:order, :scale_price_adjust_interval, :int_max],
                     [:order, :scale_profit_offset, :decimal_max],
                     [:order, :scale_auto_reset, :boolean],
                     [:order, :scale_init_position, :int_max],
                     [:order, :scale_init_position, :int_max],
                     [:order, :scale_init_fill_qty, :decimal_max],
                     [:order, :scale_random_percent, :boolean]
          end

          # As of client v.49/50, we can receive hedgeType, hedgeParam, optOutSmartRouting
          if version >= 25
            load_map [:order, :hedge_type, :string]
            unless @data[:order][:hedge_type].nil? || @data[:order][:hedge_type].empty?
              load_map [:order, :hedge_param, :string]
            end
            load_map [:order, :opt_out_smart_routing, :boolean]
          end

          load_map [:order, :clearing_account, :string],
                   [:order, :clearing_intent, :string],
                   [:order, :not_held, :boolean],
                   [:contract, :under_comp, :boolean]

          if @data[:contract][:under_comp]
            load_map [:contract, :under_con_id, :int],
                     [:contract, :under_delta, :decimal],
                     [:contract, :under_price, :decimal]
          end

          load_map [:order, :algo_strategy, :string]

          unless @data[:order][:algo_strategy].nil? || @data[:order][:algo_strategy].empty?
            @data[:order][:algo_params] = load_hash
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
