class AddIbComboLegs < ActiveRecord::Migration

  def change
    # ComboLeg objects represent individual security legs in a "BAG"
    create_table(:ib_combo_legs) do |t|
      t.references :combo
      t.references :leg_contract
      t.integer :con_id #  # int: The unique contract identifier specifying the security.
      t.string :side, :limit => 1 # Action/side: BUY/SELL/SSHORT/SSHORTX
      t.integer :ratio, :limit => 2 # int: Select the relative number of contracts for the leg you
      t.string :exchange # String: exchange to which the complete combo order will be routed.
      t.integer :exempt_code, :limit => 2 # int:
      t.integer :short_sale_slot, :limit => 2 # int: 0 - retail(default), 1 = clearing broker, 2 = third party
      t.integer :open_close, :limit => 2 #  SAME = 0; OPEN = 1; CLOSE = 2; UNKNOWN = 3
      t.string :designated_location # Otherwise leave blank or orders will be rejected.:status # String: Displays the order status.Possible values include:
      t.timestamps
    end
  end
end

__END__
rails generate scaffold combo_leg combo_id:integer leg_contract_id:integer con_id:integer 
 side:string ratio:integer exchange:string exempt_code:integer short_sale_slot:integer 
 open_close:integer designated_location:string 

