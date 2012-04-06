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

ActiveRecord::Schema.define(:version => 101) do

  create_table "executions", :force => true do |t|
    t.integer "order_id"
    t.integer "client_id"
    t.integer "perm_id"
    t.string  "exec_id"
    t.string  "time"
    t.string  "exchange"
    t.string  "order_ref"
    t.string  "account_name"
    t.float   "price"
    t.float   "average_price"
    t.integer "shares"
    t.integer "cumulative_quantity"
    t.integer "liquidation"
    t.string  "side"
  end

end
