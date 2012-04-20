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

ActiveRecord::Schema.define(:version => 141) do

  create_table "bars", :force => true do |t|
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

  create_table "combo_legs", :force => true do |t|
    t.integer  "contract_id"
    t.integer  "con_id"
    t.integer  "ratio"
    t.string   "exchange"
    t.string   "side",                :limit => 1
    t.integer  "exempt_code"
    t.integer  "short_sale_slot"
    t.string   "designated_location"
    t.integer  "open_close"
    t.datetime "created_at",                       :null => false
    t.datetime "updated_at",                       :null => false
  end

  create_table "executions", :force => true do |t|
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

  create_table "order_states", :force => true do |t|
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
    t.float    "init_margin"
    t.float    "maint_margin"
    t.float    "equity_with_loan"
    t.float    "commission"
    t.float    "min_commission"
    t.float    "max_commission"
    t.string   "commission_currency", :limit => 4
    t.string   "why_held"
    t.string   "warning_text"
    t.datetime "created_at",                       :null => false
    t.datetime "updated_at",                       :null => false
  end

  create_table "orders", :force => true do |t|
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
    t.boolean  "transmit"
    t.boolean  "what_if"
    t.boolean  "outside_rth"
    t.boolean  "not_held"
    t.boolean  "hidden"
    t.boolean  "block_order"
    t.boolean  "sweep_to_fill"
    t.boolean  "all_or_none"
    t.boolean  "etrade_only"
    t.boolean  "firm_quote_only"
    t.boolean  "opt_out_smart_routing"
    t.boolean  "override_percentage_constraints"
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
    t.integer  "scale_init_level_size"
    t.integer  "scale_subs_level_size"
    t.float    "scale_price_increment"
    t.float    "scale_price_adjust_value"
    t.integer  "scale_price_adjust_interval"
    t.float    "scale_profit_offset"
    t.integer  "scale_init_position"
    t.integer  "scale_init_fill_qty"
    t.boolean  "scale_auto_reset"
    t.boolean  "scale_random_percent"
    t.datetime "placed_at"
    t.datetime "modified_at"
    t.datetime "created_at",                                    :null => false
    t.datetime "updated_at",                                    :null => false
  end

end
