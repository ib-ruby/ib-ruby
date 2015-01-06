require 'message_helper'

# Make sure integration tests are only run against the pre-configured PAPER ACCOUNT
def verify_account
  return OPTS[:account_verified] if OPTS[:account_verified]

  puts
  puts 'WARNING: MAKE SURE TO RUN INTEGRATION TESTS AGAINST IB PAPER ACCOUNT ONLY!'
  puts 'WARNING: FINANCIAL LOSSES MAY RESULT IF YOU RUN TESTS WITH REAL IB ACCOUNT!'
  puts 'WARNING: YOU HAVE BEEN WARNED!'
  puts
  puts 'Configure your connection to IB PAPER ACCOUNT in spec/spec_helper.rb'
  puts

  account = OPTS[:connection][:account] || OPTS[:connection][:account_name]
  raise "Please configure IB PAPER ACCOUNT in spec/spec_helper.rb" unless account
#  @ib = IB::Connection.current.presence || IB::Connection.new( :port => 7496 ,:logger => Logger.new(STDOUT), client_id:1056)
  @ib = IB::Connection.current.presence || IB::Connection.new( OPTS[:connection].merge(:logger => Logger.new(STDOUT), client_id:1056))

  @ib.wait_for :ManagedAccounts, 5

  raise "Unable to verify IB PAPER ACCOUNT" unless @ib.received?(:ManagedAccounts)

  # recieved is an array of accounts, found in the accounts_list
  received = @ib.received[:ManagedAccounts].first.accounts_list.split(',')
  # we check, if the account is on the list
  raise "Connected to wrong account #{received}, expected #{account}" unless received.include?(account)

#close_connection
  OPTS[:account_verified] = true
end

### Helpers for placing and verifying orders

shared_examples_for 'Valid account data request' do

  context "received :AccountUpdateTime message" do
    subject { @ib.received[:AccountUpdateTime].first }

    it { should be_an IB::Messages::Incoming::AccountUpdateTime }
    its(:data) { should be_a Hash }
    its(:time_stamp) { should =~ /\d\d:\d\d/ }
    its(:to_human) { should =~ /AccountUpdateTime/ }
  end

  context "received :AccountValue message" do
    subject { @ib.received[:AccountValue].first }

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
    subject { @ib.received[:PortfolioValue].first }

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
    subject { @ib.received[:AccountDownloadEnd].first }

    it { should be_an IB::Messages::Incoming::AccountDownloadEnd }
    its(:data) { should be_a Hash }
    its(:account_name) { should =~ /\w\d/ }
    its(:to_human) { should =~ /AccountDownloadEnd/ }
  end
end
