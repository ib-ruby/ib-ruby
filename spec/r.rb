puts 'To run specs with rails (ActiveRecord), use:'
puts '$ bundle exec rspec -rr spec/ib-ruby/models'

require 'combustion'

Combustion.initialize!

require 'rspec/rails'
require 'yaml'
require 'pathname'
require 'ib-ruby/db'
require 'database_cleaner'

