puts 'To run specs with rails (ActiveRecord), use:'
puts '$ rspec -rr spec/ib-ruby/models'

require 'bundler/setup'
require 'combustion'
require 'ib_engine'

Combustion.initialize!

require 'rspec/rails'
require 'yaml'
require 'pathname'
require 'database_cleaner'

