require 'rspec'
require 'ib-ruby'

# Configure top level option indicating how the test suite should be run

OPTS ||= {
  :verbose => false, #true, # Run test suite in a verbose mode ?
  :brokertron => false, # Use mock (Brokertron) instead of paper account ?
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
  # Connection to IB PAPER ACCOUNT
  ACCOUNT ||= 'DU60320'
  HOST ||= '127.0.0.1'
  PORT ||= 7496

  OPTS[:connection] = {
    :account => ACCOUNT, # Your IB PAPER ACCOUNT, tests will only run against it
    :host => HOST, #       Where your TWS/gateway is located, likely '127.0.0.1'
    :port => PORT, #       4001 for Gateway, 7496 for TWS GUI
    :client_id => 1111, #  Client id that identifies the test suit
    :reuters => true #     Subscription to Reuters data enabled ?
  }
end

puts 'Running specs with OPTS:'
pp OPTS

RSpec.configure do |config|
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

    :reuters => proc { |condition| !OPTS[:connection][:reuters] == condition } # true/false
  }
  # config.filter = { :focus => true }
  # config.include(UserExampleHelpers)
  # config.mock_with :mocha
  # config.mock_with :flexmock
  # config.mock_with :rr

  if IB.db_backed?
    puts "Database backed"
    config.before(:suite) do
      DatabaseCleaner.strategy = :truncation
      DatabaseCleaner.clean
    end
  end
end
