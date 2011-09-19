#! /usr/bin/ruby 
# -----------------------------------------------------------------------------------------------------------------------------------
#  ib_ticker.rb		client-server access to the realtime datastream of interactive-brokers
#
# usage:
#	./ib-ticker.rb  starts the ib-tws-server in client-Server-Mode
#.	./ib-ticker.rb host starts the ib-tws-server in local mode and performs some tests
#              set  host to 'localhost'  or the name of the computer running the tws
#
# use remoteTicker.rb to connect to the server
#
#a demo-version of the tws is available here
# http://interactivebrokers.com/cgi-pub/jtslink.pl?user_name=edemo
=begin
Copyright (C)  2004, Dr. Hartmut Bischoff <h.bischoff@topofocus.de>
All Rights Reserved.

Redistribution and use in source and binary forms, with or without
modification, are permitted provided that the following conditions are met:

    Redistributions of source code must retain the above copyright notice,
    this list of conditions and the following disclaimer. 

    Redistributions in binary form must reproduce the above copyright
    notice, this list of conditions and the following disclaimer in the
    documentation and/or other materials provided with the distribution. 

    The name of Hartmut Bischoff may not be used to endorse or promote products
    derived from this software without specific prior written permission.

THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE
LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN
CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
POSSIBILITY OF SUCH DAMAGE.
=end
require "socket"
require 'stock'

require 'drb/drb'
require 'drb/observer'


# set constant
#TWS_HOST= ARGV.shift ||  'localhost' 

module IbMessages	 # :nodoc:
	include Observable 

	# returns either the index of the string in [code] (message is a sting or a symbol)
	# or the associated string (message is a integer)	
	def decodeMessage(code,message)   # :nodoc:
		if message.is_a?(Integer) 
			 	code[message].to_s.downcase 	 if message<=code.size
		elsif message.is_a?(String)
			code.index(message.upcase.to_sym)
		elsif message.is_a?(Symbol)
			code.index(message)
		else
			"unknown"
		end	
	end
	def tickerMessage(message)   # :nodoc:
	
		code=[	 :BID_SIZE, :BID_PRICE, :ASK_PRICE, :ASK_SIZE, :LAST_PRICE, :LAST_SIZE, :HIGH_PRICE,
					 :LOW_PRICE, :VOLUME_SIZE, :CLOSE_PRICE ]
		decodeMessage(code,message)			 
	end
	# Incoming message ids
	def twsMessage(message)   # :nodoc:

		code= ['', :TICK_PRICE, :TICK_SIZE, :ORDER_STATUS, :ERR_MSG, :OPEN_ORDER, :ACCT_VALUE,
					 :PORTFOLIO_VALUE, :ACCT_UPDATE_TIME, :NEXT_VALID_ID, :CONTRACT_DATA,
 					:EXECUTION_DATA, :MARKET_DEPTH, :MARKET_DEPTH_L2, :NEWS_BULLETINS, :MANAGED_ACCTS]
		decodeMessage(code,message)
	end
	

	# Outgoing message ids
	def twsRequestCode(message)		 # :nodoc:
		code=[ '', :REQ_MKT_DATA, :CANCEL_MKT_DATA, :PLACE_ORDER, :CANCEL_ORDER,
 					:REQ_OPEN_ORDERS, :REQ_ACCOUNT_DATA, :REQ_EXECUTIONS, :REQ_IDS,
 					:REQ_CONTRACT_DATA, :REQ_MKT_DEPTH, :CANCEL_MKT_DEPTH,
 					:REQ_NEWS_BULLETINS, :CANCEL_NEWS_BULLETINS, :SET_SERVER_LOGLEVEL,
 					:REQ_AUTO_OPEN_ORDERS, :REQ_ALL_OPEN_ORDERS, :REQ_MANAGED_ACCTS ]
		
		decodeMessage(code,message)
		
	end

=begin  rdoc
Reaktion auf <em>tick_size</em>-Events

Die registrierten Programme erhalten ein Hash mit folgenden Einträgen:
		:version	=>
		:tickerID	=>
	{Art des Events}:BID_SIZE, :ASK_SIZE, etc  =>
	
Das <em>tick_size>/em> Signal führt auf jeden Fall zu einer Benachrichtigung an die angeschlossenen Programme
=end	
	 def on_tick_size
	#	puts "\n----          tick_size-Signal !   ------------- "
		changed
		notify_observers({	:version  => readMessage.to_i ,		
		 							:tickerID=> readMessage.to_i ,
									tickerMessage(readMessage.to_i).to_sym =>readMessage.to_i } )
	 end
	 
=begin rdoc
Reaktion auf <em>tick_price<</em> Events

Es wird ein Hash mit
	:price => tickPrice
	:ibOrderID => orderID
zurückgegeben (Falls eine Orderbestätgung übermittelt wird) oder die angeschlossenen Programme erhalten ein Hash mit folgenden Einträgen
		:version	=>
		:tickerID	=>
	{Art des Events}:BID_PRICE, :ASK_PRICE, etc  =>
(TickerEvents)
=end
	 def on_tick_price
	#puts "\n----          tick_price-Signal !   ------------- "
	if  getExecutionStatus
			tickPrice=readMessage.to_f
			ibOrderID =readMessage.to_i
			a=[ :price => tickPrice, :ibOrderID => ibOrderID]
		else
		changed
		notify_observers(	{	:version  => readMessage.to_i ,		
										:tickerID => readMessage.to_i ,
										tickerMessage(readMessage.to_i).to_sym =>readMessage.to_f }	)
		end
	end
	 
	 def on_order_status  # :nodoc:
	 #puts "\n----          orderStatus-Signal !   ------------- "
	 if getExecutionStatus
	 a=	[ 	:orderID => readMessage.to_i,
			:stock =>readMessage,
			:kind =>readMessage,
			:expires=>readMessage,
			:u =>readMessage,
			:uu =>readMessage,
			:exchange=>readMessage,
			:currency=>readMessage,
			:contract=>readMessage,
			:extOrderID=>readMessage,
			:executionTime=>readMessage,
			:code=>readMessage,
			:exchange2=>readMessage,
			:buyOrSell=>readMessage
			] #.merge(rercieveTwsMessage)
		 end 
	 end
	 
=begin rdoc
Fehlermeldungen der TWS werden auf STDOUT ausgegeben
=end
	 def on_err_msg
	 puts "\n----          err_msg-Signal !   ------------- "
	 puts "ib-Version : #{readMessage}"
	 puts "ib-ErorID: #{readMessage}"
	 puts "Message: #{readMessage} "
	 end
	 
	 def on_open_order   # :nodoc:
	    puts "\n----          openOrder-Signal       -------------  "
		puts "actualOrderID: #{readMessage} "
		puts "status:  #{readMessage} "
		puts "unknownID:  #{readMessage} "	
		puts "Nr_of_Contracts:  #{readMessage} "	
		puts "Price:  #{readMessage} "	
		puts "ibOrderID:  #{readMessage} "	
		puts "unknownID:  #{readMessage} "	
		puts "otherPrice:  #{readMessage} "	
		
		
		
	 end
	 
	 def on_acct_value  # :nodoc:
	 	    puts "\n----          acount Value-Signal       -------------  "
			puts " ibVersion: #{readMessage} "
	 end
	 
	 def on_portfolio_value   # :nodoc:
	 puts "\n----          portfolio Value-Signal       -------------  "
			puts " ibVersion: #{readMessage} "
	 end
	 
	 def  on_next_valid_id   # :nodoc:
	 puts "\n----          next valid ID-Signal       -------------  "
			puts " ibVersion: #{readMessage} "
	 end
	 
	 def on_contract_data   # :nodoc:
	  puts "\n----          contract_data-Signal !   ------------- "
	 end
	 
	 def on_execution_data   # :nodoc:
	 puts "\n----          execution_data-Signal !   ------------- "
	 setExecutionStatus
	 executionData=recieveTwsMessage
	 p executionData
	 resetExecutionStatus
	 end
	 
	
end

module IbOrder		 # :nodoc:
	def orderInitialize(orderID=0)
		# orderID can only initialized once
		@orderID ||=orderID
		@excecutionStatus=false
	end
	def setExecutionStatus
		@excecutionStatus=true
	end
	def resetExecutionStatus
		@excecutionStatus=false
	end
	def getExecutionStatus
		@excecutionStatus||=false
	end
	def getOrderID
		@orderID
	end
	
	def increaseOrderID
		@orderID+=1
	end
	
	def isNewOrder?(orderID)
		 @orderId==orderId
	end
		
	def inhibitOrders
		@orderID=-1
	end
	
	def orderStatus
		if @orderID <0 
			status="not_active"
		elsif @orderID==0
			status="initializing"
		else
			status="ok"
		end
	end
end


class TWS 	# :nodoc:
	include IbMessages
	include IbOrder

		
	def initialize
		clientVersion=8
		@serverVersion=0
		port=7496
		@termStr=" "; @termStr[0]=0		# erzeugt einen string mit hex-0 als Inhalt
		@clientId=0
		@tickerId=0
		loop do
			@s= TCPsocket.open(TWS_HOST,port)  # open tws-port
			sendMessage clientVersion
			@serverVersion=self.readMessage.to_i
			sendMessage @clientId
			break if twsMessage(twsM=self.readMessage.to_i)=~ /valid/ 
			puts " got  #{twsMessage(twsM)}  from tws "
			puts "                  .... trying to increase the clientID ...."
			puts "                  .... and disabling the automatic order placing .... "
			puts "          however, it it possible to recieve tickerData with this client!"
			@clientId+=1
			@s.close		
			orderInitialize(-1)
		end
		@tickerID=self.readMessage.to_i	
		orderInitialize self.readMessage.to_i
		
		# initialize the input-queue
		Thread.new(self){|reader| 
			loop do 
				m=reader.recieveTwsMessage
					p m unless m.nil? || m.is_a?(FalseClass)
			end
			}
		#puts "sendClientID (#{@clientId}) answer: #{self.readMessage} "
	end
			
		def sendMessage(message)
		
		if message.is_a?(Array)
			message.each{|x| @s.printf "%s%s",x.to_s,@termStr }
			puts "tws-Message: #{message.join(' | ')} |"
		else
		puts "tws-Message: #{message}"
		#	@s.printf "%s%s", message.to_s,@termStr
		@s.send(message.to_s<<@termStr,0)
		end
	end
		
	def readMessage
		answer=''
		loop do
			lastChar=@s.recv(1)
			break if lastChar[0]==0
			answer+=lastChar
		end
	#	print "readMessage ...#{answer} ..."
		answer
	end
	def recieveTwsMessage
	
			message=self.readMessage
				#	print "recieveTwsMessage: #{message} ... #{twsMessage message.to_i}"
			if twsMessage(message.to_i).is_a?(String) && self.respond_to?("on_#{twsMessage(message.to_i)}")		
				# check wether a method "twsMessage.." exists
				message=self.send("on_#{twsMessage(message.to_i)}" )
				end
			message
	end
	
	def getAPIversion
			@serverVersion
	end
	
	def closeTWS
		@s.close
	end	
end

class Ticker < Stock
	include IbMessages
	include DRb::DRbObservable 
	include DRb::DRbUndumped
	@@tickerID=0
	@@tickerInstance={}
	@@tws=nil
=begin rdoc
Konstruktor-Methode mit einfachem Caching-Algorithmus

Es wird ein Ticker mit den aktuellen Eigenschaften den übergebenen Stock-Objekts erzeugt
=end     
	 def Ticker.getInstance(stock) 
         tickerVersion=2 
        #  start only one instance of the tws-server
		@@tws =TWS.new	 if @@tws.nil?
		tmpStock = Stock.new(stock)
		if @@tickerInstance.include?(tmpStock.ibSymbol)
			puts "reusing saved tickerInstance" 
			obj = @@tickerInstance[tmpStock.ibSymbol]
		else 
		     obj = Ticker.new(tmpStock)
		end 
		obj
     end 
  
 # initialize is called from getInstance
 def initialize(stock)
		# @@tickerID , @@tickerInstance and @@tws are initalized in Ticker#getInstance
		tickerVersion=2
		super(stock)
		@thisTickerID=@@tickerID			# identifies the current ticker
		@data=Hash.new
		@file=nil
		@last=Hash.new
		@@tickerInstance[ ibSymbol] = self
		@@tws.sendMessage [twsRequestCode("req_mkt_data" ), tickerVersion , @@tickerID ]+ibTicker
		@@tws.add_observer(self) 
		@@tickerID+=1
	
		end
#removes all tickers   (only needed if the max of connections to the tws is reached)		
	def stopTicker
		if count_observers>0
			puts " ----------------------------------------------------------------------------------------------------------"
			puts " #{count_observers} clients are currently connected "
			puts " "
			puts " disconnect them ? (y/n)"
			return false unless readline()=~/y/
		end
		@@tws.sendMessage [ twsRequestCode("CANCEL_MKT_DATA"), 1, @thisTickerID] 
		return true
     end

def  stopAllTicker
		ok=true
		@@tickerInstance.each{ |x,y|  	t= y.stopTicker ; ok=t unless ok} 
		@@tws.closeTWS if ok
		ok  # return false if the tws is not disconnected
		end
		
		
# called by TWS if a ticker-event is detected
	def update (ibData)
	
		if ibData.is_a?(Hash) && ibData[ :tickerID ].to_i==@thisTickerID
			ibData.delete( :version )
			ibData.delete( :tickerID )
			@data.update(ibData)
			# alle Size-Events werden gespeichert.
			# Wenn ein Price-Event ohne Positionsänderung eintritt, dann wird dies nicht registriert
			# Alternative: Prüfen, ob innerhalb einer timeOut-Zeit ein SizeEvent gesendet wird.
			##			wenn dies nicht der Fall ist, auch
			if ibData.has_key?( :last_price )
				doAction if @last[:event]=="price"
				@last[:price]=ibData[ :last_price ]
				@last[:event]='price'
				@last[:time]=Time.now
			#	print "price:  #{@last.values.join(" --  ")} \n"
			elsif ibData.has_key?( :last_size )
					@last[:size]=ibData[ :last_size ]
					@last[:event]='size'
					@last[:time]=Time.now
					doAction	
			end	
		end
	end
	
# called from update
	def doAction
		#	print "ticker: #{name} --> #{ @last.values.join(" --  ")} --> #{@file} \n";
			print "allocated observers: #{count_observers} \n"
			print "ticker: #{name} --> #{ @last.values.join(" --  ")} \n";
	
			changed
			notify_observers(@last[:time],@last[:price], @last[:size] )
		end
			
			
		def testMethod  # :nodoc:
			puts "here ticker-testMethod"
		end
end

class DRbTicker
	include DRb::DRbObservable 
	include DRb::DRbUndumped

	def connectTicker(stock)
		Ticker.getInstance(stock)  #{setHost host }
	end
	

	def testMethod
			puts "here drBticker-testMethod"
		end
end

	

# ------------------------------------------ standalone code ----------------------------------------------
 if $0 == __FILE__
# require 'optparse'
  host=`hostname`.strip
  port=33810
#  opts= OptionParser.new
#	opts.on('-p' , '--port PORT' , Integer ){  |val| port=val }
#	opts.on('-h' , '--ost HOST ' , String ){  |val| host=val }
#	 furtherArguments=opts.parse(ARGV)

	# set constant
	TWS_HOST= ARGV.shift ||  'localhost' 

 	DRb.start_service("druby://#{host}:#{port}",DRbTicker.new)
 	puts "URI of DRb-Service : #{DRb.uri}"
	DRb.thread.join
 
  
	
end
