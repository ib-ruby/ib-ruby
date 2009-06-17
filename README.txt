ib-ruby
    By Wes Devauld (wes at devauld dot ca) 
    http://github.com/wdevauld/ib-ruby 

    This is a fork of Paul Legato's (pjlegato at gmail dot com) work found at:
    http://github.com/pjlegato/ib-ruby

Copyright (C) 2009 Wes Devauld

== DESCRIPTION:

* Ruby Implementation of the Interactive Broker' TWS API

== FEATURES/PROBLEMS:

* This is a ALPHA release, and should not be used for live trading.  Any features contained with are AS-IS and may not work in all conditions
* This code is not sanctioned by Interactive Brokers

== SYNOPSIS:
 
First, start up Interactive Broker's Trader Work Station.  Ensure it is configured to allow API connections on localhost

>> require 'ib-ruby'
>> ib_connection = IB:IB.new()

== REQUIREMENTS:

* FIXME List all the requirements 

== INSTALL:

* Ensure that http://gems.github.com is in your gem sources
* sudo gem install wdevauld-ib-ruby

== LICENSE:

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
