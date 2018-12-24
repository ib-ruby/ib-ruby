require 'message_helper'

RSpec.describe IB::Messages::Outgoing  do

  context 'Newly instantiated Message' do

    subject do
      IB::Messages::Outgoing::RequestHeadTimeStamp.new(
				request_id: 123,
				contract:  IB::Symbols::Stocks.aapl,
				use_rth: true,
				what_to_show: :trades )
    end

    it { should be_an IB::Messages::Outgoing::RequestHeadTimeStamp }
    its(:message_type) { is_expected.to eq :RequestHeadTimeStamp }
    its(:message_id) { is_expected.to eq 87 }
    its(:to_human) { is_expected.to match /RequestHeadTimeStamp/ }

    it 'has class accessors as well' do
      expect( subject.class.message_type).to eq :RequestHeadTimeStamp
      expect( subject.class.message_id).to eq 87 
      expect( subject.class.version).to be_zero
    end

    it 'encodes correctly' do
     expect( subject.encode.flatten). to eq [87, 123,										# msg-id, req_id
										'', 'AAPL','STK','','','','','SMART','','USD','','',	#  contract
									0 , ### perhaps::>	true,																# include expired
										true,:trades,2 ]																	# use_rth, what_to show
    end


  end
end # describe IB::Messages:Outgoing
