class AddIbContractDetails < ActiveRecord::Migration

  def change
    # ComboLeg objects represent individual security legs in a "BAG"
    create_table(:ib_contract_details) do |t|
      t.references :contract
      t.string :market_name # The market name for this contract.
      t.string :trading_class # The trading class name for this contract.
      t.float :min_tick # double: The minimum price tick.
      t.integer :price_magnifier # int: Z on LIFFE is reported in index points not GBP.
      t.string :order_types #       The list of valid order types for this contract.
      t.string :valid_exchanges #   The list of exchanges this contract is traded on.
      t.integer :under_con_id # int: The underlying contract ID.
      t.string :long_name #         Descriptive name of the asset.
      t.string :contract_month #    The contract month of the underlying futures contract.
      t.string :industry #    Wide industry. For example Financial.
      t.string :category #    Industry category. For example InvestmentSvc.
      t.string :subcategory # Subcategory. For example Brokerage.
      t.string :time_zone # Time zone for the trading hours (e.g. EST)
      t.string :trading_hours # The trading hours of the product. 20090507:0700-18301830-2330;20090508:CLOSED.
      t.string :liquid_hours #  The liquid trading hours of the product.
      t.string :cusip # The nine-character bond CUSIP or the 12-character SEDOL.
      t.string :ratings # Credit rating of the issuer. Higher rating is less risky investment.
      t.string :desc_append # Additional descriptive information about the bond.
      t.string :bond_type #   The type of bond such as "CORP"
      t.string :coupon_type # The type of bond coupon.
      t.float :coupon # double: The interest rate used to calculate the amount you
      t.string :maturity # The date on which the issuer must repay bond face value
      t.string :issue_date # The date the bond was issued.
      t.string :next_option_date # only if bond has embedded options.
      t.string :next_option_type # only if bond has embedded options.
      t.string :notes # Additional notes if populated for the bond in IB's database
      t.boolean :callable # Can be called by the issuer under certain conditions.
      t.boolean :puttable # Can be sold back to the issuer under certain conditions
      t.boolean :convertible # Can be converted to stock under certain conditions.
      t.boolean :next_option_partial # # only if bond has embedded options.
      t.string :valid_next_option_date # Bonds only
      t.string :valid_next_option_type # Bonds only
      t.string :valid_next_option_partial # Bonds only
      t.string :ev_rule # Australian non-currency products only
      t.float :ev_multiplier # Australian non-currency products only
      t.text :sec_id_list
      t.timestamps
    end
  end
end

__END__
rails generate scaffold contract_detail contract_id:integer market_name:string
 trading_class:string min_tick:float price_magnifier:integer order_types:string
 valid_exchanges:string under_con_id:integer long_name:string contract_month:string
 industry:string category:string subcategory:string time_zone:string trading_hours:string
 liquid_hours:string cusip:string ratings:string desc_append:string bond_type:string
 coupon_type:string coupon:float maturity:string issue_date:string next_option_date:string
 next_option_type:string notes:string callable:boolean puttable:boolean convertible:boolean
 next_option_partial:boolean valid_next_option_date:string valid_next_option_type:string
 valid_next_option_partial:string ev_rule:string ev_multiplier:float sec_id_list:text

