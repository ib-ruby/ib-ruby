require 'rspec'
require 'rspec/its'
require 'rspec/collection_matchers'
require 'ib-ruby'
require 'pp'
require 'yaml'

# Configure top level option indicating how the test suite should be run

OPTS ||= {
  :verbose => false, #true, # Run test suite in a verbose mode ?
#  :rails => IB.rails? && Rails.application.class.parent_name,
  :db => IB.db_backed?
}

# read items from connect.yml (located in the root of spec's)
read_yml = -> (key) do
	if [:advisor, :user].include? key
		YAML::load_file( File.expand_path('../connect.yml',__FILE__))[:account][key]
	elsif [:gateway, :connection ].include? key
		YAML::load_file( File.expand_path('../connect.yml',__FILE__))[key]
	else
		YAML::load_file( File.expand_path('../connect.yml',__FILE__))[:gateway][key]
	end
end


  # Configure settings in connect.yml
	  OPTS[:connection] = read_yml[:connection]
		ACCOUNT =  OPTS[:connection][:account]   # shortcut for active account (orders portfolio_values ect.)

	
RSpec.configure do |config|

  puts "Running specs with OPTS:"
  pp OPTS

	# ermöglicht die Einschränkung der zu testenden Specs
	# durch  >>it "irgendwas", :focus => true do <<
	#
  #config.filter_run_including focus: true
	#
	#This configuration allows you to filter to specific examples or groups by tagging
	#them with :focus metadata. When no example or groups are focused (which should be
	#the norm since it's intended to be a temporary change), the filter will be ignored.
	
	#RSpec also provides aliases--fit, fdescribe and fcontext--as a shorthand for
	#it, describe and context with :focus metadata, making it easy to temporarily
	#focus an example or group by prefixing an f.
  config.filter_run_when_matching focus: true

	config.alias_it_should_behave_like_to :it_has_message, 'has message:'
	config.expose_dsl_globally = true  #+ monkey-patching in rspec 3
	config.order = 'defined' # "random"
	#
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
    end    , 
# true --> exclude db => true tests
    :db => true,  #proc { |condition| IB.db_backed? != condition }, # true/false

    :rails => true, # proc { |condition| IB.rails? != condition }, # false or "Dummy"/"Combustion"

    :reuters => proc { |condition| !OPTS[:connection][:reuters] == condition }, # true/false
  }

  #  not used anymore
#  if OPTS[:db]
#    require 'database_cleaner'
#
#    config.before(:suite) do
#      DatabaseCleaner.strategy = :truncation
#      DatabaseCleaner.clean
#    end
#
#    config.after(:suite) do
#      DatabaseCleaner.clean
#    end
#  end
#
#  if OPTS[:rails]
#    config.include IB::Engine.routes.url_helpers,
#      :example_group => {:file_path => /\brails_spec\//}
#
#    config.include Capybara::DSL,
#      :example_group => { :file_path => /\brails_spec\//}
#  end
end
