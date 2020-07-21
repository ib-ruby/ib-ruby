require 'integration_helper'

describe 'Request Depth of Market Data', :connected => true,
         :integration => true, :if => :forex_trading_hours  do

  before(:all) do
    verify_account
    ib = IB::Connection.new OPTS[:connection].merge(:logger => mock_logger)
    ib.wait_for :NextValidId

    @request_id = ib.send_message :RequestMarketDepth,  :num_rows => 3,
                     :contract => IB::Symbols::Forex[:eurusd]

    ib.wait_for [:MarketDepth, 4], 6 # sec
  end

  after(:all) do
		ib =  IB::Connection.current
    ib.send_message :CancelMarketDepth, :id => @request_id
    close_connection
  end

  subject { IB::Connection.current.received[:MarketDepth].last }

  it { expect( IB::Connection.current.received[:MarketDepth]).to have_at_least(4).depth_data }

 it { is_expected.to  be_an  IB::Messages::Incoming::MarketDepth }
  its(:request_id) { is_expected.to eq @request_id }
  its(:price) { is_expected.to  be_a BigDecimal }
  its(:size) { is_expected.to be_an Integer }
  its(:to_human) { is_expected.to match /MarketDepth/ }

  it 'has position field reflecting the row Id of this market depth entry' do
    expect( subject.position ).to  be_an Integer
	expect( subject.position ).to be > 0 
	expect( subject.position ).to be < 3
  end

  it 'has operation field reflecting how this entry is applied' do
    expect(  subject.operation).to be_a Symbol
    expect( subject.operation.to_s).to match /insert|update|delete/
  end

  it 'has side field reflecting side of the book: 0 = ask, 1 = bid' do
    expect( subject.side).to  be_a Symbol
    expect( subject.side.to_s).to match /ask|bid/
  end
end # Request Market Depth
