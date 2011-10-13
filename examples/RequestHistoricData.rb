#!/usr/bin/env ruby -w
#
# Copyright (C) 2007-8 Paul Legato. pjlegato at gmail dot com.
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
# >>         YOUR USE OF THIS PROGRAM IS ENTIRELY AT YOUR OWN RISK.                <<
# >> IT MAY CONTAIN POTENTIALLY COSTLY BUGS, ERRORS, ETC., BOTH KNOWN AND UNKNOWN. <<
#

$:.push(File.dirname(__FILE__) + "/../")

# IB-Ruby libraries
require 'ib'
require 'datatypes'
require 'symbols/futures'

# Stdlib
require 'time' # for extended time parsing

# An interesting opt to Hash parser.
require 'getopt/long'
include Getopt


opt = Getopt::Long.getopts(
   ["--help", BOOLEAN],
   ["--end", REQUIRED],
   ["--security", REQUIRED],
   ["--duration", REQUIRED],
   ["--barsize", REQUIRED],
   ["--header",BOOLEAN],
   ["--dateformat", REQUIRED],
   ["--nonregularhours", BOOLEAN],
   ["--verbose", BOOLEAN],
   ["--veryverbose", BOOLEAN]
)

if opt["help"] || opt["security"].nil? || opt["security"].empty?
  puts <<ENDHELP

** RequestHistoricData.rb - Copyright (C) 2007-8 Paul Legato.

 This library is free software; you can redistribute it and/or modify
 it under the terms of the GNU Lesser General Public License as
 published by the Free Software Foundation; either version 2.1 of the
 License, or (at your option) any later version.

 This library is distributed in the hope that it will be useful, but
 WITHOUT ANY WARRANTY; without even the implied warranty of
 MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU
 Lesser General Public License for more details.

 You should have received a copy of the GNU Lesser General Public
 License along with this library; if not, write to the Free Software
 Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA
 02110-1301 USA

 The author and this software are not connected with Interactive
 Brokers in any way, nor do they endorse us.

************************************************************************************

 >>         YOUR USE OF THIS PROGRAM IS ENTIRELY AT YOUR OWN RISK.                <<
 >> IT MAY CONTAIN POTENTIALLY COSTLY BUGS, ERRORS, ETC., BOTH KNOWN AND UNKNOWN. <<
 >> DO NOT USE THIS SOFTWARE IF YOU ARE UNWILLING TO ACCEPT ALL RISK IN DOING SO. <<

************************************************************************************


This program requires a TWS running on localhost on the standard port
that uses API protocol version 15 or higher. Any modern TWS should
work. (Patches to make it work on an arbitrary host/port are welcome.)

----------

One argument is required: --security, the security specification you want, in
"long serialized IB-Ruby" format. This is a colon-separated string of the format:

   symbol:security_type:expiry:strike:right:multiplier:exchange:primary_exchange:currency:local_symbol

Fields not needed for a particular security should be left blank (e.g. strike and right are only relevant for options.)

For example, to query the British pound futures contract trading on Globex expiring in September, 2008,
the correct command line is:

  ./RequestHistoricData.rb --security GBP:FUT:200809:::62500:GLOBEX::USD:

Consult datatypes.rb for allowed values, and see also the examples in the symbols/ directory (load them in
irb and run security#serialize_ib_ruby(ib_version) to see the appropriate string.)

***

Options:

--end is is the last time we want data for. The default is now.
  This is eval'ed by Ruby, so you can use a Ruby expression, which must return a Time object.


--duration is how much historic data we want, in seconds, before --end's time.
  The default is "1 D".
  The TWS-imposed limits is roughly  based on bar size (2 days per request 1 min.)
  Requests for more than limits worth of historic data will fail.
  When specifying a unit, historical data request duration format is integer{SPACE}unit (S|D|W|M|Y).
  Strings quotes are required for the duration switch.

--what determines what the data will be comprised of. This can be "trades", "midpoint", "bid", or "asked".
  The default is "trades".

--barsize determines how long each bar will be.

Possible values (from the IB documentation):

 1 = 1 sec
 2 = 5 sec
 3 = 15 sec
 4 = 30 sec
 5 = 1 minute
 6 = 2 minutes
 7 = 5 minutes
 8 = 15 minutes
 9 = 30 minutes
 10 = 1 hour
 11 = 1 day

 Values less than 4 do not appear to work for some securities.
 The default is 8, 15 minutes.

--nonregularhours :
 Normally, only data from the instrument's regular trading hours is returned.
 If --nonregularhours is given, all data available during the time
 span requested is returned, even data bars covering time
 intervals where the market in question was illiquid. If


--dateformat : a --dateformat of 1 will cause the dates in the returned
 messages with the historic data to be in a text format, like
 "20050307 11:32:16". If you set it to 2 instead, you
 will get an offset in seconds from the beginning of 1970, which
 is the same format as the UNIX epoch time.

 The default is 1 (human-readable time.)

--header : if present, prints a 1 line CSV header describing the fields in the CSV.

--veryverbose : if present, prints very verbose debugging info.
--verbose : if present, prints all messages received from IB, and print the data in human-readable
  format.

 Otherwise, in the default mode, prints only the historic data (and any errors), and prints the
 data in CSV format.

ENDHELP
#' <- fix broken syntax highlighting in Aquamacs
  exit

end

### Parameters

# DURATION is how much historic data we want, in seconds, before END_DATE_TIME.
# Date::Delta.new(1).in_secs is 1 day in seconds...86400  
DURATION = opt["duration"] || "1 D"

# if DURATION > 86400
#   STDERR.puts("\nTWS does not accept a --duration longer than 86400 seconds (1 day.) Please try again with a smaller duration.\n\n")
#   exit(1)
# end


# This is the last time we want data for.
END_DATE_TIME = (opt["end"] && eval(opt["end"]).to_ib) || Time.now.to_ib


# This can be :trades, :midpoint, :bid, or :asked
WHAT = (opt["what"] && opt["what"].to_sym) || :trades

# Possible bar size values:
# 1 = 1 sec
# 2 = 5 sec
# 3 = 15 sec
# 4 = 30 sec
# 5 = 1 minute
# 6 = 2 minutes
# 7 = 5 minutes
# 8 = 15 minutes
# 9 = 30 minutes
# 10 = 1 hour
# 11 = 1 day
#
# Values less than 4 do not appear to actually work; they are rejected by the server.
#
BAR_SIZE = (opt["barsize"] && opt["barsize"].to_i) || 8

# If REGULAR_HOURS_ONLY is set to 0, all data available during the time
# span requested is returned, even data bars covering time
# intervals where the market in question was illiquid. If useRTH
# has a non-zero value, only data within the "Regular Trading
# Hours" of the product in question is returned, even if the time
# span requested falls partially or completely outside of them.

REGULAR_HOURS_ONLY = opt["nonregularhours"] ? 0 : 1

# Using a DATE_FORMAT of 1 will cause the dates in the returned
# messages with the historic data to be in a text format, like
# "20050307 11:32:16". If you set :format_date to 2 instead, you
# will get an offset in seconds from the beginning of 1970, which
# is the same format as the UNIX epoch time.

DATE_FORMAT = (opt["dateformat"] && opt["dateformat"].to_i) || 1

VERYVERBOSE = !opt["veryverbose"].nil?
VERBOSE = !opt["verbose"].nil?

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
    123 => opt["security"]
  }


# First, connect to IB TWS.
ib = IB::IB.new


# Default level is quiet, only warnings printed.
IB::IBLogger.level = Logger::Severity::ERROR

# For verbose printing of each message:
IB::IBLogger.level = Logger::Severity::INFO if VERBOSE

# For very verbose debug messages:
IB::IBLogger.level = Logger::Severity::DEBUG if VERYVERBOSE

puts "datetime,open,high,low,close,volume,wap,has_gaps" if !opt["header"].nil?

lastMessageTime = Queue.new # for communicating with the reader thread.

#
# Subscribe to incoming HistoricalData events. The code passed in the
# block will be executed when a message of the subscribed type is
# received, with the received message as its argument. In this case,
# we just print out the data.
#
# Note that we have to look the ticker id of each incoming message
# up in local memory to figure out what security it relates to.
# The incoming message packet from TWS just identifies it by ticker id.
#
ib.subscribe(IB::IncomingMessages::HistoricalData, lambda {|msg|
               STDERR.puts @market[msg.data[:req_id]].description + ": " + msg.data[:item_count].to_s + " items:" if VERBOSE

               msg.data[:history].each { |datum|
                 puts(if VERBOSE
                        datum.to_s
                      else
                        "#{datum.date},#{datum.open.to_digits},#{datum.high.to_digits},#{datum.low.to_digits}," +
                          "#{datum.close.to_digits},#{datum.volume},#{datum.wap.to_digits},#{datum.has_gaps}"
                      end
                      )
               }
               lastMessageTime.push(Time.now)
             })

# Now we actually request historical data for the symbols we're
# interested in.  TWS will respond with a HistoricalData message,
# which will be received by the code above.

@market.each_pair {|id, contract|
  msg = IB::OutgoingMessages::RequestHistoricalData.new({
                                                          :ticker_id => id,
                                                          :contract => contract,
                                                          :end_date_time => END_DATE_TIME,
                                                          :duration => DURATION, # seconds == 1 hour
                                                          :bar_size => BAR_SIZE, # 1 minute bars
                                                          :what_to_show => WHAT,
                                                          :use_RTH => REGULAR_HOURS_ONLY,
                                                          :format_date => DATE_FORMAT
                                                        })
  ib.dispatch(msg)
}


# A complication here is that IB does not send any indication when all historic data is done being delivered.
# So we have to guess - when there is no more new data for some period, we interpret that as "end of data" and exit.

while true
  lastTime = lastMessageTime.pop # blocks until a message is ready on the queue
  sleep 2 # .. wait ..
  exit if lastMessageTime.empty? # if still no more messages after 2 more seconds, exit.
end

