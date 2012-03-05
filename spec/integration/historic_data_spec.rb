require 'integration_helper'

describe 'Request Historic Data', :connected => true, :integration => true do

  before(:all) do
    verify_account
    connect_and_receive :Alert, :HistoricalData
  end

  after(:all) do
    @ib.send_message :CancelHistoricalData, :id => 456
    close_connection
  end

  context 'Wrong Requests' do
    it 'raises if incorrect bar size' do
      expect do
        @ib.send_message :RequestHistoricalData, :id => 456,
                         :contract => IB::Symbols::Stocks[:wfc],
                         :end_date_time => Time.now.to_ib,
                         :duration => '1 D',
                         :bar_size => '11 min',
                         :what_to_show => :trades,
                         :format_date => 1
      end.to raise_error /bar_size must be one of/
    end

    it 'raises if incorrect what_to_show' do
      expect do
        @ib.send_message :RequestHistoricalData, :id => 456,
                         :contract => IB::Symbols::Stocks[:wfc],
                         :end_date_time => Time.now.to_ib,
                         :duration => '1 D',
                         :bar_size => '15 mins',
                         :what_to_show => :nonsense,
                         :format_date => 1
      end.to raise_error /:what_to_show must be one of/
    end
  end

  context 'Correct Request' do
    before(:all) do
      # No historical data for GBP/CASH@IDEALPRO
      @ib.send_message :RequestHistoricalData, :id => 456,
                       :contract => IB::Symbols::Stocks[:wfc],
                       :end_date_time => Time.now.to_ib,
                       :duration => '1 D',
                       :bar_size => '15 mins',
                       :what_to_show => :trades,
                       :format_date => 1

      wait_for(3) { received? :HistoricalData }
    end

    subject { @received[:HistoricalData].last }

    it { @received[:HistoricalData].should have_at_least(1).historic_data }

    it { should be_an IB::Messages::Incoming::HistoricalData }
    its(:request_id) { should == 456 }
    its(:count) { should be_an Integer }
    its(:start_date) { should =~ /\d{8} *\d\d:\d\d:\d\d/ } # "20120302  22:46:42"
    its(:end_date) { should =~ /\d{8} *\d\d:\d\d:\d\d/ }
    its(:to_human) { should =~ /HistoricalData/ }

    it 'has results Array with returned historic data' do
      subject.results.should be_an Array
      subject.results.size.should == subject.count
      subject.results.each do |bar|
        bar.should be_an IB::Models::Bar
        bar.time.should =~ /\d{8} *\d\d:\d\d:\d\d/
        bar.open.should be_a Float
        bar.high.should be_a Float
        bar.low.should be_a Float
        bar.close.should be_a Float
        bar.wap.should be_a Float
        bar.trades.should be_an Integer
        bar.volume.should be_an Integer
      end
    end
  end
end # Request Historic Data