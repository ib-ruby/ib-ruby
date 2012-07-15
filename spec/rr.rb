puts 'To run specs with dummy Rails app, use:'
puts '$ rspec -rrr spec/rails'

# Configure Rails Environment
ENV["RAILS_ENV"] = "test"

require File.expand_path("../dummy/config/environment.rb", __FILE__)

require 'rspec/rails'
require 'capybara/rails'
require 'capybara/dsl'
require 'database_cleaner'

Rails.backtrace_cleaner.remove_silencers!

RSpec.configure do |config|
  config.use_transactional_fixtures = true

  config.include IB::Engine.routes.url_helpers,
    :example_group => {:file_path => /\bspec\/rails\//}

  config.include Capybara::DSL,
    :example_group => { :file_path => /\bspec\/rails\//}
end
