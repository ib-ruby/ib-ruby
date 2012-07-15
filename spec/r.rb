puts 'To run specs with Combustion-based Rails app, use:'
puts '$ rspec -rr spec/models'

require 'bundler/setup'
require 'combustion'
require 'ib'

# Configure Rails Environment ?
# ENV["RAILS_ENV"] = "test"
Combustion.initialize!

require 'rspec/rails'
require 'yaml'
require 'pathname'
require 'database_cleaner'

