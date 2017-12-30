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
  ARGV.clear
  IRB.start(__FILE__)
