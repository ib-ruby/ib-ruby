#!/usr/bin/env ruby
#
# This script retrieves list of all Orders from TWS

require 'rubygems'
require 'bundler/setup'
$LOAD_PATH.unshift File.expand_path(File.dirname(__FILE__) + '/../lib')

require 'yaml'
require 'pathname'
require 'ib-ruby/db'

# Load DB config, determine correct environment
db_file = Pathname.new(__FILE__).realpath.dirname + '../db/config.yml'
raise "Unable to find DB config file: #{db_file}" unless db_file.exist?

env = RUBY_PLATFORM =~ /java/ ? 'test' : 'test-mri'
db_config = YAML::load_file(db_file)[env]

# Establish connection to test DB
IB::DB.connect db_config

require 'ib-ruby'

# Connect to IB as 0 (TWS) to retrieve all Orders, including TWS-generated ones
ib = IB::Connection.new :client_id => 0 #, :port => 7496 # TWS

## Subscribe to TWS alerts/errors and order-related messages
#@counter = 0
#
#ib.subscribe(:Alert, :OrderStatus, :OpenOrderEnd) { |msg| puts msg.to_human }
#
#ib.subscribe(:OpenOrder) do |msg|
#  @counter += 1
#  puts "#{@counter}: #{msg.to_human}"
#  #pp msg.order
#end
#
#ib.send_message :RequestAllOpenOrders
#
## Wait for IB to respond to our request
#ib.wait_for :OpenOrderEnd
#sleep 1 # Let printer do the job

combo = IB::Bag.new

google = IB::Option.new(:symbol => 'GOOG',
                        :expiry => 201301,
                        :right => :call,
                        :strike => 500)

combo.leg_contracts << google
p combo.leg_contracts
p combo.save

#combo.legs.should_not be_empty
p combo.leg_contracts
p google.combo

leg = combo.legs.first
p google.leg
