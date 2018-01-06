#!/usr/bin/env ruby
### loads the active-orient environment 
### and starts an interactive shell
###
### Parameter: (none) 
require 'bundler/setup'
require 'yaml'

require 'logger'
LogLevel = Logger::WARN
#require File.expand_path(File.dirname(__FILE__) + "/../config/boot")

require 'ib-ruby'

  puts 
  puts ">> IB-RUBY Interactive Console <<" 
  puts '-'* 45
  puts 
  puts "Namespace is IB ! "
  puts
  puts '-'* 45
 
  include IB
  require 'irb'
  client_id = ARGV[0] || 2000
  port = ARGV[1] || 4002
  ARGV.clear

  C =  Connection.new  client_id: client_id, port: port
  C.subscribe( :ContractData, :BondContractData) { |msg| puts(msg.contract.inspect + "\n") }
  					    
  C.subscribe( :Alert, :ContractDataEnd, :ManagedAccounts ) {| m| puts m.to_human }
  C.subscribe( :PortfolioValue, :AccountValue ) {| m| puts m.to_human }
  
  puts  "Connection established on Port  #{port}, client_id #{client_id} used"
  puts  "C points to the connection-instance"
  puts  "some basic Alerts are subcribed and accordingly displayed"

  IRB.start(__FILE__)
