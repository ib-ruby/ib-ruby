=begin rdoc
In dieser Klasse wird ein OHLC-Objekt behandelt

Ein OHLC-Objekt enthält die Informationen über den Kursverlauf im Zeitabschnitt einer Kerze

Die Basiswerte <em> open, close, high, low, average, volume </em>, sowie <em>openDate und date</em> 
werden bei der 
ObjektInitialisierung gesetzt und können nicht verändert werden.

Die Basiswerte sind als Methoden verfügbar ( OHLC.basiswert ).
=end
class OHLC 
	
  attr_accessor :openDate, :date 
#  Die BasisWerte "open" "high" "low" "close" "average" und "volumen" 
#  koennen ebensfalls direkt angesprochen werden (obj.open etc)
#  Die Basiswerte und alle Indikkatoren sind als Array zugaenglich (obj["indikator"])
#  Indikatoren koennen auch so gesetzt werden: obj[indikator]=wert
#	
=begin 
	initialize without a block results in an empty list-element, date and opendate are
	set to the actual system-date.
	the optional block has to initialise the @openDate, @date and the @base  class-variables
=end
=begin rdoc
Ein Aufruf ohne Parameter initialisiert ein leeres OHLC-Objekt, +date+ und +openDate+ 
werden auf das aktuelle Systemdatum gesetzt

Der optionale Block *muss* +openDate+, +date+ und +base+ in dieser Reihenfolge initialisieren.
Aufrufbeispiel::
	     @chart.unshift(OHLC.new(ohlc){|data|  openDate, date, base = *data })
		 
Es kann auch ein Array übergeben werden. Die ArrayElemente werden wie folgt zugewiesen
 Array :  [open , high, low, close, volume, price ]
Fehlende Elemente werden mit  _open_ ergänzt  ( _volume_ ist dann 1 )

Als weitere Alternative kann auch ein einzelner Zahlenwert übergeben werden. Dann wird Volumen auf 1 gesetzt und alle ohlc-Felder 
werden auf den Zahlenwert gesetzt.
 
=end

	def initialize(data=nil)
		
		if block_given?
			@openDate,@date,@base = yield(data)
		else 
			@date, @openDate=Time.new, Time.new
			data=[data] if data.is_a? Numeric 
			if data.is_a? Array
				o_data= data.dup			# prevent the data to be eaten
				@base= { :open => o_data.shift,
									:high => o_data.shift || data.first,
									:low	 =>	o_data.shift || data.first,
									:close => o_data.shift || data.first,
									:volume =>o_data.shift || 1,
									:price => o_data.shift || data.first	}
			else
				@base=Hash.new
			end
		end
	end
	class << self
# Accessor-Methoden im Eigenbau: Zugriff auf die ohlc-Daten <em> open, close, high, low, average, volume </em>
		def baseElement(*names)	# :nodoc:
			names.each do |name|
				class_eval <<-EOD
				def #{name}
					@base[ :#{name} ]
				end	
				EOD
			end		# do
		end			#def
   end				#class
	baseElement :open, :close, :price, :high, :low, :volume
	
# OHLC kann wie ein Hash angesprochen werden	
	def [](key)
		if key=='date' || key == :date
			@date
		else	
			getValue(key)
		end
	end
=begin rdoc
OHLC-Objekte können einfach per "print" ausgegeben werden
 "to_s" spezifiziert diese Ausgabe
 
Ohne weitere Parameter wird eine Ausgabe im Format
	22.03.200
	
	5 10:38 --     10000     10000     10000     10000
	Datum(open)		open	high		low	close
erzeugt.


Die auszugebenden OHLC-Werte können durch die Angabe der Werte als Parameter definiert werden
	a=OHLC.new(10000)
	a.to_s('open','close','gogo')
	=> "22.03.2005 10:45     10000     10000     10000 "

Die globale Variable '$,'' (WortSeperator) trennt die Werte.
	
Die Datumsangabe wird im (optionalen) Block ausgewählt und formatiert.
Dem Block werden das <em>OpenCandle</em>- und das <em>CloseCandle</em>-Datum als Time-Objekte zur Vefügung gestellt.
	a.to_s('open','close','gogo'){|opendate,closedate| closedate.strftime(" %H:%M -- ")}
	=> " 10:43 --     10000     10000     10000 "
	
Die OHLC-Werte werden einheitlich formatiert, der Open-Wert dient hierfür als Referenz.
Indikatoren sollten deshalb separat ausgegeben werden.
=end
	def to_s(formatString=nil)
		
		unless @date.nil? || @openDate.nil?
			if block_given?
				b=yield(@openDate, @date)
			else
				b=@openDate.strftime("%d.%m.%Y %H:%M#{$,} ")
			end
			if formatString.nil?
				case @base[ :open ]
					when 0 .. 1
						formatString= " %6.4f "
					when 1.. 100
						formatString= " %6.3f "
					when 100 .. 1000
						formatString= " %6.2f "
					when  1000 .. 100000
						formatString=" %8.0f "
					else
						formatString=" %1.0f "
				end
			end
			formatString+=$, unless $,.nil?
				b << sprintf(formatString *5,@base[ :open  ],@base[ :high ],@base[ :low ], @base[ :close ], @base[:price] ) + @base[:volume].to_s
		else
				""
		end
		
	end
=begin	rdoc
Aufbereitung der Basisdaten für den cvs-Output.

Parameter wie bei OHLC#to_s.

Das Volumen wird an den generierten String angehängt  und es wird ein SatzEndeZeichen eingefügt.

===Aufruf
	OHLC#printCSV('open','high','low','close','price'){|opendate,closedate| closedate.strftime(" %H:%M  #{$,}")}
=end
	def printCSV(*values, &b)
		if values.empty?
			a= self.to_s(&b)
		else
				a= self.to_s(*values, &b)
		end
		a +self[ :volume ].to_s+\z/
	end
				
		
=begin
	 returns the associtated value or the value of the default-Parameter
	 (old method, use OHLC#[indicator] insteed )
=end
	def getValue(usedParameter, defaultParameter= :price ) # :nodoc:
		if  @base.include? usedParameter.to_sym
			f=	@base.fetch(usedParameter.to_sym) 
	#	elsif @indicator.include?(usedParameter.to_s)
	#		f=	 @indicator.fetch(usedParameter.to_s)
		else  
		puts "getValue using fullIIndcatorName: #{usedParameter} "
	#	puts "allocated Indicators: #{allIndicators.join(" ; ")}"
	#	p	f =	 @indicator.fetch(fullIndicatorName(usedParameter))
		end
		if f.nil?
			f= defaultParameter
			$stderr.puts "OHLC#getValue:: using defaultParameter #{defaultParameter}  insteed of #{usedParameter} \n"
				# return 'nil' if defaultParameter is not a valid @base or @indicator entry
		#	f=getValue(defaultParameter,nil)
		end
		f
	end		
	
end	# class		
