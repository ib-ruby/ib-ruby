require 'integration_helper'

shared_examples_for 'a valid AccountValue' do 
  it { is_expected.to be_a IB::Account_value }
  its(:currency) { is_expected.to be_a String }
  its(:value){ is_expected.to be_a String }
  its(:key){ is_expected.to be_a Symbol }
end

describe "Request Account Data", :connected => true, :integration => true do

  before(:all) do 
    gw = IB::Gateway.current.presence || IB::Gateway.new( OPTS[:connection].merge(logger: mock_logger, client_id:1056, connect:true, serial_array: false))
    gw.connect if !gw.tws.connected?
    gw.get_account_data 
  end

  after(:all) { IB::Gateway.current.disconnect }
  let( :gw ){ IB::Gateway.current }


  context "properties of the account-object"  do
    it { expect( gw.active_accounts).to be_an Array }
    it { gw.for_active_accounts{|a| expect( a.account_values).to be_an Array } }
    it { gw.for_active_accounts{|a| expect( a.portfolio_values).to be_an Array } }
  end


  context "properties of account_values" do
   let(:account_values){ gw.active_accounts[0].account_values }
   it "each member is an account_value" do
     account_values.each do |av|
       expect( av ).to be_a IB::AccountValue
       [:key,:value,:currency].each{|i| expect( av[i]).to be_a String }
     end
   end
  end
  context "properties of portfolio_values" do
    let(:portfolio_values){ gw.active_accounts[0].portfolio_values }
    it "each member is a portfolio_value" do
      portfolio_values.each do |pv|
	expect( pv ).to be_a IB::PortfolioValue
	expect( pv.attributes ).to be_a Hash
	expect( pv.contract ).to be_a IB::Contract
	## Associated Contracts don't come with an associated ContractDetail-Record.
	expect( pv.contract.contract_detail ).not_to be
      end

    end
 end


end # Request Account Data
