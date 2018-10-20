module IB
	class Account 


		def simple_account_data_scan search_key, search_currency=nil
			if account_values.is_a? Array
				if search_currency.present? 
					account_values.find_all{|x| x.key.match( search_key )  && x.currency == search_currency.upcase }
				else
					account_values.find_all{|x| x.key.match( search_key ) }
				end

			else  # not tested!!
				if search_currency.present?
					account_values.where( ['key like %', search_key] ).where( currency: search_currency )
				else  # any currency
					account_values.where( ['key like %', search_key] )
				end
			end
		end



=begin
Account#LocateOrder
given any key of local_id, perm_id and order_ref
and an optional status, which can be a string or a 
regexp ( status: /mitted/ matches Submitted and Presubmitted) 
the last associated Orderrecord is returned.

Thus if several Orders are placed with the same order_ref, the active one is returned

(If multible keys are specified, local_id preceeds perm_id)

=end
		def locate_order local_id: nil, perm_id: nil, order_ref: nil, status: nil
			search_option= [ local_id.present? ? [:local_id , local_id] : nil ,
										perm_id.present? ? [:perm_id, perm_id] : nil,
										order_ref.present? ? [:order_ref , order_ref ] : nil ].compact.first
			matched_items =  search_option.nil? ? orders : orders.find_all{|x| x[search_option.first].to_i == search_option.last.to_i }
			if status.present?
				status = Regexp.new(status) unless status.is_a? Regexp
				matched_items.detect{|x| x.order_state.status =~ status }
			else
				matched_items.last  # return the last item
			end
		end


=begin
Account#PlaceOrder
requires an IB::Order as parameter. 
If attached, the associated IB::Contract is used to specify the tws-command
The associated Contract overtakes  the specified (as parameter)

auto_adjust: Limit- and Aux-Prices are adjusted to Min-Tick

convert_size: The action-attribute (:buy  :sell) is associated according the content of :total_quantity.


=end

		def place_order  order:, contract: nil, auto_adjust: true, convert_size:  false
			# adjust the orderprice to  min-tick
			logger.progname =  'Account#PlaceOrder' 
			qualified_contract = -> do
													contract.is_a?( IB::Bag )  ||  # Bags are always qualified
													(contract.con_id.present? 	 && contract.con_id.to_i >0)
			end
			contract ||= order.contract   # no verification at this piont
			order.account =  account  # assign the account_id to the account-field of IB::Order
			local_id =  nil
			self.orders.update_or_create order, :order_ref
			if !qualified_contract[]
				error "No qualified Contract specified .::. #{order.to_human}"
			else
				order.auto_adjust if auto_adjust && !(contract.is_a?( IB::Bag ))
				if convert_size 
					order.action =  order.total_quantity.to_i > 0  ? 	:buy  : :sell 
		      order.total_quantity =  order.total_quantity.to_i.abs
			  end
				#  con_id and exchange fully qualify a contract, no need to transmit other data
				order.contract =  contract.con_id.to_i > 0 ?  Contract.new( con_id: contract.con_id, exchange: contract.exchange)  :  contract
				puts "order: #{order.action}"
				puts "order: #{order.total_quantity}"
				puts "order : #{order.inspect}"
				local_id = Connection.current.place_order order, order.contract
			end 
			local_id  # return_value

		end # place 


=begin
Account#ModifyOrder
operates in two modi:

First: The order is specified  via local_id, perm_id or order_ref.
	It is checked, whether the order is still modificable.
	Then the Order ist provided through  the block. Any modification is done there. 
	Important: The Block has to return the modified IB::Order

Second: The order can be provided as parameter as well. This will be used
without further checking. The block is now optional. 
	Important: The OrderRecord must provide a valid Contract.

The simple version does not adjust the given prices to tick-limits.
This has to be done manualy in the provided block
=end

		def modify_order perm_id: nil, local_id: nil, order_ref: nil, order:nil, &b

			logger.tap{ |l| l.progname = "Account #{account}#modify_order"}
			order = locate_order(  perm_id: perm_id, 
													 local_id: local_id, 
													 status: /ubmitted/ ,
													 order_ref: order_ref ) if order.nil?
			if order.is_a? IB::Order
				order = yield order if block_given?  # specify modifications in the block
			end
			if order.is_a? IB::Order
				Connection.current.modify_order order, order.contract 
			else
				error "No suitable IB::Order provided/detected. Instead: #{order.inspect}" 
			end  
		end

	end # class
end ## module 
