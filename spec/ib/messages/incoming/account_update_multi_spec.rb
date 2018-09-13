require 'message_helper'

RSpec.shared_examples 'Account Updates Multi Message' do 
  it { is_expected.to be_an IB::Messages::Incoming::AccountUpdatesMulti }
  its(:message_type) { is_expected.to eq :AccountUpdatesMulti }
	its( :value ){ is_expected.to be_a BigDecimal }
	its( :key ){ is_expected.to be_a String }
	its( :currency ){ is_expected.to be_a( String ).or be_nil  }
  its(:message_id) { is_expected.to eq 73 }
	its( :buffer  ){ is_expected.to be_empty }

  it 'has class accessors as well' do
    expect( subject.class.message_id).to eq 73
    expect( subject.class.message_type).to eq :AccountUpdatesMulti
		puts subject.inspect
  end
end

RSpec.describe IB::Messages::Incoming::AccountUpdatesMulti do


  context 'Message received wfrom IB' do
    before(:all) do
      ib = IB::Connection.new OPTS[:connection].merge(:logger => mock_logger)
			request_id =ib.send_message :RequestAccountUpdatesMulti, account: 'ALL'
      ib.wait_for :AccountUpdatesMulti, 10
			sleep 1
			ib.send_message :CancelAccountUpdatesMulti, request_id: request_id
    end

    after(:all) { close_connection }
		
		subject{ IB::Connection.current.received[:AccountUpdatesMulti].first  }  
		it_behaves_like 'Account Updates Multi Message' 
	


  end #
end # describe IB::Messages:Incoming

