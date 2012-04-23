class AddContracts < ActiveRecord::Migration

  def change
    create_table(:contracts) do |t|

      t.integer :con_id # int: The unique contract identifier.
      t.string :sec_type, :limit => 5 # Security type. Valid values are: SECURITY_TYPES
      t.float :strike # double: The strike price.
      t.string :currency, :limit => 4 # Only needed if there is an ambiguity e.g. when SMART exchange
      t.string :sec_id_type, :limit => 5 # Security identifier when querying contract details or
      t.integer :sec_id # Unique identifier of the given secIdType.
      t.string :legs_description # received in OpenOrder for all combos
      t.string :symbol # This is the symbol of the underlying asset.
      t.string :local_symbol # Local exchange symbol of the underlying asset
      t.integer :multiplier
      t.string :expiry # The expiration date. Use the format YYYYMM or YYYYMMDD
      t.string :exchange # The order destination such as Smart.
      t.string :primary_exchange # Non-SMART exchange where the contract trades.
      t.boolean :include_expired, :limit => 1 # When true contract details requests and historical
      t.string :right, :limit => 1 # Specifies a Put or Call. Valid input values are: P PUT C CALL

      t.string  :type # Contract Subclasses STI
      t.timestamps
    end
  end
end
