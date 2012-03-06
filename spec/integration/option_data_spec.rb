require 'integration_helper'

def wait_for_all_ticks
  wait_for(5) do
    received?(:TickPrice) && received?(:TickSize) &&
        received?(:TickOption) && received?(:TickString)
  end
end

describe 'Request Market Data for Options', :if => :us_trading_hours,
         :connected => true, :integration => true do

  before(:all) do
    verify_account
    connect_and_receive :Alert, :TickPrice, :TickSize, :TickOption, :TickString

    @ib.send_message :RequestMarketData, :id => 456,
                     :contract => IB::Symbols::Options[:aapl500]
    wait_for_all_ticks
  end

  after(:all) do
    @ib.send_message :CancelMarketData, :id => 456
    close_connection
  end

  context "received :Alert message " do
    subject { @received[:Alert].first }

    it { should be_an IB::Messages::Incoming::Alert }
    it { should be_warning }
    it { should_not be_error }
    its(:code) { should be_an Integer }
    its(:message) { should =~ /Market data farm connection is OK/ }
    its(:to_human) { should =~ /TWS Warning/ }
  end

  context "received :TickPrice message" do
    subject { @received[:TickPrice].first }

    it { should be_an IB::Messages::Incoming::TickPrice }
    its(:tick_type) { should be_an Integer }
    its(:type) { should be_a Symbol }
    its(:price) { should be_a Float }
    its(:size) { should be_an Integer }
    its(:can_auto_execute) { should be_an Integer }
    its(:data) { should be_a Hash }
    its(:ticker_id) { should == 456 } # ticker_id
    its(:to_human) { should =~ /TickPrice/ }
  end

  context "received :TickSize message" do
    subject { @received[:TickSize].first }

    it { should be_an IB::Messages::Incoming::TickSize }
    its(:type) { should_not be_nil }
    its(:data) { should be_a Hash }
    its(:tick_type) { should be_an Integer }
    its(:type) { should be_a Symbol }
    its(:size) { should be_an Integer }
    its(:ticker_id) { should == 456 }
    its(:to_human) { should =~ /TickSize/ }
  end

  context "received :TickOption message" do
    subject { @received[:TickOption].first }

    it { should be_an IB::Messages::Incoming::TickOption }
    its(:type) { should_not be_nil }
    its(:data) { should be_a Hash }
    its(:tick_type) { should be_an Integer }
    its(:type) { should be_a Symbol }
    its(:under_price) { should be_a Float }
    its(:option_price) { should be_a Float }
    its(:pv_dividend) { should be_a Float }
    its(:implied_volatility) { should be_a Float }
    its(:gamma) { should be_a Float }
    its(:vega) { should be_a Float }
    its(:theta) { should be_a Float }
    its(:ticker_id) { should == 456 }
    its(:to_human) { should =~ /TickOption/ }
  end

  context "received :TickString message" do
    subject { @received[:TickString].first }

    it { should be_an IB::Messages::Incoming::TickString }
    its(:type) { should_not be_nil }
    its(:data) { should be_a Hash }
    its(:tick_type) { should be_an Integer }
    its(:type) { should be_a Symbol }
    its(:value) { should be_a String }
    its(:ticker_id) { should == 456 }
    its(:to_human) { should =~ /TickString/ }
  end
end # Request Options Market Data
