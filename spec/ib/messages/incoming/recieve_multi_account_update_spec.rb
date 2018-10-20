require 'message_helper'
require 'account_helper'

shared_examples_for 'ReceiveFA message' do
  it { is_expected.to be_an IB::Messages::Incoming::ReceiveFA }
  its(:message_type) { is_expected.to eq :ReceiveFA }
  its(:message_id) { is_expected.to eq 16 }
	its(:accounts) {is_expected.to be_an Array}
	its( :buffer  ){ is_expected.to be_empty }

  it 'has class accessors as well' do
    expect( subject.class.message_id).to eq  16 
    expect( subject.class.message_type).to eq :ReceiveFA
  end
end


describe IB::Messages::Incoming do


  context 'Message received from IB', :connected => true do
    before(:all) do
      ib = IB::Connection.new OPTS[:connection].merge(:logger => mock_logger)
										 
			ib.send_message :RequestFA, fa_data_type: 3   # alias

      ib.wait_for :ReceiveFA
    end

    after(:all) { close_connection }

    subject { IB::Connection.current.received[:ReceiveFA].first }
		 
    it_behaves_like 'ReceiveFA message'

		it_behaves_like 'Valid Account Object' do
			let( :the_account_object ){ IB::Connection.current.received[:ReceiveFA].first.accounts.first  }  
		end
  end #
end # describe IB::Messages:Incoming
