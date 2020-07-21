module CoreExtensions
  module Array
    module DuplicatesCounter
      def count_duplicates
        self.each_with_object(Hash.new(0)) { |element, counter| counter[element] += 1 }.sort_by{|k,v| -v}.to_h
      end
    end
  end
end

Array.include CoreExtensions::Array::DuplicatesCounter
module IB

	module BuisinesDays
		#		https://stackoverflow.com/questions/4027768/calculate-number-of-business-days-between-two-days

		# Calculates the number of business days in range (start_date, end_date]
		#
		# @param start_date [Date]
		# @param end_date [Date]
		#
		# @return [Fixnum]
		def self.business_days_between(start_date, end_date)
			days_between = (end_date - start_date).to_i
			return 0 unless days_between > 0

			# Assuming we need to calculate days from 9th to 25th, 10-23 are covered
			# by whole weeks, and 24-25 are extra days.
			#
			# Su Mo Tu We Th Fr Sa    # Su Mo Tu We Th Fr Sa
			#        1  2  3  4  5    #        1  2  3  4  5
			#  6  7  8  9 10 11 12    #  6  7  8  9 ww ww ww
			# 13 14 15 16 17 18 19    # ww ww ww ww ww ww ww
			# 20 21 22 23 24 25 26    # ww ww ww ww ed ed 26
			# 27 28 29 30 31          # 27 28 29 30 31
			whole_weeks, extra_days = days_between.divmod(7)

			unless extra_days.zero?
				# Extra days start from the week day next to start_day,
				# and end on end_date's week date. The position of the
				# start date in a week can be either before (the left calendar)
				# or after (the right one) the end date.
				#
				# Su Mo Tu We Th Fr Sa    # Su Mo Tu We Th Fr Sa
				#        1  2  3  4  5    #        1  2  3  4  5
				#  6  7  8  9 10 11 12    #  6  7  8  9 10 11 12
				# ## ## ## ## 17 18 19    # 13 14 15 16 ## ## ##
				# 20 21 22 23 24 25 26    # ## 21 22 23 24 25 26
				# 27 28 29 30 31          # 27 28 29 30 31
				#
				# If some of the extra_days fall on a weekend, they need to be subtracted.
				# In the first case only corner days can be days off,
				# and in the second case there are indeed two such days.
				extra_days -= if start_date.tomorrow.wday <= end_date.wday
												[start_date.tomorrow.sunday?, end_date.saturday?].count(true)
											else
												2
											end
			end

			(whole_weeks * 5) + extra_days
		end
	end

	

# define a custom ErrorClass which can be fired if a verification fails
class VerifyError < StandardError
end

class Contract

# Reading Contract-Defaults
	#
# by default, the yml-file in the base-directory (ib-ruby) is used.
# This method can be overloaded to include a file from a different location
	#
#  IB::Symbols::Stocks.wfc.yml_file
#   => "/home/ubuntu/workspace/ib-ruby/contract_config.yml" 
# 
    def yml_file
      File.expand_path('../../../../contract_config.yml',__FILE__ )
    end
# IB::Contract#Verify 
 
# verifies the contract 
#
# returns the number of contracts retured by the TWS.
# 
# 
# The method accepts a block. The  queried contract-Object is assessible there.
# If multible contracts are specified, the block is executed with each of these contracts.
#
# Parameter: thread: (true/false) 
#
# The verifiying-process ist time consuming. If multible contracts are to be verified, 
# they can be queried simultaniously.
#    IB::Symbols::W500.map{|c|  c.verify(thread: true){ |vc| do_something }}.join
# 
# A simple verification works as follows:
# 
#  s = IB::Stock.new symbol:"A"  
#  s --> <IB::Stock:0x007f3de81a4398 
#  	  @attributes= {"symbol"=>"A", "sec_type"=>"STK", "currency"=>"USD", "exchange"=>"SMART"}> 
#  s.verify   --> 1
#  # s is unchanged !
#	 
#  s.verify{ |c| puts c.inspect }
#   --> <IB::Stock:0x007f3de81a4398
#       @attributes={"symbol"=>"A",  "updated_at"=>2015-04-17 19:20:00 +0200,
# 		  "sec_type"=>"STK", "currency"=>"USD", "exchange"=>"SMART", 
# 		  "con_id"=>1715006, "expiry"=>"", "strike"=>0.0, "local_symbol"=>"A",
# 		  "multiplier"=>0, "primary_exchange"=>"NYSE"}, 
#       @contract_detail=#<IB::ContractDetail:0x007f3de81ed7c8 
# 		    @attributes={"market_name"=>"A", "trading_class"=>"A", "min_tick"=>0.01,
# 		    "order_types"=>"ACTIVETIM, (...),WHATIF,", 
# 		    "valid_exchanges"=>"SMART,NYSE,CBOE,ISE,CHX,(...)PSX", 
# 		    "price_magnifier"=>1, "under_con_id"=>0, 
# 		    "long_name"=>"AGILENT TECHNOLOGIES INC", "contract_month"=>"",
# 		    "industry"=>"Industrial", "category"=>"Electronics",
# 		    "subcategory"=>"Electronic Measur Instr", "time_zone"=>"EST5EDT",
# 		    "trading_hours"=>"20150417:0400-2000;20150420:0400-2000",
# 		    "liquid_hours"=>"20150417:0930-1600;20150420:0930-1600", 
# 		    "ev_rule"=>0.0, "ev_multiplier"=>"", "sec_id_list"=>{}, 
# 		    "updated_at"=>2015-04-17 19:20:00 +0200, "coupon"=>0.0, 
# 		    "callable"=>false, "puttable"=>false, "convertible"=>false,
# 		    "next_option_partial"=>false}>> 
# 
# 
		def  verify  thread: nil,  &b 
				_verify update: false, thread: thread,  &b  # returns the allocated threads
			end # def

# Verify that the contract is a valid IB::Contract, update the Contract-Object and return it.
#
# Returns nil if the contract could not be verified. 
# 
#	 > s =  Stock.new symbol: 'AA'
#     => #<IB::Stock:0x0000000002626cc0 
#        @attributes={:symbol=>"AA", :con_id=>0, :right=>"", :include_expired=>false, 
#                     :sec_type=>"STK", :currency=>"USD", :exchange=>"SMART"}
#  > sp  = s.verify! &.essential
#     => #<IB::Stock:0x00000000025a3cf8 
#        @attributes={:symbol=>"AA", :con_id=>251962528, :exchange=>"SMART", :currency=>"USD",
#                     :strike=>0.0, :local_symbol=>"AA", :multiplier=>0, :primary_exchange=>"NYSE", 
#                     :trading_class=>"AA", :sec_type=>"STK", :right=>"", :include_expired=>false}
#                   
#  > s =  Stock.new symbol: 'invalid'
#     =>  @attributes={:symbol=>"invalid", :sec_type=>"STK", :currency=>"USD", :exchange=>"SMART"}
#  >  sp  = s.verify! &.essential
#     => nil

			def verify!
				c =  0
				_verify( update: true){| response | c+=1 } # wait for the returned thread to finish
				IB::Connection.logger.error { "Multible Contracts detected during verify!."  } if c > 1
				con_id.to_i < 0 || contract_detail.is_a?(ContractDetail) ? self :  nil
			end

# Resets a Contract to enable a renewed ContractData-Request via Contract#verify
# 
# Standardattributes to reset: :con_id, :last_trading_day, :contract_detail
# 
# Additional Attributes can be specified ie.
# 
# 	e =  IB::Symbols::Futures.es
# 	e.verify! 
# 	e.reset_attributes! :expiry
# 	e.verify!
# 	--> IB::VerifyError (Currency, Exchange, Expiry, Symbol are needed to retrieve Contract,).

			def reset_attributes! *attr
				# modifies the contract
				attr = ( attr +  [:con_id, :last_trading_day ]).uniq
				attr.each{|y| @attributes[y] = nil }
				self.contract_detail =  nil if contract_detail.present?
			end
			# returns a copy of the contract with modifications
			def reset_attributes *attr
				e= essential	
				e.reset_attributes! *attr 
				e
	end


# Receive EOD-Data 
#  
# The Enddate has to be specified (as Date Object)
#
# The Duration can either be specified as Sting " yx D" or as Integer. 
# Altenative a start date can be specified with the :start parameter.
#
# The parameter :what specified the kind of received data: 
			#  Valid values:
      #   :trades, :midpoint, :bid, :ask, :bid_ask,
      #   :historical_volatility, :option_implied_volatility,
      #   :option_volume, :option_open_interest
# 
# The results are available through a block, thus
#  
#     contract =  IB::Symbols.Index.estx.verify!
#		  contract.eod( duration: '10 d' ) do | results |
#		    results.each{ |s| puts s.to_human }
#		  end
#		   
#
#   Symbols::Index::stoxx.verify!.eod( duration: '10 d',  to: Date.today){|y| y.each{|z| puts z.to_human}}
#   <Bar: 2019-04-01 wap 0.0 OHLC 3353.67 3390.98 3353.67 3385.38 trades 1750 vol 0>
#   <Bar: 2019-04-02 wap 0.0 OHLC 3386.18 3402.77 3382.84 3395.7 trades 1729 vol 0>
#   <Bar: 2019-04-03 wap 0.0 OHLC 3399.93 3435.9 3399.93 3435.56 trades 1733 vol 0>
#   <Bar: 2019-04-04 wap 0.0 OHLC 3434.34 3449.44 3425.19 3441.93 trades 1680 vol 0>
#   <Bar: 2019-04-05 wap 0.0 OHLC 3445.05 3453.01 3437.92 3447.47 trades 1677 vol 0>
#   <Bar: 2019-04-08 wap 0.0 OHLC 3446.15 3447.08 3433.47 3438.06 trades 1648 vol 0>
#   <Bar: 2019-04-09 wap 0.0 OHLC 3437.07 3450.69 3416.67 3417.22 trades 1710 vol 0>
#   <Bar: 2019-04-10 wap 0.0 OHLC 3418.36 3435.32 3418.36 3424.65 trades 1670 vol 0>
#   <Bar: 2019-04-11 wap 0.0 OHLC 3430.73 3442.25 3412.15 3435.34 trades 1773 vol 0>
#   <Bar: 2019-04-12 wap 0.0 OHLC 3432.16 3454.77 3425.84 3447.83 trades 1715 vol 0>
	def eod start:nil, to: Date.today, duration: nil , what: :trades 

			tws = IB::Connection.current
			recieved =  Queue.new
			
			tws.subscribe(IB::Messages::Incoming::HistoricalData) do |msg|
				if msg.request_id == con_id
#					msg.results.each { |entry| puts "  #{entry}" }
					yield msg.results if block_given?
				end
					recieved.push Time.now
			end

			duration =  if duration.present?
										duration.is_a?(String) ? duration : duration.to_s + " D"
									elsif start.present?
	 BuisinesDays.business_days_between(start, to).to_s + " D"
									else
										"1 D"
										end

			tws.send_message IB::Messages::Outgoing::RequestHistoricalData.new(
				:request_id => con_id,
				:contract =>  self,
				:end_date_time => to.to_time.to_ib, #  Time.now.to_ib,
				:duration => duration, #    ?
				:bar_size => :day1, #  IB::BAR_SIZES.key(:hour)?
				:what_to_show => what,
				:use_rth => 0,
				:format_date => 2,
				:keep_up_todate => 0)

			Timeout::timeout(50) do   # max 5 sec.
				sleep 0.1 
				last_time =  recieved.pop # blocks until a message is ready on the queue
				loop do
					sleep 0.1
					break if recieved.empty?  # finish if no more data received
				end
			end

		end

# Ask for the Market-Price and store item in IB::Contract.misc
# 
# For valid contracts, either bid/ask or last_price and close_price are transmitted.
# 
# If last_price is recieved, its returned. 
# If not, midpoint (bid+ask/2) is used. Else the closing price will be returned.
# 
# Any  value (even 0.0) which is stored in IB::Contract.misc indicates that the contract is 
# accepted by `place_order`.
# 
# The result can be costomized by a provided block.
# 
# 	IB::Symbols::Stocks.sie.market_price{ |x| puts x.inspect; x[:last] }.to_f
# 	-> {"bid"=>0.10142e3, "ask"=>0.10144e3, "last"=>0.10142e3, "close"=>0.10172e3}
# 	-> 101.42 
# 
# assigns IB::Symbols.sie.misc with the value of the :last (or delayed_last) TickPrice-Message
# and returns this value, too
			def market_price delayed:  true, thread: false

				tws=  Connection.current 		 # get the initialized ib-ruby instance
				the_id =  nil
				tickdata =  Hash.new
				# define requested tick-attributes
				last, close, bid, ask	 = 	[ [ :delayed_last , :last_price ] , [:delayed_close , :close_price ],
																[  :delayed_bid , :bid_price ], [  :delayed_ask , :ask_price ]] 
				request_data_type =  delayed ? :frozen_delayed :  :frozen

				tws.send_message :RequestMarketDataType, :market_data_type =>  IB::MARKET_DATA_TYPES.rassoc( request_data_type).first

				#keep the method-call running until the request finished
				#and cancel subscriptions to the message handler
				# method returns the (running) thread
				th = Thread.new do
					finalize= false
					# subscribe to TickPrices
					s_id = tws.subscribe(:TickSnapshotEnd) { |msg|	finalize = true	if msg.ticker_id == the_id }
					e_id = tws.subscribe(:Alert){|x|  finalize = true if x.code == 354 && x.error_id == the_id } 
					# TWS Error 354: Requested market data is not subscribed.
					sub_id = tws.subscribe(:TickPrice ) do |msg| #, :TickSize,  :TickGeneric, :TickOption) do |msg|
						[last,close,bid,ask].each do |x| 
							tickdata[x] = msg.the_data[:price] if x.include?( IB::TICK_TYPES[ msg.the_data[:tick_type]]) 
							finalize = true if tickdata.size ==4  || ( tickdata[bid].present? && tickdata[ask].present? )  
						end if  msg.ticker_id == the_id 
					end
					# initialize »the_id« that is used to identify the received tick messages
					# by fireing the market data request
					the_id = tws.send_message :RequestMarketData,  contract: self , snapshot: true 

					begin
						# todo implement config-feature to set timeout in configuration   (DRY-Feature)
						Timeout::timeout(5) do   # max 5 sec.
							loop{ break if finalize ; sleep 0.1 } 
							# reduce :close_price delayed_close  to close a.s.o 
							tz = -> (z){ z.map{|y| y.to_s.split('_')}.flatten.count_duplicates.max_by{|k,v| v}.first.to_sym}
							data =  tickdata.map{|x,y| [tz[x],y]}.to_h
							valid_data = ->(d){ !(d.to_i.zero? || d.to_i == -1) }
							self.misc = if block_given? 
														yield data 
														# yields {:bid=>0.10142e3, :ask=>0.10144e3, :last=>0.10142e3, :close=>0.10172e3}
													else # behavior if no block is provided
														if valid_data[data[:last]]
															data[:last] 
														elsif valid_data[data[:bid]]
															(data[:bid]+data[:ask])/2
														elsif data[:close].present? 
															data[:close]
														else
															nil
														end
													end
						end
					rescue Timeout::Error
						Connection.logger.info{ "#{to_human} --> No Marketdata recieved " }
					end
					tws.unsubscribe sub_id, s_id, e_id
				end
				if thread
					th		# return thread
				else
					th.join
					misc	# return 
				end
			end #

# returns the Option Chain of the contract (if available)
#
## parameters
### right:: :call, :put, :straddle
### ref_price::  :request or a numeric value
### sort:: :strike, :expiry 
### exchange:: List of Exchanges to be queried (Blank for all avaialable Exchanges)
		def option_chain ref_price: :request, right: :put, sort: :strike, exchange: ''

			ib =  Connection.current

			## Enable Cashing of Definition-Matrix
			@option_chain_definition ||= [] 

			my_req = nil; finalize= false
			
			# -----------------------------------------------------------------------------------------------------
			# get OptionChainDefinition from IB ( instantiate cashed Hash )
			if @option_chain_definition.blank?
				sub_sdop = ib.subscribe( :SecurityDefinitionOptionParameterEnd ) { |msg| finalize = true if msg.request_id == my_req }
				sub_ocd =  ib.subscribe( :OptionChainDefinition ) do | msg |
					if msg.request_id == my_req
						message =  msg.data
						# transfer the the first record to @option_chain_definition
						if @option_chain_definition.blank?
							@option_chain_definition =  msg.data

						end
							# override @option_chain_definition if a decent combintion of attributes is met
							# us- options:  use the smart dataset
							# other options: prefer options of the default trading class 
							if message[:currency] == 'USD' && message[:exchange] == 'SMART'	 || message[:trading_class] == symbol 
								@option_chain_definition =  msg.data

								finalize = true
							end
						end
					end
					
					verify do | c |
						my_req = ib.send_message :RequestOptionChainDefinition, con_id: c.con_id,
																			symbol: c.symbol,
																			exchange: sec_type == :future ? c.exchange : "", # BOX,CBOE',
																			sec_type: c[:sec_type]
					end

					Thread.new do  

			Timeout::timeout(1, IB::TransmissionError,"OptionChainDefinition not recieved" ) do
						loop{ sleep 0.1; break if finalize } 
			end
						ib.unsubscribe sub_sdop , sub_ocd
					end.join
				else
					Connection.logger.error { "#{to_human} : using cached data" }
				end

			# -----------------------------------------------------------------------------------------------------
			# select values and assign to options
			#
			unless @option_chain_definition.blank? 
				requested_strikes =  if block_given?
															 ref_price = market_price if ref_price == :request
															 if ref_price.nil?
																 ref_price =	 @option_chain_definition[:strikes].min  +
																	 ( @option_chain_definition[:strikes].max -  
																		@option_chain_definition[:strikes].min ) / 2 
																 Connection.logger.error{  "#{to_human} :: market price not set – using midpoint of avaiable strikes instead: #{ref_price.to_f}" }
															 end
															 atm_strike = @option_chain_definition[:strikes].min_by { |x| (x - ref_price).abs }
															 the_grouped_strikes = @option_chain_definition[:strikes].group_by{|e| e <=> atm_strike}	
															 begin
																 the_strikes =		yield the_grouped_strikes
#																 puts "TheStrikes #{the_strikes}"
																 the_strikes.unshift atm_strike unless the_strikes.first == atm_strike	  # the first item is the atm-strike
																 the_strikes
															 rescue
																 Connection.logger.error "#{to_human} :: not enough strikes :#{@option_chain_definition[:strikes].map(&:to_f).join(',')} "
																 []
															 end
														 else
															 @option_chain_definition[:strikes]
														 end

				# third friday of a month
				monthly_expirations =  @option_chain_definition[:expirations].find_all{|y| (15..21).include? y.day }
#				puts @option_chain_definition.inspect
				option_prototype = -> ( ltd, strike ) do 
						IB::Option.new( symbol: symbol, 
													 exchange: @option_chain_definition[:exchange],
													 trading_class: @option_chain_definition[:trading_class],
													 multiplier: @option_chain_definition[:multiplier],
													 currency: currency,  
													 last_trading_day: ltd, 
													 strike: strike, 
													 right: right )
				end
				options_by_expiry = -> ( schema ) do
					# Array: [ mmyy -> Options] prepares for the correct conversion to a Hash
					Hash[  monthly_expirations.map do | l_t_d |
						[  l_t_d.strftime('%m%y').to_i , schema.map{ | strike | option_prototype[ l_t_d, strike ]}.compact ]
					end  ]                         # by Hash[ ]
				end
				options_by_strike = -> ( schema ) do
					Hash[ schema.map do | strike |
						[  strike ,   monthly_expirations.map{ | l_t_d | option_prototype[ l_t_d, strike ]}.compact ]
					end  ]                         # by Hash[ ]
				end

				if sort == :strike
					options_by_strike[ requested_strikes ] 
				else 
					options_by_expiry[ requested_strikes ] 
				end
			else
				Connection.logger.error "#{to_human} ::No Options available"
				nil # return_value
			end
		end  # def

		# return a set of AtTheMoneyOptions
		def atm_options ref_price: :request, right: :put
			option_chain(  right: right, ref_price: ref_price, sort: :expiry) do | chain |
								chain[0]
			end

				
			end

		# return   InTheMoneyOptions
		def itm_options count:  5, right: :put, ref_price: :request, sort: :strike
			option_chain(  right: right,  ref_price: ref_price, sort: sort ) do | chain |
					if right == :put
						above_market_price_strikes = chain[1][0..count-1]
					else
						below_market_price_strikes = chain[-1][-count..-1].reverse
				end # branch
			end
		end		# def

    # return OutOfTheMoneyOptions
		def otm_options count:  5,  right: :put, ref_price: :request, sort: :strike
			option_chain( right: right, ref_price: ref_price, sort: sort ) do | chain |
					if right == :put
						#			puts "Chain: #{chain}"
						below_market_price_strikes = chain[-1][-count..-1].reverse
					else
						above_market_price_strikes = chain[1][0..count-1]
					end
			end
		end


	def associate_ticdata

		tws=  IB::Gateway.tws 		 # get the initialized ib-ruby instance
		the_id =  nil
		finalize= false
		#  switch to delayed data
		tws.send_message :RequestMarketDataType, :market_data_type => :delayed

		s_id = tws.subscribe(:TickSnapshotEnd) { |msg|	finalize = true	if msg.ticker_id == the_id }
				
		sub_id = tws.subscribe(:TickPrice, :TickSize,  :TickGeneric, :TickOption) do |msg|
			    self.bars << msg.the_data if msg.ticker_id == the_id 
			end

		# initialize »the_id« that is used to identify the received tick messages
		# by firing the market data request
		the_id = tws.send_message :RequestMarketData,  contract: self , snapshot: true 

		#keep the method-call running until the request finished
		#and cancel subscriptions to the message handler.
		Thread.new do 
                  i=0; loop{ i+=1; sleep 0.1; break if finalize || i > 1000 }
                  tws.unsubscribe sub_id 
                  tws.unsubscribe s_id
                  puts "#{symbol} data gathered" 
                end  # method returns the (running) thread

	end # def 
######################  private methods 

private

# Base method to verify a contract
# 
# if :thread is given, the method subscribes to messages, fires the request and returns the thread, that 
# receives the exit-condition-message
# 
# otherwise the method waits until the response form tws is processed
# 
# 
# if :update is true, the attributes of the Contract itself are apdated
# 
# otherwise the Contract is untouched
			def _verify thread: nil , update:,  &b # :nodoc:

			ib =  Connection.current
			# we generate a Request-Message-ID on the fly
			message_id = nil #1.times.inject([]) {|r| v = rand(200) until v and not r.include? v; r << v}.pop 			
			# define local vars which are updated within the query-block
			exitcondition, count , queried_contract = false, 0, nil

			# currently the tws-request is suppressed for bags and if the contract_detail-record is present
			tws_request_not_nessesary = bag? || contract_detail.is_a?( ContractDetail )

			if tws_request_not_nessesary
				yield self if block_given?
				count = 1
			else # subscribe to ib-messages and describe what to do
				a = ib.subscribe(:Alert, :ContractData,  :ContractDataEnd) do |msg| 
					case msg
					when Messages::Incoming::Alert
						if msg.code == 200 && msg.error_id == message_id
							ib.logger.error { "Not a valid Contract :: #{self.to_human} " }
							exitcondition = true
						end
					when Messages::Incoming::ContractData
						if msg.request_id.to_i == message_id
							# if multible contracts are present, all of them are assigned
							# Only the last contract is saved in self;  'count' is incremented
							count +=1
							## a specified block gets the contract_object on any uniq ContractData-Event
							if block_given?
								yield msg.contract
							elsif count > 1 
								queried_contract = msg.contract  # used by the logger (below) in case of mulible contracts
							end
							if update
								self.attributes = msg.contract.attributes
								self.contract_detail = msg.contract_detail unless msg.contract_detail.nil?
							end
						end
					when Messages::Incoming::ContractDataEnd
						exitcondition = true if msg.request_id.to_i ==  message_id

					end  # case
				end # subscribe

				### send the request !
				contract_to_be_queried =  con_id.present? ? self : query_contract  
				# if no con_id is present,  the given attributes are checked by query_contract
				if contract_to_be_queried.present?   # is nil if query_contract fails
					message_id = ib.send_message :RequestContractData, :contract => contract_to_be_queried 
					
					th =  Thread.new do
						begin
							Timeout::timeout(1) do
								loop{ break if exitcondition ; sleep 0.005 } 
							end
						rescue Timeout::Error
							Connection.logger.error{ "#{to_human} --> No ContractData recieved " }
						end
						ib.unsubscribe a
					end
					if thread.nil?
						th.join    # wait for the thread to finish
						count			 # return count
					else
						th			# return active thread
					end
				else
					ib.logger.error { "Not a valid Contract-spezification, #{self.to_human}" }
				end
			end
			end

# Generates an IB::Contract with the required attributes to retrieve a unique contract from the TWS
# 
# Background: If the tws is queried with a »complete« IB::Contract, it fails occacionally.
# So – even to update its contents, a defined subset of query-parameters  has to be used.
# 
# The required data-fields are stored in a yaml-file and fetched by #YmlFile.
# 
# If `con_id` is present, only `con_id` and `exchange` are transmitted to the tws.
# Otherwise a IB::Stock, IB::Option, IB::Future or IB::Forex-Object with necessary attributes
# to query the tws is build (and returned)
# 
# If Attributes are missing, an IB::VerifyError is fired,
# This can be trapped with 
#   rescue IB::VerifyError do ...
	
    def  query_contract( invalid_record: true )  # :nodoc:
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
			nessesary_items = YAML.load_file(yml_file)[sec_type]
      ## now lets proceed, but only if no con_id is present
			if con_id.blank?
				if item_values[nessesary_items].any?( &:nil? ) 
					 raise VerifyError, "#{items_as_string[nessesary_items]} are needed to retrieve Contract,
																	got: #{item_values[nessesary_items].join(',')}"
				end
				Contract.build  item_attributehash[nessesary_items].merge(:sec_type=> sec_type)  # return this
			else   # its always possible, to retrieve a Contract if con_id and exchange are present 
				 Contract.new  con_id: con_id , :exchange => exchange.presence || item_attributehash[nessesary_items][:exchange].presence || 'SMART'				# return this
			end  # if 
    end # def
		end # class




end # module
