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

ActiveRecord::Schema.define(:version => 121) do

  create_table "bars", :force => true do |t|
    t.string  "time",     :limit => 18
    t.float   "open"
    t.float   "high"
    t.float   "low"
    t.float   "close"
    t.float   "wap"
    t.integer "volume"
    t.integer "trades"
    t.boolean "has_gaps", :limit => 1
  end

  create_table "executions", :force => true do |t|
    t.integer "order_id"
    t.integer "client_id"
    t.integer "perm_id"
    t.string  "exec_id"
    t.string  "time",                :limit => 18
    t.string  "exchange"
    t.string  "order_ref"
    t.string  "account_name"
    t.float   "price"
    t.float   "average_price"
    t.integer "shares"
    t.integer "cumulative_quantity"
    t.boolean "liquidation",         :limit => 1
    t.string  "side",                :limit => 1
  end

  create_table "order_states", :force => true do |t|
    t.integer "order_id"
    t.integer "perm_id"
    t.integer "client_id"
    t.integer "parent_id"
    t.integer "filled"
    t.integer "remaining"
    t.float   "average_fill_price"
    t.float   "last_fill_price"
    t.string  "why_held"
    t.float   "init_margin"
    t.float   "maint_margin"
    t.float   "equity_with_loan"
    t.float   "commission"
    t.float   "min_commission"
    t.float   "max_commission"
    t.string  "commission_currency"
    t.string  "warning_text"
    t.string  "status"
  end

end
