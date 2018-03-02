require 'message_helper'

shared_examples_for 'PositionData message' do
  it { is_expected.to be_an IB::Messages::Incoming::PositionData }
  its(:message_type) { is_expected.to eq :PositionData }
	its( :contract ){ is_expected.to be_a IB::Contract }
  its(:message_id) { is_expected.to eq 61 }
	its( :buffer  ){ is_expected.to be_empty }

  it 'has class accessors as well' do
    expect( subject.class.message_id).to eq  61
    expect( subject.class.message_type).to eq :PositionData
  end
end

describe IB::Messages::Incoming do

  context 'Simulated Response from TWS', focus: false do

    subject do
      IB::Messages::Incoming::HistogramData.new ["89","123","5","1.2",1,"2.1","2","3.1","3","4.1","4","5.1","5"]
    end

    it_behaves_like 'PositionData message'
  end

  context 'Message received from IB', :connected => true , focus: true do
## This happends on the lack of permissions
#I, [2018-03-02T05:44:38.411662 #15045]  
		#INFO -- : TWS Warning 10188: Failed to request histogram data:No market data permissions for ISLAND STK
#
##
    before(:all) do
      ib = IB::Connection.new OPTS[:connection].merge(:logger => mock_logger)
			ib.send_message :RequestPositions
										 
      ib.wait_for :PositionData
			sleep 1
			ib.send_message :CancelPositions

    end

    after(:all) { close_connection }

    subject { IB::Connection.current.received[:PositionData].first }
		 
    it_behaves_like 'PositionData message'

  end #
end # describe IB::Messages:Incoming
