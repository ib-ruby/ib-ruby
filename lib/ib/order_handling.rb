module OrderHandling
  def initialize_order_handling
    tws.subscribe( :CommissionReport, :ExecutionData, :OrderStatus, :OpenOrder, :OpenOrderEnd ) do |msg| 
      logger.progname = 'Gateway#order_handling'
      case msg
      when IB::Messages::Incoming::CommissionReport
	logger.info "CommissionReport -------#{msg.exec_id} :...:C: #{msg.commission} :...:P/L: #{msg.realized_pnl}-"
      when IB::Messages::Incoming::OrderStatus

	logger.debug { "Order State --- #{msg.order_state.status} ----------" }
	# Orderstatus-Events werden zu Beginn jeder Sitzung geliefert.
	# Falls keine Datenbankeinträge existieren, wird die Order in der TWS gelöscht.
	# Falls Datenbankeinträge bestehen, werden diese mit dem Orderstate abgeglichen.
	#os = msg.order_state
	#order = InvestOrder.perm! os
	#order.update_status  os if order.present?
	#ActiveRecord::Base.connection.close

      when IB::Messages::Incoming::OpenOrder
	   for_selected_account(msg.order.account) do | this_account |
	    # first update the contracts
	     if this_account.contracts.is_a?(Array)
	       msg.contract.orders << msg.order
	     c= this_account.contracts.first_or_create msg.contract, msg.contract.con_id
	     else
	       this_account.contracts.where(con_id: msg.contract.con_id).first_or_create do |new_contract|
		 new_contract.attributes.merge msg_contract.attributes
	       end
	     end
	     # now save the order-record
	     
	     if this_account.orders.is_a?(Array)
	       msg.order.contract = msg.contract
	       this_account.orders.first_or_create msg.order, msg.order.perm_id

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
	# Execution-Reports kommen bei Market-Ordern noch bevor der OrderStatus presubmitted
	# in der Datenbank festgehalten wurdea
	#		  puts msg.inspect
	#order = InvestOrder.perm! msg.execution
	#	msg.execution.save!
	#	order.execution_dataset = msg.execution
	#if order.present? #&& order.execution_dataset.is_a?( IB::Execution )
	#  order.execute_order msg.execution  
	  #				puts order.inspect
	#  if  msg.execution.cumulative_quantity.to_i == order.size.abs
	#    logger.debug{ "ExecutionData: Order_id:#{order.id} Ausführung abgeschlossen" }
	#  else
	#    logger.debug{ "ExecutionData: Order_id:#{order.id} TeilAusführung #{msg.execution.cumulative_quantity}" }
	#  end
	#  ActiveRecord::Base.connection.close
	#end
      end  # case msg.code
    end # do
  end # def subscribe

    def request_open_orders
      tws.send_message :RequestAllOpenOrders
    end
  end # module
