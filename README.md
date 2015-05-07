# ib-ruby

Ruby Implementation of the Interactive Brokers Trader Workstation (TWS) API v.965-967.
## Development-Branch, Environment: Ruby 2.20, ActiveModel,  Rspec3/Guard-Testsuite

The hole TWS-Environment is accessible through Ruby-Objects.

IB::Gateway is the root. It manages a list of TWS-Users. 
An Advisor, who manages a list of contract-queries
and ActiveAccounts, where AccountValues, PortfolioValues and Orders are linked.

Whenever queries are send to the TWS, the response is stored in the object-tree
and can then read out with standard Array-Methods.

Thus ib-ruby supports the following workflow

* Application sends Request 
* IB::Gateway transmits to the TWS
* TWS-Response is stored in Object-Tree
* Application gets Response
* Application reads the evaluated response from Object-Tree

Time-critical operations are encapsulated in IB::Connection, which itself is
managed by IB::Gateway. IB::Gateway takes care of interrupted connections to the TWS
and tolerates the daily reset of the TWS, and thus enables a 24/7-operation-mode.

However, ib-ruby offers a simple translation of ruby-queries to tws-socket-codes and
offers the pure TWS-response as well. The usage of the object-tree is optional.
Any code for previous versions of the programm should work.

For more details refer to the [introduction](intro.md)
and for programming hints the [integration](integration.md) section.

### Changes from the stable branch


* Only ActiveModel-Support. 
* Alert-Messages are handled by IB::Alerts
* IB::Stock, IB::Future, IB::Forex are derived from IB::Contract
* IB::Account model added, where contracts, orders, positions and AccountValues are present
* IB::Gateway builds an object-orientated representation of Accounts with pending and completed 
Orders, Positions and Contracts. A thread-safe access to objects which are updated concurrently 
by the TWS is realized.

An Example
``` ruby
    require 'ib'
    
    gw= IB::Gateway.new get_account_data:true  # connects to the TWS by default
    accounts = gw.active_accounts
    accounts.each do |account|
     puts account.simple_account_data_scan('AccountCode')
     puts account.simple_account_data_scan('TotalCashValue')
     puts account.contracts.map &:to_human 
     puts account.portfolio_values &:to_human
    end
    gw.disconnect
 ``` 
 leads to
 ```
 <AccountCode=DU167348 >
 <TotalCashValue=601740.49 EUR>
 <TotalCashValue-C=29290.41 EUR>
 <TotalCashValue-S=572450.08 EUR>
 <Stock: BLUE EUR>
 <Stock: CBA AUD>
 <Stock: CIEN USD>
 <PortfolioValue: <Stock: BLUE EUR> (720): Market 25.3299999 price 18237.6 value; PnL: 1934.31 unrealized, 0.0 realized;>
 <PortfolioValue: <Stock: CBA AUD> (1004): Market 83.1100006 price 83442.44 value; PnL: 3761.55 unrealized, 0.0 realized;
 ```
* To Query the TWS manualy, the IB::Connection-Object is always available via IB::Gateway.tws, eg.
```ruby
   IB::Gateway.tws.send_message(...)
   IB::Gateway.tws.subscribe(...)
```
The previous way to access the TWS by initializing IB::Connection is still supported. 
IB::Connection.current is replaced by IB::Gateway.tws






Copyright (C) 2006-2014 Paul Legato, Wes Devauld, Ar Vicco and Hartmut Bischoff.

https://github.com/ib-ruby/ib-ruby

__WARNING:__ This software is provided __AS-IS__ with __NO WARRANTY__, express or
implied. Your use of this software is at your own risk. It may contain any number
of bugs, known or unknown, which might cause you to lose money if you use it.
You've been warned.

This code is not sanctioned or supported by Interactive Brokers.

## SUMMARY:

This is a pure Ruby implementation of Interactive Brokers API. It is NOT a wrapper
for a Java or C++ API, but rather uses socket API directly. So it does not have any
dependencies other than TWS/Gateway itself.

Why Ruby? Many people are put off by the amount of boilerplate code/plumbing required
by Java, ActiveX or C++ API to do even the simplest of things, like getting account
data and placing/monitoring orders. This library intends to keep all the fluff away
and let you focus on writing your business logics, rather than useless boilerplate.

No more endless definitions of obligatory methods you'd never need, no spaghetti code
to divide your execution flow between multiple callbacks and interfaces.

Instead, a very simple paradigm is offered: your code interacts with the server
(TWS or Gateway) via exchange of messages. You subscribe to the server messages
that you're interested in, and send messages to server that request specific data
from it. You wait for specific messages being received, or other conditions you
define. The execution flow is under your control, rather than delegated somewhere.

Using this clear paradigm, you can hack together a simple automation of your
daily TWS-related routine in just a couple of minutes. Alternatively, you can
create a mechanical trading system with complex order processing logics, that
contains 1/10th of code and is 500% more maintaineable than it is possible with
other API implementations. The choice is yours.

## INSTALLATION:

### From Source

    $ git clone https://github.com/ib-ruby/ib-ruby
    $ cd ib-ruby; rake gem:install

## PREREQUISITES:

1. Install Interactive Brokers connectivity software: either
   [TWS](http://www.interactivebrokers.com/en/p.php?f=tws) or
   [Gateway](http://www.interactivebrokers.com/en/p.php?f=programInterface&ib_entity=llc)

2. Configure the software to allow API connections from the computer you plan to run
   ib-ruby on, which is typically localhost (127.0.0.1) if you're running ib-ruby on
   the same machine as TWS/Gateway. [Here](http://www.youtube.com/watch?v=53tmypRq5wI)
   you can see how this is done for TWS.

3. Make sure sure your ib-ruby gem version is compatible with your software version.
   As a rule of thumb, most recent ib-ruby gem only supports latest versions of
   TWS/Gateway API. Older versions of API are supported by previous gem versions:

    | ib-ruby gem | TWS version | API version  |
    |:------------|------------:|:------------:|
    | 0.5.21      |    918-920  |    965       |
    | 0.6.1       |    921-923  |    966       |
    | 0.7.1       |    924-925  |    966       |
    | 0.8.1       |    926-930  |    967 beta  |
    | 0.9.0+      |    931-932  |    967 final |

4. Start Interactive Broker's Trader Work Station or Gateway before your code
   attempts to connect to it. Note that TWS and Gateway listen to different ports,
   this library assumes connection to Gateway on the same machine (localhost:4001)
   by default, this can be changed via :host and :port options given to IB::Connection.new.

## SYNOPSIS:

This is an example of your script that requests and prints out account data, then
places limit order to buy 100 lots of WFC and waits for execution. All in about ten
lines of code - and without sacrificing code readability or flexibility.
``` ruby
    require 'ib'

    ib = IB::Connection.new :port => 7496
    ib.subscribe(:Alert, :AccountValue) { |msg| puts msg.to_human }
    ib.send_message :RequestAccountData
    ib.wait_for :AccountDownloadEnd

    ib.subscribe(:OpenOrder) { |msg| puts "Placed: #{msg.order}!" }
    ib.subscribe(:ExecutionData) { |msg| puts "Filled: #{msg.execution}!" }
    contract = IB::Contract.new :symbol => 'WFC', :exchange => 'NYSE',
                                :currency => 'USD', :sec_type => :stock
    buy_order = IB::Order.new :total_quantity => 100, :limit_price => 21.00,
                                :action => :buy, :order_type => :limit
    ib.place_order buy_order, contract
    ib.wait_for :ExecutionData
```
Your code interacts with TWS via exchange of messages. Messages that you send to
TWS are called 'Outgoing', messages your code receives from TWS - 'Incoming'.

First, you need to subscribe to incoming message types you're interested in
using `Connection#subscribe`. The code block (or proc) given to `#subscribe`
will be executed when an incoming message of the this type is received from TWS,
with the received message as its argument.

Then, you request specific data from TWS using `Connection#send_message` or place
your order using `Connection#place_order`. TWS will respond with messages that you
should have subscribed for, and these messages will be processed in a code block
given to `#subscribe`.

In order to give TWS time to respond, you either run a message processing loop or
just wait until Connection receives the messages type you requested.

See `lib/ib/messages` for a full list of supported incoming/outgoing messages
and their attributes. The original TWS docs and code samples can also be found
in `misc` directory.

Sample scripts in `example` directory demonstrate common ib-ruby use cases. Examples
show you how to access account info, print real time quotes, retrieve historic or
fundamental data, request options calculations, place, list, and cancel orders.
You may also want to look into `spec/integration` directory for more scenarios,
use cases and examples of handling IB messages.



## DB BACKEND:

If you want to take advantage of data persistance layer ActiveRecord ORM, you have to set up the database
(SQLite recommended for simplicity) and run migrations located at gems 'db/migrate' folder.

You further need to:
``` ruby
    require 'ib/db'
    IB::DB.connect :adapter => 'sqlite3', :database => 'db/test.sqlite3'
    require 'ib'
```
Only require 'ib' AFTER you've connected to DB, otherwise your Models will not
inherit from ActiveRecord::Base and won't be persistent. 

Now, all your IB Models are just ActiveRecords and you can save them to the DB.

## RUNNING TESTS:

The gem comes with a spec suit that may be used to test ib-ruby compatibility with your
specific TWS/Gateway installation. Please read 'spec/Readme.md' for more details about
running specs.


## CONTRIBUTING:

If you want to contribute to ib-ruby development:

1. Make a fresh fork of ib-ruby (Fork button on top of Github GUI)
2. Clone your fork locally (git clone /your fork private URL/)
3. Add main ib-ruby repo as upstream (git remote add upstream git://github.com/ib-ruby/ib-ruby.git)
4. Create your feature branch (git checkout -b my-new-feature)
5. Modify code as you see fit
6. Commit your changes (git commit -am 'Added some feature')
7. Pull in latest upstream changes (git fetch upstream -v; git merge upstream/master)
8. Push to the branch (git push origin my-new-feature)
9. Go to your Github fork and create new Pull Request via Github GUI

... then proceed from step 5 for more code modifications...

## LICENSE:

This software is available under the LGPL.

This library is free software; you can redistribute it and/or modify
it under the terms of the GNU Lesser General Public License as
published by the Free Software Foundation; either version 2.1 of the
License, or (at your option) any later version.

This library is distributed in the hope that it will be useful, but
WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the file LICENSE
for full licensing details of GNU Lesser General Public License.

You should have received a copy of the GNU Lesser General Public
License along with this library; if not, write to the Free Software
Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA
02110-1301 USA

