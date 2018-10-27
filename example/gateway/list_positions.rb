#!/usr/bin/env ruby
#
# This script uses the IB::Gateway to connect to the tws
# 
# It displays all contracts in all accounts
#
# It is assumed, that the TWS/Gateway is running on localhost,  using 7497/4002 as port
#
# call   `ruby list_positions TWS ` to connect to a running TWS-Instance

require 'bundler/setup'
require 'yaml'
require 'ib-gateway'
require 'logger'

logger = Logger.new  STDOUT
logger.level = Logger::INFO

client_id = ARGV[1] ||  2500
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

	begin
	G =  IB::Gateway.new  get_account_data: true,
			client_id: client_id, port: port, logger: logger
	rescue IB::TransmissionError => e
		puts "E: #{e.inspect}"
	end


	puts "List of Contracts"
	puts '-'*25
  puts	G.all_contracts.map(&:to_human).join("\n")
	puts '-'*25


	G.active_accounts.each do | user |
		puts "\n"*3
		puts "Postions Account: #{user.account}"
		puts '-'*25
		puts	user.portfolio_values.map(&:to_human).join("\n")
		puts '-'*25
	end



	# Gateway.all_contracts is defined in lib/ib/account_infos.rb
	# and is simply
	# active_accounts.map(&:contracts).flat_map(&:itself).uniq(&:con_id)
	#

