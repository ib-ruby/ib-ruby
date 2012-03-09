require 'integration_helper'

describe 'Request Market Data', :connected => true, :integration => true do

  context 'when subscribed to :Tick... messages' do

    before(:all) do
      verify_account
      @ib = IB::Connection.new OPTS[:connection].merge(:logger => mock_logger)

      ##TODO consider a follow the sun market lookup for windening the types tested
      @ib.subscribe(:Alert, :TickPrice, :TickSize) {}
      @ib.send_message :RequestMarketData, :id => 456,
                       :contract => IB::Symbols::Forex[:eurusd]

      @ib.wait_for 3, :TickPrice, :TickSize
    end

    after(:all) do
      @ib.send_message :CancelMarketData, :id => 456
      close_connection
    end

    it_behaves_like 'Received Market Data'

    it "logs warning about unhandled :Alert message" do
      should_not_log /No subscribers for message .*:Alert/
    end

    it "logs warning about unhandled :Tick... messages" do
      should_not_log /No subscribers for message .*:TickPrice/
    end

    it "logs warning about unhandled :Tick... messages", :if => :forex_trading_hours do
      should_not_log /No subscribers for message .*:TickSize/
    end

  end # when subscribed to :Tick... messages

  context 'when NOT subscribed to :Tick... messages', :slow => true do

    before(:all) do
      @ib = IB::Connection.new OPTS[:connection].merge(:logger => mock_logger)

      @ib.send_message :RequestMarketData, :id => 456,
                       :contract => IB::Symbols::Forex[:eurusd]
      @ib.wait_for 3, :TickPrice, :TickSize
    end

    after(:all) do
      @ib.send_message :CancelMarketData, :id => 456
      close_connection
    end

    it "logs warning about unhandled :Alert message" do
      should_log /No subscribers for message .*:Alert/
    end

    it "logs warning about unhandled :Tick... messages" do
      should_log /No subscribers for message .*:TickPrice/
    end

    it "logs warning about unhandled :Tick... messages", :if => :forex_trading_hours do
      should_log /No subscribers for message .*:TickSize/
    end

  end # NOT subscribed to :Tick... messages

end # Request Market Data
