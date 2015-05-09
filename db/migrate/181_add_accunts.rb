
class AddIbAccounts < ActiveRecord::Migration
def change
  create_table(:ib_accounts) do |t|
         t.integer  "lock_version",        limit: 4
         t.integer  "advisor_id",           limit: 4
         t.string   "type",                 limit: 25
         t.string   "account",              limit: 15,                 null: false
         t.string   "name",                 limit: 35
         t.boolean  "connected",            limit: 1,  default: false

    t.timestamps
  end
end
