class OHLC
=begin rdoc
Ein SQL-Kommando  wird erzeugt, das die _Basiswerte_ des aktuellen OHLC-Objekts in einer Datenbank ablegt.

===Aufrufbeispiel
 SQLquery.new("ohlc", ohlc.mysqlInsertString("ib_#{@stock.getDatabaseName} "))
=end	
	def mysqlInsertString(database)
		"insert into #{database} (date, #{@base.keys.join(',')}) values  ('#{@date.strftime( "%Y-%m-%d %H:%M:%S")}',#{@base.values.join(',')}) "
	end
	
	
end

class Stock
=begin rdoc
Ein SQL-Kommando  wird erzeugt, das die _OHLCdaten_ des aktuellen Stock-Objekts aus einer Datenbank liesst.

===Aufrufbeispiel
 SQLquery.new("ohlc", stock.mysqlFetchOHLC ")
=end	

	def mysqlFetchOHLC
			"select  unix_timestamp(date) as date,price,volume,open, high, low,close 
									from ib_#{getDatabaseName} 
									where date between  '#{startDay.strftime( "%Y-%m-%d" )} '  and
									'#{endDay.strftime( "%Y-%m-%d" )} ' 
									and hour(date) between #{hourStart.to_i} and #{hourEnd.to_i}
									order by date"
			
	end
end

require "mysql"
	#diese Klasse setzt Queries an die Default-Datenbank ab
	#und speichert das Ergebnis in den Variablen
	#queryArray und querryHash
	#* Aufbau von queryHash
	#  [{"feld1"=>"wert1", "feld2"=>"wert2", ..."}, {...} , .. ]
	#* Aufbau von queryArray  [[ wert1"], [wert2"], [...], ...], [ ...] , ...
	#
	#Dies ist die Basisklasse für alle SQL-Abfragen
	#
	#todo:: Die Default-Datenbank sollte als xml-file spezifiziert und eingelesen werden
	#
	# Der Parameter: query wird an die Datenbank gesendet
	# Das Ergebnis wird zurückgegeben
	#	entweder als Array
	#oder (bei Abfragen ohne Ergebnis z.b. insert, update, drop, delete)
	#als mysql_affectedRows
	#Alternativ akzeptiert die Klasse hierfür (kein ErgebnisSet)  einen Block.
	#Beispiel:
	#SQLquery.new("insert into Unternehmen set Name='TestUnternhemen' ")
	#					{|resultSet| resultSet.insert_id}.getResult
	#gibt die id der letzen Insert-Aktion zurück
	#--------------------------------------------------------------------------------------
class SQLquery
	#--------------------------------------------------------------------------------------

	#aufruf: SQLquery.new([server,[user,[password,[database,]]]], query
	# die ersten Argumente können weggelassen werden
	def initialize(*args)
	#p query
	args= args.flatten
		@queryArray=Array.new
		@queryHash=Array.new
		query=args.pop
		dbs= args.pop || 'ib' 
		password= args.pop || 'focus'
		user=args.pop || 'topo'
		server=args.pop || 'server'				# change to   topofocus.t-link.de
		db = Mysql.new(server, user,password)
		db.select_db(dbs)
		begin
		@result = db.query(query.strip)
		rescue MysqlError
			print "ERROR: #{query.strip} \n"
			raise
		end
#		p @result.class
# 		Elemente über Namen ansprechen
		if  block_given?
#		print " block detected \n"
			@result=yield db
		elsif @result.class==MysqlRes
			@result.each_hash do
				 |row|
				 h=Hash.new
				 row.each{|x,y| h[x.to_sym]=y }
				 @queryHash.push(h) 
			end
			@result.data_seek(0)
			@result.each { |a| @queryArray.push(a) }
		elsif @result.nil?
			 @result= db.affected_rows
		end
		db.close
	end

	#Das Ergebnis der letzten mysql-Abfrage wird zurückgeben
	def getResult
		@result
	end
#	Übergabeparamter: Liste von Elementen.
#	Es wird ein Array mit den Werten zurückgegeben
	def getRows(*field)
#	p  @queryArray if field.empty?
		if field.empty? 
			@queryArray
		else
			(field.collect{|p| getField(p)}).transpose
		end
		
	end

#	Es wird die Größe der Ergebnismenge zurückgegeben (Anzahl der Ergebniszeilen)
	def getRowCount
		@result.num_rows
	end
#	Das Abfrageergebnis wird als Hash zurükgegeben.
#	Die Zeilen sind als Array organisiert: [{bez1 =>wert1, bez2=>wert2, ..}][{...}]...
#	Das Ergebnis kann mit pop oder each durchmustert werden
	def getHash
		@queryHash
	end
#
#	Übergabeparamter: Feldname.
#	Es wird ein Array mit den Elementen zurückgegeben
	def getField(field)
		thisResult=Array.new
#		puts "field="+field.to_s
		( field.instance_of? Fixnum)? @queryArray.each {|a|thisResult.push(a[field]) }:@queryHash.each { |a|thisResult.push(a[field])}
		return thisResult
	end

#	Das QueryErgebnis wird als String in einem Array zurückgegeben
	def getHoleItem(*field)
# 	die übergebenen Felder als Array populieren : [feld1/wert1, feld2/wert2, ... ] [..] ..
		thisResult=	(field.flatten!.collect!{|p| getField(p)}).transpose
# 	und dann die Unterarrays zu strings zusammenfassen
		thisResult.collect!{|p| p.join(" ") }
	end

#	Alle Felder der aktuellen Abfrage in ein Array einlesen
	def getFields
		fields = @result.fetch_fields.collect! {|f| f.name }
	end;

#	Die Datenbankfelder des aktuellen Datensatzes auslesen
#	und auf Stdout ausgeben.
	def getInfo
		fields = @result.fetch_fields.collect! {|f| f.name }
# 	Überschrift
		puts fields.join("\t")
# 	Daten
		@queryArray.each  { |row|  puts row.join("\t") }
	end

	def oneData
			@result.data_seek(0)
			@result.fetch_row[0] unless @queryHash.empty?
	end

=begin rdoc
gibt die Ergebnismenge der SQL-Abfrage als ein Array von OHLC Objekten zurück
=end
	def ohlc
		getHash.collect  do
			|row| 
		#	pp row
				a= OHLC.new(row) do 
							|data| 
							date= Time.at(data.delete( :date ).to_i)
							ohlcData=Hash.new
							data.each{|x,y| ohlcData[x]=y.to_f }
							[date,date,ohlcData ]
						end
				yield a if block_given?
		end
	end

end
#	Sonderfall der DatenbankabfrageKlasse
#	Es wird ein einziges Feld zurückgegeben
class SQLoneData < SQLquery

	attr_reader(:queryData)	# Zugriff von aussen auf den Wert gestatten

	def initialize(*args)
		super
			@result.data_seek(0)
			@queryData=@result.fetch_row[0] unless @result.fetch_row.nil?
			
	end
end
#--------------------------------------------------------------------------------------------------

#	Sonderfall der DatenbankabfrageKlasse.
#	Es wird eine in der Datenbank gespeicherte Abfrage ausgeführt
#
#todo::
# 	Der Name der abzufragenden Datenbanktabelle sollte in der Konfigurationsdatei festgelegt werden.
# 	derzeit: tf_Queries
class SQLstoredQuery < SQLquery

#	Die Abfrage, die in der angegebenen Tabellenzeile gespeichert ist, wird ausgeführt.
#	Die optionalen Argumente werden in die Abfrage integriert.
#	Das Abfrageergebnis wird in den StandardVariablen der Basisklasse abgelegt.
	def initialize(queryName,*arguments)
#	p arguments
#	p queryName
		query=SQLoneData.new("select query from queries where short='#{queryName}'")

		if arguments.length>0
			arguments.flatten!
			arguments.collect!{|x| "'"+x.to_s+"'"}	# die Argumente in Hochkommata setzen
			p arg=arguments.join(",")				# die einzelnen Argumente mit ',' trennen
# 	Vorbereitung  auf sprintf :  % gegen  &&  austauschen
			arg.gsub!(/[%]/ , '&&' )
			sQuery= <<AWT
sprintf("#{query.queryData}",#{arg})
AWT
# 	Maskierte:  % zurückwandeln
			sQuery.gsub!(/[&][&]/,'%')
												# Den ZeichenkettenAuswertungsString zusammensetzen
			super(eval(sQuery.strip))			# .. und umsetzen sowie die Basisklasse damit füllen
		else
			# keine Argrumente für die Query übergeben
			super(query.queryData)
		end
	end
end

# ------------------------------------------ standalone code ----------------------------------------------
 if $0 == __FILE__
 
 id=SQLquery.new('topofocus.de', 'fmp-consulting', 'bischoff', 'fmp1',"show tables")
 id.getInfo
 # execute a stored query	
  #stocks=SQLstoredQuery.new('getStocks',"")
 # and display its  result 
  #stocks.getInfo
#  require 'stock'
 # stock=Stock.new('dax')
 # stock.setContract(305)
 # puts "using#{stock.getDatabaseName }"
  #ins= [Time.now.strftime( "%Y-%m-%d %H:%M:%S"), 3456.5, 45]
  #ins.collect!{|x| "'"+x.to_s+"'"}
 # puts " doing insert "
 # id=SQLquery.new("insert into #{stock.getDatabaseName } ( date, price, volume ) values (#{ins.join(',')}) "){|resultSet| resultSet.insert_id}.getResult

#  p id
 end
 
=begin
from the ruby-talk mailing-list:
 You can only read a Mysql::Result object once because
each_key deletes the values as it reads them.
[Abba:/tmp] josephal% cat resulttest 
#!/usr/bin/ruby
require 'mysql'
m = Mysql.new("localhost", "root", "", "Development")
r = m.query("select * from processedfiles limit 5")
r.each_hash { |row| print "#{row['name']}\n" }
print "---------------------------------------\n"
r.each_hash { |row| print "#{row['name']}\n" }
print "------------------- -\nthis is the end\n"

[Abba:/tmp] josephal% resulttest 
AD030220
AD030221
AD030228
AD030307
AD000428
---------------------------------------
------------------- -
this is the end
[Abba:/tmp] josephal%
answer:
No, this corresponds to the way Mysql C API works. Use 
Mysql::Result#row_seek to return to the beginning of the result set. 
You shouldn't treat Mysql::Result as a in-memory Enumerable object, 
because there are usually resources allocated on the server for each 
Mysql::Result instance.
=end
