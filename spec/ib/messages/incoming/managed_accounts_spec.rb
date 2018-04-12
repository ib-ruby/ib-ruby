require 'message_helper'
require 'account_helper'

shared_examples_for 'ManagedAccounts message' do
  it { is_expected.to be_an IB::Messages::Incoming::ManagedAccounts }
  its(:message_type) { is_expected.to eq :ManagedAccounts }
  its(:message_id) { is_expected.to eq 15 }
	its(:accounts) {is_expected.to be_an Array}
	its( :buffer  ){ is_expected.to be_empty }

  it 'has class accessors as well' do
    expect( subject.class.message_id).to eq  15 
    expect( subject.class.message_type).to eq :ManagedAccounts
  end
end


describe IB::Messages::Incoming do


  context 'Message received from IB', :connected => true  do
    before(:all) do
      ib = IB::Connection.new OPTS[:connection].merge(:logger => mock_logger)
										 
      ib.wait_for :ManagedAccounts
    end

    after(:all) { close_connection }

    subject { IB::Connection.current.received[:ManagedAccounts].first }
		 
    it_behaves_like 'ManagedAccounts message'

		it_behaves_like 'Valid Account Object' do
			let( :the_account_object ){ IB::Connection.current.received[:ManagedAccounts].first.accounts.first  }  
		end
  end #
end # describe IB::Messages:Incoming
