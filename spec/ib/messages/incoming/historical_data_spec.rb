require 'message_helper'

shared_examples_for 'HistoricalData message' do
  it { is_expected.to be_an IB::Messages::Incoming::HistoricalData }
  its(:message_type) { is_expected.to eq :HistoricalData }
  its(:message_id) { is_expected.to eq 17 }
	its(:request_id) {is_expected.to eq 123}
	its( :count ){ is_expected.to be_a Integer }
  its(:start_date) { is_expected.to be_a DateTime }
	its(:end_date) { is_expected.to be_a DateTime }

  it 'has class accessors as well' do
    expect( subject.class.message_id).to eq 17 
    expect( subject.class.message_type).to eq :HistoricalData
  end
end

describe IB::Messages::Incoming::HistoricalData do


  context 'Instantiated with buffer data'  do
    subject do
   IB::Messages::Incoming::HistoricalData.new ["123", 
							"20181119  13:00:21", "20181120  13:00:21", "6", 
							"20181120  08:00:00", "3153.18", "3153.19", "3127.03", "3127.03", "0", "0", "232", 
							"20181120  09:00:00", "3127.03", "3137.78", "3125.12", "3130.56", "0", "0", "220", 
							"20181120  10:00:00", "3130.56", "3138.01", "3123.03", "3131.18", "0", "0", "230", 
							"20181120  11:00:00", "3131.19", "3142.03", "3125.99", "3137.54", "0", "0", "214", 
							"20181120  12:00:00", "3137.54", "3137.54", "3120.01", "3120.01", "0", "0", "224", 
							"20181120  13:00:00", "3120.01", "3120.27", "3119.30", "3120.27", "0", "0", "3"]
    end

    it_behaves_like 'HistoricalData message'
		its( :count ){ is_expected.to eq 6 }
		its( :results ){ is_expected.to be_a Array }
  end


# todo
#  context 'Message received from IB', :connected => true , focus: true do
#
#    before(:all) do
#      @ib = IB::Connection.new OPTS[:connection].merge(:logger => mock_logger)
#			@ib.send_message :RequestHeadTimeStamp, request_id: 123, contract: IB::Symbols::Stocks.aapl
#      @ib.wait_for :HeadTimeStamp
#    end
#
#    after(:all) { close_connection }
#
#    subject { @ib.received[:HeadTimeStamp].first }
#		 
#  #  it_behaves_like 'HeadTimeStamp message'
#  end #
end # describe IB::Messages:Incoming
