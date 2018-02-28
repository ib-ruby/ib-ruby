require 'order_helper'
require 'message_helper'

# The API can receive frozen market data from Trader Workstation. Frozen market
# data is the last data recorded in our system. During normal trading hours,
# the API receives real-time market data. If you use this function, you are
# telling TWS to automatically switch to frozen market data AFTER the close.
# Then, before the opening of the next trading day, market data will automatically
# switch back to real-time market data.
# :market_data_type = 1 for real-time streaming, 2 for frozen market data


shared_examples_for 'No MarketData Subscription' do
		its( :code  ){ is_expected.to eq 354 }
		its( :message ){ is_expected.to match /Requested market data is not subscribed/ }
end
describe "Request Market Data Type", :connected => true, :integration => true, focus: true  do

  before(:all) do
    verify_account
    @ib = IB::Connection.new OPTS[:connection].merge(:logger => mock_logger)
  end

  after(:all) { close_connection }

  context "switching to real_time streaming after-hours" do
    before(:all) do
      @ib.send_message :RequestMarketDataType, :market_data_type => :real_time
			@ib.send_message :RequestMarketData, :id => 123, :contract => IB::Symbols::Stocks.aapl
      @ib.wait_for 2 # sec
    end

		# assuming, the tws has no market-data-subscriptions
		# then trying to subscribe to real-time data fails with an error
		subject do
			@ib.received[:Alert].last
		end
		it_behaves_like 'No MarketData Subscription' 
		
    after(:all) { clean_connection }

  end

  context "switching to frozen market data after-hours" do
    before(:all) do
      @ib.send_message :RequestMarketDataType, :market_data_type => :frozen
			@ib.send_message :RequestMarketData, :id => 123, :contract => IB::Symbols::Stocks.aapl
      @ib.wait_for 2 # sec
    end

    after(:all) { clean_connection }

		subject do
			@ib.received[:Alert].last
		end
		it_behaves_like 'No MarketData Subscription' 
  end


  context "switching to delayed market data" do
    before(:all) do
			@ib.clear_received :Alert
      @ib.send_message :RequestMarketDataType, :market_data_type => :delayed
			@ib.send_message :RequestMarketData, :id => 123, :contract => IB::Symbols::Stocks.aapl
      @ib.wait_for 10 # sec
			@ib.send_message :CancelMarketData, :id => 123
    end

    after(:all) { clean_connection }

		it{ expect( @ib.received? :Alert, 1).to be_truthy  }
		it{ expect( @ib.received[:Alert].message.last).to match /Displaying delayed market data/  }
		it{ expect( @ib.received[:MarketDataType].market_data_type ).to eq [3] }
		it{ expect( @ib.received[:TickPrice].price).to be_an Array  }
  end
end # Request Market Data Type
