#!/usr/bin/env ruby
#
# This script connects to IB API, subscribes to account info and prints out
# messages received from IB (update every 3 minute or so)

require 'rubygems'
require 'bundler/setup'
$LOAD_PATH.unshift File.expand_path(File.dirname(__FILE__) + '/../lib')
require 'ib-ruby'

api = IB::Connection.new :port => 7496
api.subscribe(:Alert, :AccountValue) { |msg|
    puts msg.to_human
}

puts "\n\nFirst set of outputs"
api.send_message :RequestAccountData, :subscribe => true
api.wait_for :AccountDownloadEnd

api.send_message :RequestAccountData, :subscribe => false
api.received[:AccountDownloadEnd].clear

sleep 10

puts "\n\nSecond set of outputs"
api.send_message :RequestAccountData, :subscribe => true
api.wait_for :AccountDownloadEnd