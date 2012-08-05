#!/usr/bin/env ruby
#
#  This script is used for testing and experimenting.
#

require 'rubygems'
require 'bundler/setup'
$LOAD_PATH.unshift File.expand_path(File.dirname(__FILE__) + '/../lib')
require 'ib-ruby'

# define forex contract like this
#@market = {123 => IB::Symbols::Forex[:gbpusd],
#           456 => IB::Symbols::Forex[:eurusd],
#           789 => IB::Symbols::Forex[:usdcad]}
#

# test invalid symbol  
  @market = {
    1 => IB::Symbols::Forex[:abcdef]
    }
    
@prices = Array.new(2)
@gotall = false

# connect to IB TWS.
ib = IB::Connection.new :client_id => 1112, :port => 7496 # TWS

## Subscribe to TWS alerts/errors
ib.subscribe(:Alert) { |msg| puts msg.to_human }

# Subscribe to TickerPrice and TickerSize events.
# (only print msg if it includes price)
ib.subscribe(:TickPrice, :TickSize) do |msg|
  puts @market[msg.ticker_id].description + ": " + msg.to_human if msg.to_human.include?("price")
 
  if @market[msg.ticker_id].description == "AUDCHF" then
    @prices[0] = msg.to_human.scan(/\d*\.\d*/) if msg.to_human.include?("ask_price")
    @prices[1] = msg.to_human.scan(/\d*\.\d*/) if msg.to_human.include?("bid_price")
  end
    
  puts "Got all prices! #{@prices.inspect}" unless @prices.include?(nil)
  
  @gotall = true unless @prices.include?(nil)
  if @gotall then
    @prices.flatten!
    @prices[0] = @prices[0].to_f
    @prices[1] = @prices[1].to_f

    puts "Cancel data subscription ..."
    @market.each_pair { |id, _| ib.send_message :CancelMarketData, :id => id }
    puts "Done!"
  end
end

# request market data for the subscribed symbols.
@market.each_pair do |id, contract|
  ib.send_message :RequestMarketData, :ticker_id => id, :contract => contract
end

puts "\nSubscribed to market data"
puts "\n******** Press <Enter> to cancel... *********\n\n"
STDIN.gets


