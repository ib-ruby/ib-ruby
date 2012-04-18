require 'message_helper'

# The API can receive frozen market data from Trader Workstation. Frozen market
# data is the last data recorded in our system. During normal trading hours,
# the API receives real-time market data. If you use this function, you are
# telling TWS to automatically switch to frozen market data AFTER the close.
# Then, before the opening of the next trading day, market data will automatically
# switch back to real-time market data.
# :market_data_type = 1 for real-time streaming, 2 for frozen market data

describe "Request Market Data Type", :connected => true, :integration => true do

  before(:all) do
    verify_account
    @ib = IB::Connection.new OPTS[:connection].merge(:logger => mock_logger)
  end

  after(:all) { close_connection }

  context "switching to real_time streaming after-hours" do
    before(:all) do
      @ib.send_message :RequestMarketDataType, :market_data_type => :real_time
      @ib.wait_for 2 # sec
    end

    after(:all) { clean_connection }

    it 'just works' do
    end
  end

  context "switching to frozen market data after-hours" do
    before(:all) do
      @ib.send_message :RequestMarketDataType, :market_data_type => :frozen
      @ib.wait_for 2 # sec
    end

    after(:all) { clean_connection }

    it 'just works' do
    end
  end

end # Request Market Data Type
