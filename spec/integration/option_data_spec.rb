require 'integration_helper'

describe 'Request Market Data for Options', :if => :us_trading_hours,
         :connected => true, :integration => true do

  before(:all) do
    verify_account
    @ib = IB::Connection.new OPTS[:connection].merge(:logger => mock_logger)

    @ib.send_message :RequestMarketData, :id => 456,
                     :contract => IB::Symbols::Options[:aapl500]
    @ib.wait_for 5, :TickPrice, :TickSize, :TickString, :TickOption
  end

  after(:all) do
    @ib.send_message :CancelMarketData, :id => 456
    close_connection
  end

  it_behaves_like 'Received Market Data'

  context "received :TickOption message" do
    subject { @ib.received[:TickOption].first }

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
    subject { @ib.received[:TickString].first }

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
