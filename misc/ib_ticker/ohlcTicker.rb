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

require 'drb'
require 'stock'
require 'drb/observer'
require 'ohlc'
require 'ohlcRecord'
require 'mysql_class'
=begin rdoc
Basis- OHLC-Tticker-Klasse

Stellt die Verbindug zu ib_ticker (port 33810 oder gemäß --port KommandoParameter) her und 
registriert sich dort als Observator. 

Die Methode 'update' wird bei jedem "changed" Ereignis aufgerufen.
Sie erhält den jeweils fertiggestellten OHLC-Objekt als Parameter.

RemoteTicker stellt die OHLC-Objekte auf dem Bildschirm dar.
=end
class RemoteTicker
		include DRb::DRbUndumped
		def initialize(s,server)
			@stock=s
			@ohlcRecord=OHLCrecord.new s
			x=server.connectTicker(s)
			x.add_observer(self)
			output
		end
		def output
					@ohlcRecord.on_ohlc_ready do
				| ohlc |
				print "%6s" % @stock.name, '-->', ohlc.to_s,"\n"
				end

		end
		def update *args
		#	debug # puts " RemoteTicker#update: recieved tickData for stock  #{@stock.name}"
			@ohlcRecord.accumulateTicks *args
		end
		
end
=begin rdoc

Überschreibt die 'update'-Methode von RemoteTicker.

Die OHLC-Objekte werden nun in der zugeordneten mysql-Tabelle gespeichert.

=end
class MysqlTicker < RemoteTicker
	def initialize(s,server)
			super(s,server)
			# check wether the datbase exists
			db=SQLquery.new("ohlc","show tables like 'ib_#{@stock.getDatabaseName}'")
			if db.getRowCount==0
				vorkomma=Math::log10(s.tickRange["max"]).round + Math::log10(s.tickSize).round.abs
				nachkomma=Math::log10(s.tickSize) < 0  ? Math::log10(s.tickSize).round.abs : 0  
				SQLquery.new('ohlc',	"CREATE TABLE ib_#{s.getDatabaseName }  (
									id int( 10 ) unsigned NOT NULL AUTO_INCREMENT ,
									date datetime NOT NULL default '0000-00-00 00:00:00',
									open decimal( #{vorkomma},#{nachkomma} ) NOT NULL default '0',
									high decimal( #{vorkomma},#{nachkomma} ) NOT NULL default '0',
									low decimal( #{vorkomma},#{nachkomma} ) NOT NULL default '0',
									close decimal( #{vorkomma},#{nachkomma} ) NOT NULL default '0',			
									price  decimal( #{vorkomma+2},#{nachkomma+2} ) NOT NULL default '0',
									volume mediumint( 9 ) NOT NULL default '0',
									PRIMARY KEY ( `id` ) ,
									KEY `date` ( `date` )
									) TYPE = MYISAM COMMENT = 'ohlc-IndexFuture-Table';
				
								")
				puts "database table created"
			end
		end

		def output
			@ohlcRecord.on_ohlc_ready do
				| ohlc |
					id= 'z' #SQLquery.new("ohlc", ohlc.mysqlInsertString("ib_#{@stock.getDatabaseName} ")){|resultSet| resultSet.insert_id}.getResult
					puts "#{ohlc.openDate.strftime( "%H:%M:%S")} -- #{ohlc.date.strftime( "%H:%M:%S")}  traded  #{ohlc["volume"]} contracts @ #{ohlc.close} of #{@stock.name} --> ib_#{@stock.getDatabaseName }  with id #{id}"
			end
		end
		
	end
=begin	

Überschreibt die 'update'-Methode von RemoteTicker.

Die OHLC-Objekte werden in eine Datei gesichert..

=end
	class FileTicker < RemoteTicker
				
		def output
			@ohlcRecord.on_ohlc_ready do
				|ohlc|
				File.open("#{@stock.ibSymbol}.ohlc",'a') do |thisFile| 
					$,=","
					print ohlc.printCSV
					thisFile.print ohlc.printCSV
				end
			end
		end
	end
# ------------------------------------------ standalone code ----------------------------------------------
 if $0 == __FILE__
require 'optparse'

Version = "1.2"
repeat = 1
#  default-values
 	host='localhost'
	port=33810
	type='nothing'
	res='1m'

	ARGV.options do |o|
		o.banner = "Usage: ohlcTicker.rb [options] [ stocks ]"
		o.separator( 'Connectes via "ib-ticker"  to  ib\'s tws.' )
		o.separator( "" )
		
		o.on( "-p", "--port PORT", Integer, "specify a Port to connect to the ib-ticker ( default: #{port})." ) { |p|   port = p }
		o.on('-h' , '--host HOST ' , String, "specity the location of the running ib-ticker (default: #{host}). " ){  |val| host=val }
		o.on('-t', '--type TYPE', String, "specify the type of Destination: mysql, file or screen.") {|val| type=val }
		o.on('-r', '--resolution RES',String, "specify the OHLC-resolution (Fomat: 1m, 1h, 1d)."){|val| res=val}
		o.on('--file', 'shortcut for  "--type file " ' ){ type='file'}
		o.on('--mysql','shortcut for  "--type mysql " '   ){ type='mysql'}
		o.on_tail("-?", "--help", "this help message." ){    puts o;     exit }
		o.on_tail("--version", "Show version") do
			puts o.ver
			puts "Written by Dr. Hartmut Bischoff"
			puts ""
			puts "Copyright (C) 2005 topofocus, stuttgart, germany"
			puts "This is free software; see the source for copying conditions."
			puts "There is NO warranty; not even for MERCHANTABILITY or"
			puts "FITNESS FOR A PARTICULAR PURPOSE."
			exit
		end
	end
  


		def connectNow(s,server,type)	
				puts ' '
				puts " requesting ticker data for	 #{s.ibSymbol}	"
				puts ' '
				
				begin
					case type
						when 'mysql'
							ticker=MysqlTicker.new(s,server)
			
						when 'file'
							ticker=FileTicker.new(s,server)
				
						else
						ticker=RemoteTicker.new(s,server)
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
#opts= OptionParser.new
#

#require 'pp'
	 ARGV.parse!

	puts '------------------------------------------------------------------------------------------'
	puts ' trying to allocate a Drb-Connection		'	
	puts'------------------------------------------------------------------------------------------'
	DRb.start_service
	tickerArray=Array.new
	server=DRbObject.new(nil,"druby://#{host}:#{port}")
	if ARGV.empty?
		[ 'stoxx', 'bund', 'bobl', 'dax','es','dow','russel'].each do |fut|
	 		[905,1205].each do |contract|
				s=Stock.new(fut)
				s.contract =contract
				s.resolution = res
				tickerArray.push(connectNow(s,server,type))
			 end
		end 
	else
		until ARGV.empty? do
		s=Stock.new(ARGV.shift)
	#	s.contract = furtherArguments.shift  unless furtherArguments.empty?
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
