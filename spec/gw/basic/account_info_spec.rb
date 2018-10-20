require 'account_helper'

RSpec.shared_examples 'Portfolio Value Message' do 
	subject{ the_portfolio_value }
  it { is_expected.to be_an IB::Messages::Incoming::PortfolioValue }
  its(:message_type) { is_expected.to eq :PortfolioValue }
	its( :contract ){ is_expected.to be_a IB::Contract }
	its( :portfolio_value ){ is_expected.to be_a IB::PortfolioValue }
  its(:message_id) { is_expected.to eq 7 }
	its( :buffer  ){ is_expected.to be_empty }

	it_behaves_like 'Valid PortfolioValue Object' do
			let( :the_portfolio_value_object  ){ the_portfolio_value.portfolio_value }
	end
  it 'has class accessors as well' do
    expect( subject.class.message_id).to eq 7 
    expect( subject.class.message_type).to eq :PortfolioValue
  end
end
shared_examples_for 'Valid PortfolioValue Object' do
		subject{ the_portfolio_value_object }
		it{ is_expected.to be_a IB::PortfolioValue }
		its( :position ) { is_expected.to be_a BigDecimal }
		its( :market_price ) { is_expected.to be_a BigDecimal }
		its( :market_value ) { is_expected.to be_a BigDecimal }
		its( :average_cost ) { is_expected.to be_a BigDecimal }
		its( :unrealized_pnl ) { is_expected.to be_a BigDecimal }
		its( :realized_pnl ) { is_expected.to be_a BigDecimal }
end


RSpec.shared_examples 'Account Value Message' do
	subject{ the_account_value }
  it { is_expected.to be_an IB::Messages::Incoming::AccountValue }
  its( :message_type ) { is_expected.to eq :AccountValue }
	its( :account_name ){ is_expected.to be_a String }
  its( :message_id)  { is_expected.to eq 6 }
	its( :buffer  ){ is_expected.to be_empty }

  it 'has class accessors as well' do
    expect( subject.class.message_id).to eq 6 
    expect( subject.class.message_type).to eq :AccountValue
  end
end
RSpec.describe IB::Messages::Incoming do

  context 'Message received from IB', :connected => true , focus: true do
    before(:all) do
      ib = IB::Connection.new OPTS[:connection].merge(:logger => mock_logger)
			ib.send_message :RequestAccountData, :subscribe => true, :account_code => ACCOUNT
										 
      ib.wait_for :PortfolioValue
			sleep 1
			ib.send_message :RequestAccountData, :subscribe => false
    end

    after(:all) { close_connection }
		
		it_behaves_like 'Portfolio Value Message' do
			let( :the_portfolio_value ){ IB::Connection.current.received[:PortfolioValue].first  }  
		end

		it_behaves_like 'Account Value Message' do
			let( :the_account_value ) { IB::Connection.current.received[:AccountValue].first }
		end

		it_behaves_like 'Valid AccountValue Object' do
			let( :the_account_value_object ){ IB::Connection.current.received[:AccountValue].first.account_value }  
		end
  end #
end # describe IB::Messages:Incoming

