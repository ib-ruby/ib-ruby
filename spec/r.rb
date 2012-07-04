puts 'To run specs with rails (ActiveRecord), use:'
puts '$ bundle exec rspec -rr spec/ib-ruby/models'

require 'combustion'

require 'ib_engine'

Combustion.initialize!

require 'rspec/rails'
require 'yaml'
require 'pathname'
require 'database_cleaner'

