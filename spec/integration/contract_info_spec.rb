require 'integration_helper'

describe "Request Contract Info", :connected => true, :integration => true do

  before(:all) do
    verify_account
    connect_and_receive :NextValidID, :Alert, :ContractData, :ContractDataEnd
    wait_for { received? :NextValidID }
  end

  after(:all) { close_connection }

  context "Request Option data" do

    before(:all) do
      @contract = IB::Symbols::Options[:aapl500]
      @ib.send_message :RequestContractData,
                       :id => 123,
                       :contract => @contract

      wait_for { received? :ContractData }
    end

    it { @received[:ContractData].should have_exactly(1).contract_data }
    it { @received[:ContractDataEnd].should have_exactly(1).contract_data_end }

    it 'receives filled OpenOrder' do
      msg = @received[:ContractData].first
      msg.contract.should == @contract
    end

  end # Request Option data
end # Contract Data
