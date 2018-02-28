module IB
#  module UseOrder
    module  ForexLimit
      extend OrderPrototype
      class << self


      def defaults
	  super.merge order_type: :limit , tif: :day
      end


      def requirements
	super.merge cash_qty: '(true/false) to indicate to let IB calculate the cash-quantity of the alternate currency'
     end


      def summary
	<<-HERE
	Forex orders can be placed in denomination of second currency in pair using cashQty field.
	Don't specify a limit-price to force immidiate execution.
	HERE
      end
      end
=begin
2.5.0 :001 > f =  Symbols::Forex[:eurusd]
 => #<IB::Contract:0x0000000003299458 @attributes={"symbol"=>"EUR", "exchange"=>"IDEALPRO", "currency"=>"USD", "sec_type"=>"CASH", "created_at"=>2018-01-20 05:21:01 +0100, "updated_at"=>2018-01-20 05:21:01 +0100, "con_id"=>0, "right"=>"", "include_expired"=>false}, @description="EURUSD"> 

2.5.0 :002 > uf =  ForexLimit.order action: :buy, size: 15000, cash_qty: true
{:action=>:buy, :cash_qty=>true, :total_quantity=>15000}
 => #<IB::Order:0x0000000002f45a40 @attributes={"tif"=>"DAY", "order_type"=>"LMT", "side"=>"B", "cash_qty"=>true, "total_quantity"=>15000, "created_at"=>2018-01-20 05:21:06 +0100, "updated_at"=>2018-01-20 05:21:06 +0100, "active_start_time"=>"", "active_stop_time"=>"", "algo_strategy"=>"", "algo_id"=>"", "auction_strategy"=>0, "conditions"=>[], "continuous_update"=>0, "delta_neutral_designated_location"=>"", "delta_neutral_con_id"=>0, "delta_neutral_settling_firm"=>"", "delta_neutral_clearing_account"=>"", "delta_neutral_clearing_intent"=>"", "designated_location"=>"", "display_size"=>0, "discretionary_amount"=>0, "etrade_only"=>true, "exempt_code"=>-1, "ext_operator"=>"", "firm_quote_only"=>true, "not_held"=>false, "oca_type"=>0, "open_close"=>1, "opt_out_smart_routing"=>false, "origin"=>0, "outside_rth"=>false, "parent_id"=>0, "random_size"=>false, "random_price"=>false, "scale_auto_reset"=>false, "scale_random_percent"=>false, "scale_table"=>"", "short_sale_slot"=>0, "solicided"=>false, "transmit"=>true, "trigger_method"=>0, "what_if"=>false, "leg_prices"=>[], "algo_params"=>{}, "combo_params"=>[], "soft_dollar_tier_params"=>{"name"=>"", "val"=>"", "display_name"=>""}}, @order_states=[#<IB::OrderState:0x0000000002f44258 @attributes={"status"=>"New", "filled"=>0, "remaining"=>0, "price"=>0, "average_price"=>0, "created_at"=>2018-01-20 05:21:06 +0100, "updated_at"=>2018-01-20 05:21:06 +0100}>]> 
 2.5.0 :004 > C.place_order uf, f
 => 4 
 2.5.0 :005 > 05:21:23.606 Got message 4 (IB::Messages::Incoming::Alert)
 I, [2018-01-20T05:21:23.606819 #31020]  INFO -- : TWS Warning 10164: Traders are responsible for understanding cash quantity details, which are provided on a best efforts basis only.
 Restriction is specified in Precautionary Settings of Global Configuration/Presets.

=end
    end
end
