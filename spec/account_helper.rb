require 'message_helper'

# Make sure integration tests are only run against the pre-configured PAPER ACCOUNT
def verify_account

 @gw = IB::Gateway.current.presence || IB::Gateway.new( OPTS[:connection].merge(logger: mock_logger, client_id:1056, connect:true, serial_array: true))

  @ib=  @gw.tws
  account =  @gw.active_accounts.last

  raise "Unable to verify IB PAPER ACCOUNT" unless account.test_environment?

  OPTS[:account_verified] = true
end

### Helpers for placing and verifying orders

shared_examples_for 'Valid account data request' do

  context "received :AccountUpdateTime message" do
    subject { IB::Gateway.tws.received[:AccountUpdateTime].first }

    it { should be_an IB::Messages::Incoming::AccountUpdateTime }
    its(:data) { should be_a Hash }
    its(:time_stamp) { should =~ /\d\d:\d\d/ }
    its(:to_human) { should =~ /AccountUpdateTime/ }
  end

  context "received :AccountValue message" do
    subject { IB::Connection.current.received[:AccountValue].first }

    #ps
    it { should be_an IB::Messages::Incoming::AccountValue }
    its(:data) { should be_a Hash }
    its(:account_name) { should =~ /\w\d/ }
    its(:key) { should be_a String }
    its(:value) { should be_a String }
    its(:currency) { should be_a String }
    its(:to_human) { should =~ /AccountValue/ }
  end

  context "received :PortfolioValue message" do
    subject { IB::Gateway.tws.received[:PortfolioValue].first }

    it { should be_an IB::Messages::Incoming::PortfolioValue }
    its(:contract) { should be_a IB::Contract }
    its(:data) { should be_a Hash }
    its(:position) { should be_a Integer }
    its(:market_price) { should be_a Float }
    its(:market_value) { should be_a Float }
    its(:average_cost) { should be_a Float }
    its(:unrealized_pnl) { should be_a Float }
    its(:realized_pnl) { should be_a Float }
    its(:account_name) { should =~ /\w\d/ }
    its(:to_human) { should =~ /PortfolioValue/ }
  end

  context "received :AccountDownloadEnd message" do
    subject { IB::Gateway.tws.received[:AccountDownloadEnd].first }

    it { should be_an IB::Messages::Incoming::AccountDownloadEnd }
    its(:data) { should be_a Hash }
    its(:account_name) { should =~ /\w\d/ }
    its(:to_human) { should =~ /AccountDownloadEnd/ }
  end
end
