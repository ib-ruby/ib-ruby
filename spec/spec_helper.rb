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

BROKERTRON = false

CONNECTION_OPTS = BROKERTRON ?
    {:client_id => 1111,
     :host => 'free.brokertron.com',
     :port=> 10501
    } :
    {:client_id => 1111,
     :host => '127.0.0.1',
     :port=> 4001
    }

puts
puts 'WARNING: MAKE SURE ALL YOUR TESTS ARE RUN AGAINST PAPER ACCOUNT!'
