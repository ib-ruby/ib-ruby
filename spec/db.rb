puts 'To run specs with database backend (ActiveRecord), use:'
puts '$ rspec -rdb spec'

require 'yaml'
require 'pathname'
require 'ib/db'
require 'database_cleaner'

# Load DB config, determine correct environment
db_file = Pathname.new(__FILE__).realpath.dirname + '../db/config.yml'
raise "Unable to find DB config file: #{db_file}" unless db_file.exist?

#env = RUBY_PLATFORM =~ /java/ ? 'test' : 'test-mri'
#db_config = YAML::load_file(db_file)[env]

# Establish connection to test DB

ActiveRecord::Base.configurations = ActiveRecord::Tasks::DatabaseTasks.database_configuration = YAML::load_file(db_file)  # YOUR_CONFIG_HASH_AS_IN_DATABASE_YML 
ActiveRecord::Tasks::DatabaseTasks.db_dir = 'db' # PATH_TO_YOUR_DB_DIRECTORY
ActiveRecord::Tasks::DatabaseTasks.env    = 'test' # YOUR_ENV_AS_RAILS_ENV
ActiveRecord::Base.table_name_prefix = ""
IB::DB.connect ActiveRecord::Tasks::DatabaseTasks.database_configuration[ActiveRecord::Tasks::DatabaseTasks.env]


