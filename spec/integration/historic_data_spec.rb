require 'integration_helper'

describe 'Request Historic Data', :connected => true, :integration => true do

  CORRECT_OPTS = {:id => 567,
                  :contract =>  IB::Stock.new( symbol: 'T').query_contract,
                  :end_date_time => Time.now.to_ib,
                  :duration => '5 D',
                  :bar_size => '15 mins',
                  :data_type => :trades,
                  :format_date => 1}
  before(:all) do
    # use a tws where the appropiate permissions exist
    gw = IB::Gateway.current.presence || IB::Gateway.new( OPTS[:connection].merge(logger: mock_logger, client_id:1056, connect:true, serial_array: true, host: 'beta'))
    gw.connect if !gw.tws.connected?
    @ib=gw.tws
    #verify_account
    ## use Connection from verify-Account
#    @ib = IB::Connection.new OPTS[:connection].merge( host: '172.28.50.135')
      @ib.subscribe(:Alert) { |msg| puts msg.to_human }
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
      @ib.send_message :RequestHistoricalData, CORRECT_OPTS
      @ib.wait_for :HistoricalData, 6 # sec
    end

    subject { @ib.received[:HistoricalData].last }

    it { expect( @ib.received[:HistoricalData]).to have_at_least(1).historic_data }

    it { should be_an IB::Messages::Incoming::HistoricalData }
    its(:request_id) { is_expected.to eq 567 }
    its(:count) { is_expected.to be_an Integer }
    its(:start_date) { is_expected.to match /\d{8} *\d\d:\d\d:\d\d/ } # "20120302  22:46:42"
    its(:end_date) { is_expected.to match /\d{8} *\d\d:\d\d:\d\d/ }
    its(:to_human) { is_expected.to match /HistoricalData/ }

    it 'has results Array with returned historic data' do
      expect( subject.results).to be_an Array
      expect( subject.results.size).to eq subject.count
      subject.results.each do |bar|
        expect( bar).to be_an IB::Bar
        expect( bar.time).to match /\d{8} *\d\d:\d\d:\d\d/
        expect( bar.open).to be_a Float
        expect( bar.high).to be_a Float
        expect( bar.low).to  be_a Float
        expect( bar.close).to be_a Float
        expect( bar.wap).to be_a Float
        expect( bar.trades).to be_an Integer
        expect( bar.volume).to be_an Integer
      end
    end
  end
end # Request Historic Data
