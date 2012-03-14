#!/usr/bin/env ruby

# This script reproduces https://github.com/ib-ruby/ib-ruby/issues/12

require 'pathname'
LIB_DIR = (Pathname.new(__FILE__).dirname + '../lib/').realpath.to_s
$LOAD_PATH.unshift LIB_DIR unless $LOAD_PATH.include?(LIB_DIR)

require 'rubygems'
require 'bundler/setup'
require 'ib-ruby'

contract = IB::Models::Contract.new :symbol=> 'AAPL',
                                    :exchange=> "Smart",
                                    :currency=> "USD",
                                    :sec_type=> IB::SECURITY_TYPES[:stock],
                                    :description=> "Some stock"
ib = IB::Connection.new
ib.subscribe(:Alert) { |msg| puts msg.to_human }
ib.subscribe(:TickGeneric, :TickString, :TickPrice, :TickSize) { |msg| puts msg.inspect }
ib.send_message :RequestMarketData, :id => 123, :contract => contract

puts "\nSubscribed to market data"
puts "\n******** Press <Enter> to cancel... *********\n\n"
gets
puts "Cancelling market data subscription.."
