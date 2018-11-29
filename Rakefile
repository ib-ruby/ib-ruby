begin
  require 'rake'
rescue LoadError
  require 'rubygems'
  gem 'rake', '~> 0.8.3.1'
  require 'rake'
end

require 'pathname'

BASE_PATH = Pathname.new(__FILE__).dirname
LIB_PATH = BASE_PATH + 'lib'
PKG_PATH = BASE_PATH + 'pkg'
DOC_PATH = BASE_PATH + 'rdoc'

$LOAD_PATH.unshift LIB_PATH.to_s
require 'ib/version'

NAME = 'ib-ruby'
CLASS_NAME = IB

# Load rakefile tasks
Dir['tasks/*.rake'].sort.each { |file| load file }

# Project-specific tasks

## Migrations

# rake db:new_migration name=FooBarMigration
# rake db:migrate
# rake db:migrate VERSION=20081220234130
# rake db:migrate:up VERSION=20081220234130
# rake db:migrate DB=osx-test
# rake db:rollback
# rake db:rollback STEP=3
#begin
#  require 'tasks/standalone_migrations'
#rescue LoadError => e
#  puts "gem install standalone_migrations to get db:migrate:* tasks! (Error: #{e})"
#end

# rake db:redo DB=test"
#namespace :db do
#  desc "Remake db from scratch: $ rake db:redo DB=test"
#  task :redo => [:drop, :create, :migrate] do
#    puts "Redo Finished!"
#  end
#end
