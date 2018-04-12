require 'message_helper'
require 'contract_helper'  # provides request_con_id

RSpec.shared_examples 'OptionChainDefinition Message' do 
	subject{ the_message }
  it { is_expected.to be_an IB::Messages::Incoming::OptionChainDefinition }
#	it "print it" doa  # debug
#		puts subject.inspect
#	end
  its(:message_type) { is_expected.to eq :OptionChainDefinition }
	its( :con_id ){ is_expected.to be_a Integer }
	its( :multiplier ){ is_expected.to be_a Integer }
	its( :trading_class ){ is_expected.to be_a String }
	its( :exchange ){ is_expected.to be_a String }
	its( :strikes){ is_expected.to be_an Array }
	its( :expirations){ is_expected.to be_an Array }
  its(:message_id) { is_expected.to eq 75 }
	its( :buffer  ){ is_expected.to be_empty }

  it 'has class accessors as well' do
    expect( subject.class.message_id).to eq 75
    expect( subject.class.message_type).to eq :OptionChainDefinition
  end
end

RSpec.describe IB::Messages::Incoming::OptionChainDefinition do

  context 'Message received from IB', :connected => true  do
    before(:all) do
      ib = IB::Connection.new OPTS[:connection].merge(:logger => mock_logger)
			contract= IB::Stock.new symbol: 'GOOG'
			the_con_id = request_con_id(  contract: contract).first

			ib.send_message :RequestOptionChainDefinition, con_id: the_con_id,
																					 symbol: contract.symbol,
																				#	 exchange: 'BOX,CBOE',
																					 sec_type: "STK" #contract.sec_type


      ib.wait_for :SecurityDefinitionOptionParameterEnd, 10
    end

    after(:all) { close_connection }
		
		it_behaves_like 'OptionChainDefinition Message' do
			let( :the_message ){ IB::Connection.current.received[:OptionChainDefinition].first  }  
		end


  end #
end # describe IB::Messages:Incoming

