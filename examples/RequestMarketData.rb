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

$:.push(File.dirname(__FILE__) + "/../")

require 'ib'
require 'datatypes'
require 'symbols/forex'

#
# Definition of what we want market data for.  We have to keep track
# of what ticker id corresponds to what symbol ourselves, because the
# ticks don't include any other identifying information.
# 
# The choice of ticker ids is, as far as I can tell, arbitrary.
#
@market = 
  {
    123 => IB::Symbols::Forex[:gbpusd],
    456 => IB::Symbols::Forex[:eurusd]
  }


# First, connect to IB TWS.
ib = IB::IB.new


#
# Now, subscribe to TickerPrice and TickerSize events.  The code
# passed in the block will be executed when a message of that type is
# received, with the received message as its argument. In this case,
# we just print out the tick.
# 
# Note that we have to look the ticker id of each incoming message
# up in local memory to figure out what it's for.
#
# (N.B. The description field is not from IB TWS. It is defined
#  locally in forex.rb, and is just arbitrary text.)

ib.subscribe(IB::IncomingMessages::TickPrice, lambda {|msg|
               puts @market[msg.data[:ticker_id]].description + ": " + msg.to_human
             })

ib.subscribe(IB::IncomingMessages::TickSize, lambda {|msg|
               puts @market[msg.data[:ticker_id]].description + ": " + msg.to_human
             })


# Now we actually request market data for the symbols we're interested in.

@market.each_pair {|id, contract|
  msg = IB::OutgoingMessages::RequestMarketData.new({
                                                      :ticker_id => id,
                                                      :contract => contract
                                                    })
  ib.dispatch(msg)
}

         
puts "Main thread going to sleep. Press ^C to quit.."
while true
  sleep 2
end
