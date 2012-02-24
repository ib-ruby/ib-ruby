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

puts
puts 'WARNING: MAKE SURE TO RUN ALL YOUR TESTS AGAINST IB PAPER ACCOUNT ONLY!'
puts 'WARNING: FINANCIAL LOSSES MAY RESULT IF YOU RUN TESTS WITH REAL IB ACCOUNT!'
puts 'WARNING: YOU HAVE BEEN WARNED!'
puts
puts 'Configure your connection to IB PAPER ACCOUNT in spec/spec_helper.rb'
puts

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

