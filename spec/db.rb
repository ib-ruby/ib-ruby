puts 'TODO: Run rspec with ActiveRecord version. Use:'
puts '$ rspec -rdb spec'

require 'yaml'
require 'pathname'
require 'ib-ruby/db'

# Do other DB plumbing, like establishing connection to test DB
p db_file = Pathname.new(__FILE__).realpath.dirname + '../db/config.yml'
raise "Unable to find DB config file: #{db_file}" unless db_file.exist?
p db_config = YAML::load_file(db_file)['test']

IB::DB.connect db_config

# Set RSpec metadata to run AR-specific specs