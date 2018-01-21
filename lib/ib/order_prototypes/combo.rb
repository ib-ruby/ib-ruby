module IB
#  module UseOrder
    module Combo
      ### Basic Order Prototype: Combo with two limits
      extend OrderPrototype
      class << self
=begin
	O order = new Order();
	order.action(action);
	order.orderType("LMT");
	order.lmtPrice(limitPrice);
	order.totalQuantity(quantity);
	if (nonGuaranteed)
	  {
	    List<TagValue> smartComboRoutingParams = new ArrayList<>();
	    smartComboRoutingParams.add(new TagValue("NonGuaranteed", "1")
							end
=end
      def defaults
	## todo implement serialisation of  key/tag Hash to camelCased-keyValue-List 
#      super.merge order_type: :limit , combo_params: { non_guaranteed: true} 
	#      for the time beeing, we use the array representation
      super.merge order_type: :limit , combo_params: [ ['NonGuaranteed', true] ]
      end


      def requirements
	Limit.requirements
      end

      def aliases
	Limit.aliases
      end

      def summary
	<<-HERE
	Create combination orders. It is constructed through  options, stock and futures legs 
	(stock legs can be included if the order is routed through SmartRouting). 
	
	Although a combination/spread order is constructed of separate legs, it is executed 
	as a single transaction if it is routed directly to an exchange. For combination orders 
	that are SmartRouted, each leg may be executed separately to ensure best execution. 
	--------
	Products: Options, Stocks, Futures
	HERE
      end
      end # class
    end	# module combo
end  # module ib
