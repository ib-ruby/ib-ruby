#! /usr/bin/ruby
## -----------------------------------------------------------------------------------------------------------------------------------
#  ohlcTicker.rb		client-for ib-ticker
#
#	.ohlcTicker.rb  connects to 'ib-ticker'  running on port 33810 on localhost 
# 	and saves the data according to the following command line parameter
#		* --mysql	-> saves data in mysql-tables
#		* --file			-> saves data in  [ib_symbol].ohlc  files in the current directory
#  	* --type	[file, mysql, remote]	-> sets the output-Mode directly 
#      *  stock 	one stock out of stocks.yaml (name and alias-entrys are supported) 
#		* 	contract	 [mmyy] month and year either as string or as number e.g. 305, 1204 
#								(uses default of stocks.yaml if omitted or not suitable) 
#		all command-parameters are optional.
#
#	Example:
#		ruby ohlcTicker.rb --file --resolution 10m dax 605 stoxx 605
# 	saves 10 min. ohlc-records to FESX JUN 05.ohlc and FDAX JUN 05.ohlc
#
#		DefaultValue of 	--type is 'remote', 
#										--resolution is '1m' (1 Minute)
#		The default-stocks are noted in the branch starting at row 145:
##			 if furtherArguments.empty?
##					[ 'stoxx', 'bund', 'bobl', 'dax'].each do |fut|
##				 		[605].each do |contract|	

#
# a demo-version of the tws is available here
# http://interactivebrokers.com/cgi-pub/jtslink.pl?user_name=edemo
#
=begin
Copyright (C)  2005, Dr. Hartmut Bischoff <h.bischoff@topofocus.de>
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

require 'drb'
require 'stock'
require 'drb/observer'
#require 'observer'
require 'ohlc'
require 'mysql_class'
=begin rdoc
Basis- OHLC-Tticker-Klasse

Stellt die Verbindug zu ib_ticker (port 33810 oder gem‰ﬂ --port KommandoParameter) her und 
registriert sich dort als Observator. 

Die Methode 'update' wird bei jedem "changed" Ereignis aufgerufen.
Sie erh‰lt die TickDaten als Parameter

RemoteTicker stellt die OHLC-Objekte auf dem Bildschirm dar.
=end
class PureRemoteTicker
		include DRb::DRbUndumped
		def initialize(s,server)
			@stock=s
			x=server.connectTicker(s)
			x.add_observer(self)
		end
		
		
		def update(*args)
			puts " #{@stock.name}"
		#	pp ohlc
			p args.inspect
		#	print ohlc.printCSV( 'open', 'high', 'low', 'close' ){ |date1,date2| date1.strftime( "%H:%M:%S ") + '-- ' + date2.strftime( "%M:%S ")}
		end
		
end
=begin rdoc

‹berschreibt die 'update'-Methode von RemoteTicker.

Die Tickdaten werden nun in der zugeordneten mysql-Tabelle gespeichert.

=end
class PureMysqlTicker < PureRemoteTicker
		def initialize(stock, server)
			super(stock, server)
			# check wether the database exists
			vorkomma=Math::log10(@stock.tickRange["max"]).round + Math::log10(@stock.tickSize).round.abs
			nachkomma=Math::log10(@stock.tickSize) < 0  ? Math::log10(@stock.tickSize).round.abs : 0  
			db=SQLquery.new("show tables like '#{@stock.getDatabaseName}'")
			if db.getRowCount==0
				SQLquery.new("ib","CREATE TABLE #{@stock.getDatabaseName }  (
									id int( 10 ) unsigned NOT NULL AUTO_INCREMENT ,
									date datetime NOT NULL default '0000-00-00 00:00:00',
									price  decimal( #{vorkomma},#{nachkomma} ) NOT NULL default '0',
									volume mediumint( 9 ) NOT NULL default '0',
									PRIMARY KEY ( `id` ) ,
									KEY `date` ( `date` )
									) TYPE = MYISAM COMMENT = 'IndexFuture-Table';
								")
				puts "database table created"
			end
		end
		
		def update(time, price, size)
					ins= [time.strftime( "%Y-%m-%d %H:%M:%S"), price, size]
  					ins.collect!{|x| "'"+x.to_s+"'"}
					id=SQLquery.new("insert into #{@stock.getDatabaseName } ( date, price, volume ) values (#{ins.join(',')}) "){|resultSet| resultSet.insert_id}.getResult
					puts "traded  #{size} contracts @ #{price} of #{@stock.name} --> #{@stock.getDatabaseName } with id #{id}"
		end
	end

	class PureFileTicker < PureRemoteTicker
				
			def update(*args)	
				File.open("#{@stock.ibSymbol}.ohlc",'a') do |thisFile| 
					$,=","
# debug					print ohlc.printCSV
					thisFile.print args.join(",")
				end
			end
	end
# ------------------------------------------ standalone code ----------------------------------------------
 if $0 == __FILE__
require 'optparse'

		def connectNow(s,server,type)	
				puts ' '
				puts " requesting ticker data for	 #{s.ibSymbol}	"
				puts ' '
				
				begin
					case type
						when 'mysql'
							ticker=PureMysqlTicker.new(s,server)
			
						when 'file'
							ticker=PureFileTicker.new(s,server)
				
						else
						ticker=PureRemoteTicker.new(s,server)
					end
			
				rescue  StandardError
  					$stderr.print " drb failed: \n\n --------------------------------------------------\n no connection to the server\n"
					$stderr.print " --------------------------------------------------\n"
					$stderr.print " please start the server (ib_ticker.rb) \n"
					$stderr.print " and restart #{$0}\n \n errorCode:\n #{$!} \n\n\n"
				 	raise SystemError
				end
			[ticker]		# returnValue
		end
opts= OptionParser.new

 	host='localhost'
	port=33810
	type='nothingl'
	res='1m'
opts.on('-p' , '--port PORT' , Integer ){  |val| port=val }
opts.on('-h' , '--host HOST ' , String ){  |val| host=val }
opts.on('-t', '--type TYPE', String) {|val| type=val }
opts.on('--file'){ type='file'}
opts.on('--mysql' ){ type='mysql'}
furtherArguments=opts.parse(ARGV)

require 'pp'
	
	puts '------------------------------------------------------------------------------------------'
	puts ' trying to allocate a Drb-Connection		'	
	puts'------------------------------------------------------------------------------------------'
	DRb.start_service
	tickerArray=Array.new
	server=DRbObject.new(nil,"druby://#{host}:#{port}")
	if furtherArguments.empty?
		[ 'stoxx', 'bund', 'bobl', 'dax',  'es', 'dow', 'russel'].each do |fut|
	 		[905,1205].each do |contract|	
				s=Stock.new(fut)
				s.contract =contract
					tickerArray.push(connectNow(s,server,type))
			 end
		end 
	else
		until furtherArguments.empty? do
		s=Stock.new(furtherArguments.shift)
		s.contract = furtherArguments.shift  unless furtherArguments.empty?
		s.resolution=res
		tickerArray.push(connectNow(s,server,type))
		end
	end

	puts' ------------------------------------------------------------------------------------------'
	puts'  done'
	puts''
	puts' print <enter> to stop all ticker'
	$stdin.readline()
	puts' ------------------------------------------------------------------------------------------'
	puts'  removing the observer  from the tickerServer'
	puts' ------------------------------------------------------------------------------------------'
	  
#	tickerArray.each{|x| x.first.delete_observer(x.last)}
end
