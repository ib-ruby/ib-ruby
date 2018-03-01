require 'integration_helper'

## todo  test with a real account (with historical data permissions )

describe 'Request Historic Data', :connected => true, :integration => true , focus: true do

  CORRECT_OPTS = {:id => 567,
                  :contract => IB::Symbols::Stocks[:wfc],
                  :end_date_time => Time.now.to_ib,
                  :duration => '5 D',
                  :bar_size => '15 mins',
                  :data_type => :trades,
                  :format_date => 1}
  before(:all) do
    verify_account
    @ib = IB::Connection.new OPTS[:connection].merge(:logger => mock_logger)
  end

  after(:all) do
    #@ib.send_message :CancelHistoricalData, :id => 456
    close_connection
  end

  context 'Wrong Requests' do
    it 'raises if incorrect bar size' do
      expect do
        @ib.send_message :RequestHistoricalData, CORRECT_OPTS.merge(:bar_size => '11 min')
      end.to raise_error /bar_size must be one of/
    end

    it 'raises if incorrect data_type' do
      expect do
        @ib.send_message :RequestHistoricalData, CORRECT_OPTS.merge(:data_type => :nonsense)
      end.to raise_error /:data_type must be one of/
    end
  end

  context 'Correct Request' do
    before(:all) do
      # No historical data for GBP/CASH@IDEALPRO
			@ib.send_message :RequestMarketDataType, :market_data_type => :delayed
      @ib.send_message :RequestHistoricalData, CORRECT_OPTS
      @ib.wait_for :HistoricalData, 6 # sec
    end

    subject { @ib.received[:HistoricalData].last }

    it { @ib.received[:HistoricalData].should have_at_least(1).historic_data }

    it { should be_an IB::Messages::Incoming::HistoricalData }
    its(:request_id) { should == 567 }
    its(:count) { should be_an Integer }
    its(:start_date) { should =~ /\d{8} *\d\d:\d\d:\d\d/ } # "20120302  22:46:42"
    its(:end_date) { should =~ /\d{8} *\d\d:\d\d:\d\d/ }
    its(:to_human) { should =~ /HistoricalData/ }

    it 'has results Array with returned historic data' do
      subject.results.should be_an Array
      subject.results.size.should == subject.count
      subject.results.each do |bar|
        bar.should be_an IB::Bar
        bar.time.should =~ /\d{8} *\d\d:\d\d:\d\d/
        bar.open.should be_a BigDecimal
        bar.high.should be_a BigDecimal
        bar.low.should be_a BigDecimal
        bar.close.should be_a BigDecimal
        bar.wap.should be_a BigDecimal
        bar.trades.should be_an Integer
        bar.volume.should be_an Integer
      end
    end
  end
end # Request Historic Data
