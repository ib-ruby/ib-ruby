require 'message_helper'

# Make sure integration tests are only run against the pre-configured PAPER ACCOUNT
def verify_account

 gw = IB::Gateway.current.presence || IB::Gateway.new( OPTS[:connection].merge(logger: mock_logger, client_id:1056, connect:true, serial_array: true))

  @ib=  gw.tws
  @account = gw.active_accounts[0]

  raise "Unable to verify IB PAPER ACCOUNT" unless @account.test_environment?

  OPTS[:account_verified] = true
end

