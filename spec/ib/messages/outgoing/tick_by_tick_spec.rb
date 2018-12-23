require 'message_helper'

shared_examples_for 'TickByTickiData message' do
  it { is_expected.to be_an IB::Messages::Incoming::TickByTickData }
  its(:message_type) { is_expected.to eq :TickByTickData}
  its(:message_id) { is_expected.to eq 91 }
	its(:ticker_id) {is_expected.to eq 5320}
	its( :buffer  ){ is_expected.to be_empty }

  it 'has class accessors as well' do
    expect( subject.class.message_id).to eq 21 
    expect( subject.class.message_type).to eq :TickOption
  end
end

RSpec.describe IB::Messages::Outgoing::RequestTickByTickData do
	context ' the object'  do
		subject do
			IB::Messages::Outgoing::RequestTickByTickData.new(
				request_id: 5320,
				contract: IB::Symbols::Stock.sie,
				tick_type: 'Last'
			)
		end
		it_behaves_like 'TickByTickData message'
	end
	context 'Serialized Message'  do

		subject do
			IB::Messages::Outgoing::TickByTickData.new
			["+0", "91", "5320",
		"", "SIE", "STK", "", "", "", "", "SMART", "", "EUR", "", "",  # contract
		"1",																												# ticktype
		"10", "1", "\""]																					 # numberofticks, ignoresize
		end

		it_behaves_like 'TickByTickData message'

	end
 end
RSpec.describe IB::Messages::Incoming::TickByTick do


  context 'Message received from IB', :connected => true , focus: true do
##
    before(:all) do
      ib = IB::Connection.new OPTS[:connection].merge(:logger => mock_logger)
			ib.send_message :RequestiTickByTickData, request_id: 5320, contract: IB::Symbols::Stock.sie,
								:tick_type => 'last'

      ib.wait_for :TickByTick
    end

    after(:all) { close_connection }

    subject { IB::Connection.current.received[:TickByTick].first }
		 
    it_behaves_like 'TickByTick message'
#		its( :implied_volatility ){ is_expected.to eq 0.29 }
#		its( :under_price ){ is_expected.to eq 190 }
#		its( :option_price ){ is_expected.to be_a BigDecimal }
#		its( :delta ){ is_expected.to be_a BigDecimal }
#		its( :gamma ){ is_expected.to be_a BigDecimal }
#		its( :vega ){ is_expected.to be_a BigDecimal }
#		its( :theta ){ is_expected.to be_a BigDecimal }
#		its( :pv_dividend ){ is_expected.to be_a BigDecimal }
#		its( :type ){ is_expected.to eq :cust_option_computation }

	
  end 
end # describe IB::Messages:Incoming
