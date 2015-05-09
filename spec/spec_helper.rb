require 'active_support'
require 'rspec'
require 'rspec/its'
require 'rspec/collection_matchers'
require 'ib'
require 'factory_girl'
require 'yaml'

# Configure top level option indicating how the test suite should be run

# read items from connect.yml (located in the root of spec's)
read_yml = -> (key) do
	if [:advisor, :user].include?(key)
		YAML::load_file( File.expand_path('../connect.yml',__FILE__))[:account][key]
	elsif key==:gateway
		YAML::load_file( File.expand_path('../connect.yml',__FILE__))[key]
	else
		YAML::load_file( File.expand_path('../connect.yml',__FILE__))[:gateway][key]
	end
end

OPTS ||= {
  :verbose => false, #true, # Run test suite in a verbose mode ?
  :brokertron => false, # Use mock (Brokertron) instead of paper account ?
  :rails => IB.rails? && Rails.application.class.parent_name,
  :db => IB.db_backed?
}

if OPTS[:brokertron]
  puts "Using Brokerton free.brokertron.com mock service."
  # Connection to mock (Brokertron) account
  OPTS[:connection] = {
    :client_id => 1111, # Client id that identifies the test suit
    :host => 'free.brokertron.com',
    :port => 10501
  }
else
  # read from connect.yml

  OPTS[:connection] = read_yml[:gateway]
  
end
 

FactoryGirl.find_definitions

RSpec.configure do |config|

  puts "Running specs with OPTS:"
  puts OPTS.inspect

  config.alias_it_behaves_like_to :it_returns_a, 'it returns a:'

  # config.include(UserExampleHelpers)
  # config.mock_with :mocha
  # config.mock_with :flexmock
  # config.mock_with :rr
	# ermöglicht die Einschränkung der zu testenden Specs
	# durch  >>it "irgendwas", :focus => true do <<
	#
  config.filter_run focus:true
  config.run_all_when_everything_filtered = true
  config.include FactoryGirl::Syntax::Methods

  config.exclusion_filter = {
    :if => proc do |condition|
      t = Time.now.utc
      case condition # NB: excludes if condition is false!
      when :us_trading_hours
        # 09:30 - 16:00 (ET) Mon-Fri 14:30 - 21:00 (UTC)
        !(t.wday >= 1 && t.wday <= 5 && t.hour >= 15 && t.hour <= 21)
      when :forex_trading_hours
        # 17:15 - 17:00 (ET) Sunday-Friday Forex  22:15 - 22:00 (UTC)
        !(t.wday > 0 && t.wday < 5 || t.wday == 5 && t.hour < 22)
      end
    end,

    :db => proc { |condition| IB.db_backed? != condition }, # true/false

    :rails => proc { |condition| IB.rails? != condition }, # false or "Dummy"/"Combustion"

    :reuters => proc { |condition| !OPTS[:connection][:reuters] == condition }, # true/false
  }
  config.before(:suite) do
  end

  if OPTS[:db]
    require 'database_cleaner'

	config.before(:suite) do
		begin
			DatabaseCleaner.strategy = :truncation
			DatabaseCleaner.start
			FactoryGirl.lint
		ensure
			DatabaseCleaner.clean
		end
	end
  end

  if OPTS[:rails]
    config.include IB::Engine.routes.url_helpers,
      :example_group => {:file_path => /\brails_spec\//}

    config.include Capybara::DSL,
      :example_group => { :file_path => /\brails_spec\//}
  end
	config.order = 'defined'  # "random"
end
