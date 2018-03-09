require 'message_helper'
require 'account_helper'

shared_examples_for 'Received Market Data' do
  context "received :Alert message " do
    subject { IB::Connection.current.received[:Alert].first }

    it { should be_an IB::Messages::Incoming::Alert }
    it { should be_warning }
    it { should_not be_error }
    its(:code) { should be_an Integer }
    its(:message) { should =~ /data farm connection is OK/ }
    its(:to_human) { should =~ /TWS Warning/ }
  end

  context "received :TickPrice message" do
    subject { IB::Connection.current.received[:TickPrice].first }

    it { should be_an IB::Messages::Incoming::TickPrice }
    its(:tick_type) { should be_an Integer }
    its(:type) { should be_a Symbol }
    its(:price) { should be_a BigDecimal }
    its(:size) { should be_an Integer }
    its(:data) { should be_a Hash }
    its(:ticker_id) { should == 456 } # ticker_id
    its(:to_human) { should =~ /TickPrice/ }
  end

  context "received :TickSize message", :if => :us_trading_hours do
    before(:all) do
      IB::Connection.current.wait_for 3, :TickSize
    end

    subject { IB::Connection.current.received[:TickSize].first }

    it { should be_an IB::Messages::Incoming::TickSize }
    its(:type) { should_not be_nil }
    its(:data) { should be_a Hash }
    its(:tick_type) { should be_an Integer }
    its(:type) { should be_a Symbol }
    its(:size) { should be_an Integer }
    its(:ticker_id) { should == 456 }
    its(:to_human) { should =~ /TickSize/ }
  end
end
