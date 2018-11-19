require 'integration_helper'
# todo:  run with a real account with marketdata subsriptions
RSpec.describe 'Request Market Data for Options', :if => :us_trading_hours,
         :connected => true, :integration => true  do

  before(:all) do
    verify_account
    ib = IB::Connection.new OPTS[:connection].merge(:logger => mock_logger)
		ib.send_message :RequestMarketDataType, :market_data_type => :delayed
    @req = ib.send_message :RequestMarketData, :contract => IB::Symbols::Options.aapl200
    ib.wait_for :TickPrice, :TickSize, :TickString, :TickOption, 5 # sec
  end

  after(:all) do
    IB::Connection.current.send_message :CancelMarketData, :id =>  @req
    close_connection
  end

  it_behaves_like 'Received Market Data', @req

  context IB::Messages::Incoming::TickOption do
    subject { IB::Connection.current.received[:TickOption].first }

    it { is_expected.to be_an IB::Messages::Incoming::TickOption }
    its(:type) { is_expected.not_to be_nil }
    its(:data) { is_expected.to be_a Hash }
    its(:tick_type) { is_expected.to be_an Integer }
    its(:type) { is_expected.to be_a Symbol }
    its(:under_price) { is_expected.to be_a BigDecimal }
    its(:option_price) { is_expected.to be_a BigDecimal }
    its(:pv_dividend) { is_expected.to be_a BigDecimal }
    its(:implied_volatility) { is_expected.to be_a BigDecimal }
    its(:gamma) { is_expected.to be_a BigDecimal }
    its(:vega) { is_expected.to be_a BigDecimal }
    its(:theta) { is_expected.to be_a BigDecimal }
    its(:ticker_id) { is_expected.to eq @req  }
    its(:to_human) { is_expected.to match /TickOption/ }
  end

  context IB::Messages::Incoming::TickString  do
    subject { IB::Connection.current.received[:TickString].first }

    it { is_expected.to be_an IB::Messages::Incoming::TickString }
    its(:type) { is_expected.not_to be_nil }
    its(:data) { is_expected.to be_a Hash }
    its(:tick_type) { is_expected.to be_an Integer }
    its(:type) { is_expected.to be_a Symbol }
    its(:value) { is_expected.to be_a String }
    its(:ticker_id) { is_expected.to eq @req }
    its(:to_human) { is_expected.to match /TickString/ }
  end
end # Request Options Market Data
