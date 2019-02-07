module OrderHandling
=begin
UpdateOrderDependingObject

Generic method which enables operations on the order-Object,
which is associated to OrderState, Execution, CommissionReport 
Events fired by the tws.
They identify the order by local_id and perm_id

Everything is carried out in a mutex-synchonized environment
=end
	def update_order_dependent_object order_dependent_object  # :nodoc:
		for_active_accounts do  | a | 
			order = if order_dependent_object.local_id.present?
								a.locate_order( :local_id => order_dependent_object.local_id)
							else
								a.locate_order( :perm_id => order_dependent_object.perm_id)
							end
			yield order if order.present?
		end 
	end
  def initialize_order_handling
		tws.subscribe( :CommissionReport, :ExecutionData, :OrderStatus, :OpenOrder, :OpenOrderEnd, :NextValidId ) do |msg| 
			logger.progname = 'Gateway#order_handling'
			case msg
	
			when IB::Messages::Incoming::CommissionReport
				# Commission-Reports are not assigned to a order -  
				logger.info "CommissionReport -------#{msg.exec_id} :...:C: #{msg.commission} :...:P/L: #{msg.realized_pnl}-"
			when IB::Messages::Incoming::OrderStatus

				# The order-state only links via local_id and perm_id to orders.
				# There is no reference to a contract or an account

				success= update_order_dependent_object( msg.order_state) do |o|
					o.order_states.update_or_create msg.order_state, :status 
				end

				logger.info {  "Order State not assigned-- #{msg.order_state.to_human} ----------" } if success.nil?

			when IB::Messages::Incoming::OpenOrder
				## todo --> handling of bags --> no con_id
				for_selected_account(msg.order.account) do | this_account |
					# first update the contracts
					# make open order equal to IB::Spreads (include negativ con_id)
					msg.contract[:con_id] = -msg.contract.combo_legs.map{|y| y.con_id}.sum  if msg.contract.is_a? IB::Bag
					msg.contract.orders.update_or_create msg.order, :local_id
						this_account.contracts.first_or_create msg.contract, :con_id
					# now save the order-record
						msg.order.contract = msg.contract
						this_account.orders.update_or_create msg.order, :local_id
				end

				#     update_ib_order msg  ## aus support 
			when  IB::Messages::Incoming::OpenOrderEnd
				#             exitcondition=true
				logger.debug { "OpenOrderEnd" }

			when IB::Messages::Incoming::ExecutionData
				# Excution-Data are fired independly from order-states.
				# The Objects are stored at the associated order
				success= update_order_dependent_object( msg.execution) do |o|
					logger.progname = 'Gateway#order_handling::ExecutionData '
					o.executions << msg.execution 
					if  msg.execution.cumulative_quantity.to_i == o.total_quantity.abs
						logger.info{ "#{o.account} --> #{o.contract.symbol}: Execution completed" }
						o.order_states.first_or_create(  IB::OrderState.new( perm_id: o.perm_id, local_id: o.local_id,
						
																																status: 'Filled' ),  :status )
							# update portfoliovalue
						a = @accounts.detect{|x| x.account == o.account } #  we are in a mutex controlled environment
						 pv =  a.portfolio_values.detect{|y| y.contract.con_id == o.contract.con_id}
						 change =  o.action == :sell ? -o.total_quantity : o.total_quantity
						 if pv.present?
						 pv.update_attribute :position,  pv.position + change
						 else
							 a.portfolio_values << IB::PortfolioValue.new( position: change, contract: o.contract)
						 end
					else
						logger.debug{ "#{o.account} --> #{o.contract.symbol}: Execution not completed (#{msg.execution.cumulative_quantity.to_i}/#{o.total_quantity.abs})" }
					end  # branch
				end # block

				logger.error {  "Execution-Record not assigned-- #{msg.execution.to_human} ----------" } if success.nil?

			end  # case msg.code
		end # do
	end # def subscribe

# Resets the order-array for each account first.
# Requests all open (eg. pending)  orders from the tws 
#
# Waits until the OpenOrderEnd-Message is recieved


	def request_open_orders

		exit_condition = false
		subscription = tws.subscribe(  :OpenOrderEnd ){ exit_condition = true }
		for_active_accounts{| account | account.orders=[] }
		send_message :RequestAllOpenOrders
		Timeout::timeout(1, IB::TransmissionError,"OpenOrders not received" ) do
			loop{  sleep 0.1; break if exit_condition  }
		end
		tws.unsubscribe subscription
	end

	alias update_orders request_open_orders 




end # module





module IB
	class Alert

		def self.alert_202 msg
			# do anything in a secure mutex-synchronized-environment
			any_order = IB::Gateway.current.for_active_accounts do | account |
				order= account.locate_order( local_id: msg.error_id )
				if order.present? && ( order.order_state.status != 'Cancelled' )
					order.order_states.update_or_create( IB::OrderState.new( status: 'Cancelled', 
																																	perm_id: order.perm_id, 
																																	local_id: order.local_id  ) ,
																																	:status )

				end
				order # return_value
			end
			if any_order.compact.empty? 
				IB::Gateway.logger.error{"Alert 202: The deleted order was not registered: local_id #{msg.error_id}"}
			end

		end


		def self.alert_2102
			# Connectivity between IB and Trader Workstation has been restored - data maintained.
			sleep 0.1  #  no need to wait too long.
			if IB::Gateway.current.check_connection
				IB::Gateway.logger.debug { "Alert 2102: Connection stable" }
			else
				IB::Gateway.current.reconnect
			end
		end
		class << self
=begin
IB::Alert#AddOrderstateAlert

The OrderState-Record is used to record the history of the order.
If selected Alert-Messages appear, they are  added to the Order.order_state-Array.
The last Status is available as Order.order_state, all states are accessible by Order.order_states

The TWS-Message-text is stored to the »warning-text«-field.
The Status is always »rejected«. 
If the first OrderState-object of a Order is »rejected«, the order is not placed at all.
Otherwise only the last action is not applied and the order is unchanged.

=end
			def add_orderstate_alert  *codes
				codes.each do |n|
					class_eval <<-EOD
						 def self.alert_#{n} msg

								 if msg.error_id.present?
										IB::Gateway.current.for_active_accounts do | account |
												order= account.locate_order( local_id: msg.error_id )
												if order.present? && ( order.order_state.status != 'Rejected' )
													order.order_states.update_or_create(  IB::OrderState.new( status: 'Rejected' ,
															perm_id: order.perm_id, 
															warning_text: '#{n}: '+  msg.message,
															local_id: msg.error_id ), :status ) 	

													IB::Gateway.logger.error{  msg.to_human  }
												end	# order present?
										 end	# mutex-environment
									end	# branch
							end	# def
					EOD
				end # loop
			end # def
		end
		add_orderstate_alert  103,  # duplicate order
			201,  # deleted object
			105,  # Order being modified does not match original order
			462,  # Cannot change to the new Time in Force:GTD
			329,  # Cannot change to the new order type:STP
			10147 # OrderId 0 that needs to be cancelled is not found.
	end  # class Alert


	class Order
		def auto_adjust
			# lambda to perform the calculation	
			adjust_price = ->(a,b) do
				a=BigDecimal(a,5) 
				b=BigDecimal(b,5) 
				_,o =a.divmod(b)
			  a-o 
			end
			error "No Contract provided to Auto adjust " unless contract.is_a? IB::Contract
			unless contract.is_a? IB::Bag
			# ensure that contract_details are present
				contract.verify do |the_contract | 
					the_details =  the_contract.contract_detail
					# there are two attributes to consider: limit_price and aux_price
					# limit_price +  aux_price may be nil or an empty string. Then ".to_f.zero?" becomes true 
					self.limit_price= adjust_price.call(limit_price.to_f, the_details.min_tick) unless limit_price.to_f.zero?
					self.aux_price= adjust_price.call(aux_price.to_f, the_details.min_tick) unless aux_price.to_f.zero?
				end
			end
		end
	end  # class Order
end  # module
