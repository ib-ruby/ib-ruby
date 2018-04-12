require 'message_helper'
require 'account_helper'

shared_examples_for 'AccountSummary message' do
  it { is_expected.to be_an IB::Messages::Incoming::AccountSummary }
  its(:message_type) { is_expected.to eq :AccountSummary }
  its(:message_id) { is_expected.to eq 63 }
	its(:request_id) {is_expected.to be_a Integer}
	its( :buffer  ){ is_expected.to be_empty }

  it 'has class accessors as well' do
    expect( subject.class.message_id).to eq  63
    expect( subject.class.message_type).to eq :AccountSummary
  end
end


describe IB::Messages::Incoming do


  context 'Message received from IB', :connected => true  do
    before(:all) do
      ib = IB::Connection.new OPTS[:connection].merge(:logger => mock_logger)
			req_id= ib.send_message :RequestAccountSummary, tags: 'RegTMargin,ExcessLiquidity, DayTradesRemaining'
										 
      ib.wait_for :AccountSummary
			sleep 1
			ib.send_message :CancelAccountSummary, id: req_id

    end

    after(:all) { close_connection }

    subject { IB::Connection.current.received[:AccountSummary].first }
		 
    it_behaves_like 'AccountSummary message'

		it_behaves_like 'Valid AccountValue Object' do
			let( :the_account_value_object ){ IB::Connection.current.received[:AccountSummary].first.account_value  }  
		end
		it "has appropiate attributes" do
			expect( subject.account_value ).to be_a  IB::AccountValue
			expect( subject.account_name).to be_a String
		end
  end #
end # describe IB::Messages:Incoming
