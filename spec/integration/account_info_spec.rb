require 'integration_helper'

describe IB::Messages do

  # Pattern for writing message specs is like this:
  #
  # 1. You indicate your interest in some message types by calling 'connect_and_receive'
  #    in a top-level before(:all) block. All messages of given types will be caught
  #    and placed into @received Hash, keyed by message type
  #
  # 2. You send request messages to IB and then wait for specific conditions (or timeout)
  #    by calling 'wait_for' in a context before(:all) block.
  #
  # 3. Once the condition is satisfied, you can test the content of @received Hash
  #    to see what messages were received, or log_entries Array to see what was logged
  #
  # 4. When done, you call 'close_connection' in a top-level  after(:all) block.

  context "Request Account Data", :connected => true do

    before(:all) do
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
end # describe IB::Messages::Incomming
