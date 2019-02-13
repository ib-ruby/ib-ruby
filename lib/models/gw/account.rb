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



=begin rdoc
given any key of local_id, perm_id or order_ref
and an optional status, which can be a string or a 
regexp ( status: /mitted/ matches Submitted and Presubmitted) 
the last associated Orderrecord is returned.

Thus if several Orders are placed with the same order_ref, the active one is returned

(If multible keys are specified, local_id preceeds perm_id)

=end
		def locate_order local_id: nil, perm_id: nil, order_ref: nil, status: /ubmitted/, con_id: nil
			search_option= [ local_id.present? ? [:local_id , local_id] : nil ,
										perm_id.present? ? [:perm_id, perm_id] : nil,
										order_ref.present? ? [:order_ref , order_ref ] : nil ].compact.first
			matched_items = if search_option.nil? 
												orders 
											else 
												orders.find_all{|x| x[search_option.first].to_i == search_option.last.to_i }
											end
			matched_items = matched_items.find_all{|x| x.contract.con_id == con_id } if con_id.present?

			if status.present?
				status = Regexp.new(status) unless status.is_a? Regexp
				matched_items.detect{|x| x.order_state.status =~ status }
			else
				matched_items.last  # return the last item
			end
		end


=begin rdoc 
requires an IB::Order as parameter. 

If attached, the associated IB::Contract is used to specify the tws-command

The associated Contract overtakes  the specified (as parameter)

auto_adjust: Limit- and Aux-Prices are adjusted to Min-Tick

convert_size: The action-attribute (:buy  :sell) is associated according the content of :total_quantity.


The parameter «order» is modified! 

It can be used to modify and eventually cancel 

The method raises an  IB::TransmissionError if the transmitted order ist not acknowledged by the tws after
one second.

Example

   j36 =  IB::Stock.new symbol: 'J36', exchange: 'SGX'
   order =  IB::Limit.order size: 100, price: 65.5
   g =  IB::Gateway.current.active_accounts.last

	 g.preview contract: j36, order: order
      => {:init_margin=>0.10864874e6, 
			    :maint_margin=>0.9704137e5, 
					:equity_with_loan=>0.97877973e6, 
					:commission=>0.524e1, 
					:commission_currency=>"USD", 
					:warning=>""}

   the_local_id = g.place order: order,  contract: j36
		  => 67						# returns local_id
	 order.contract			# updated contract-record 
      => #<IB::Contract:0x00000000013c94b0 @attributes={:con_id=>95346693, 
			                                                   :exchange=>"SGX", 
																												 :right=>"", 
																												 :include_expired=>false}> 

		order.limit_price = 65   # set new price
	  g.modify order: order    # and transmit 
		  => 67 # returns local_id

		g.locate_order( local_id: the_local_id  )
		  => returns the assigned order-record for inspection

		g.cancel order: order
				# logger output: 05:17:11 Cancelling 65 New #250/ from 3000/DU167349>
	 
=end

		def place_order  order:, contract: nil, auto_adjust: true, convert_size:  false
			# adjust the orderprice to  min-tick
			logger.progname =  'Account#PlaceOrder' 
			result = ->(l){ orders.detect{|x| x.local_id == l  && x.submitted? } }
			#·IB::Symbols are always qualified. They carry a description-field
			qualified_contract = ->(c) { c.description.present? || (c.con_id.present?  &&  !c.con_id.to_i.zero?) }
			contract &.verify{|c| order.contract = c}  # don't touch the parameter, get a new object
			## sending of plain vanilla IB::Bags will fail using account.place, unless a (negative) con-id is provided!
			error "place order: ContractVerification failed. No con_id assigned" if order &.contract &.con_id.to_i.zero?
			order.account =  account  # assign the account_id to the account-field of IB::Order
			the_local_order_id =  nil
			if qualified_contract[order.contract]
				self.orders.update_or_create order, :order_ref
				order.auto_adjust # if auto_adjust  /defined in lib/order_handling
			end
			if convert_size 
			 	order.action = order.total_quantity.to_i > 0  ? 	:buy : :sell 
				order.total_quantity  = order.total_quantity.to_i.abs
			end
				# apply non_guarenteed and other stuff bound to the contract to order.
			order.attributes.merge! order.contract.order_requirements unless order.contract.order_requirements.blank?
				#  con_id and exchange fully qualify a contract, no need to transmit other data
			the_contract = order.contract.con_id >0 ? Contract.new( con_id: order.contract.con_id, exchange: order.contract.exchange) : nil 
			the_local_id = order.place the_contract # return the local_id
			Timeout::timeout(1, IB::TransmissionError,"TimeOut ::Transmitted Order was not acknowledged") do 
				loop{ sleep(0.001); break if locate_order( local_id: the_local_id, status: nil ).present? }
			end

			the_local_id  # return_value


		end # place 

		# shortcut to enable
		#  account.place order: {} , contract: {} 
		#  account.preview order: {} , contract: {}
		#  account.modify order: {}
		alias place place_order

=begin #rdoc
Account#ModifyOrder operates in two modi:

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

		def modify_order  local_id: nil, order_ref: nil, order:nil

			result = ->(l){ orders.detect{|x| x.local_id == l  && x.submitted? } }
			logger.tap{ |l| l.progname = "Account #{account}#modify_order"}
			order ||= locate_order( local_id: local_id, 
														 status: /ubmitted/ ,
														 order_ref: order_ref ) 
			if order.is_a? IB::Order
				order.modify
			else
				error "No suitable IB::Order provided/detected. Instead: #{order.inspect}" 
			end  
		end

		alias modify modify_order

# Preview
		#
		# Submits a "WhatIf" Order
		#
		# Returns the order_state.forcast 
		#
		# The order received from the TWS is kept in account.orders
		#
		# Raises IB::TransmissionError if the Order could not be placed properly
		#
	def preview order:, contract: nil, **args_which_are_ignored
		# to_do:  use a copy of order instead of temporary setting order.what_if
		result = ->(l){ orders.detect{|x| x.local_id == l  && x.submitted? } }
		order.what_if = true
		the_local_id = place_order order: order, contract: contract
		Timeout::timeout(1, IB::TransmissionError,"(Preview-)Order is not transmitted properly" ) do
			loop{  sleep 0.1;  break if  result[the_local_id] }  
		end
		order.what_if = false # reset what_if flag
		order.local_id = nil  # reset local_id to enable reusage of the order-object for placing
		result[the_local_id].order_state.forcast  #  return_value
	end 

# closes the contract by submitting an appropiate order
	# the action- and total_amount attributes of the assigned order are overwritten.
	#
	# if a ratio-value (0 ..1) is specified in _order.total_quantity_ only a fraction of the position is closed. 
	# Other values are silently ignored
	#
	# if _reverse_ is specified, the opposide position is established. 
	# Any value in total_quantity is overwritten 
	#
	# returns the order transmitted
	#
	# raises an IB::Error if no PortfolioValues have been loaded to the IB::Acoount
	def close order:, contract: nil, reverse: false,  **args_which_are_ignored
		error "must only be called after initializing portfolio_values "  if portfolio_values.blank?
		contract_size = ->(c) do			# note: portfolio_value.position is either positiv or negativ
			if c.con_id <0 # Spread
				p = portfolio_values.detect{|p| p.contract.con_id ==c.legs.first.con_id} &.position.to_i
				p/ c.combo_legs.first.weight  unless p.to_i.zero?
			else
				portfolio_values.detect{|x| x.contract.con_id == c.con_id} &.position.to_i   # nil.to_i -->0
			end
		end

		contract &.verify{|c| order.contract = c}   # if contract is specified: don't touch the parameter, get a new object . 
		error "Cannot transmit the order – No Contract given " unless order.contract.is_a?(IB::Contract)
	
		the_quantity = if reverse
														 -contract_size[order.contract] * 2 
													 elsif order.total_quantity.abs < 1 && !order.total_quantity.zero? 
														-contract_size[order.contract] *  order.total_quantity.abs 
													 else
														 -contract_size[order.contract] 
													 end
		if the_quantity.zero?
			logger.info{ "Cannot close #{order.contract.to_human} - no position detected"}
		else
			order.total_quantity = the_quantity
			order.action =  nil
			order.local_id =  nil  # in any case, close is a new order
			logger.info { "Order modified to close, reduce or revese position: #{order.to_human}" }
			place order: order, convert_size: true
		end
	end

# just a wrapper to the Gateway-cancel-order method
	def cancel order: 
		Gateway.current.cancel_order order 
	end

	#returns an hash where portfolio_positions are grouped into Watchlists.
	#
	# Watchlist => [  contract => [ portfoliopositon] , ... ] ]
	#
		def organize_portfolio_positions   the_watchlists
		  the_watchlists = [ the_watchlists ] unless the_watchlists.is_a?(Array)
			self.focuses = portfolio_values.map do | pw |
											z=	the_watchlists.map do | w |		
												ref_con_id = pw.contract.con_id
												watchlist_contract = w.find do |c| 
													c.is_a?(IB::Bag) ? c.combo_legs.map(&:con_id).include?(ref_con_id) : c.con_id == ref_con_id 
												end rescue nil	
												watchlist_contract.present? ? [w,watchlist_contract] : nil
											end.compact

											z.empty? ? [ IB::Symbols::Unspecified, pw.contract, pw ] : z.first << pw
			end.group_by{|a,_,_| a }.map{|x,y|[x, y.map{|_,d,e|[d,e]}.group_by{|e,_| e}.map{|f,z| [f, z.map(&:last)]} ] }.to_h
			# group:by --> [a,b,c] .group_by {|_g,_| g} --->{ a => [a,b,c] }
			# group_by+map --> removes "a" from the resulting array
		end


		def locate_contract con_id
			contracts.detect{|x| x.con_id.to_i == con_id.to_i }
		end

		## returns the contract definition of an complex portfolio-position detected in the account
		def complex_position con_id
			con_id = con_id.con_id	if con_id.is_a?(IB::Contract)
			focuses.map{|x,y| y.detect{|x,y| x.con_id.to_i==  con_id.to_i} }.compact.flatten.first
		end
	end # class
		##
		# in the console   (call gateway with watchlist: [:Spreads, :BuyAndHold])
#head :001 > .active_accounts.first.focuses.to_a.to_human
#Unspecified
#<Stock: BLUE EUR SBF>
#<PortfolioValue: DU167348 Pos=720 @ 15.88;Value=11433.24;PNL=-4870.05 unrealized;<Stock: BLUE EUR SBF>
#<Stock: CSCO USD NASDAQ>
#<PortfolioValue: DU167348 Pos=44 @ 44.4;Value=1953.6;PNL=1009.8 unrealized;<Stock: CSCO USD NASDAQ>
#<Stock: DBB USD ARCA>
#<PortfolioValue: DU167348 Pos=-1 @ 16.575;Value=-16.58;PNL=1.05 unrealized;<Stock: DBB USD ARCA>
#<Stock: NEU USD NYSE>
#<PortfolioValue: DU167348 Pos=1 @ 375.617;Value=375.62;PNL=98.63 unrealized;<Stock: NEU USD NYSE>
#<Stock: WFC USD NYSE>
#<PortfolioValue: DU167348 Pos=100 @ 51.25;Value=5125.0;PNL=-171.0 unrealized;<Stock: WFC USD NYSE>
#BuyAndHold
#<Stock: CIEN USD NYSE>
#<PortfolioValue: DU167348 Pos=812 @ 29.637;Value=24065.57;PNL=4841.47 unrealized;<Stock: CIEN USD NYSE>
#<Stock: J36 USD SGX>
#<PortfolioValue: DU167348 Pos=100 @ 56.245;Value=5624.5;PNL=-830.66 unrealized;<Stock: J36 USD SGX>
#Spreads
#<Strangle Estx50(3200.0,3000.0)[Dec 2018]>
#<PortfolioValue: DU167348 Pos=-3 @ 168.933;Value=-5067.99;PNL=603.51 unrealized;<Option: ESTX50 20181221 call 3000.0  EUR>
#<PortfolioValue: DU167348 Pos=-3 @ 142.574;Value=-4277.22;PNL=-867.72 unrealized;<Option: ESTX50 20181221 put 3200.0  EUR>
# => nil 
#		# 
end ## module 
