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
puts 'WARNING: MAKE SURE TO RUN ALL YOUR TESTS AGAINST IB PAPER ACCOUNT!'
puts 'WARNING: FINANCIAL LOSSES MAY RESULT IF YOU RUN TESTS WITH REAL IB ACCOUNT!'
puts 'WARNING: YOU HAVE BEEN WARNED!'
puts
puts 'Configure your connection to IB PAPER ACCOUNT in spec/spec_helper.rb'
puts

# Please uncomment next line if you are REALLY sure you have properly configured
# Connection to IB PAPER ACCOUNT or mock (Brokertron) account
exit

SILENT = false #true

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

