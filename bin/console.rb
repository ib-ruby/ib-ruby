#!/usr/bin/env ruby
### loads the active-orient environment 
### and starts an interactive shell
###
### Parameter: (none) 
require 'bundler/setup'
require 'yaml'

require 'logger'
LogLevel = Logger::INFO
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
  logger = Logger.new  STDOUT

  ## The Block takes instructions taking in effect after initializing all instance-variables
  ## and prior to the connection-process
  ## Here we just subscribe to some events  
  C =  Connection.new  client_id: client_id, port: port do |c|

    c.subscribe( :ContractData, :BondContractData) { |msg| logger.info { msg.contract.inspect } }
    c.subscribe( :Alert, :ContractDataEnd, :ManagedAccounts ) {| m| logger.info { m.to_human } }
    c.subscribe( :PortfolioValue, :AccountValue ) {| m| logger.info { m.to_human }}

  end
  
  puts  "Connection established on Port  #{port}, client_id #{client_id} used"
  puts
  puts  "----> C    points to the connection-instance"
  puts
  puts  "some basic Messages are subcribed and accordingly displayed"
  puts '-'* 45

  IRB.start(__FILE__)
