require 'message_helper'

shared_examples_for 'AccountSummary message' do
  it { is_expected.to be_an IB::Messages::Incoming::AccountSummary }
  its(:message_type) { is_expected.to eq :AccountSummary }
  its(:message_id) { is_expected.to eq 63 }
	its(:request_id) {is_expected.to eq 123}
	its( :buffer  ){ is_expected.to be_empty }

  it 'has class accessors as well' do
    expect( subject.class.message_id).to eq  63
    expect( subject.class.message_type).to eq :AccountSummary
  end
end

describe IB::Messages::Incoming do

  context 'Simulated Response from TWS', focus: false do

    subject do
      IB::Messages::Incoming::HistogramData.new ["89","123","5","1.2",1,"2.1","2","3.1","3","4.1","4","5.1","5"]
    end

    it_behaves_like 'AccountSummary message'
  end

  context 'Message received from IB', :connected => true , focus: true do
    before(:all) do
      ib = IB::Connection.new OPTS[:connection].merge(:logger => mock_logger)
			ib.send_message :RequestAccountSummary, request_id: 123, tags: 'RegTMargin,ExcessLiquidity, DayTradesRemaining'
										 
      ib.wait_for :AccountSummary
			sleep 1
			ib.send_message :CancelAccountSummary, request_id: 123

    end

    after(:all) { close_connection }

    subject { IB::Connection.current.received[:AccountSummary].first }
		 
    it_behaves_like 'AccountSummary message'

		it "print recieved messages" do
			ib =  IB::Connection.current
			print ib.received[:AccountSummary].account
			puts
			print ib.received[:AccountSummary].tag
			puts
			print ib.received[:AccountSummary].value
			puts
		end
  end #
end # describe IB::Messages:Incoming
