# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# Note that this schema.rb definition is the authoritative source for your
# database schema. If you need to create the application database on another
# system, you should be using db:schema:load, not running all the migrations
# from scratch. The latter is a flawed and unsustainable approach (the more migrations
# you'll amass, the slower it'll run and the greater likelihood for issues).
#
# It's strongly recommended to check this file into your version control system.

ActiveRecord::Schema.define(:version => 171) do

  create_table "ib_bars", :force => true do |t|
    t.float    "open"
    t.float    "high"
    t.float    "low"
    t.float    "close"
    t.float    "wap"
    t.integer  "volume"
    t.integer  "trades"
    t.boolean  "has_gaps",   :limit => 1
    t.string   "time",       :limit => 18
    t.datetime "created_at",               :null => false
    t.datetime "updated_at",               :null => false
  end

  create_table "ib_combo_legs", :force => true do |t|
    t.integer  "combo_id"
    t.integer  "leg_contract_id"
    t.integer  "con_id"
    t.string   "side",                :limit => 1
    t.integer  "ratio",               :limit => 2
    t.string   "exchange"
    t.integer  "exempt_code",         :limit => 2
    t.integer  "short_sale_slot",     :limit => 2
    t.integer  "open_close",          :limit => 2
    t.string   "designated_location"
    t.datetime "created_at",                       :null => false
    t.datetime "updated_at",                       :null => false
  end

  create_table "ib_contract_details", :force => true do |t|
    t.integer  "contract_id"
    t.string   "market_name"
    t.string   "trading_class"
    t.float    "min_tick"
    t.integer  "price_magnifier"
    t.string   "order_types"
    t.string   "valid_exchanges"
    t.integer  "under_con_id"
    t.string   "long_name"
    t.string   "contract_month"
    t.string   "industry"
    t.string   "category"
    t.string   "subcategory"
    t.string   "time_zone"
    t.string   "trading_hours"
    t.string   "liquid_hours"
    t.string   "cusip"
    t.string   "ratings"
    t.string   "desc_append"
    t.string   "bond_type"
    t.string   "coupon_type"
    t.float    "coupon"
    t.string   "maturity"
    t.string   "issue_date"
    t.string   "next_option_date"
    t.string   "next_option_type"
    t.string   "notes"
    t.boolean  "callable",            :limit => 1
    t.boolean  "puttable",            :limit => 1
    t.boolean  "convertible",         :limit => 1
    t.boolean  "next_option_partial", :limit => 1
    t.datetime "created_at",                       :null => false
    t.datetime "updated_at",                       :null => false
  end

  create_table "ib_contracts", :force => true do |t|
    t.integer  "con_id"
    t.string   "sec_type",         :limit => 5
    t.float    "strike"
    t.string   "currency",         :limit => 4
    t.string   "sec_id_type",      :limit => 5
    t.integer  "sec_id"
    t.string   "legs_description"
    t.string   "symbol"
    t.string   "local_symbol"
    t.integer  "multiplier"
    t.string   "expiry"
    t.string   "exchange"
    t.string   "primary_exchange"
    t.boolean  "include_expired",  :limit => 1
    t.string   "right",            :limit => 1
    t.string   "type"
    t.datetime "created_at",                    :null => false
    t.datetime "updated_at",                    :null => false
  end

  create_table "ib_executions", :force => true do |t|
    t.integer  "order_id"
    t.integer  "local_id"
    t.integer  "client_id"
    t.integer  "perm_id"
    t.string   "order_ref"
    t.string   "exec_id"
    t.string   "side",                :limit => 1
    t.integer  "quantity"
    t.integer  "cumulative_quantity"
    t.float    "price"
    t.float    "average_price"
    t.string   "exchange"
    t.string   "account_name"
    t.boolean  "liquidation",         :limit => 1
    t.string   "time",                :limit => 18
    t.datetime "created_at",                        :null => false
    t.datetime "updated_at",                        :null => false
  end

  create_table "ib_order_states", :force => true do |t|
    t.integer  "order_id"
    t.integer  "local_id"
    t.integer  "client_id"
    t.integer  "perm_id"
    t.integer  "parent_id"
    t.string   "status"
    t.integer  "filled"
    t.integer  "remaining"
    t.float    "price"
    t.float    "average_price"
    t.string   "why_held"
    t.string   "warning_text"
    t.string   "commission_currency", :limit => 4
    t.float    "commission"
    t.float    "min_commission"
    t.float    "max_commission"
    t.float    "init_margin"
    t.float    "maint_margin"
    t.float    "equity_with_loan"
    t.datetime "created_at",                       :null => false
    t.datetime "updated_at",                       :null => false
  end

  create_table "ib_orders", :force => true do |t|
    t.integer  "contract_id"
    t.integer  "local_id"
    t.integer  "client_id"
    t.integer  "perm_id"
    t.integer  "parent_id"
    t.string   "order_ref"
    t.string   "order_type",                      :limit => 20
    t.string   "tif",                             :limit => 3
    t.string   "side",                            :limit => 1
    t.integer  "quantity"
    t.float    "limit_price"
    t.float    "aux_price"
    t.integer  "open_close"
    t.integer  "oca_type"
    t.string   "oca_group"
    t.boolean  "transmit",                        :limit => 1
    t.boolean  "what_if",                         :limit => 1
    t.boolean  "outside_rth",                     :limit => 1
    t.boolean  "not_held",                        :limit => 1
    t.boolean  "hidden",                          :limit => 1
    t.boolean  "block_order",                     :limit => 1
    t.boolean  "sweep_to_fill",                   :limit => 1
    t.boolean  "all_or_none",                     :limit => 1
    t.boolean  "etrade_only",                     :limit => 1
    t.boolean  "firm_quote_only",                 :limit => 1
    t.boolean  "opt_out_smart_routing",           :limit => 1
    t.boolean  "override_percentage_constraints", :limit => 1
    t.integer  "min_quantity"
    t.integer  "display_size"
    t.integer  "trigger_method"
    t.integer  "origin"
    t.string   "good_after_time"
    t.string   "good_till_date"
    t.string   "rule_80a"
    t.float    "percent_offset"
    t.float    "trail_stop_price"
    t.float    "trailing_percent"
    t.string   "fa_group"
    t.string   "fa_profile"
    t.string   "fa_method"
    t.string   "fa_percentage"
    t.integer  "short_sale_slot"
    t.string   "designated_location"
    t.integer  "exempt_code"
    t.string   "account"
    t.string   "settling_firm"
    t.string   "clearing_account"
    t.string   "clearing_intent"
    t.float    "discretionary_amount"
    t.float    "nbbo_price_cap"
    t.integer  "auction_strategy"
    t.float    "starting_price"
    t.float    "stock_ref_price"
    t.float    "delta"
    t.float    "stock_range_lower"
    t.float    "stock_range_upper"
    t.float    "volatility"
    t.integer  "volatility_type"
    t.integer  "reference_price_type"
    t.integer  "continuous_update"
    t.string   "delta_neutral_order_type"
    t.string   "delta_neutral_aux_price"
    t.integer  "delta_neutral_con_id"
    t.string   "delta_neutral_settling_firm"
    t.string   "delta_neutral_clearing_account"
    t.string   "delta_neutral_clearing_intent"
    t.string   "hedge_type"
    t.string   "hedge_param"
    t.float    "basis_points"
    t.float    "basis_points_type"
    t.string   "algo_strategy"
    t.text     "leg_prices"
    t.text     "algo_params"
    t.text     "combo_params"
    t.integer  "scale_init_level_size"
    t.integer  "scale_subs_level_size"
    t.float    "scale_price_increment"
    t.float    "scale_price_adjust_value"
    t.integer  "scale_price_adjust_interval"
    t.float    "scale_profit_offset"
    t.integer  "scale_init_position"
    t.integer  "scale_init_fill_qty"
    t.boolean  "scale_auto_reset",                :limit => 1
    t.boolean  "scale_random_percent",            :limit => 1
    t.datetime "placed_at"
    t.datetime "modified_at"
    t.datetime "created_at",                                    :null => false
    t.datetime "updated_at",                                    :null => false
  end

  create_table "ib_underlyings", :force => true do |t|
    t.integer  "contract_id"
    t.integer  "con_id"
    t.float    "delta"
    t.float    "price"
    t.datetime "created_at",  :null => false
    t.datetime "updated_at",  :null => false
  end

end
