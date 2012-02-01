# ib-ruby

Ruby Implementation of the Interactive Brokers Trader Workstation (TWS) API v.965.

Copyright (C) 2006-2011 Paul Legato, Wes Devauld, and Ar Vicco.

https://github.com/ib-ruby/ib-ruby

__WARNING:__ This software is provided __AS-IS__ with __NO WARRANTY__, express or
implied. Your use of this software is at your own risk. It may contain
any number of bugs, known or unknown, which might cause you to lose
money if you use it. You've been warned.

__It is specifically NOT RECOMMENDED that this code be used for live trading.__

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

    >> require 'ib-ruby'
    >> ib = IB::Connection.new
    >> ib.subscribe(:Alert, :AccountValue) { |msg| puts msg.to_human }
    >> ib.send_message :RequestAccountData, :subscribe => true

Your code and TWS interact via an exchange of messages. You
subscribe to message types you're interested in using
`IB::Connection#subscribe` and request data from TWS using
`IB::Connection#send_message`.

The code blocks (or procs) given to `#subscribe` will be executed when
a message of the requested type is received, with the received message as
its argument.

See `lib/ib-ruby/messages` for a full list of supported incoming/outgoing messages and
their attributes. The original TWS docs and code samples can be found
in the `misc/` folder.

The sample scripts in the `bin/` directory provide examples of how
common tasks can be achieved using ib-ruby.


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

