require 'ncurses'
require 'drb'
require 'stock'
require 'drb/observer'
class NcursesWindow
	include Ncurses
	# initialisiert die Ncurses-Umgebung
	def initialize(title="ib_ticker")
		@win=Array.new
		
	 	Ncurses.initscr()
  	 	Ncurses.cbreak()
  	 	Ncurses.noecho()
		# start_color muss alle Farb-Definitionen vorangehen	
		Ncurses.start_color()
		Ncurses.init_color(COLOR_WHITE,1000,1000,1000)
 		Ncurses.init_pair(1,COLOR_BLACK, COLOR_WHITE)
		Ncurses.init_pair(2, COLOR_BLUE, COLOR_WHITE)
 		Ncurses.init_pair(3, COLOR_GREEN, COLOR_WHITE)
 		Ncurses.init_pair(4, COLOR_RED, COLOR_WHITE)
 		@color={ "normal" => Ncurses.COLOR_PAIR(1) ,
 						"blue" => Ncurses.COLOR_PAIR(2) ,
  						"green" => Ncurses.COLOR_PAIR(3) ,
 						"red" => Ncurses.COLOR_PAIR(4) }
		@dimFenster={ :width =>29, :height => (Ncurses.LINES / 1).to_i-1}	# /1: volle Bildschirmhohe , /2: halbee höhe...
		e=Ncurses::WINDOW.new(0,0,0,0)
  	 	e.bkgd(@color["normal"])
		e.attron(@color["blue"])
 		e.mvprintw(0,(Ncurses.COLS / 2)-5 ,title)
		e.attroff(@color["blue"])
		
		Ncurses::Panel::PANEL.new(e)
	end
	
	
	# erzeugt ein neues Fenster und gibt die  FensterNummer zurueck
	def allocateWindow(stock,colorBorder='normal', colorWindow='normal')
		  	# Ncurses::WINDOW.new(Höhe, Breite, X-Pos, Y-Pos)
   			# Ist Höhe oder Breite 0, wird die maximal mögliche Ausbreitung verwendet
		countFenster=@win.size
		
		if (countFenster+1)* @dimFenster[:width] > Ncurses.COLS 
			top=@dimFenster[:height]+2
			colFenster= countFenster- (Ncurses.COLS/@dimFenster[:width]).to_i  
			
		else
			top=1
			colFenster=countFenster
		end
		eins = Ncurses::WINDOW.new(@dimFenster[:height]	,
													@dimFenster[:width],
													top, 
													colFenster*@dimFenster[:width])
   		eins.bkgd(@color[colorBorder])
		# Nun malen wir noch hübsche Rahmen in unser Fenster
   		eins.border(*([0] * 8))
   	 # Ausserdem sollten wir sie einen Panel hinzufügen, damit sie immer
  	 # aktualisiert werden, wenn wir Ncurses::Panel.update aufrufen. Bei
   	 # Ncurses wird erst alles in einen Buffer geschrieben und erst mit
   	 # entsprechenden Refresh-Aufrufen wirklich auf dem Bildschirm dargestellt!
  		Ncurses::Panel::PANEL.new(eins)
 	 # Nun machen wir uns unsere inneren Fenster, damit der Rahmen nicht
   	 # übermalt wird, machen wir sie um je ein Zeichen pro Rand kleiner
 	
		@win[countFenster] = Ncurses::WINDOW.new(@dimFenster[:height] - 2,
													@dimFenster[:width] - 2,
													 top+1,
													  (colFenster*@dimFenster[:width]) +1)
   		@win[countFenster].bkgd(@color[colorWindow])
	  # Und wieder fügen wir sie dem Panel hinzu
		Ncurses::Panel::PANEL.new(@win[countFenster])
	  # Wenn wir am Ende des Fensters angekommen sind, soll weiterscrollt werden
  		@win[countFenster].scrollok(true)
		
		eins.mvprintw(0,4,stock.ibSymbol)
		display countFenster,""
		countFenster
	end
	# schreibt den Text auf das Fenster
	def display(window,message,color="normal")
		@win[window].attron(@color[color])	 
		@win[window].printw(message<<"\n")		
		 @win[window].attroff(@color[color])
		 Ncurses::Panel.update
		 Ncurses.doupdate
	end
	# diese Routine vertraegt sich nicht mit dem KursImport
	def getInput
		loop do
			display(0,'press a key or "d" to exit')
			ch=@eins.getch
			display(0,"you pressed #{ch}")
			break if ch==100
		end
	end
	

	# AufraeumAktionen zum Ende der Apllikation
	def finishIt
			Ncurses.echo()
  			Ncurses.nocbreak()
  			Ncurses.nl()
			Ncurses.endwin		
	end
end	

class NcursesTicker 
	include DRb::DRbUndumped
	attr_reader :a, :eins, :zwei
	
	def initialize(stock, server, ncurses)
		x=server.connectTicker(stock)
		x.add_observer(self)
		@nc=ncurses
		@window=ncurses.allocateWindow(stock)
		@last=[0,'normal']
		@formatstr="%7."+Math::log10(1/stock.tickSize).ceil.to_s+"f"
	  end
	
	
	
	
	def update(time, price,volume) # callback for observer 
	if @last[0]< price
		color="blue"
	elsif @last[0]==price
		color=@last[1]
	else
		color="red"
	end
	
	displaystr= sprintf(  "%s#{@formatstr} <> %5d" , time.strftime('%H:%M:%S->'), price, volume)
	@nc.display( @window, displaystr, color)
#	@nc.display(@window,"#{time.strftime('%H:%M:%S')} ->#{"%7.2f" % price} <>#{"%5d"% volume}",color)
	@last=[price,color]
	end
end 

# ------------------------------------------ standalone code ----------------------------------------------
 if $0 == __FILE__
#require 'optparse'
#opts= OptionParser.new

 	host='server'
	port=33810
#furtherArguments=opts.parse(ARGV)

tickerArray=Array.new
exception = nil
threads=[]
	DRb.start_service
 	server=DRbObject.new(nil,"druby://#{host}:#{port}")
begin
	nc=NcursesWindow.new
	if ARGV.empty?
		[ 'stoxx', 'dax',  'bund', 'es', 'russel'].each do |fut|
		
			s=Stock.new(fut)
			tickerArray.push(NcursesTicker.new(s,server,nc))
		end
	else
		until ARGV.empty? do
			s=Stock.new(ARGV.shift)
			tickerArray.push(NcursesTicker.new(s,server,nc))
			
		end
	end
	$stdin.readline
	rescue DRb::DRbConnError => e 
		nc.finishIt
		print "\n no running ticker found \n " 
		
#	rescue Exception => exception
	
	ensure 
# put the screen back in its normal state
  	nc.finishIt
  
end

# Exceptions zeigen wir auch besser an, wenn wir sie sehen können. Also jetzt ;)
if exception
   raise exception
end		
				
				
end			
