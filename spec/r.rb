puts 'To run specs with Combustion-based Rails app, use:'
puts '$ rspec -rr spec/ib-ruby/models'

require 'bundler/setup'
require 'combustion'
require 'ib'

Combustion.initialize!

require 'rspec/rails'
require 'yaml'
require 'pathname'
require 'database_cleaner'

