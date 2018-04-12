require 'message_helper'

RSpec.shared_examples 'Position Message' do 
	subject{ the_message }
  it { is_expected.to be_an IB::Messages::Incoming::PositionsMulti }
  its(:message_type) { is_expected.to eq :PositionsMulti }
	its( :contract ){ is_expected.to be_a IB::Contract }
  its(:message_id) { is_expected.to eq 71 }
	its( :buffer  ){ is_expected.to be_empty }

  it 'has class accessors as well' do
    expect( subject.class.message_id).to eq 71
    expect( subject.class.message_type).to eq :PositionsMulti
  end
end

RSpec.describe IB::Messages::Incoming::PositionsMulti do

	context "Syntetic Message" do
		let( :the_message ) do 
			IB::Messages::Incoming::PositionsMulti.new(
			["1", "204", "DU167348", "14171", "LHA", "STK", "", "0.0", "", "", "IBIS", "EUR", "LHA", "XETRA", "10124", "15.39373125"])
		end

		it "has the basic attributes" do
			expect( the_message.request_id ).to eq 204
			expect( the_message.contract.symbol ).to eq 'LHA'
			puts the_message.inspect
		end
		it_behaves_like 'Position Message' 

		end
  context 'Message received from IB', :connected => true , focus: true do
    before(:all) do
      ib = IB::Connection.new OPTS[:connection].merge(:logger => mock_logger)
			ib.send_message :RequestPositionsMulti, request_id: 204, account: ACCOUNT
      ib.wait_for :PositionsMulti, 10
			sleep 1
			ib.send_message :CancelPositionsMulti, :subscribe => false
    end

    after(:all) { close_connection }
		
		it_behaves_like 'Position Message' do
			let( :the_message ){ IB::Connection.current.received[:PositionsMulti].first  }  
		end


  end #
end # describe IB::Messages:Incoming

