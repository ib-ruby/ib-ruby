require 'message_helper'

shared_examples_for 'TickByTickData message' do
  it { is_expected.to be_an IB::Messages::Outgoing::RequestTickByTickData }
  its( :message_type ) { is_expected.to eq :RequestTickByTickData}
	its( :request_id ) {is_expected.to be_an Integer }

  it 'has class accessors as well' do
    expect( subject.class.message_type).to eq :RequestTickByTickData
  end
end


shared_examples_for 'TickByTick message' do
  it { is_expected.to be_an IB::Messages::Incoming::TickByTick }
  its( :message_type ) { is_expected.to eq :TickByTick}
  its( :message_id ) { is_expected.to eq 99 }
#	its( :request_id ) {is_expected.to eq 5320}
	its( :ticker_id ) {is_expected.to be_an Integer}
	its( :tick_type ){ is_expected.to be_an Integer }
	its( :time ){ is_expected.to be_an Time }
end

shared_examples_for 'ticktype 1 message' do
	its( :tick_type ){ is_expected.to eq 1 }
#	it{ puts subject.inspect }
	its( :size ){ is_expected.to be_an Integer }
	its( :price ){ is_expected.to be_an Numeric }
	its( :mask ){ is_expected.to be_an Integer }
end

shared_examples_for 'ticktype 3 message' do
	its( :tick_type ){ is_expected.to eq 3 }
#	it{ puts subject.inspect }
	its( :bid_size ){ is_expected.to be_an Integer }
	its( :ask_size ){ is_expected.to be_an Integer }
	its( :bid_price ){ is_expected.to be_an Numeric }
	its( :ask_price ){ is_expected.to be_an Numeric }
	its( :mask ){ is_expected.to be_an Integer }
end
RSpec.describe IB::Messages::Outgoing::RequestTickByTickData do
	context ' the object'  do
		subject do
			IB::Messages::Outgoing::RequestTickByTickData.new(
				request_id: 5320,
				contract: IB::Symbols::Stocks.sie,
				tick_type: 'Last'
			)
		end
		it_behaves_like 'TickByTickData message'
	end
#	context 'Serialized Message'  do
#
#		subject do
#			IB::Messages::Outgoing::RequestTickByTickData.new
#			["+0", "91", "5320",
#		"", "SIE", "STK", "", "", "", "", "SMART", "", "EUR", "", "",  # contract
#		"1",																												# ticktype
#		"10", "1", "\""]																					 # numberofticks, ignoresize
#		end
#
#		it_behaves_like 'TickByTickData message'
#
#	end
 end
RSpec.describe IB::Messages::Incoming::TickByTick do
		
	context 'Newly instantiated Message' do

    subject do
      IB::Messages::Incoming::TickByTick.new ["5320", "1", "1545661744", "2399.75", "1", "0"]
		end
		
    it_behaves_like 'TickByTick message'
		it_behaves_like 'ticktype 1 message'
	end
  context 'received Last-Ticks from IB', :connected => true  do
##
    before(:all) do
      ib = IB::Connection.new OPTS[:connection].merge(:logger => mock_logger)
			req= ib.send_message :RequestTickByTickData,  contract: IB::Symbols::Futures.es,
								:tick_type => 'Last'

      ib.wait_for :TickByTick
			ib.send_message :CancelTickByTickData, request_id: req    end

    after(:all) { close_connection }

    subject { IB::Connection.current.received[:TickByTick].first }
		 
    it_behaves_like 'TickByTick message'
		it_behaves_like 'ticktype 1 message'

	
  end 
  context 'received BidAsk-Ticks from IB', :connected => true  do
##
    before(:all) do
      ib = IB::Connection.new OPTS[:connection].merge(:logger => mock_logger)
			req = ib.send_message :RequestTickByTickData,  contract: IB::Symbols::Futures.es,
								:tick_type => 'BidAsk'

      ib.wait_for :TickByTick
			ib.send_message :CancelTickByTickData, request_id: req
    end

    after(:all) { close_connection }

    subject { IB::Connection.current.received[:TickByTick].first }
		 
    it_behaves_like 'TickByTick message'
		it_behaves_like 'ticktype 3 message'

	
  end 
end # describe IB::Messages:Incoming
