#!/usr/bin/env ruby
### loads the active-orient environment 
### and starts an interactive shell
###
### Parameter: t)ws | g)ateway (or number of port ) Default: Gateway ,
###							client_id , Default 2000
require 'bundler/setup'
require 'yaml'

require 'logger'
LogLevel = Logger::DEBUG  ##INFO # DEBUG # ERROR 
#require File.expand_path(File.dirname(__FILE__) + "/../config/boot")

require 'ib-gateway'

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
  puts ">> I B – G A T E W A Y  Interactive Console <<" 
  puts '-'* 45
  puts 
  puts "Namespace is IB ! "
  puts
  puts '-'* 45
 
  include IB
  require 'irb'
  client_id = ARGV[1] || 3000
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
  logger = Logger.new  STDOUT
  logger.formatter = proc do |level, time, prog, msg|
      "#{time.strftime('%H:%M:%S')} #{msg}\n"
	end
			logger.level = Logger::INFO 
	
  ## The Block takes instructions which are executed  after initializing all instance-variables
  ## and prior to the connection-process
  ## Here we just subscribe to some events  
	begin
		G =  Gateway.new  get_account_data: true, serial_array: true,
			client_id: client_id, port: port, logger: logger,
			watchlists: [:Spreads, :BuyAndHold]
	rescue IB::TransmissionError => e
		puts "E: #{e.inspect}"
	end

	C =  G.tws
  unless  C.received[:OpenOrder].blank?
        puts "------------------------------- OpenOrders ----------------------------------"
    puts C.received[:OpenOrder].to_human.join "\n"
  end
  puts  "Connection established on Port  #{port}, client_id #{client_id} used"
  puts
  puts  "----> G    points to the Gateway-Instance"
	puts  "----> C    points to the Connection-Instance"
  puts
  puts  "some basic Messages are subscribed and accordingly displayed"
  puts '-'* 45

  IRB.start(__FILE__)
