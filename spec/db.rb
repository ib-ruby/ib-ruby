puts 'To run specs with database backend (ActiveRecord), use:'
puts '$ rspec -rdb spec'

require 'yaml'
require 'pathname'
require 'ib-ruby/db'
require 'database_cleaner'

# Load DB config, determine correct environment
db_file = Pathname.new(__FILE__).realpath.dirname + '../db/config.yml'
raise "Unable to find DB config file: #{db_file}" unless db_file.exist?

env = RUBY_PLATFORM =~ /java/ ? 'test' : 'test-mri'
db_config = YAML::load_file(db_file)[env]

# Establish connection to test DB
IB::DB.connect db_config

