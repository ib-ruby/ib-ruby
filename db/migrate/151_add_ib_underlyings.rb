class AddIbUnderlyings < ActiveRecord::Migration

  def change
    # Calculated characteristics of underlying Contract (volatile)
    create_table(:ib_underlyings) do |t|
      t.references :contract
      t.integer :con_id #  # int: The unique contract identifier specifying the security
      t.float :delta # double: The underlying stock or future delta
      t.float :price #  double: The price of the underlying
      t.timestamps
    end
  end
end

__END__
rails generate scaffold underlying contract_id:integer con_id:integer delta:float price:float 
