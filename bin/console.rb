#!/usr/bin/env ruby
### loads the active-orient environment 
### and starts an interactive shell
###
### Parameter: t)ws | g)ateway (or number of port ) Default: Gateway ,
###							client_id , Default 2000
require 'bundler/setup'
require 'yaml'

require 'logger'
#require File.expand_path(File.dirname(__FILE__) + "/../config/boot")

require 'ib-ruby'

class Array
  # enables calling members of an array. which are hashes  by it name
  # i.e
  #
  #  2.5.0 :006 > C.received[:OpenOrder].local_id
  #   => [16, 17, 21, 20, 19, 8, 7] 
  #   2.5.0 :007 > C.received[:OpenOrder].contract.to_human
  #    => ["<Bag: IECombo SMART USD legs:  >", "<Stock: GE USD>", "<Stock: GE USD>", "<Stock: GE USD>", "<Stock: GE USD>", "<Stock: WFC USD>", "<Stock: WFC USD>"] 
  #
  # its included only in the console, for inspection purposes

  def method_missing(method, *key)
    unless method == :to_hash || method == :to_str #|| method == :to_int
      return self.map{|x| x.public_send(method, *key)}
    end

  end
end # Array

  puts 
  puts ">> IB-RUBY Interactive Console <<" 
  puts '-'* 45
  puts 
  puts "Namespace is IB ! "
  puts
  puts '-'* 45
	include LogDev
  include IB
  require 'irb'
  client_id = ARGV[1] || 2000
  specified_port = ARGV[0] || 'Gateway'
	port =  case specified_port
					when Integer
						specified_port  # just use the number
					when /^[gG]/ 
						4002
					when /^[Tt]/
						7497
					end
  ARGV.clear
  logger = default_logger #  Logger.new  STDOUT
	
  ## The Block takes instructions which are executed  after initializing all instance-variables
  ## and prior to the connection-process
  ## Here we just subscribe to some events  
  C =  Connection.new  client_id: client_id, port: port  do |c|  # future use__ , optional_capacities: "+PACEAPI"  do |c|

    c.subscribe( :ContractData, :BondContractData) { |msg| logger.info { msg.contract.to_human } }
    c.subscribe( :Alert, :ContractDataEnd, :ManagedAccounts, :OrderStatus ) {| m| logger.info { m.to_human } }
    c.subscribe( :PortfolioValue, :AccountValue, :OrderStatus, :OpenOrderEnd, :ExecutionData ) {| m| logger.info { m.to_human }}
    c.subscribe :ManagedAccounts do  |msg|
        puts "------------------------------- Managed Accounts ----------------------------------"
				puts "Detected Accounts: #{msg.accounts.account.join(' -- ')} " 
				puts
    end

    c.subscribe( :OpenOrder){ |msg|  "Open Order detected and stored: C.received[:OpenOrders] " }
		c.logger.level = Logger::INFO 
	end 
  unless  C.received[:OpenOrder].blank?
        puts "------------------------------- OpenOrders ----------------------------------"
    puts C.received[:OpenOrder].to_human.join "\n"
  end
  puts  "Connection established on Port  #{port}, client_id #{client_id} used"
  puts
  puts  "----> C    points to the connection-instance"
  puts
  puts  "some basic Messages are subscribed and accordingly displayed"
  puts '-'* 45

  IRB.start(__FILE__)
