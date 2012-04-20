class AddComboLegs < ActiveRecord::Migration

  def change
    # ComboLeg objects represent individual security legs in a "BAG"
    create_table(:combo_legs) do |t|
      t.references :contract
      t.integer :con_id #  # int: The unique contract identifier specifying the security.
      t.integer :ratio # int: Select the relative number of contracts for the leg you
      t.string :exchange # String: exchange to which the complete combo order will be routed.
      t.string :side, :limit => 1 # Action/side: BUY/SELL/SSHORT/SSHORTX
      t.integer :exempt_code # int:
      t.integer :short_sale_slot # int: 0 - retail(default), 1 = clearing broker, 2 = third party
      t.string :designated_location # Otherwise leave blank or orders will be rejected.:status # String: Displays the order status.Possible values include:
      t.integer :open_close #  SAME = 0; OPEN = 1; CLOSE = 2; UNKNOWN = 3
      t.timestamps
    end
  end
end
