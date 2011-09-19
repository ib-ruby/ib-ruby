
# Die Klasse Stock ist die MutterKlasse für Chart, Account und Ticker.
=begin rdoc
==Modul IB_Definitions

Die Methoden dieses Moduls bündeln den Zugang zu den ib-spezifischen Einstellungen 

Aus der yaml-Datei werden folgende Daten verarbeitet:
 160 ib:
 161  underlying: gbm			<--- Hier Eintrag der TWS im Underlying-Modus eintragen
 162  symbol:  fgbm			<--- Hier den konstanten Teil aus dem Symbol-Modus eintragen
 163  exchange: dtb			<--- Die Börse 
 164  contract: 305			<--- Das ist der default-Kontrakt. 
 165  backtestintervall: [ 1203, 304 , 604 , 904, 1204 ]

=end
module IB_Definitions	
	
	def getDatabaseName
		sprintf("%s%04d",@stock["name"],@stock["ib"]["contract"])
	end
	# Reflektiert den Yaml-eintrag unter 'ib' + 'exchange'
		def ibExchange
		@stock["ib"]["exchange"].upcase
	end	
	# Reflektiert den Yaml-eintrag unter 'ib' + 'underlying'
	def ibUnderlying
			@stock["ib"]["underlying"].upcase 
	end

	def contract= (thiscontract)
		@stock["ib"]["contract"]= checkContract(thiscontract)  unless thiscontract==0
	end
	def contract
		@stock["ib"]["contract"]
	end
=begin rdoc
setzt aus +contract+ und +symbol+ ein gültiges <em>ib_symbol</em> zusammen.
====Symbolumsetzung
ibExchange = DTB:: Yaml-Eintrag für 'symbol'+ Monat+Jahr : z.B. FGBL MAR05
ibExchange = CME, GLOBEX, CFE:: Yaml-Eintrag für 'symbol' + Monatsabkürzung  + Jahr : z.B. ES2H5 
=end
require 'pp'
	def ibSymbol
			contractTime=Time.mktime(@stock["ib"]["contract"].to_s[-2..-1].to_i,@stock["ib"]["contract"].to_s[0..-3].to_i)
								# mktime: year, month
			ibS= case ibExchange
				when 'DTB' , 'ECBOT'
						@stock["ib"]["symbol"]+contractTime.strftime(" %b %y")				# generate symbol
				when 'GLOBEX', 'CME', 'CFE' , 'MONEP'
						contract={ 3 => "H", 6 => "M", 9 => "U" , 12 => "Z"}
						@stock["ib"]["symbol"]+contract[contractTime.month]+contractTime.strftime("%Y")[3..3]
			end
		ibS.upcase																						# return value
	end
	
=begin rdoc
Liefert ein ib-Ticker-Request-String als Array

=end
	def ibTicker(contr=0)
		self.contract =contr
		[ibUnderlying, 'FUT' ,'', 0,'',ibExchange,"",ibSymbol]
	end
	
end

class String	# :nodoc:
=begin rdoc
Strings können auch  über String.name angesprochen werden. 
Damit ist es unerheblich, ob ein String oder  ein Stock-Objekt an Objekte übergeben wird, und eine Methode auf den Nammen zurückgreifen will.
=end
	def name
		self
	end
end
=begin rdoc
Die Klasse Stock ist die MutterKlasse für Chart, Account und Ticker.

In der Datei <em>stocks.yaml</em> sind die Default-Einstellungen für  die handelbaren Futures zusammengefasst.
Diese Yaml-Datei wird für die Initialisierung des Stock-Objekts herangezogen.

Die Daten werden in ein Hash (Stock.stock) eingelesen.

Stock bietet einen kontrollierten Zugriff auf die eingelesenen BasisDaten.


=end
class Stock	
	
	require 'yaml'
	require 'stdExt'
	include IB_Definitions
	attr_reader :stock
	FILENAME = 'stocks.yaml'
=begin rdoc
Auch ohne vorherige Initialisierung des Stock-Objekts können mit
Stock#availableStocks die verfügbaren Stocks ausgelesen werden

====Beispiel
pp Stock.availableStocks
 ["dax", "stoxx", "smi", "bund", "bobl", "russel2000_", "end"]

pp Stock.availableStocks('alias')
 gibt eine Liste der verfügbaren Aliase aus
 
=end	
	def Stock.availableStocks(attribut='name')
		File.open(FILENAME) do
		 |f|
		 YAML.load_stream( f ).documents.collect{|x| x[attribut]}
		end
	end
	def initialize(stock=nil)
		if stock.is_a?  Stock
			# initialize from modifed stock-object
			@stock=stock.stock.dup
		else
			# initialize from default values; convert Hash-Keys to downcase
			@stock=Hash.new
			readStockYAML(stock).each{|x,y| @stock[x.downcase]=y} 
		end
	end
	
		# gets the Stock-specific attributs  (no checking here!)
	def readStockYAML(stock) 	# :nodoc: 
		first=nil
		stock='' unless stock.is_a?(String)
		File.open(FILENAME) do |f|
			 yp=YAML::load_documents(f) do |doc|
				first= doc if first.nil?
				return first if doc['name']=="end"
				return doc 	if  doc['name']==stock || doc["alias"].include?(stock)
			end
		 end
	end


=begin rdoc
Gibt den Inhalt des Yaml-Files zurück
	Der übergebene Block kann Eigenschaften herausfiltern
====Aufrufbeispiel:
		Stock#getAvailableProperties{ |yaml| yaml["name"] } 
		gibt die möglichen Stocks zurück 
Die Einträge werden wie im Yaml-File notiert wiedergegeben. 
(Es findet z.B. keine Konversation der Schlüsselelemente zu Kleinbuchstaben statt.)
=end
	def getAvailableProperties
		value=Array.new		# declare value
		File.open('stocks.yaml') do |f|
			 yp=YAML::load_documents(f) do |doc|
				unless block_given?
					value.push doc
				else
					value.push yield(doc)
				end
			end
		end
		value.compact
	end

	
	# -----------------------------------
	# prepare for the assessor-methods of  "name, server, etc. "
 class << self
=begin rdoc
dynElement erzeugt Assessor-Methoden für 
	:name,  :tickValue, :tickRange, :tickSize, :halfTurnFee, :currency, :backtestIntervall, :resolution

=end
    def dynElement(*names)
       names.each do |name|
	   #	"remove the first get if nessesary to enable the access of (get)Resolution etc"
	    if name.to_s.include?("get")
			pname=name.to_s.sub(/get/,'').downcase 
		else
	   		pname=name.to_s.downcase
 		end	
		# now create the method
		class_eval <<-EOD
          def #{name}
             @stock['#{pname}']
          end
        EOD
      end
    end

	def setElement(*names)
		names.each do |name|
	       #	"remove the first set if nessesary to enable the access of (set)Resolution etc"
	
	    	if name.to_s.include?("set")
				pname=name.to_s.sub(/set/,'').downcase 
			else
	   			pname=name.to_s.downcase
				name= name.to_s << "="
 			end	
			# now create the method
        	class_eval <<-EOD
          		def #{name}(value)
            		@stock['#{pname}']=value
          		end
        	EOD
      	end
    end
end
  # lets create the accessor-methods now
  dynElement :name,  :tickValue, :tickRange, :tickSize, :halfTurnFee, :currency, :backtestIntervall, :resolution

=begin
Template zur formatierten Ausgabe von Stock-Werten
=====Anwendungsbeispiel
 s=Stock.new('fgbl')
 puts " aktueller Datenpunkt: #{s.printFormat % 134.4323}
 		-> aktueller Datenpunkt:  134.43
=end
	def printFormat

		def tt
			ts = Math::log10(tickSize).floor.to_i
			tr =  Math::log10( tickRange[ 'max' ] ).ceil
		 	tr  = (tr +1).to_i
			ts < 0 ? "%#{tr-ts}.#{-ts}f" : "%#{tr}.0f"
		end
		@pv ||= tt
	end 

	def hourStart
		@stock["time"]["open"]
	end
	
	def hourEnd
		@stock["time"]["close"]
	end
	
	def resolution=(r)
		@stock['resolution']=r
		@stock['convertedresolution']=convertResolution
	end
=begin rdoc
Die aktuelle OHLC-Auflösung in Sekunden  
=end
	def convertedResolution
			
			@stock['convertedresolution']=convertResolution if @stock['convertedresolution'].nil?
			@stock['convertedresolution']
	end
	
	def boxSize
		@stock['boxsize'] || @stock['ticksize'] * 5
	end

	def reversalBoxSize
		@stock['reversalboxsize'] || boxSize * 3
	end

	def startDay= (value)
	if value==-1
			@stock["startday"]=  Time.getDateFromString(self.startDay-60*60*24)
		else
			@stock["startday"] = value.is_a?(Time) ? value :  Time.getDateFromString(value)
		end
	end
	
	def endDay= (value=Time.now)
		@stock["endday"]= value.is_a?(Time) ? value :  Time.getDateFromString(value)		
	end
	
	def tadingDays= (value)
		@stock["tradingdays"]=value
	end
=begin rdoc
				waehlt den gesamten Kontraktzeitraum aus
=end
	def assignContract(contract=@stock["ib"]["contract"])
		self.startDay = @stock["contracts"][contract.to_i][1].to_s
		self.endDay = @stock["contracts"][contract.to_i][2].to_s
	end
=begin rdoc
			prueft, ob der angegebene Kontrakt in "contracts" definiert ist
			und gibt den Kontrakt (als IntegerWert) zurueck
=end	
	def checkContract(thisContract)
# alte routine
#		validMonth=[3,6,9,12]
#		validYears=[1,2,3,4,5]
#		month=contract.to_s[0..-3].to_i
#		year=contract.to_s[-2..-1].to_i
	#	unless validMonth.include?(month) && validYears.include?(year)
		unless @stock["contracts"].key? thisContract.to_i
			$stderr.print "STOCK.rb::checkContract: contract is not usable : #{thisContract} . Using the default from stocks.yaml \r\n"
			@stock["ib"]["contract"]	
		else
			thisContract.to_i
		end
	end
	
=begin rdoc
 ein Array im Format [ [{monat},{jahr}],[..],..] 
 mit 
  {monat} und {jahr} im Fixum-format, z.B. [[12, 4], [3, 5]]

=end
	def availableContracts 
		@stock["contracts"].keys.collect{|x| [(x / 100).ceil, x %(100*( x / 100).ceil)]}.sort{|x,y| x[1] <=> y[1]}

	end

	
	# charting related methods
	 dynElement :getStartDay, :getEndDay, :getTradingDays, :getServer, :startDay, :endDay
	 setElement :setServer

	def getTradingRange
		if getTradingDays.is_a?(Integer)
			if getStartDay.class==Time
				{"startDay"  => self.startDay,
				"tradingDays" => self.tradingDays}
			elsif getEndDay.class==Time
			{"endDay"  => self.endDay,
				"tradingDays" => self.tradingDays}
			end
		else
			{"endDay"  => self.endDay,
			"startDay"  => self.startDay}
		end
	end
=begin rdoc
ermittelt den für die Datenbankabfrage  geeigneten Contract
aus den  +StartDay+- und +EndDay+-Eigenschaften des Objekts
und legt diese Angabe in <i>ib-contract</i> ab
	
* Wird nur der StartDay spezifiziert, dann wird der gesamte Rest des Kontrakts selektiert
* Wird nur der EndDay spezifiziert, dann wird der Anfang des Kontrakts als Beginn selektiert
* Wird keine Angabe gemacht, oder liegen beide Werte ausserhalb der Werte, dann wird der aktuelle Kontrakt bis zum aktuellen Datum selektiert
	
=end
	 def adjustContract
	 	# we have to clone the hash because it will be modified here
		# and we dont want to change the yaml-reference-data 
		# because other methods may relay on that data
	 	contractClone=@stock["contracts"].clone
#	 	format  @stock["contracts"].: { contract  => [ start_date,, activate_date, end_date] } 
		if self.startDay.nil? && self.endDay.nil? 	# nothing is set until now
																									# select the hole default-contract
			assignContract
		elsif self.endDay.nil?
			startDate=Date.new(self.startDay.year,  self.startDay.month,  self.startDay.day)
			thisContract=contractClone.delete_if{ 	|c, b| startDate  < b[1]}
			self.endDay =  thisContract[thisContract.keys.sort.last][2].to_s
		elsif self.startDay.nil?
			endDate=Date.new(self.endDay.year,  self.endDay.month,  self.endDay.day)
			thisContract=contractClone.delete_if{ 	|c, b| endDate  > b[2]}
			self.startDay = thisContract[thisContract.keys.sort.last][1].to_s
		else
		
			startDate=Date.new(self.startDay.year,  self.startDay.month,  self.startDay.day) 
			endDate=Date.new(self.endDay.year,  self.endDay.month,  self.endDay.day) 
			
			# startDate < b[0] --> remove all entries starting after the startDay
			# endDate  > b[2] --> remove all entries ending before the endDay
			thisContract= contractClone.delete_if{ 	|c, b| startDate  < b[0]	or endDate > b[2] } 
			if thisContract.size >1
				thisContract= contractClone.delete_if{ 	|c, b| startDate  < b[1]	or endDate > b[2] } 
			elsif thisContract.empty?
				assignContract
			end
	#		thisContract.each{|x,y| puts "contract : #{x}";  y.each{ |k|  print k.to_s,"  "};  print "\n" }
	#		puts "setting Contract to #{thisContract.keys.first} "
			self.contract =  thisContract.keys.first
		end	
	end
	
	private
=begin rdoc
Übersetzt die mit Einheiten versehenen Angaben (z.b. 10m) in  die Anzahl  von Sekunden  und gibt diesen Wert zurück

====Akzeptierte Einheiten:
* m (minuten)
* h (stunden)
* d (tage)

Bei der Einheit _d_ werden  <em>time.open</em> und <em>time.close</em> aus der Yaml-Steuerdatei zur Ermittlung der Dauer eines Tages herangezogen.

=end
	def convertResolution	
	
		if resolution.class==String
			# convert resolution into seconds
			case resolution[ -1 .. -1 ]
				when  'm'
					resolution.to_i*60
				when  'h'
					resolution.to_i*60*60
				when  'd'		
				# ziehe die Nachtstunden des letzten Tages ab, damit die Distanz in Sekunden bis
				# zum Handelsschluss des letzten Tages ausgegeben wird 
					resolution.to_i*60*60*24 - (60*60*(24-(hourEnd-hourStart)))
				else
					resolution.to_i*60
			end	# case
		else
			resolution.to_i*60
		end	# if branch
	end

end


# ------------------------------------------ standalone code ----------------------------------------------
 if $0 == __FILE__
 require 'optparse'
 require 'pp'
 
 opts= OptionParser.new
 opts.on('-t', '--test [PROPERTY]' ) {|val|
 	p val
	puts "---------------"
	thisStock=Stock.new
	unless val.nil?
		pp thisStock.getAvailableProperties{ |yaml| yaml[val] }  
	 else
	 	pp thisStock.getAvailableProperties
	end
	}
	furtherArguments=opts.parse(ARGV)
	if furtherArguments.empty?
		puts "no stock specified"
		puts " call this with one of the following Stock-Arguments"
		pp Stock.availableStocks('alias')
	else
	# call this file with stock--arguments
	until furtherArguments.empty?
		thisStock= Stock.new(furtherArguments.shift)
		thisStock.contract = 305
		print " recognized stock: #{thisStock.name}  "
		#print " @ #{thisStock.server} \n"
		print " or in mysqlDatabaseTable: #{thisStock.getDatabaseName} \n"
		puts "Setting the resolution to 64m"
		thisStock.resolution = "64m"
		puts "now reading the stored  resolution ---> #{thisStock.resolution}"
		puts " assoziated ib-values: Underlying:  #{thisStock.ibUnderlying} , "
		puts "                   Symbol for #{thisStock.contract}: #{thisStock.ibSymbol} "
		puts "------------------------------------------------------------------------------------"
		puts " now allocating the stock-object based on the former one "
		puts "-----------------------------------------------------------------------------------"
		
		
		newStock=Stock.new(thisStock)
		
		puts " assigning the contract from  specified Start- and endDays :"
		newStock.startDay = "2004-10-31"
		newStock.endDay = "2004-12-16"
	
		newStock.adjustContract
		puts	"contract :: #{newStock.contract} "
		puts 	"startDay :: #{newStock.startDay}"
		puts 	"endDay  :: #{newStock.endDay}"
		puts "available Contracts:"
		pp newStock.availableContracts
	
		puts "assigning Contract 305 "
		newStock.assignContract 305
		newStock.adjustContract
		puts "reading contract, startday and endday from Stock:"
		puts	newStock.contract
		puts 	newStock.startDay
		puts 	newStock.endDay
		puts " get the stored tickRange "
		puts newStock.tickRange
		
		puts " this is the stored Hash-Content "
		pp thisStock.stock
		end
		end
	
end
