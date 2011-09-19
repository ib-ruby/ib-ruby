module Comparable 	# :nodoc:
   def sign 
   	if block_given?
		yield(self) <=>0
	else
     	self <=> 0 
	end
   end 
 end

module Enumerable
  def sum
  	if block_given?
		inject(0) {|n, i|   yield(i).nil? ? n : yield(i) + n }
	else
		inject(0) {|n, i|  n + i }
   	end
  end
  
  def average(&b)
		if self.size>0
		#puts "sum: #{self.sum(&b)}"
			(sum(&b) / size).to_f
		else
			0
		end
	end

		# calculates the variance
		#
		# if sample is given and is not zero (0), the calculation is based on a sample of the array-elements
	def variance(sample=0)
	   if size >1
			if block_given?
				if sample.zero?
					(size *  inject(0){|x, k| x + yield(k) ** 2 }  - inject(0){|x, k| x + yield(k) } **  2).to_f 	/ ( size**2 ) .to_f 
				else
					(size * 	inject(0){|x, k| x + yield(k) ** 2 }  - inject(0){|x, k| x + yield(k) } **  2).to_f 	/ (size* (size - 1) ).to_f 
				end
			else
				if sample.zero?
					(size *  inject(0){|x, k| x + k ** 2 }  - inject(0){|x, k| x +k } **  2).to_f 	/ (size**2) .to_f 
				else
					(size * 	inject(0){|x, k| x + k ** 2 }  - inject(0){|x, k| x + k } **  2).to_f 	/ (size* (size - 1) ).to_f 
				end
			end
		end
	end
	# calculates the standard- deviation 
	def sigma(sample=0,&b)
		Math::sqrt( variance(sample,&b)) rescue 0
	end
	# calculates the correlation coefficent of the linear regession
	#
	# requirement: the contents  are Arrays itself
	def correlate(sample=0)
	#	if self.first.class.is_a? Array
#		require 'pp'
		p	vSum=self.sum{|x| x.first * x.last }
		p	xyMean = vSum / self.size.to_f
		p	xMean = self.average{|x| x.first}
		p	yMean = self.average{|x| x.last}
		p	xSigma= self.sigma(sample){|x| x.first}
		p	ySigma = self.sigma(sample){|x| x.last}
			( xyMean - (xMean * yMean)) / (xSigma * ySigma ) 
	#	else
	#		0
		#end	
	end

end	
class Float
# rounds to the p's 	
	def roundf p
		t =  self.to_s.length
		sprintf("%#{t}.#{p}f",self).to_f
	end
end

class Array
=begin rdoc
berechnet die Kovarianz der Datenreihen.

Diese Methode erwartet  zwei Vektoren, die vertikal ein Array populieren:
 	[ [x0, y0] ... [xn, yn] ]

Dokumentation der Berechnung: http://de.wikipedia.org/wiki/Kovarianz
=end	
	def covariance
		averageX= average{|x| x.first}
		averageY= average{|x| x.last}
		(sum{|x| (x.first - averageX ) * (x.last * averageY)} ) / size	
	end	

=begin 
	Ermittelt, ob der gegebene Referenzwert gleich dem im Block ermittelten Wert ist
	z.B
		a=[2,4,5,6]
		a.localExtrem(2){|x| x.min}  --> true

#	def localExtrem(ref)
#		ref == yield(self)
#	end
=end
=begin rdoc
Gibt die  Differenz  zweier aufeinanderfolgender Arraywerte zurück (inc=1) oder
die Differenz zweier _inc_ getrennter Werte.

Aufruf ohne Parameter: Differenz zwischen dem aktuellen und dem vorherigen Wert (Also die erste Ableitung)
=end
	def delta(start=0,inc=1)
		if size > start+1
				at(start) - at(start+1) rescue 0
		 else
		 	0
		end
	end
	
alias momentum delta
alias derivation delta
	
=begin rdoc
Wir stellen fest, ob im gegebenen Intervall (count Datenpunkte)ein Trend zu verzeichnen ist.
Der optionale Parameter "toleranz" gibt an, wie oft der kontinuierliche Verlauf verletzt werden darf (Anzahl der Ausreisser).
	(Derzeit erfolgt noch keine Statistische Auswerung)

Wenn gleiche Werte toleriert werden sollen, dann kann Toleranz auf  0.5 gesetzt werden
		[ {"var" => 3}, {"var" => 4 } , {'var' => 5}, {'var'=>5}].trend(3,0.5){|x| x['var']}	=> tue
		[ {"var" => 3}, {"var" => 4 } , {'var' => 5}, {'var'=>4}].trend(3,0.5){|x| x['var']} => false
=end
	def trend(count=2,tolerance=0,&b)
	# count  tupel are analysed
	# trendCount contains the amount of eqal-signed tupel
	trendCount = (0..count-1).collect{ |x| delta(x,&b) }.collect{|x| x.sign }.sum.abs
	# we detect a trend, if ...
	trendCount>= (count - (tolerance*2))
	end
	
=begin rdoc
	Es wird die zweite Ableitung gebildet.	
	Praktisch wird  Steigung der Wertepaare 
		( @chart [start]-@chart[start+1] und  @chart[ref]-@chart[ref+1] 
	ermittelt.	Das absolute Vorzeichen der Steigerung ist unerheblich.
		Je negativer Slope ist, desto größer ist die Abnahme der Steigung,
		je positiver Slope ist, desto größer ist die Zunahme der Steigung
=end

	def slope(start=0, ref=1, &b)
		 delta(start,&b).abs - delta(ref,&b).abs 
	end
	
end

 
class Fixnum		# :nodoc:
	def each(&b)
		yield self
	end
end
# extension to realize net-compatible events --> http://rubygarden.org/ruby?ObserverPattern
class Module
    def sends *args
        args.each { |arg|
            class_eval <<-CEEND
                def on_#{arg}(&callback)
                    @#{arg}_observers ||= []
                    @#{arg}_observers.push callback
                end
		def del_#{arg}											# removes the last observer
		    @#{arg}_observers ||= []
		    @#{arg}_observers.pop unless @#{arg}_observers.empty?
		end
                private
                def #{arg} *the_args
                    @#{arg}_observers ||= []
                    @#{arg}_observers.each { | cb |
                        cb.call *the_args
                    }
                end
            CEEND
        }
    end
   def send *args													# send stores the observers in a Hash and allows to modify it
        args.each { |arg|
            class_eval <<-CEEND
                def on_#{arg}(&callback)
                    @#{arg}_observers ||= {}
                    @#{arg}_observers[caller[0]]=callback
                    return caller[0]
                end
                def del_#{arg}(id)
                    @#{arg}_observers ||= {}
                    return @#{arg}_observers.delete( id)
                end
                private
                def #{arg} *the_args
					 unless instance_methods(true).include?(arg.to_s)
          			class_eval %{attr_reader :#{arg}}
        			end
					self.#{arg}= the_args
                    @#{arg}_observers ||= {}
                    @#{arg}_observers.each { |caller, cb|
                        cb.call *the_args
                    }
                end
            CEEND
        }
    end


end

class TrueClass
    def ifTrue(&block) yield self; end
    def ifFalse(&block) self end
end

class FalseClass
    def ifTrue(&block) self end
    def ifFalse(&block) yield self; end
end

class Time	 # :nodoc:
	class << Time
	## --------------------getDateFromString(thisString,incrementDate=false) --------------------------------------------
	# uebertraegt das im string uebergebene Datum in ein 
	# Time-Objekt, das zurueckgegeben wird.
	# Der zweite Parameter ist die Basis für optional zu verarbeitende Inkremente
	# Wird nur eine Zahl übergeben, dann wird das Datum [incrementDate] um n-Tage
	# weitergesetzt. Ansonsten wird eine einzelne Zahl als Tag des aktuellen Monats
	# interpretiert. (Nur Zahlen bis zum aktuellen Datum sind erlaubt)
	# Fällt das Datum auf ein Wochenende, dann wird bei übergebenen Datumswerten Freitagswert ausgegeben.
	#		Bei übergebenen Inkrementen wird der folgende Montag ausgegben
	# Es werden folgende Formate erkannt: YYYY-mm-dd, YYYY/mm/dd, dd.mm.YYYY
	#	Das Jahr und der Monat koennen entfallen, hierfuer werden die aktuellen Daten eingesetzt.
	#		Aufrufbeispiele:	getDateFromString("10.3.2004")
	#									getDateFromString(3,"Time-objekt")
	def getDateFromString(thisString,incrementDate=false)
#	require 'initialize'
#		print "dateFromString . ", thisSting
		today=self.now
		# thisString kann auch ein Time-Objekt sein (quick&dirty Implemmentierung)
		thisString= thisString.strftime('%Y-%m-%d') if thisString.class==Time
		if thisString.class==String
			if thisString.split(/[-\/]/).size>1
				day, month, year = thisString.split(/[-\/]/).reverse
			elsif thisString.split(/[.]/).size>1
				day, month, year = thisString.split(/[.]/)
			else
				thisString=thisString.to_i
			end		
		end
			# wenn nur der tag übergeben wird, diesen hier zuweisen
		if thisString.class == Fixnum
			if !incrementDate 								
					 if thisString <= today.day 	
					 	day=thisString
					end
			# incrementDate wurde uebergeben --> Incremente verarbeiten
			else
				if thisString<0
			# wochenendkorrektur  (alle 5 tage zwei hinzuaddieren und dann ggf auf montag korrigieren)
				newday=incrementDate+(60*60*24*thisString)
				else
				newday=incrementDate+(60*60*24*(thisString+2*(thisString/5).ceil-1)) 
				end
				# falls newday ein Bankfeiertag ist, dann einen Tag weiter gehen
	#			newday+=(60*60*24) if Initialize::holidays.include?(newday)
				until (1..5)===newday.wday 
						newday+=(60*60*24) 
		#				newday+=(60*60*24) if Initialize::holidays.include?(newday)
				end
				
				return newday
			end
		end
		year ||=today.year
		month||=today.month
		day||=today.day
		newday=self.mktime(year, month, day)
		# falls newday ein Bankfeiertag ist, dann einen Tag zurueck gehen
	#	newday-=(60*60*24) if Initialize::holidays.include?(newday)
		# wochenendkorrektur (gehe zurueck zum letzten freitag, falls noetig)
		until (1..5)===newday.wday.to_i
			newday-=(60*60*24) 
	#		newday-=(60*60*24) if Initialize::holidays.include?(newday)
		end
		return newday
		# wochenendkorrektur
	end
	end
	# wochenenden werden zum folgenden Montag 
	def omitWeekends
		t=self.dup
		until  (1..5) === wday  do 
			t+=60*60*24
		end
		t
	end
	# wochenenden werden zum vorherigen Freitag
	def getWeekDay
	t= self.dup
		until  (1..5) === t.wday  do 
			t-=60*60*24
		end
		t
	end
	# converts time into hh.mm
	def timeFraction
		( hour * 100 + min ) / 100.to_f
	end
end
module Memoize	#  :nodoc: 
  $MEMOIZE_CACHE = Hash.new

  def memoize(*methods)
    methods.each do |meth|
      mc = $MEMOIZE_CACHE[meth] = Hash.new
      old = method(meth)
      new = proc {|*args|
        if mc.has_key? args
          mc[args]
        else
          mc[args] = old.call(*args)
        end
      }
      self.class.send(:define_method, meth, new)
    end
  end
 end

# ------------------------------------------ standalone code ----------------------------------------------
 if $0 == __FILE__
 
 a=[10.65,20,30.756,40.67]
#a=[5,7,8,10,10]		--> mean: 8, variance: 4.5 , stdDev: 2.12 
 a=(1..10).to_a
 puts "a : #{a.join(" , ")} "
 puts " sum: #{a.sum} "
 puts  " average: #{a.average} "
 puts " variance: #{a.variance} "
 
 puts "enumerable test: (1...10) --> sum #{(1..10).sum} "
# puts "enumerable test: (1...10) --> average #{(1..10).average} "
#puts "enumerable test: (1...10) --> variance #{(1..10).variance} " 

time=Time.mktime("2004","9",1)
p time.omitWeekends
time=Time.mktime("2004","9",11)
p time.omitWeekends
p time.getWeekDay

end
