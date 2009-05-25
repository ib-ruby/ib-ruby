#!/usr/bin/env ruby -w
#
# Copyright (C) 2007 Paul Legato.
# 
# This library is free software; you can redistribute it and/or modify
# it under the terms of the GNU Lesser General Public License as
# published by the Free Software Foundation; either version 2.1 of the
# License, or (at your option) any later version.
#
# This library is distributed in the hope that it will be useful, but
# WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU
# Lesser General Public License for more details.
#
# You should have received a copy of the GNU Lesser General Public
# License along with this library; if not, write to the Free Software
# Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA
# 02110-1301 USA
#
#####################################################################
#
# This program demonstrates how to download historic data and write it
# to a CSV file.
#
# To use, set CSV_FILE to the file you want to write (which will be
# overwritten automatically if it already exists), set the contract
# data, duration, data type (trades, bid, ask, midpoint), etc. as you
# like, and run the program.
#
# Note that it does not detect when the historic data from the server
# has stopped arriving automatically. This limitation will be
# addressed soon. For now, just press <Enter> when the data stream on
# the console stops, and the output file will be closed and the
# program terminated.
#

# Where to write output:
CSV_FILE = "/tmp/HistoricQuotes.csv"


$:.push(File.dirname(__FILE__) + "/../")

require 'ib'
require 'datatypes'
require 'symbols/futures'

#
# Definition of what we want market data for.  We have to keep track
# of what ticker id corresponds to what symbol ourselves, because the
# ticks don't include any other identifying information.
# 
# The choice of ticker ids is, as far as I can tell, arbitrary.
#
# Note that as of 4/07 there is no historical data available for forex spot.
#
@market = 
  {
    123 => IB::Symbols::Futures[:jpy]
  }


# First, connect to IB TWS.
ib = IB::IB.new

# Uncomment this for verbose debug messages:
# IB::IBLogger.level = Logger::Severity::DEBUG

#
# Now, subscribe to HistoricalData incoming events.  The code
# passed in the block will be executed when a message of that type is
# received, with the received message as its argument. In this case,
# we just print out the data.
# 
# Note that we have to look the ticker id of each incoming message
# up in local memory to figure out what it's for.
#
# (N.B. The description field is not from IB TWS. It is defined
#  locally in forex.rb, and is just arbitrary text.)

csv = File.open(CSV_FILE, "w")

ib.subscribe(IB::IncomingMessages::HistoricalData, lambda {|msg|
               puts @market[msg.data[:req_id]].description + ": " + msg.data[:item_count].to_s + " items:"
               msg.data[:history].each { |datum|
                 puts "   " + datum.to_s
                 csv.puts "#{datum.date},#{datum.open.to_digits},#{datum.high.to_digits},#{datum.low.to_digits},#{datum.close.to_digits},#{datum.volume}"
               }
             })
 
# Now we actually request historical data for the symbols we're
# interested in.  TWS will respond with a HistoricalData message,
# which will be received by the code above.

@market.each_pair {|id, contract|
  msg = IB::OutgoingMessages::RequestHistoricalData.new({
                                                          :ticker_id => id,
                                                          :contract => contract,
                                                          :end_date_time => Time.now.to_ib,
                                                          :duration => (60 * 60 * 24).to_s, # seconds 
                                                          :bar_size => 4, # 30 sec
                                                          :what_to_show => :trades,
                                                          :use_RTH => 0,
                                                          :format_date => 2
                                                        })
  ib.dispatch(msg)
}

         
puts "\n\nPress <Enter> when done..\n\n"
gets
csv.close

