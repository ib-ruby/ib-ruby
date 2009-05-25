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
require 'symbols/futures'

# First, connect to IB TWS.
ib = IB::IB.new

# Uncomment this for verbose debug messages:
# IB::IBLogger.level = Logger::Severity::DEBUG

## Subscribe to the messages that TWS sends in response to a request
## for account data.

ib.subscribe(IB::IncomingMessages::AccountValue, lambda {|msg|
               puts msg.to_human
             })

ib.subscribe(IB::IncomingMessages::PortfolioValue, lambda {|msg|
               puts msg.to_human
             })

ib.subscribe(IB::IncomingMessages::AccountUpdateTime, lambda {|msg|
               puts msg.to_human
             })



msg = IB::OutgoingMessages::RequestAccountData.new({
                                                     :subscribe => true,
                                                     :account_code => ''
                                                   })
ib.dispatch(msg)

         
puts "\n\n\t******** Press <Enter> to quit.. *********\n\n"

gets

puts "Cancelling account data subscription.."

msg = IB::OutgoingMessages::RequestAccountData.new({
                                                     :subscribe => false,
                                                     :account_code => ''
                                                   })
ib.dispatch(msg)


puts "Done."

