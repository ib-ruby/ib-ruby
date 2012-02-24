require 'rspec'
require 'ib-ruby'

RSpec.configure do |config|
  # config.exclusion_filter = { :slow => true }
  # config.filter = { :focus => true }
  # config.include(UserExampleHelpers)
  # config.mock_with :mocha
  # config.mock_with :flexmock
  # config.mock_with :rr
end

SILENT = false #true

BROKERTRON = false

# Connection to IB PAPER ACCOUNT or mock (Brokertron) account
CONNECTION_OPTS = BROKERTRON ?
    {:client_id => 1111,
     :host => 'free.brokertron.com',
     :port=> 10501
    } :
    {:account => 'DU118180', #  Your IB PAPER ACCOUNT, tests will only run against it
     :client_id => 1111, #      Just an arbitrary id
     :host => '10.211.55.2', #  Where your TWS/gateway is located, likely 'localhost'
     :port=> 4001 #             4001 for Gateway, 7496 for TWS GUI
    }

