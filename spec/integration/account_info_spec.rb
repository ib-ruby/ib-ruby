require 'integration_helper'

describe "Request Account Data", :connected => true, :integration => true do

  before(:all) do
    verify_account

    connect_and_receive(:Alert, :AccountValue, :AccountDownloadEnd,
                        :PortfolioValue, :AccountUpdateTime)

    @ib.send_message :RequestAccountData, :subscribe => true

    wait_for(5) { received? :AccountDownloadEnd }
  end

  after(:all) do
    @ib.send_message :RequestAccountData, :subscribe => false
    close_connection
  end

  context "received :Alert message " do
    subject { @received[:Alert].first }

    it { should be_an IB::Messages::Incoming::Alert }
    it { should be_warning }
    it { should_not be_error }
    its(:code) { should be_a Integer }
    its(:message) { should =~ /Market data farm connection is OK/ }
    its(:to_human) { should =~ /TWS Warning / }
  end

  context "received :AccountUpdateTime message" do
    subject { @received[:AccountUpdateTime].first }

    it { should be_an IB::Messages::Incoming::AccountUpdateTime }
    its(:data) { should be_a Hash }
    its(:time_stamp) { should =~ /\d\d:\d\d/ }
    its(:to_human) { should =~ /AccountUpdateTime/ }
  end

  context "received :AccountValue message" do
    subject { @received[:AccountValue].first }

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
    subject { @received[:PortfolioValue].first }

    it { should be_an IB::Messages::Incoming::PortfolioValue }
    its(:contract) { should be_a IB::Models::Contract }
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
    subject { @received[:AccountDownloadEnd].first }

    it { should be_an IB::Messages::Incoming::AccountDownloadEnd }
    its(:data) { should be_a Hash }
    its(:account_name) { should =~ /\w\d/ }
    its(:to_human) { should =~ /AccountDownloadEnd/ }
  end
end # Request Account Data
