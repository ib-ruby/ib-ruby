module IB
	module TWS_Reader
=begin
Generates an IB::Contract with the required attributes to retrieve a unique contract from the TWS

Background: If the tws is queried with a fully assigned IB::Contract, it fails occacionally.
So – even update the contents, a defined set of query-parameters is to be used.

The required data-fields are stored in a yaml-file.
If the con_id is present, only con_id and currency are transmitted to the tws.
=end
	def  query_contract invalid_record:true
		## the yml presents symbol-entries
		## these are converted to capitalized strings 
		items_as_string = ->(i){i.map{|x,y| x.to_s.capitalize}.join(', ')}
		## here we read the corresponding attributes of the specified contract 
		item_values = ->(i){ i.map{|x,y| self.send(x).presence || y }}
		## and finally we create a attribute-hash to instantiate a new Contract
		## to_h is present only after ruby 2.1.0
		item_attributehash = ->(i){ i.keys.zip(item_values[i]).to_h }
		## now lets proceed, but only if no con_id is present
		nessesary_items = YAML.load_file(yml_file)[sec_type]
		ret_var= if con_id.nil?  || con_id.zero?

			raise "#{items_as_string[nessesary_items]} are needed to retrieve Contract, got: #{item_values[nessesary_items].join(',')}" if item_values[nessesary_items].any?( &:nil? ) 
			IB::Contract.new  item_attributehash[nessesary_items].merge(:sec_type=> sec_type)
			else #if currency.present?
			IB::Contract.new  con_id:con_id , :exchange => exchange.presence || item_attributehash[nessesary_items][:exchange]
		end  # if
		## modify the Object, ie. set con_id to zero
		if new_record?
			self.con_id=0
		else
			update_attribute( :con_id,  0 )
		end if invalid_record
		ret_var

		

	end # def
=begin
by default, the yml-file in the base-directory (ib-ruby) is used.
This method can be overloaded to include a file from a different location
=end
		def yml_file
			File.expand_path('../../../contract_config.yml',__FILE__ )
		end
=begin
read_contract_from_tws (alias update_contract) requests ContractData from the TWS and
stores/updates them in this contract_object.

If the parameter »unique« is set (the default), the #yml_file is used to check the nessesary 
query-attributes, otherwise the check is suppressed.
ContractDetails are not saved, by default. Instead they are supposed to be adressed by 
yielding a block.

The msg-object returned by the tws is asessible via an optional block.
If many Contracts match the definition by the attributs of the IB::Contract
the block is executed for each returned Contract

Example:
	given an active-record-Model with min_tick-attribute:
	--------------------------------------------------
	contract = IB::Contract.find x
        count_datasets,lth = 0
        contract.update_contract do |msg|
	    update_attibute :min_tic , msg.contractdetail.min_tick
	    count_datasets +=1
	    lth= msg.contractdetail.liquid_trading_hours
	end
	puts "More then one dataset specified: #{count_datasets)" if count_datasets > 1
	puts "Invalid Attribute Combination or unknown symbol/con_id" if count_datasets.zero?
	puts "Trading-hours: #{lth}" unless lth.zero?


=end
	def read_contract_from_tws unique: true, save_details: false

		ib = IB::Connection.current
		raise "NO TWS" unless ib.present?
		to_be_saved = IB.db_backed? && !new_record?

		# if it's a not-saved object, we generate an Request-Message-ID on the fly
		# otherwise the Object.id is used as Message-ID and the database is updated 
		# after the query
		#
		message_id =  if !to_be_saved
				      random = 1.times.inject([]) {|r| v = rand(200) until v and not r.include? v; r << v}.pop 			
				      random + ( IB::Contract.maximum(:id).presence||1 )  rescue random ## return_value
			      else
				      id
			      end
		# define loacl vars which are updated within the follwoing block
		exitcondition, count = false, 0

		wait_until_exitcondition = -> do 
			u=0; while u<100  do   # wait max 5 sec
				break if exitcondition 
				u+=1; sleep 0.05 
			end
		end
		
		attributes_to_be_transfered = ->(obj) do
			obj.attributes.reject{|x,y| ["created_at","updated_at","id"].include? x }
		end
			
		# subscribe to ib-messages and describe what to do
		a = ib.subscribe(:Alert, :ContractData,  :ContractDataEnd) do |msg| 
			case msg
			when IB::Messages::Incoming::Alert
				if msg.code==200 && msg.error_id==message_id
					warn { "Not a valid Contract :: #{self.to_human} " }
					# save message to local_symbol
				 to_be_saved ? update_attribute( :local_symbol,  msg.message ) : self.local_symbol= msg.message 

					exitcondition = true
					# alternative
			#		raise 'Not a valid Contract '
				else
					puts msg.to_human 
				end
			when IB::Messages::Incoming::ContractData
				if msg.request_id.to_i ==  message_id
					# if multible contracts are present, all of them are assigned
					# Only the last contract is returned. However 'count' is incremented
					count +=1
	warn{ "Multible Contracts are detected, only the last is returned, this one is overridden -->#{self.to_human} "} if count>1
					## a specified block gets the msg-object on any uniq ContractData-Event
					yield msg if block_given?
					if to_be_saved 
						update attributes_to_be_transfered[msg.contract]
						if contract_detail.nil?
						self.contract_detail =  msg.contract_detail 
						else
						contract_detail.update attributes_to_be_transfered[msg.contract_detail] ## AR4 specific
						end if save_details
					else
						self.attributes =  msg.contract.attributes  # AR4 specific

					end
				end
			when IB::Messages::Incoming::ContractDataEnd
				exitcondition = true if msg.request_id.to_i ==  message_id

			end  # case
		end # subscribe

		### send the request !
		begin
		ib.send_message :RequestContractData, 
			:id => new_record? ? message_id : id,
			:contract => ( unique ? query_contract : self  rescue self )  # prevents error if Ruby vers < 2.1.0
		# we do not rely on the received hash, we simply wait for the ContractDataEnd Event 
		# (or 5 sec). 
		wait_until_exitcondition[]
		ib.unsubscribe a
		rescue ThreadError => e
		  puts "ERROR"
		  puts e.inspect
		  raise
		end
		
		warn{ "NO Contract returned by TWS -->#{self.to_human} "} unless exitcondition
		warn{ "Multible Contracts are detected, only the last is returned -->#{contract.to_human} "} if count>1
		count>1 ? count : local_symbol # return_value
	end # def

  	alias update_contract read_contract_from_tws
end # module
end # module
