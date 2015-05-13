module IB

# define a custom ErrorClass which can be fired if a verification fails
class VerifyError < StandardError
end
  module TWS_Reader
=begin
Generates an IB::Contract with the required attributes to retrieve a unique contract from the TWS

Background: If the tws is queried with a »complete« IB::Contract, it fails occacionally.
So – even to update its contents, a defined subset of query-parameters  has to be used.

The required data-fields are stored in a yaml-file and fetched by #YmlFile.

If con_id is present, only con_id and exchange are transmitted to the tws.
Otherwise a IB::Stock, IB::Option, IB::Future or IB::Forex-Object with nessesay attributes
to query the tws is build (and returned)

If Attributes are missing, an IB::VerifyError is fired,
This can be trapped with 
  rescue IB::VerifyError do ...
=end
    def  query_contract invalid_record:true
      ## the yml presents symbol-entries
      ## these are converted to capitalized strings 
      # dont do anything if no sec-type is specified
      return unless sec_type.present?

      items_as_string = ->(i){i.map{|x,y| x.to_s.capitalize}.join(', ')}
      ## here we read the corresponding attributes of the specified contract 
      item_values = ->(i){ i.map{|x,y| self.send(x).presence || y }}
      ## and finally we create a attribute-hash to instantiate a new Contract
      ## to_h is present only after ruby 2.1.0
      item_attributehash = ->(i){ i.keys.zip(item_values[i]).to_h }
      ## now lets proceed, but only if no con_id is present
      nessesary_items = YAML.load_file(yml_file)[sec_type]
      ret_var= if con_id.nil?  || con_id.zero?
		 raise VerifyError, "#{items_as_string[nessesary_items]} are needed to retrieve Contract,
         got: #{item_values[nessesary_items].join(',')}" if item_values[nessesary_items].any?( &:nil? ) 
		 IB::Contract.build  item_attributehash[nessesary_items].merge(:sec_type=> sec_type)
	       else 
		 IB::Contract.new  con_id: con_id , :exchange => exchange.presence || item_attributehash[nessesary_items][:exchange].presence || 'SMART'
	       end  # if
      ## modify the Object, ie. set con_id to zero if the record is still invalid
#      if new_record?
#	self.con_id=0
#      else
#	update_attribute( :con_id,  0 )
#      end if invalid_record
#      ret_var



    end # def
=begin
by default, the yml-file in the base-directory (ib-ruby) is used.
This method can be overloaded to include a file from a different location
=end
    def yml_file
      File.expand_path('../../../contract_config.yml',__FILE__ )
    end
=begin
IB::Contract#Verify 

verifies the contract as specified in the attributes. Modifies the Contract-Object and
returns the number of contracts retured by the TWS.

The attributes are completed/updated by quering the tws
If the query is not successfull, nothing is upated and zero is returned.
If multible contracts are specified, the object becomes the last one.
The count of queried contracts is returned.

The method accepts a block. The  TWS-contract-Object  is assessible there.
If multible contracts are specified, the block is executed with each of these contracts.

A successful (simple) verification the Contract looks works as follows:

s = IB::Stock.new symbol:"A"  
s --> <IB::Stock:0x007f3de81a4398 
	  @attributes= {"symbol"=>"A", "sec_type"=>"STK", "currency"=>"USD", "exchange"=>"SMART"}> 
s.verify   --> 1
s --> <IB::Stock:0x007f3de81a4398
      @attributes={"symbol"=>"A",  "updated_at"=>2015-04-17 19:20:00 +0200,
		  "sec_type"=>"STK", "currency"=>"USD", "exchange"=>"SMART", 
		  "con_id"=>1715006, "expiry"=>"", "strike"=>0.0, "local_symbol"=>"A",
		  "multiplier"=>0, "primary_exchange"=>"NYSE"}, 
      @contract_detail=#<IB::ContractDetail:0x007f3de81ed7c8 
		    @attributes={"market_name"=>"A", "trading_class"=>"A", "min_tick"=>0.01,
		    "order_types"=>"ACTIVETIM, (...),WHATIF,", 
		    "valid_exchanges"=>"SMART,NYSE,CBOE,ISE,CHX,(...)PSX", 
		    "price_magnifier"=>1, "under_con_id"=>0, 
		    "long_name"=>"AGILENT TECHNOLOGIES INC", "contract_month"=>"",
		    "industry"=>"Industrial", "category"=>"Electronics",
		    "subcategory"=>"Electronic Measur Instr", "time_zone"=>"EST5EDT",
		    "trading_hours"=>"20150417:0400-2000;20150420:0400-2000",
		    "liquid_hours"=>"20150417:0930-1600;20150420:0930-1600", 
		    "ev_rule"=>0.0, "ev_multiplier"=>"", "sec_id_list"=>{}, 
		    "updated_at"=>2015-04-17 19:20:00 +0200, "coupon"=>0.0, 
		    "callable"=>false, "puttable"=>false, "convertible"=>false,
		    "next_option_partial"=>false}>> 
=end

    def  verify 
      
      ib = IB::Gateway.tws

      # we generate a Request-Message-ID on the fly
      message_id = 1.times.inject([]) {|r| v = rand(200) until v and not r.include? v; r << v}.pop 			
      # define loacl vars which are updated within the query-block
      exitcondition, count , queried_contract = false, 0, nil

      # currently the tws-request is suppressed only if the contract_detail-record is present
      tws_request_not_nessesary = contract_detail.present? && contract_detail.is_a?( IB::ContractDetail )

      wait_until_exitcondition = -> do 
	u=0; while u<10000  do   # wait max 50 sec
	  break if exitcondition 
	  u+=1; sleep 0.05 
	end
      end

      if tws_request_not_nessesary
	yield self if block_given?
	count = 1
      
      else

	# subscribe to ib-messages and describe what to do
	a = ib.subscribe(:Alert, :ContractData,  :ContractDataEnd) do |msg| 
	  case msg
	  when IB::Messages::Incoming::Alert
	    if msg.code == 200 && msg.error_id == message_id
	      IB::Gateway.logger.error { "Not a valid Contract :: #{self.to_human} " }
	      exitcondition = true
	    end
	  when IB::Messages::Incoming::ContractData
	    if msg.request_id.to_i == message_id
	      # if multible contracts are present, all of them are assigned
	      # Only the last contract is saved in self;  'count' is incremented
	      count +=1
	      IB::Gateway.logger.warn{ "Multible Contracts are detected, only the last is returned, this one is overridden -->#{queried_contract.to_human} "} if count>1
	      ## a specified block gets the contract_object on any uniq ContractData-Event
	      yield msg.contract if block_given?
	      queried_contract = msg.contract  # used by the logger in case of mulible contracts
	      self.attributes = msg.contract.attributes
	      self.contract_detail = msg.contract_detail unless msg.contract_detail.nil?
	    end
	  when IB::Messages::Incoming::ContractDataEnd
	    exitcondition = true if msg.request_id.to_i ==  message_id

	  end  # case
	end # subscribe

	### send the request !
	contract_to_be_queried =  con_id.present? ? self : query_contract  
	# if no con_id is present,  the given attributes are checked by query_contract
	if contract_to_be_queried.present?   # is nil if query_contract fails
	  IB::Gateway.current.send_message :RequestContractData, 
	    :id =>  message_id,
	    :contract => contract_to_be_queried 
	  wait_until_exitcondition[]
	  ib.unsubscribe a

	  IB::Gateway.logger.error { "NO Contract returned by TWS -->#{self.to_human} "} unless exitcondition

	  IB::Gateway.logger.error { "Multible Contracts are detected, only the last is returned -->#{queried_contract.to_human} "} if count>1
	else
	  IB::Gateway.logger.error { "Not a valid Contract-spezification, #{self.to_human}" }
	end
      end
      count # return_value
      #queried_contract # return_value
      end # def


      def update_option_details wait_for_data: true, snapshot: false
	# aimed to be included into an option model
	gw = IB::Gateway.current
	ib = gw.tws
	self.option_detail ||=  IB::OptionDetail.new 

#	flag= { tick_option: false, close_price: false, ask_price: false, bid_price: false }
	sub= ib.subscribe(:TickPrice, :TickSize, :TickOption, :TickString) do |msg|

	  if msg.ticker_id == con_id
	    case msg
	    when IB::Messages::Incoming::TickOption
	      unless msg.implied_volatility.nil?
		#             print_tickoption[msg]
		attributes_to_transfer = msg.data.reject{|x,_| [:version, :ticker_id,:tick_type].include? x}.keys
		attributes_to_transfer.each{|a| option_detail.update_attribute a,   msg.data[a] }
		option_detail.update_attribute :updated_at, Time.now  # perform validations
		option_detail.save  # perform validations
#		flag[:tick_option] = true

	      end
	    when IB::Messages::Incoming::TickPrice
	      option_detail.update_attribute msg.type.to_sym, msg.price
	      option_detail.update_attribute :updated_at, Time.now  # perform validations
	      option_detail.save  # perform validations
#	      flag[ msg.type.to_sym ] = true

	    end  # case
	  end # branch
	end  # subscribe



	ib.send_message( :RequestMarketData, ticker_id: con_id, contract: self)

	if wait_for_data
	  # wait for flag to fill
	  u=0; while u<100  do   # wait max 50 sec
	    break if ( !snapshot && option_detail.complete? ) ||( snapshot &&  option_detail.greeks? )
	    u+=1; sleep 0.05 
	  end
	  ib.send_message( :CancelMarketData, id: con_id)
	  ib.unsubscribe sub 
	  # exchange is closed if u==100
	  #
	  nil  # return nil
	  else
	    sub # return subscription_id 
	  end
	end
    end # module
  end # module
