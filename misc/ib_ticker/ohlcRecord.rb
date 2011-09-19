require 'stdExt'
#require 'observer'
require 'ohlc'
class OHLC
	def ohlcKeys
		@base.keys
	end
=begin rdoc
Einfache Prüfung der OHLC-BasisWerte.
* <em>open, high, close, low </em> und <em> price </em> müssen innerhalb Stock#tickRange liegen
* <em>volume</em> muss größer als Null sein
* _openDate_ muss kleiner als Stock.hourEnd, _date_ muss größer als Stock#hourStart sein.

Die Methode liefert true, wenn die Daten ok sind.

===Parameter
s	:: Ein Stock-Objekt
=end
	def checkData(s)
		result=true
		@base.each do 
			|x,y|
				unless x == :volume
						return nil unless ( s.tickRange[ "min" ]  ..  s.tickRange[ "max" ]).include?(y) 
				else 
						return nil if  y <=  0
				end					# unless
			end						#each
	#	return  nil  if @date.timeFraction  < s.hourStart || @openDate.timeFraction  > s.hourEnd
		true
	end								#def
=begin rdoc
_openDate_ und _date_ werden auf  Stock#hourStart bzw Stock.hourEnd gesetzt, wenn die ursprünglichen Werte ausserhalb des
Intervalls liegen.
 
In Verbindung mit OHLC#checkData können die OHLC-Objekte zuverlässig initialisiert werden.
=end
	def adjustDate(s)
		
		 if @openDate.timeFraction < s.hourStart
		 	@openDate  = @openDate.adjust2timeFraction(s.hourStart)
		 end
		if @date.timeFraction >  s.hourEnd
			@date = @date.adjust2timeFraction(s.hourEnd)
		end
	end	
	
	def is_dailyClose  s
		@date.timeFraction >= s.hourEnd
	end
end

class Time 	# :nodoc:
=begin rdoc
Ermittelt die absolute Differenz (in Sekunden) zwischen der Zeit des Objekts und dem übergebenen Zeitwert (floating Zahl, aus Time#timeFraction)
		t=Time.mktime(2005,4,6,7,0,10)  ==> Wed Apr 06 07:00:10 CEST 2005
		t.diffFraction 7.50					==>	 300 
		
=end
	def  diffFraction(fraction)
		value=timeFraction
		time1=(value-value.floor)*100*60 + value.floor * 3600
		time2=(fraction-fraction.floor) * 100 * 60 + fraction.floor * 3600
		(time1-time2).abs.to_i
	end
=begin rdoc
gibt eine neue Zeit zurueck bei dem die Uhrzeit auf die "timeFraction" gesetzt wird
=end	
	
	def adjust2timeFraction timeFraction
			return self if timeFraction < 0
				
			tempTime = self - ( self.hour * 60 + self.min ) * 60
			tf = ( timeFraction - timeFraction.to_i ) * 100 * 60 +  timeFraction.to_i * 3600
			tempTime +  tf
	end
=begin rdoc
Die aktuelle Zeit wird auf das Intervall timeFraction1 ... timeFraction2 beschnitten.

Zeitan ausserhalb des Intervalls werden auf den ersten/ letzten zulässigen Zeitwert gesetzt.
=end	
	def cutTime(timeFraction1,timeFraction2)
			timeFraction1, timeFraction2 = timeFraction2, timeFraction1 if timeFraction2 < timeFraction1
			if timeFraction < timeFraction1 
				adjust2timeFraction timeFraction1
			elsif timeFraction > timeFraction2
				adjust2timeFraction timeFraction2
			else
				self
			end
	end
end
=begin rdoc
Tickdaten  oder OHLC-Objekte werden jeweils zu einem OHLC-Objekt  zusammengefasst.

Bei der Initialisierung wird ein Stock Objekt übergeben. Die dort festgelegte Auflösung wird hier realisiert.

Die Methoden  _accumulateOHLC_ und  _accumulateTicks_ akkumulieren die Eingangsdaten.
Sie akzeptieren jeweils einen Block, dem das erstellte OHLC-Objekt zur Verfügung gestellt wird.

Die OHLC-Objekte werden  abhängig von der Eigenschaft _ohlcRaster_ 
*variable*:: in festen Abständen, beginnend mit dem ersten realen Tick nach Stock.hourStart des ersten Tages
*fix* :: in festen Abständen, täglich  beginend bei Stock.hourStart. Die <em>erste Kerze</em> des Tages ist  <b>verkürzt</b>. 
*startDay*:: in festen Abständen, täglich beginnend mit dem ersten realen Tick nach Stock.hourStart. Die <em>erste Kerze</em> des Tages ist  <b>vollständig.</b>
erzeugt. Im letzten Fall wird die Zeit zwischen Stock.hourEnd und dem ersten Tick des nächsten Tages einfach ignoriert.

Die OHLC-Eigenschaften _openDate_ und _date_ werden wie folgt initialisiert:
OHLC.openDate:: enthält das fixe Raster der OHLC-Objekte. Diese Eigenschaft ist nicht identisch mit dem ersten tatsächlich registrierten Tick im OHLC-Zeitrahmen sondern mit dem theoretischen Begin dieser Kerze.
OHLC.date:: enthält die tatsächliche Zeit des letzten in das OHLC-Objekt integrierten Ticks.

Die Einträge werden einer Prüfung unterzogen, ob sie sich im akzeptierten Wertebereich des Stock-Objekts  befinden (Stock.tickRange und Stock.hourStart / hourEnd)

Nachdem ein OHLC-Element fertig gestellt wurde, wird das Signal <em>ohlc_ready </em> ausgelöst, dem das fertige OHLC-Element mitgegeben wird.
=end		
class OHLCrecord
sends :ohlc_ready
=begin rdoc
====Parameter
stock:: Stock-Objekt 
=end
	def initialize stock
		@stock = stock
		@tickArray= []
		@close, @first,  @lastTime = nil, nil, nil
		@ohlcRaster = 'startDay'
	end
=begin   # old code
		if ohlc.is_a? OHLC
				@first, @lastTime= ohlc.openDate, ohlc.date
				@tickArray.push ohlc
		elsif ohlc.is_a? Hash
				time=Time.at(ohlc[:date].to_i)
				@first,@lastTime= time,time 
				@tickArray.push(OHLC.new(ohlc){ 
					| data| 
						date= data.delete( :data )
						ohlcData=Hash.new
						data.each{|x,y| ohlcData[x]=y.to_f }
						[date,date,OHLCdata ] } )
				
		end
	end	
=end	
=begin rdoc
Die OHLC-Objekte werden  abhängig von der Eigenschaft _ohlcRaster_ 
*fix* :: in festen Abständen, täglich  beginend bei Stock.hourStart. Die <em>erste Kerze</em> des Tages ist  <b>verkürzt</b>. 
*startDay* :: in festen Abständen, täglich beginnend mit dem ersten realen Tick nach Stock.hourStart. Die <em>erste Kerze</em> des Tages ist  <b>vollständig.</b>
*variable* :: in festen Abständen, beginnend mit dem ersten realen Tick nach Stock.hourStart des ersten Tages 
erzeugt. Im letzten Fall wird die Zeit zwischen Stock#ourEnd und dem ersten Tick des nächsten Tages einfach ignoriert.


=end
def raster= value
	@ohlcRaster= ['fix', 'variable', 'startDay' ].detect{|v| v== value} || 'startDay'
end

=begin 
Callback-Methode, falls OhlcRecord selbst als Observer angemeldet wurde.

def update(*args)
	# args.flatten!		#		uncomment if nessesary 
	if args.first.is_a? OHLC
		accumulateOHLC(*args)
	else
		accumulateTicks(*args)
	end
end
=end
=begin
	Transforms tickdata from  @tickArray into an OHLC-record
	- the first tickdata--Event of a new day unconditionally creates a new OHLC-Array-Entry and sends the last 
	ohlc-record of the previous day to all abservers
	- OHLC-Arrays are submitted to all Observers
=end	
=begin rdoc
ohlc-Datensätze werden zu einem  <em>Master</em>-Datensatz  zusammengefasst.

*Einsatz*  z.B.  Akkumulation von 1-min-ohlc-Datenblöcken zu einem OHLC-Objekt der Auflösung Stock#resolution.

=end	
	def accumulateOHLC(ohlc)
		
		 
	 if ohlc.checkData(@stock)	
			ohlc.adjustDate(@stock)
			 if @first.nil?
			 resetCandleBoundaries(ohlc) 
			elsif is_open(ohlc.date)		# war: ohlcOpenDate als Parameter
				makeOHLC
				resetCandleBoundaries(ohlc)
			end
			@lastTime=ohlc.date
			@tickArray.push ohlc  
		end

	end
=begin 
In Abhängigkeit von *ohlcRaster* wird der Startwert für die nächste Kerze gesetzt
=end
	def resetCandleBoundaries(parm) # :nodoc:
		# the method returns @frist 
			 if parm.is_a?(OHLC)
				openDate, date = parm.openDate, parm.date 
			else
				openDate , date = parm, parm.dup
			end
			@lastTime = date
			if  @first.nil? || is_daily_open(openDate) 
				@first = case 	@ohlcRaster
					when 'fix'
						openDate.adjust2timeFraction hourStart
					when 'variable'
						openDate
					when 'startDay'
						openDate
				end
			else
			@first += convertedResolution until (@first + convertedResolution) >= date
			end
	end
=begin rdoc
EinleseMethode für TickDaten


=end 	
	def accumulateTicks(time, price, volume)
		 tickTime=Time.at(time.to_i)
		 # Alle tick-daten vor hourStart verwerfen
		 # Alle tick-daten ohne Volumen  verwerfen

		 if tickTime.timeFraction >= hourStart && volume.to_i >0 && price.to_f >= tickRange["min"] &&  price.to_f <= tickRange["max"]
			 if @first.nil?
				 resetCandleBoundaries(tickTime) 
			elsif	is_daily_close(tickTime)
				# Positions after the "closingBell" are ignored. 
				# Only the value of the 'closing-auction' , the last dataTick of the day, is added to the last candle
				 @tickArray.pop if @close
				 @close=true 
				tickTime=tickTime.adjust2timeFraction hourEnd
			elsif is_open(tickTime)
				makeOHLC
				resetCandleBoundaries(tickTime)
			else
				@lastTime=tickTime	
			end
			@tickArray.push( { :price => price.to_f , :volume => volume.to_i}) 
		#	p price
		end
	end

=begin rdoc
Erzeugt aus noch nicht verarbeiteten TickDaten ein OHLC-Objekt, verändert die Rohdaten jedoch nicht.

Hiermit kann  stets ein _Snapshot_ des aktuellen OHLC-Records abgefragt werden
=end	
	def unfilledOHLC	  
		makeOHLC false
	end
	

#protected
=begin
	implements a simple proxy pattern  (internal use only)
	all undefind method calls are forwarded to @stock
=end	
	def method_missing(meth, *args, &block) # :nodoc:
 		if @stock.respond_to?(meth)			# check wether a method "meth" exists in stock
			@stock.send(meth, *args, &block)
		else
			puts "Version: #{@version} --> #{meth}"
			 raise StandardError,  "method  #{meth} unknown ", caller
		end 
	 end 
	 
		
=begin
	extracts OHLC data from @tickArray
	uses closing data from @close if provided
	@tickArray is cleared and @close is resetted
=end
=begin rdoc
Erzeugt ein OHLC-Objekt aus den akkumulierten Daten 

Es wird das Signal ohlc_ready ausgelöst
=end
	def makeOHLC(clearTickDataArray=true)

	unless  @tickArray.nil? || @tickArray.empty?
		if 	@tickArray.first.is_a? OHLC
			open=@tickArray.first.open
			close=@tickArray.last.close
			low=@tickArray.collect{|obj| obj.low}.min
			high=@tickArray.collect{|obj| obj.high}.max
			volume=@tickArray.collect{|obj| obj.volume}.sum
		
		else			# tick-data  --> [:price :volume]
			open=@tickArray.first[:price].to_f
			close=@tickArray.last[:price].to_f
			low=@tickArray.collect{|obj| obj[:price].to_f}.min
			high=@tickArray.collect{|obj| obj[:price].to_f}.max
			volume=@tickArray.collect{|obj| obj[:volume].to_i}.sum
		end
		if volume<=0
				price=low=high=open=close
		else
				price=@tickArray.collect{|obj| obj[ :price ].to_f  * obj[ :volume ] }.sum / volume
		end
		# in case of 'variable' ohlc-raster set the start of the day-overlapping candle to hourStart
		if  is_daily_open(@lastTime) && @ohlcRaster == 'variable'
				@first=@lastTime.adjust2timeFraction hourStart  
				@first -= convertedResolution
		end
		@tickArray.clear if clearTickDataArray
		newOHLC=OHLC.new{ [@first.cutTime(hourStart, hourEnd), @lastTime.cutTime(hourStart,hourEnd),
											 { :open => open, :high => high , :low => low,
											   :close => close , :volume => volume, :price => price} ] }
	#	yield newOHLC if block_given?
		@close=false				# reset the close-flag  (used in accumulateTicks) 
	#	if count_observers >0
	#		changed
	#		notify_observers(newOHLC )
	#	end	
		ohlc_ready newOHLC
		newOHLC				# returnValue
	end				# unless
	end

	
	def is_daily_open(tickTime)
		unless tickTime.nil?
			tickTime.day !=@first.day || @first.timeFraction < @stock.hourStart
		end
	end
	
	def is_daily_close(tickTime)
		tickTime.timeFraction > @stock.hourEnd
	end
	
	def is_open(tickTime)
		if	@ohlcRaster == 'variable' 
			if is_daily_open(tickTime)
	#		# Uebertrag von Vortag mitberuecksichtigen
			carry=@first.diffFraction( @stock.hourEnd )
			todaysTime= tickTime.diffFraction( @stock.hourStart ) 
			(carry + todaysTime ) > @stock.convertedResolution
			else
			(tickTime - @first) >  @stock.convertedResolution 
			end
		else

			 is_daily_open(tickTime) || 	(tickTime - @first) >  @stock.convertedResolution 
		end
	
	end
	
	def get_next_open
		convertedResolution - (@lastTime - @first )
	end
	
		

end
# ------------------------------------------ standalone code ----------------------------------------------
if $0 == __FILE__
	require 'test/unit'

	require 'optparse'
 	require 'pp'
	require 'stock'
	class TestTime < Test::Unit::TestCase 	#:nodoc:
		def test_adjust2timeFraction
			# generell checking
			t=Time.now
			h=t.hour
			assert_equal h-2 , t.adjust2timeFraction(h-2).hour
			# check localtime time objects
			openDate= Time.local 2004,'jan',10, 3,0,0
			timeFraction = 7.15
			closeDate=Time.local 2004,'jan',10, 7,15,0
			assert_equal closeDate , openDate.adjust2timeFraction(timeFraction)
			# check gmt time objects
			openDate= Time.gm 2004,'jan',10, 3,0,0
			closeDate=Time.gm 2004,'jan',10, 7,15,0
			assert_equal closeDate , openDate.adjust2timeFraction(timeFraction)
		end
		def  test_cutTime
			openDate= Time.local 2004,'jan',10, 13,0,0	# set time to 1 pm
			assert_equal openDate,  openDate.cutTime( 8, 18 )
			closeDate= Time.local 2004, 'jan',10, 12, 0, 0	 # set time to 12 am
			assert_equal closeDate,  openDate.cutTime(8,12)
			assert_equal closeDate,  openDate.cutTime(12,8)
		end
	end
	
	class TestOHLC < Test::Unit::TestCase 	#:nodoc:
		def test_checkData
		s =  Stock.new
			o = OHLC.new 0
			assert_nil  o.checkData( s )
			o = OHLC.new( (s.tickRange["min"] + s.tickRange["max"]) /2 )
			assert o.checkData( s )
			o = OHLC.new s.tickRange["min"]
			assert o.checkData( s )
			o = OHLC.new s.tickRange["max"]
			assert o.checkData( s )
			o = OHLC.new( s.tickRange["min"] -1)
			assert_nil o.checkData( s )
			o = OHLC.new( s.tickRange["max"] +1)
			assert_nil o.checkData( s )
		end
		def test_adjustDate
			s = Stock.new
			o = OHLC.new 1
			o.openDate= Time.local 2004,'jan',10, s.hourStart-2
			openDate= Time.local 2004,'jan',10, s.hourStart
			o.adjustDate s
			assert_equal o.openDate, openDate
	
		end
	end
	class TestOHLCrecord < Test::Unit::TestCase 	#:nodoc:
		def setup
			@s = Stock.new
			@s.resolution= '1m'
			@o = OHLCrecord.new @s
		end

#		def test_conditions
#			time = Time.local 2004,'jan',10, @s.hourStart
#			@o.resetCandleBoundaries time
#			assert @o.is_open( time ), "check is_open-method"
#		end
		def test_ticks
			### ohlc-based checks
			sn= Stock.new
			sn.resolution='59m'
			on=OHLCrecord.new sn
			# let's simulate some tickData-values
			time = Time.local 2004,'jan',10, @s.hourStart
			tick=@s.tickRange['min']
			ohlc=nil		# this is the container for the ohlc-object
			stop=false
			@o.on_ohlc_ready{ |u|   ohlc = u; on.accumulateOHLC u }
			12.times do |i|		# just produce one candle
				@o.accumulateTicks( time + ( i*10 ), tick, 100)
				tick +=1
				tick=@s.tickRange['min'] if tick > @s.tickRange['max']
#				exit if stop
			end
			assert_kind_of OHLC, ohlc, "check ohlc-Object creation "
			assert_equal time, ohlc.openDate, "the openDate should be the initial time"
			assert_equal @s.tickRange['min'], ohlc.low
			assert_equal @s.tickRange['min'], ohlc.open
			assert_equal time+@s.convertedResolution, ohlc.date, "check the current length of a ohlc-candle"
			### ohlc-based checks

			# we need 10 6-min ohlc-records
			nohlc=nil
			on.on_ohlc_ready{ |u| p nohlc=u }
			time=ohlc.date		# start at the closing of the first candle
			480.times do |i|		# just produce one candle
				@o.accumulateTicks( time + ( i*10 ), tick, 100)
				tick +=1
				tick=@s.tickRange['min'] if tick > @s.tickRange['max']
			end
			
			assert_kind_of OHLC, nohlc, "check ohlc-Object creation "
	
		end
	end
=begin		
		range = s.tickRange
		
		
		opts= OptionParser.new
		# StandardAuflösung für ohlc-Records
		res='5m'
		# Default-Einstellungen für tickRange +  hourStart/ hourEnd  
		stock='bund'
		# Default-Einstellung für das OHLC-Raster
		raster='fix'
		# Anzahl der Durchläufe
		nr=1000
		opts.on('-s', '--stock STOCK', String) {|val| stock=val }
		opts.on('-r', '--resolution RES',String){|val| res=val}
		opts.on('-t', '--times TIMES', Numeric){|val| nr=val}
		opts.on('--fix' ){raster='fix'}
		opts.on('--variable' ){raster='variable'}
		opts.on('--startday' ){raster='startDay'}
		furtherArguments=opts.parse(ARGV)
		@s=Stock.new(stock)
		@s.resolution = res
		tick=@s.tickRange['min']
		@ohlcRecord=OHLCrecord.new(@s)
		@ohlcRecord.raster = raster
	end

	
		time=Time.mktime(2005,4,1,8,0,10)
	nr.times do
		ohlcRecord.accumulateTicks(time, tick, 100) do
			|thisOHLC|
			# puts thisOHLC
				puts thisOHLC.to_s('open', 'high', 'low', 'close', 'price','volume'){|start, ende| start.strftime("%d.%m.%Y %H:%M -- ")+ende.strftime(" %H:%M  ")}
		end
		time+=100
		tick +=1
		tick=s.tickRange['min'] if tick > s.tickRange['max']
	end
=end		
end
