module OrderHandling
=begin
UpdateOrderDependingObject

Generic method which enables operations on the order-Object,
which is associated to OrderState, Execution, CommissionReport 
Events fired by the tws.
They identify the order by local_id and perm_id
=end
  def update_order_dependent_object order_dependent_object
    order = nil
    if order_dependent_object.local_id.blank?
      success =  nil
      for_active_accounts do |a|
	if success.nil?
	  success =  true if order = a.orders.detect{|x| x.perm_id == order_dependent_object.perm_id }
	end
      end
      logger.info { "Unable to update OrderState. Only PermId is given and no corresponding Order found. Perm_id: #{order_stat.perm_id} "} if success.nil?
    else
      order= for_active_accounts{ |a| a.locate_order( local_id: order_state.local_id )}.compact.first
     # old version :: order=  @local_orders.detect{|x| x.local_id == order_state.local_id }
    end
    ## perform the block if the order is assigned and the argument is valid
    if order.present?  #&& order_dependent_object.save
      yield order
      true # return_value
    else
      nil # return_value
    end
  end
  def initialize_order_handling
    tws.subscribe( :CommissionReport, :ExecutionData, :OrderStatus, :OpenOrder, :OpenOrderEnd ) do |msg| 
      logger.progname = 'Gateway#order_handling'
      case msg
      when IB::Messages::Incoming::CommissionReport
	# Commission-Reports are not assigned to a order -  
	logger.info "CommissionReport -------#{msg.exec_id} :...:C: #{msg.commission} :...:P/L: #{msg.realized_pnl}-"
      when IB::Messages::Incoming::OrderStatus

	# The order-state only links via local_id and perm_id to orders.
	# There is no reference to a contract or an account
      
	success= update_order_dependent_object( msg.order_state) do |o|
		o.order_states << msg.order_state
	end
	    
	logger.info {  "Order State not assigned-- #{msg.order_state.to_human} ----------" } if success.nil?

      when IB::Messages::Incoming::OpenOrder
	#puts  "Order  --- #{msg.order.inspect} ----------" 
	   for_selected_account(msg.order.account) do | this_account |
	    # first update the contracts
	     if this_account.contracts.is_a?(Array)
	       msg.contract.orders.update_or_create msg.order, :perm_id
	     c= this_account.contracts.first_or_create msg.contract, :con_id
	     else
	       this_account.contracts.where(con_id: msg.contract.con_id).first_or_create do |new_contract|
		 new_contract.attributes.merge msg_contract.attributes
	       end
	     end
	     # now save the order-record
	     
	     if this_account.orders.is_a?(Array)
	       msg.order.contract = msg.contract
	       this_account.orders.update_or_create msg.order, :perm_id

	     else
	      this_account.orders.where( perm_id: msg.order.perm_id ).first_or_create do | new_order |
		new_order.attributes.merge msg.order.attributes
		new_order.contract =  msg.contract
	      end
	     end
	   end

          #     update_ib_order msg  ## aus support 
	 #      ActiveRecord::Base.connection.close
      when  IB::Messages::Incoming::OpenOrderEnd
#             exitcondition=true
	logger.debug { "OpenOrderEnd" }

      when IB::Messages::Incoming::ExecutionData
	# Excution-Data are fired independly from order-states.
	# The Objects are stored at the associated order
	success= update_order_dependent_object( msg.execution) do |o|
	  logger.progname = 'Gateway#order_handling::ExecutionData '
	  o.executions << msg.execution 
	  if  msg.execution.cumulative_quantity.to_i == o.quantity.abs
	    logger.info{ "#{o.account.account} --> #{o.contract.symbol}: Execution completed" }
	  else
	    logger.debug{ "#{o.account.account} --> #{o.contract.symbol}: Execution not completed (#{msg.execution.cumulative_quantity.to_i}/#{o.quantity.abs})" }
	  end  # branch
	end # block

	logger.info {  "Execution-Record not assigned-- #{msg.execution.to_human} ----------" } if success.nil?

	end  # case msg.code
    end # do
  end # def subscribe
=begin
Gateway#RequestOpenOrders  aliased as UpdateOrders

Resets the order-array for each account first.
Requests all open (eg. pending)  orders from the tws 

=end

    def request_open_orders
      for_active_accounts{| account | account.orders=[] }
      send_message :RequestAllOpenOrders
    end

    alias update_orders request_open_orders 
  end # module





module IB
  class Alert

    def self.alert_202 msg
      #
      order = IB::Gateway.current.for_active_accounts do | account |
	account.locate_order( local_id: msg.error_id )
      end.compact.first
      if order.present?
	order.order_states << IB::OrderState.new( status:'Cancelled' )
      else
	IB::Gateway.logger.error{"Alert 202: The deleted order was not registered: local_id #{msg.error_id}"} 
      end
    end
    class << self
=begin
IB::Alert#AddOrderstateAlert

The OrderState-Record is used to record the history of the order.
If selected Alert-Messages appear, they are added added to the Order.OrderState-Array.
The last Status is available as Order.order_state, all states are accessible by Order.order_states

The TWS-Message-text is stored to the »warning-text«-field.
The Status is always »rejected«. 
If the first OrderState-object of a Order is »rejected«, the order is not placed at all.
Otherwise only the last action is not applied and the order is unchanged.

ToDo:: Encapsulate the order-State operation in Mutex as its not threadsafe ie. delegate it to connection.
=end
      def add_orderstate_alert  *codes
	codes.each do |n|
	  class_eval <<-EOD
	   def self.alert_#{n} msg
	      IB::Gateway.logger.error{ msg.to_human }

	       if msg.error_id.present? && msg.error_id > 0
		order = IB::Gateway.current.for_active_accounts do | account |
		account.locate_order( local_id: msg.error_id )
		end.compact.first
		if order.present?
		  order.order_states << IB::OrderState.new( status: 'Rejected' ,
						  warning_text: '#{n}: '+  msg.message,
						  local_id: msg.error_id ) 	
		end
	      end	# branch
	    end		# def
	  EOD
	end # loop
      end # def
    end
    add_orderstate_alert  103,  # duplicate order
			  201,  # deleted object
			  105,  # Order being modified does not match original order
			  462,  # Cannot change to the new Time in Force:GTD
			  329   # Cannot change to the new order type:STP


  end  # class

end  # module
