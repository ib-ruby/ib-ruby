require 'integration_helper'

require 'spec_helper'

describe 'Request Market Data', :connected => true, :integration => true do

  require 'ib-ruby'
  before(:all) { verify_account }

  context 'US Stocks market', :if => :us_trading_hours do
    before(:all) do
      @ib = IB::Connection.new OPTS[:connection].merge(:logger => mock_logger)
      @contract = IB::Contract.new(:symbol => 'AAPL',
                                   :exchange => "Smart",
                                   :currency => "USD",
                                   :sec_type => :stock,
                                   :description => "Apple"
      )
      @ib.send_message :RequestMarketData, :id => 456, :contract => @contract
      @ib.wait_for :TickSize, :TickString, 3 # sec
    end

    after(:all) do
      @ib.send_message :CancelMarketData, :id => 456
      close_connection
    end

    it_behaves_like 'Received Market Data'

    context "received :TickString message" do
      subject { @ib.received[:TickString].first }

      it { should be_an IB::Messages::Incoming::TickString }
      its(:tick_type) { should be_an Integer }
      its(:type) { should be_a Symbol }
      its(:value) { should be_a String }
      its(:data) { should be_a Hash }
      its(:ticker_id) { should == 456 } # ticker_id
      its(:to_human) { should =~ /TickString/ }
    end
  end

  context 'FOREX market' do
    context 'when subscribed to :Tick... messages' do

      before(:all) do
        @ib = IB::Connection.new OPTS[:connection].merge(:logger => mock_logger)

        ##TODO consider a follow the sun market lookup for widening the types tested
        @ib.subscribe(:Alert, :TickPrice, :TickSize) {}
        @ib.send_message :RequestMarketData, :id => 456,
                         :contract => IB::Symbols::Forex[:eurusd]

        @ib.wait_for :TickPrice, :TickSize, 3 # sec
      end

      after(:all) do
        @ib.send_message :CancelMarketData, :id => 456
        close_connection
      end

      it_behaves_like 'Received Market Data'

      it 'logs no warning about unhandled :Alert message' do
        should_not_log /No subscribers for message .*:Alert/
      end

      it 'logs no warning about unhandled :Tick... messages' do
        should_not_log /No subscribers for message .*:TickPrice/
      end

      it 'logs no warning about unhandled :Tick... messages', :if => :forex_trading_hours do
        should_not_log /No subscribers for message .*:TickSize/
      end

    end # when subscribed to :Tick... messages

    context 'when NOT subscribed to :Tick... messages', :slow => true do

      before(:all) do
        @ib = IB::Connection.new OPTS[:connection].merge(:logger => mock_logger)

        @ib.send_message :RequestMarketData, :id => 456,
                         :contract => IB::Symbols::Forex[:eurusd]
        @ib.wait_for :TickPrice, :TickSize, 3 # sec
      end

      after(:all) do
        @ib.send_message :CancelMarketData, :id => 456
        close_connection
      end

      it 'logs warning about unhandled :Alert message' do
        should_log /No subscribers for message .*:Alert/
      end

      it 'logs warning about unhandled :Tick... messages' do
        should_log /No subscribers for message .*:TickPrice/
      end

      it 'logs warning about unhandled :Tick... messages', :if => :forex_trading_hours do
        should_log /No subscribers for message .*:TickSize/
      end

    end # NOT subscribed to :Tick... messages
  end

end # Request Market Data
