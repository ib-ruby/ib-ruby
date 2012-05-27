puts 'To run specs with rails (ActiveRecord), use:'
puts '$ bundle exec rspec -rr spec/ib-ruby/models'

require 'rubygems'
require 'bundler'
Bundler.require :default, :development

Combustion.initialize!

require 'rspec/rails'
require 'yaml'
require 'pathname'
require 'ib-ruby/db'
require 'database_cleaner'

# Load DB config, determine correct environment
db_file = Pathname.new(__FILE__).realpath.dirname + 'internal/config/database.yml'
raise "Unable to find DB config file: #{db_file}" unless db_file.exist?

env = RUBY_PLATFORM =~ /java/ ? 'test' : 'test-mri'
db_config = YAML::load_file(db_file)[env]

# Establish connection to test DB
IB::DB.connect db_config

