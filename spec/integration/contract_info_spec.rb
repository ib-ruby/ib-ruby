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
      @contract = IB::Models::Contract::Option.new :symbol => "AAPL",
                                               :expiry => "201301",
                                               :right => "CALL",
                                               :strike => 500
      @ib.send_message :RequestContractData,
                       :id => 123,
                       :contract => @contract

      wait_for(3) { received? :ContractData }
    end

    subject { @received[:ContractData].first }

    it { @received[:ContractData].should have_exactly(1).contract_data }
    it { @received[:ContractDataEnd].should have_exactly(1).contract_data_end }

    it 'receives Contract Data for requested contract' do
      subject.request_id.should == 123
      subject.contract.should == @contract
    end

    it 'receives Contract Data with extended fields' do
      contract = subject.contract
      contract.symbol.should == 'AAPL'

      contract.local_symbol.should == 'AAPL  130119C00500000'
      contract.market_name.should == 'AAPL'
      contract.trading_class.should == 'AAPL'
      contract.long_name.should == 'APPLE INC'
      contract.industry.should == 'Technology'
      contract.category.should == 'Computers'
      contract.subcategory.should == 'Computers'
      contract.expiry.should == '20130118'
      contract.exchange.should == 'SMART'
      contract.con_id.should == 82635631
      contract.trading_hours.should =~ /\d{8}:\d{4}-\d{4}/
      contract.liquid_hours.should =~ /\d{8}:\d{4}-\d{4}/
      contract.valid_exchanges.should =~ /CBOE|SMART/
      contract.order_types.should be_a String
      contract.price_magnifier.should == 1
      contract.min_tick.should == 0.01
    end

  end # Request Option data
end # Contract Data
