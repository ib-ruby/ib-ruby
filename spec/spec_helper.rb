require 'rspec'
require 'ib-ruby'

RSpec.configure do |config|
  config.exclusion_filter = {
      :if => proc do |condition|
        case condition
          when :forex_trading_hours
            # 17:15 - 17:00 (ET) Sunday-Friday Forex  22:15 - 22:00 (UTC)
            t = Time.now.utc
            !(t.wday < 5 || t.wday == 5 && t.hour < 22) # excludes if condition false!
        end

      end # :slow => true
  }
  # config.filter = { :focus => true }
  # config.include(UserExampleHelpers)
  # config.mock_with :mocha
  # config.mock_with :flexmock
  # config.mock_with :rr
end

# Top level metadata opts for suite-level hacking
OPTS = {
    :silent => true, #false, #true,
    :brokertron => false,
}

# Connection to IB PAPER ACCOUNT or mock (Brokertron) account
if OPTS[:brokertron]
  OPTS[:connection] =
      {:client_id => 1111,
       :host => 'free.brokertron.com',
       :port=> 10501
      }
else
  OPTS[:connection] =
      {:account => 'DU118180', #  Your IB PAPER ACCOUNT, tests will only run against it
       :client_id => 1111, #      Just an arbitrary id
       :host => '10.211.55.2', #  Where your TWS/gateway is located, likely 'localhost'
       :port=> 4001 #             4001 for Gateway, 7496 for TWS GUI
      }
end
