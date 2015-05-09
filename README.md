# ib-ruby

Ruby Implementation of the Interactive Brokers Trader Workstation (TWS) API v.965-967.

Copyright (C) 2006-2013 Paul Legato, Wes Devauld, and Ar Vicco.

https://github.com/ib-ruby/ib-ruby

__WARNING:__ This software is provided __AS-IS__ with __NO WARRANTY__, express or
implied. Your use of this software is at your own risk. It may contain any number
of bugs, known or unknown, which might cause you to lose money if you use it.
You've been warned.

This code is not sanctioned or supported by Interactive Brokers.

##ANNOUNCE:
Checkout Branch »Gateway«  for support of FA-(aka Friends & Family)-Accounts.
Its a release-candidate for Version 0.9.3

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

### From RubyGems

    $ sudo gem install ib-ruby [-v version]

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

## RAILS INTEGRATION:

This gem has two operating modes: standalone and Rails-engine. If you require it in a
Rails environment, it loads Rails engine automatically. Otherwise, it does not load any
Rails integration.

To add ib-ruby to your Rails 3 project, follow these steps:

Add to your Gemfile:
``` ruby
gem 'ib-ruby', '~>0.9'
```
Add the require to your config/application.rb:
``` ruby
require File.expand_path('../boot', __FILE__)
require 'rails/all'
require 'ib'
if defined?(Bundler)
```
Now run:

    $ bundle install
    $ rake ib:install:migrations
    $ rake db:migrate

This will install ib-ruby gem and copy its migrations into your Rails apps migrations.

You can now use or modify IB models, develop controllers and views for them in your Rails app.

## DB BACKEND:

Even if you don't use Rails, you can still take advantage of its data persistance layer
(ActiveRecord ORM). In order to use data persistance, you have to set up the database
(SQLite recommended for simplicity) and run migrations located at gems 'db/migrate' folder.
It is recommended that you use a gem like [standalone_migrations](https://github.com/thuss/standalone-migrations) for this.

You further need to:
``` ruby
    require 'ib/db'
    IB::DB.connect :adapter => 'sqlite3', :database => 'db/test.sqlite3'
    require 'ib'
```
Only require 'ib' AFTER you've connected to DB, otherwise your Models will not
inherit from ActiveRecord::Base and won't be persistent. If you are using Rails,
you don't need IB::DB.connect part, Rails will take care of it for you.

Now, all your IB Models are just ActiveRecords and you can save them to DB just
like you would with Rails models.

## RUNNING TESTS:

The gem comes with a spec suit that may be used to test ib-ruby compatibility with your
specific TWS/Gateway installation. Please read 'spec/Readme.md' for more details about
running specs.

## RUBY VERSION COMPATIBILITY:

The library is continuously tested with JRuby 1.6.7 (ruby-1.8.7-p357-compatible mode) and
JRuby head (ruby-1.9.3-p203-compatible mode). It is not JRuby-specific though, as it is currently used in a some MRI Ruby based projects. If there are any problems in any mode
for either JRuby or MRI, please report an [issue](https://github.com/ib-ruby/ib-ruby/issues/new)
and we will work on it.

Please keep in mind that when using Ruby 1.8.7, you need to either explicitly:
``` ruby
    require 'rubygems'
    require 'ib'
```

or set the environment variable "RUBYOPT" to "-rubygems":

    set RUBYOPT=-rubygems

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

