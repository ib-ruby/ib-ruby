require 'rubygems'
require 'bundler'

Bundler.require :default, :development
require 'ib-ruby/engine'

Combustion.initialize!
run Combustion::Application
