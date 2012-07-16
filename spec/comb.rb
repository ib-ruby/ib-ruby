puts 'To run specs with Combustion-based Rails app, use:'
puts '$ rspec -rcomb rails_spec'

require 'bundler/setup'
require 'combustion'
require 'backports/1.9.2' if RUBY_VERSION =~ /1.8/
require 'ib'

Combustion.path = 'rails_spec/combustion'
Combustion.initialize!

require 'rspec/rails'

