
#!/usr/bin/env ruby
#
# Your script description here...

require 'bundler/setup'
require 'ib-gateway'
require 'yaml'


# First, connect to IB TWS and subscribe for events. 
ib = IB::Gateway.new :client_id => 1112  do | gw | #, :port => 7497 # TWS

	# Subscribe to TWS alerts/errors
	gw.subscribe(:Alert) { |msg| puts msg.to_human }
	# Set log level
	gw.logger.level = Logger::FATAL # DEBUG  -- INFO -- WARN -- ERROR  -- FATAL

end
# Put your code here
# ...
 IB::Symbols.allocate_collection :w500

 puts
 puts '*'*40
 puts "(1) asynchon fetching of snapshot data "
 start =  Time.now; 
 IB::Symbols::W500.bunch(45,1){|x| x.map{|y| y.market_price(thread: true)}}; 
 
 print "Finished  Time:"
 puts second_duration = Time.now - start
 puts "Prices: "; sleep(7)
 puts IB::Symbols::W500.map{|x| x.misc.last}.join( ' - ' )

 IB::Gateway.current.reconnect
 puts '*'*40
 puts "(2) sequencial fetching of snapshot data "
 start =  Time.now; 
 prices = IB::Symbols::W500.map &:market_price
 
 print "Finished  Time:"
 puts first_duration = Time.now - start

 puts "Prices: #{prices.map( &:to_s ).join(" - ")}"


 puts 
 puts "first_duration:  #{first_duration} s "
 puts "second_duration:  #{second_duration} s "

 puts "finished"
