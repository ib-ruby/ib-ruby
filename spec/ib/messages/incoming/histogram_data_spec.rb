require 'message_helper'

shared_examples_for 'HistogramData message' do
  it { is_expected.to be_an IB::Messages::Incoming::HistogramData }
  its(:message_type) { is_expected.to eq :HistogramData }
  its(:message_id) { is_expected.to eq 89 }
	its(:request_id) {is_expected.to eq 123}
  its(:number_of_points) { is_expected.to eq 5 }  #be > 0 }
  its(:results) { is_expected.to be_an Array }
	its( :buffer  ){ is_expected.to be_empty }

  it 'has class accessors as well' do
    expect( subject.class.message_id).to eq 89 
    expect( subject.class.message_type).to eq :HistogramData
  end
end

describe IB::Messages::Incoming do

  context 'Simulated Response from TWS' do

    subject do
      IB::Messages::Incoming::HistogramData.new ["89","123","5","1.2",1,"2.1","2","3.1","3","4.1","4","5.1","5"]
    end

    it_behaves_like 'HistogramData message'
  end

  context 'Message received from IB', :connected => true , pending: true do
## This happends on the lack of permissions
#I, [2018-03-02T05:44:38.411662 #15045]  
		#INFO -- : TWS Warning 10188: Failed to request histogram data:No market data permissions for ISLAND STK
#
##
    before(:all) do
      @ib = IB::Connection.new OPTS[:connection].merge(:logger => mock_logger)
			@ib.send_message :RequestHistogramData,  contract: IB::Symbols::Stocks.aapl, 
											 time_period: '1 month'
      @ib.wait_for :HistogramData
    end

    after(:all) { close_connection }

    subject { @ib.received[:HistogramData].first }
		 
    it_behaves_like 'HistogramData message'
  end #
end # describe IB::Messages:Incoming
