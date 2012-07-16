puts 'To run specs with dummy Rails app, use:'
puts '$ rspec -rdummy rails_spec'

# Configure Rails Environment
ENV["RAILS_ENV"] = "test"

require File.expand_path("../../rails_spec/dummy/config/environment.rb", __FILE__)

require 'rspec/rails'
require 'capybara/rails'
require 'capybara/dsl'

Rails.backtrace_cleaner.remove_silencers!
