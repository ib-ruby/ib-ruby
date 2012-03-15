# ib-ruby

Ruby Implementation of the Interactive Brokers Trader Workstation (TWS) API v.965.

Copyright (C) 2006-2011 Paul Legato, Wes Devauld, and Ar Vicco.

https://github.com/ib-ruby/ib-ruby

__WARNING:__ This software is provided __AS-IS__ with __NO WARRANTY__, express or
implied. Your use of this software is at your own risk. It may contain
any number of bugs, known or unknown, which might cause you to lose
money if you use it. You've been warned.

This code is not sanctioned or supported by Interactive Brokers
This software is available under the LGPL. See the file LICENSE for full licensing details.

## REQUIREMENTS:

Either the Interactive Brokers
[TWS](http://www.interactivebrokers.com/en/p.php?f=tws) or
[IB Gateway](http://www.interactivebrokers.com/en/control/systemstandalone-ibGateway.php?os=unix&ib_entity=llc)
software must be installed and configured to allow API connections
from the computer you plan to run ib-ruby on, which is typically
localhost if you're running ib-ruby on the same machine as TWS.

## INSTALLATION:

### From RubyGems

    $ sudo gem install ib-ruby

### From Source

    $ git clone https://github.com/ib-ruby/ib-ruby
    $ cd ib-ruby; rake gem:install

## SYNOPSIS:

First, start up Interactive Broker's Trader Work Station or Gateway.
Make sure it is configured to allow API connections on localhost.
Note that TWS and Gateway listen to different ports, this library assumes
connection to Gateway (localhost:4001) by default, this can changed via :host
and :port options given to IB::Connection.new.

    require 'ib-ruby'

    ib = IB::Connection.new
    ib.subscribe(:Alert, :AccountValue) { |msg| puts msg.to_human }
    ib.send_message :RequestAccountData
    ib.wait_for :AccountDownloadEnd

    ib.subscribe(:OpenOrder) { |msg| puts "Placed: #{msg.order}!" }
    ib.subscribe(:ExecutionData) { |msg| puts "Filled: #{msg.execution}!" }
    contract = IB::Models::Contract.new :symbol => 'WFC',
                                        :exchange => 'NYSE'
                                        :currency => 'USD',
                                        :sec_type => IB::SECURITY_TYPES[:stock]
    buy_order = IB::Models::Order.new :total_quantity => 100,
                                      :limit_price => 21.00,
                                      :action => 'BUY',
                                      :order_type => 'LMT'
    ib.place_order buy_order, contract
    ib.wait_for :ExecutionData

Your code interacts with TWS via exchange of messages. Messages that you send to
TWS are called 'Outgoing', messages your code receives from TWS - 'Incoming'.

First, you need to subscribe to incoming message types you're interested in
using `Connection#subscribe`. The code block (or proc) given to `#subscribe`
will be executed when an incoming message of the requested type is received
from TWS, with the received message as its argument.

Then, you request specific data from TWS using `Connection#send_message` or place
your order using `Connection#place_order`. TWS will respond with messages that you
should have subscribed for, and these messages will be processed in a code block
given to `#subscribe`.

In order to give TWS time to respond, you either run a message processing loop or
just wait until Connection receives the messages type you requested.

See `lib/ib-ruby/messages` for a full list of supported incoming/outgoing messages
and their attributes. The original TWS docs and code samples can be found
in `misc` directory.

The sample scripts in `bin` directory provide examples of how common tasks
can be achieved using ib-ruby. You may also want to look into `spec/integration`
directory for more scenarios and examples of handling IB messages.

## LICENSE:

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

