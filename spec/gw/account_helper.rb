require 'spec_helper'
require 'thread'
require 'stringio'
require 'rspec/expectations'
require 'gw_helper'

# Make sure integration tests are only run against the pre-configured PAPER ACCOUNT
def verify_account

 gw = IB::Gateway.current.presence || IB::Gateway.new( OPTS[:connection].merge(logger: mock_logger, client_id:1056, connect:true, serial_array: true))

  @ib=  gw.tws
  @account = gw.active_accounts[0]

  raise "Unable to verify IB PAPER ACCOUNT" unless @account.test_environment?

  OPTS[:account_verified] = true
end

## Logger helpers

def mock_logger
  stdout = StringIO.new

  logger = Logger.new(stdout).tap do |l|
    l.formatter = proc do |level, time, prog, msg|
      "#{time.strftime('%H:%M:%S')} #{msg}\n"
    end
    l.level = Logger::INFO
  end
end
