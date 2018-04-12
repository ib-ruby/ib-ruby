require 'integration_helper'

describe 'Request Depth of Market Data', :connected => true,
         :integration => true, :if => :forex_trading_hours  do

  before(:all) do
    verify_account
    @ib = IB::Connection.new OPTS[:connection].merge(:logger => mock_logger)

    @ib.send_message :RequestMarketDepth, :id => 456, :num_rows => 3,
                     :contract => IB::Symbols::Forex[:eurusd]

    @ib.wait_for [:MarketDepth, 4], 6 # sec
  end

  after(:all) do
    @ib.send_message :CancelMarketDepth, :id => 456
    close_connection
  end

  subject { @ib.received[:MarketDepth].last }

  it { @ib.received[:MarketDepth].should have_at_least(4).depth_data }

  it { should be_an IB::Messages::Incoming::MarketDepth }
  its(:request_id) { should == 456 }
  its(:price) { should be_a BigDecimal }
  its(:size) { should be_an Integer }
  its(:to_human) { should =~ /MarketDepth/ }

  it 'has position field reflecting the row Id of this market depth entry' do
    subject.position.should be_an Integer
    subject.position.should be >= 0
    subject.position.should be <= 3
  end

  it 'has operation field reflecting how this entry is applied' do
    subject.operation.should be_a Symbol
    subject.operation.to_s.should =~ /insert|update|delete/
  end

  it 'has side field reflecting side of the book: 0 = ask, 1 = bid' do
    subject.side.should be_a Symbol
    subject.side.to_s.should =~ /ask|bid/
  end
end # Request Market Depth
