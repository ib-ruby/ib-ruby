module IB
  module Messages
    module Incoming

      # OpenOrder is the longest message with complex processing logics
      OpenOrder =
          def_message [5, [23, 28]],
                      [:order, :local_id, :int],

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
                      [:shares_allocation, :string], # deprecated! field

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

        # Accessors to make OpenOrder API-compatible with OrderStatus message

        def local_id
          order.local_id
        end

        alias order_id local_id

        def status
          order.status
        end

        def order
          @order ||= IB::Order.new @data[:order].merge(:order_state => order_state)
        end

        def order_state
          @order_state ||= IB::OrderState.new(
              @data[:order_state].merge(
                  :local_id => @data[:order][:local_id],
                  :perm_id => @data[:order][:perm_id],
                  :parent_id => @data[:order][:parent_id],
                  :client_id => @data[:order][:client_id]))
        end

        def contract
          @contract ||= IB::Contract.build(
              @data[:contract].merge(:underlying => underlying)
          )
        end

        def underlying
          @underlying = @data[:underlying_present] ? IB::Underlying.new(@data[:underlying]) : nil
        end

        alias under_comp underlying

        def load
          super

          load_map [27, [proc { | | filled?(@data[:order][:delta_neutral_order_type]) },
                         # As of client v.52, we receive delta... params in openOrder
                         [:order, :delta_neutral_con_id, :int],
                         [:order, :delta_neutral_settling_firm, :string],
                         [:order, :delta_neutral_clearing_account, :string],
                         [:order, :delta_neutral_clearing_intent, :string]]
                   ],
                   [:order, :continuous_update, :int],
                   [:order, :reference_price_type, :int],
                   [:order, :trail_stop_price, :decimal_max],

                   # As of client v.56, we receive trailing_percent in openOrder
                   [30, [:order, :trailing_percent, :decimal_max]], # Never! 28 currently

                   [:order, :basis_points, :decimal_max],
                   [:order, :basis_points_type, :int_max],
                   [:contract, :legs_description, :string],

                   # Never happens! 28 is the max supported version currently
                   # As of client v.55, we receive orderComboLegs (price) in openOrder
                   [29, [:contract, :legs, :array, proc do |_|
                     IB::ComboLeg.new :con_id => socket.read_int,
                                      :ratio => socket.read_int,
                                      :action => socket.read_string,
                                      :exchange => socket.read_string,
                                      :open_close => socket.read_int,
                                      :short_sale_slot => socket.read_int,
                                      :designated_location => socket.read_string,
                                      :exempt_code => socket.read_int
                   end],

                    # Order keeps received leg prices in a separate Array for some reason ?!
                    [:order, :leg_prices, :array, proc { |_| socket.read_decimal_max }],
                   ],
                   # As of client v.51, we can receive smartComboRoutingParams in openOrder
                   [26, [:smart_combo_routing_params, :hash]],

                   [:order, :scale_init_level_size, :int_max],
                   [:order, :scale_subs_level_size, :int_max],
                   [:order, :scale_price_increment, :decimal_max],

                   # As of client v.54, we can receive scale order fields
                   [28, [proc { | | filled?(@data[:order][:scale_price_increment]) },
                         [:order, :scale_price_adjust_value, :decimal_max],
                         [:order, :scale_price_adjust_interval, :int_max],
                         [:order, :scale_profit_offset, :decimal_max],
                         [:order, :scale_auto_reset, :boolean],
                         [:order, :scale_init_position, :int_max],
                         [:order, :scale_init_fill_qty, :decimal_max],
                         [:order, :scale_random_percent, :boolean]]
                   ],

                   # As of client v.49/50, we can receive hedgeType, hedgeParam, optOutSmartRouting
                   [25,
                    [:order, :hedge_type, :string],
                    [proc { | | filled?(@data[:order][:hedge_type]) },
                     [:order, :hedge_param, :string],
                    ],
                    [:order, :opt_out_smart_routing, :boolean]
                   ],

                   [:order, :clearing_account, :string],
                   [:order, :clearing_intent, :string],
                   [:order, :not_held, :boolean],
                   [:underlying_present, :boolean],

                   [proc { | | filled?(@data[:underlying_present]) },
                    [:underlying, :con_id, :int],
                    [:underlying, :delta, :decimal],
                    [:underlying, :price, :decimal]
                   ],

                   [:order, :algo_strategy, :string],

                   # TODO: Test Order with algo_params, scale and legs!
                   [proc { | | filled?(@data[:order][:algo_strategy]) },
                    [:order, :algo_params, :hash]
                   ],

                   [:order, :what_if, :boolean],

                   [:order_state, :status, :string],
                   # IB uses weird String with Java Double.MAX_VALUE to indicate no value here
                   [:order_state, :init_margin, :decimal_max], # :string],
                   [:order_state, :maint_margin, :decimal_max], # :string],
                   [:order_state, :equity_with_loan, :decimal_max], # :string],
                   [:order_state, :commission, :decimal_max], # May be nil!
                   [:order_state, :min_commission, :decimal_max], # May be nil!
                   [:order_state, :max_commission, :decimal_max], # May be nil!
                   [:order_state, :commission_currency, :string],
                   [:order_state, :warning_text, :string]
        end

        # Check if given value was set by TWS to something vaguely "positive"
        def filled? value
          case value
            when String
              !value.empty?
            when Float, Integer
              value > 0
            else
              !!value # to_bool
          end
        end

        def to_human
          "<OpenOrder: #{contract.to_human} #{order.to_human}>"
        end

      end # class OpenOrder
    end # module Incoming
  end # module Messages
end # module IB
