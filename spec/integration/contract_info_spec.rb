require 'integration_helper'

describe "Request Contract Info", :connected => true, :integration => true do

  before(:all) do
    verify_account
    @ib = IB::Connection.new OPTS[:connection].merge(:logger => mock_logger)
    @ib.wait_for :NextValidId
  end

  after(:all) { close_connection }

  context "Request Stock data" do

    before(:all) do
      @contract = IB::Models::Contract.new :symbol => 'AAPL',
                                           :sec_type => IB::SECURITY_TYPES[:stock]
      @ib.send_message :RequestContractData, :id => 111, :contract => @contract
      @ib.wait_for 3, :ContractDataEnd
    end

    after(:all) { clean_connection } # Clear logs and message collector

    it { @ib.received[:ContractData].should have_exactly(2).contract_data }
    it { @ib.received[:ContractDataEnd].should have_exactly(1).contract_data_end }

    it 'receives Contract Data for requested contract' do
      msg = @ib.received[:ContractData].first
      msg.request_id.should == 111
      msg.contract.should == @contract
    end

    it 'receives Contract Data with extended fields' do
      # Returns 2 contracts, one for NASDAQ and one for IBIS - internal crossing?

      @ib.received[:ContractData].each do |msg|
        contract = msg.contract
        contract.symbol.should == 'AAPL'

        contract.local_symbol.should =~ /AAPL|APC/
        contract.market_name.should =~ /NMS|USSTARS/
        contract.trading_class.should =~ /NMS|USSTARS/
        contract.long_name.should == 'APPLE INC'
        contract.industry.should == 'Technology'
        contract.category.should == 'Computers'
        contract.subcategory.should == 'Computers'
        contract.exchange.should == 'SMART'
        contract.con_id.should be_an Integer
        contract.trading_hours.should =~ /\d{8}:\d{4}-\d{4}/
        contract.liquid_hours.should =~ /\d{8}:\d{4}-\d{4}/
        contract.valid_exchanges.should =~ /ISLAND|IBIS/
        contract.order_types.should be_a String
        contract.price_magnifier.should == 1
        contract.min_tick.should be <= 0.01

        contract.expiry.should be_nil
      end
    end
  end # Stock

  context "Request Option contract data" do

    before(:all) do
      @contract = IB::Models::Contract::Option.new :symbol => "AAPL",
                                                   :expiry => "201301",
                                                   :right => "CALL",
                                                   :strike => 500
      @ib.send_message :RequestContractData, :id => 123, :contract => @contract
      @ib.wait_for 3, :ContractDataEnd
    end

    after(:all) { clean_connection } # Clear logs and message collector

    subject { @ib.received[:ContractData].first }

    it { @ib.received[:ContractData].should have_exactly(1).contract_data }
    it { @ib.received[:ContractDataEnd].should have_exactly(1).contract_data_end }

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
      contract.con_id.should be_an Integer
      contract.trading_hours.should =~ /\d{8}:\d{4}-\d{4}/
      contract.liquid_hours.should =~ /\d{8}:\d{4}-\d{4}/
      contract.valid_exchanges.should =~ /CBOE/
      contract.order_types.should be_a String
      contract.price_magnifier.should == 1
      contract.min_tick.should == 0.01
    end
  end # Request Option data

  context "Request Forex contract data" do

    before(:all) do
      @contract = IB::Models::Contract.new :symbol => 'EUR', # EURUSD pair
                                           :currency => "USD",
                                           :exchange => "IDEALPRO",
                                           :sec_type => IB::SECURITY_TYPES[:forex]
      @ib.send_message :RequestContractData, :id => 135, :contract => @contract
      @ib.wait_for 3, :ContractDataEnd
    end

    after(:all) { clean_connection } # Clear logs and message collector

    subject { @ib.received[:ContractData].first }

    it { @ib.received[:ContractData].should have_exactly(1).contract_data }
    it { @ib.received[:ContractDataEnd].should have_exactly(1).contract_data_end }

    it 'receives Contract Data for requested contract' do
      subject.request_id.should == 135
      subject.contract.should == @contract
    end

    it 'receives Contract Data with extended fields' do
      contract = subject.contract
      contract.symbol.should == 'EUR'

      contract.local_symbol.should == 'EUR.USD'
      contract.market_name.should == 'EUR.USD'
      contract.trading_class.should == 'EUR.USD'
      contract.long_name.should == 'European Monetary Union euro'
      contract.industry.should == ''
      contract.category.should == ''
      contract.subcategory.should == ''
      contract.expiry.should be_nil
      contract.exchange.should == 'IDEALPRO'
      contract.con_id.should be_an Integer
      contract.trading_hours.should =~ /\d{8}:\d{4}-\d{4}/
      contract.liquid_hours.should =~ /\d{8}:\d{4}-\d{4}/
      contract.valid_exchanges.should =~ /IDEALPRO/
      contract.order_types.should be_a String
      contract.price_magnifier.should == 1
      contract.min_tick.should be <= 0.0001
    end
  end # Request Forex data

  context "Request Futures contract data" do

    before(:all) do
      @contract = IB::Symbols::Futures[:ym] # Mini Dow Jones Industrial
      @ib.send_message :RequestContractData, :id => 147, :contract => @contract
      @ib.wait_for 3, :ContractDataEnd
    end

    after(:all) { clean_connection } # Clear logs and message collector

    subject { @ib.received[:ContractData].first }

    it { @ib.received[:ContractData].should have_exactly(1).contract_data }
    it { @ib.received[:ContractDataEnd].should have_exactly(1).contract_data_end }

    it 'receives Contract Data for requested contract' do
      subject.request_id.should == 147
      subject.contract.should == @contract
    end

    it 'receives Contract Data with extended fields' do
      contract = subject.contract
      contract.symbol.should == 'YM'

      contract.local_symbol.should =~ /YM/
      contract.market_name.should == 'YM'
      contract.trading_class.should == 'YM'
      contract.long_name.should == 'Mini Sized Dow Jones Industrial Average $5'
      contract.industry.should == ''
      contract.category.should == ''
      contract.subcategory.should == ''
      contract.expiry.should =~ Regexp.new(IB::Symbols.next_expiry)
      contract.exchange.should == 'ECBOT'
      contract.con_id.should be_an Integer
      contract.trading_hours.should =~ /\d{8}:\d{4}-\d{4}/
      contract.liquid_hours.should =~ /\d{8}:\d{4}-\d{4}/
      contract.valid_exchanges.should =~ /ECBOT/
      contract.order_types.should be_a String
      contract.price_magnifier.should == 1
      contract.min_tick.should == 1
    end
  end # Request Forex data
end # Contract Data
