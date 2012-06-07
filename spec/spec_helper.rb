require 'rspec'
require 'ib-ruby'

PORT ||= 4001 #           4001 for Gateway, 7496 for TWS GUI

# Top (test suite) level metadata
OPTS ||= {
    :verbose => false, #true, # Verbosity of test outputs
    :brokertron => false, # Use mock (Brokertron) instead of paper account
}

if OPTS[:brokertron]
  # Connection to mock (Brokertron) account
  OPTS[:connection] =
      {:client_id => 1111, # Just an arbitrary id
       :host => 'free.brokertron.com',
       :port=> 10501
      }
else
  # Connection to IB PAPER ACCOUNT
  OPTS[:connection] =
      {:account_name => 'DU118180', # Your IB PAPER ACCOUNT, tests will only run against it
       :client_id => 1111, #      Just an arbitrary id
       :host => '10.211.55.2', #  Where your TWS/gateway is located, likely '127.0.0.1'
       :port => PORT,
       :reuters => true #         Subscription to Reuters data enabled ?
      }
end

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

      :db => proc { |condition| !IB::DB == condition }, # true/false

      :reuters => proc { |condition| !OPTS[:connection][:reuters] == condition } # true/false
  }
  # config.filter = { :focus => true }
  # config.include(UserExampleHelpers)
  # config.mock_with :mocha
  # config.mock_with :flexmock
  # config.mock_with :rr

  if IB::DB
    config.before(:suite) do
      DatabaseCleaner.strategy = :truncation
      DatabaseCleaner.clean
    end
  end
end

