require 'message_helper'

shared_examples_for 'HeadTimeStamp message' do
  it { is_expected.to be_an IB::Messages::Incoming::HeadTimeStamp }
  its(:message_type) { is_expected.to eq :HeadTimeStamp }
  its(:message_id) { is_expected.to eq 88 }
	its(:request_id) {is_expected.to eq 123}
  its(:date) { is_expected.to be_a Time }
  its(:to_human) { is_expected.to match  /First Historical Datapoint/ }

  it 'has class accessors as well' do
    expect( subject.class.message_id).to eq 88 
    expect( subject.class.message_type).to eq :HeadTimeStamp
  end
end

describe IB::Messages::Incoming do

  context 'Newly instantiated Message' do

    subject do
      IB::Messages::Incoming::HeadTimeStamp.new(
          :request_id => 123,
          :date =>  Time.new )
    end

    it_behaves_like 'HeadTimeStamp message'
  end

  context 'Message received from IB', :connected => true , focus: true do

    before(:all) do
      @ib = IB::Connection.new OPTS[:connection].merge(:logger => mock_logger)
			@ib.send_message :RequestHeadTimeStamp, request_id: 123, contract: IB::Symbols::Stocks.aapl
      @ib.wait_for :HeadTimeStamp
    end

    after(:all) { close_connection }

    subject { @ib.received[:HeadTimeStamp].first }
		 
    it_behaves_like 'HeadTimeStamp message'
  end #
end # describe IB::Messages:Incoming
