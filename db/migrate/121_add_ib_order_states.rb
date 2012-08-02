class AddIbOrderStates < ActiveRecord::Migration

  def change
    # OrderState represents dynamic (changeable) info about a single Order
    create_table(:ib_order_states) do |t|
      t.references :order
      t.integer :local_id #  int: Order id associated with client (volatile).
      t.integer :client_id # int: The id of the client that placed this order.
      t.integer :perm_id #   int: TWS permanent id, remains the same over TWS sessions.
      t.integer :parent_id # int: The order ID of the parent (original) order, used
      t.string :status # String: Displays the order status.Possible values include:
      t.integer :filled
      t.integer :remaining
      t.float :price #     double
      t.float :average_price #  double
      t.string :why_held # String: comma-separated list of reasons for order to be held.
      t.string :warning_text # String: Displays a warning message if warranted.
      t.string :commission_currency, :limit => 4 # String: Shows the currency of the commission.
      t.float :commission # double: Shows the commission amount on the order.
      t.float :min_commission # The possible min range of the actual order commission.
      t.float :max_commission # The possible max range of the actual order commission.
      t.float :init_margin # Float: The impact the order would have on your initial margin.
      t.float :maint_margin # Float: The impact the order would have on your maintenance margin.
      t.float :equity_with_loan # Float: The impact the order would have on your equity
      t.timestamps
    end
  end
end

__END__
rails generate scaffold order_state order_id:integer local_id:integer client_id:integer 
perm_id:integer parent_id:integer status:string filled:integer remaining:integer 
price:float average_price:float why_held:string warning_text:string
commission_currency:string commission:float min_commission:float max_commission:float 
init_margin:string maint_margin:float equity_with_loan:float

