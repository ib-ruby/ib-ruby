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
      @contract = IB::Contract.new :symbol => 'AAPL', :sec_type => :stock
      @ib.send_message :RequestContractData, :id => 111, :contract => @contract
      @ib.wait_for :ContractDataEnd, 3 # sec
      # java: 15:33:16:159 <- 9-6-111-0-AAPL-STK--0.0---     ---0-- -
      # ruby: 15:36:15:736 <- 9-6-111-0-AAPL-STK--0.0---SMART--- --0-
    end

    after(:all) { clean_connection } # Clear logs and message collector

    it { @ib.received[:ContractData].should have_exactly(2).contract_data }
    it { @ib.received[:ContractDataEnd].should have_exactly(1).contract_data_end }

    it 'receives Contract Data for requested contract' do
      msg = @ib.received[:ContractData].first
      msg.request_id.should == 111
      msg.contract.should == @contract
      msg.contract.should be_valid
    end

    it 'receives Contract Data with extended fields' do
      # Returns 2 contracts, one for NASDAQ and one for IBIS - internal crossing?

      @ib.received[:ContractData].each do |msg|
        contract = msg.contract
        detail = msg.contract_detail

        contract.symbol.should == 'AAPL'
        contract.local_symbol.should =~ /AAPL|APC/
        contract.con_id.should be_an Integer
        contract.expiry.should == ''
        contract.exchange.should == 'SMART'

        detail.market_name.should =~ /NMS|USSTARS/
        detail.trading_class.should =~ /NMS|USSTARS/
        detail.long_name.should == 'APPLE INC'
        detail.industry.should == 'Technology'
        detail.category.should == 'Computers'
        detail.subcategory.should == 'Computers'
        detail.trading_hours.should =~ /\d{8}:\d{4}-\d{4}/
        detail.liquid_hours.should =~ /\d{8}:\d{4}-\d{4}/
        detail.valid_exchanges.should =~ /ISLAND|IBIS/
        detail.order_types.should be_a String
        detail.price_magnifier.should == 1
        detail.min_tick.should be <= 0.01
      end
    end
  end # Stock

  context "Request Option contract data" do

    before(:all) do
      @contract = IB::Option.new :symbol => "TAP", :expiry => "201501",
                                 :right => :call, :strike => 72.5
      @ib.send_message :RequestContractData, :id => 123, :contract => @contract
      @ib.wait_for :ContractDataEnd, 5 # sec
    end

    after(:all) { clean_connection } # Clear logs and message collector

    subject { @ib.received[:ContractData].first }

    it { @ib.received[:ContractData].should have_exactly(1).contract_data }
    it { @ib.received[:ContractDataEnd].should have_exactly(1).contract_data_end }

    it 'receives Contract Data for requested contract' do
      subject.request_id.should == 123
      subject.contract.should == @contract
      subject.contract.should be_valid
    end

    it 'receives Contract Data with extended fields' do
      contract = subject.contract
      detail = subject.contract_detail

      contract.symbol.should == 'TAP'
      contract.local_symbol.should == 'TAP   150117C00072500'
      contract.expiry.should == '20150116'
      contract.exchange.should == 'SMART'
      contract.con_id.should be_an Integer

      detail.market_name.should == 'TAP'
      detail.trading_class.should == 'TAP'
      detail.long_name.should == 'MOLSON COORS BREWING CO -B'
      detail.industry.should == 'Consumer, Non-cyclical'
      detail.category.should == 'Beverages'
      detail.subcategory.should == 'Brewery'
      detail.trading_hours.should =~ /\d{8}:\d{4}-\d{4}/
      detail.liquid_hours.should =~ /\d{8}:\d{4}-\d{4}/
      detail.valid_exchanges.should =~ /CBOE/
      detail.order_types.should be_a String
      detail.price_magnifier.should == 1
      detail.min_tick.should == 0.01
    end
  end # Request Option data

  context "Request Forex contract data" do

    before(:all) do
      @contract = IB::Contract.new :symbol => 'EUR', # EURUSD pair
                                   :currency => "USD",
                                   :exchange => "IDEALPRO",
                                   :sec_type => :forex
      @ib.send_message :RequestContractData, :id => 135, :contract => @contract
      @ib.wait_for :ContractDataEnd, 3 # sec
    end

    after(:all) { clean_connection } # Clear logs and message collector

    subject { @ib.received[:ContractData].first }

    it { @ib.received[:ContractData].should have_exactly(1).contract_data }
    it { @ib.received[:ContractDataEnd].should have_exactly(1).contract_data_end }

    it 'receives Contract Data for requested contract' do
      subject.request_id.should == 135
      subject.contract.should == @contract
      subject.contract.should be_valid
    end

    it 'receives Contract Data with extended fields' do
      contract = subject.contract
      detail = subject.contract_detail

      contract.symbol.should == 'EUR'
      contract.local_symbol.should == 'EUR.USD'
      contract.expiry.should == ''
      contract.exchange.should == 'IDEALPRO'
      contract.con_id.should be_an Integer

      detail.market_name.should == 'EUR.USD'
      detail.trading_class.should == 'EUR.USD'
      detail.long_name.should =~ /European Monetary Union [Ee]uro/
      detail.industry.should == ''
      detail.category.should == ''
      detail.subcategory.should == ''
      detail.trading_hours.should =~ /\d{8}:\d{4}-\d{4}/
      detail.liquid_hours.should =~ /\d{8}:\d{4}-\d{4}/
      detail.valid_exchanges.should =~ /IDEALPRO/
      detail.order_types.should be_a String
      detail.price_magnifier.should == 1
      detail.min_tick.should be <= 0.0001
    end
  end # Request Forex data

  context "Request Futures contract data" do

    before(:all) do
      @contract = IB::Symbols::Futures[:ym] # Mini Dow Jones Industrial
      @ib.send_message :RequestContractData, :id => 147, :contract => @contract
      @ib.wait_for :ContractDataEnd, 3 # sec
    end

    after(:all) { clean_connection } # Clear logs and message collector

    subject { @ib.received[:ContractData].first }

    it { @ib.received[:ContractData].should have_exactly(1).contract_data }
    it { @ib.received[:ContractDataEnd].should have_exactly(1).contract_data_end }

    it 'receives Contract Data for requested contract' do
      subject.request_id.should == 147
      subject.contract.should == @contract
      subject.contract.should be_valid
    end

    it 'receives Contract Data with extended fields' do
      contract = subject.contract
      detail = subject.contract_detail

      contract.symbol.should == 'YM'
      contract.local_symbol.should =~ /YM/
      contract.expiry.should =~ Regexp.new(IB::Symbols::Futures.next_expiry)
      contract.exchange.should == 'ECBOT'
      contract.con_id.should be_an Integer

      detail.market_name.should == 'YM'
      detail.trading_class.should == 'YM'
      detail.long_name.should == 'Mini Sized Dow Jones Industrial Average $5'
      detail.industry.should == ''
      detail.category.should == ''
      detail.subcategory.should == ''
      detail.trading_hours.should =~ /\d{8}:\d{4}-\d{4}/
      detail.liquid_hours.should =~ /\d{8}:\d{4}-\d{4}/
      detail.valid_exchanges.should =~ /ECBOT/
      detail.order_types.should be_a String
      detail.price_magnifier.should == 1
      detail.min_tick.should == 1
    end
  end # Request Forex data

  context "Request Bond data" do

    before(:all) do
      @contract = IB::Symbols::Bonds[:wag] # Wallgreens bonds (multiple)
      @ib.send_message :RequestContractData, :id => 158, :contract => @contract
      @ib.wait_for :ContractDataEnd, 5 # sec
    end

    after(:all) { clean_connection } # Clear logs and message collector

    subject { @ib.received[:BondContractData].first }

    it { @ib.received[:BondContractData].should have_at_least(1).contract_data }
    it { @ib.received[:ContractDataEnd].should have_exactly(1).contract_data_end }

    it 'receives Contract Data for requested contract' do
      subject.request_id.should == 158
      # subject.contract.should == @contract # symbol is blanc in returned Bond contracts
      subject.contract.should be_valid
    end

    it 'receives Contract Data with extended fields' do
      contract = subject.contract
      detail = subject.contract_detail

      contract.sec_type.should == :bond
      contract.symbol.should == ''
      contract.con_id.should be_an Integer

      detail.cusip.should be_a String
      detail.desc_append.should =~ /WAG/ # "WAG 4 7/8 08/01/13" or similar
      detail.trading_class.should =~ /IBCID/ # "IBCID113527163"
      detail.sec_id_list.should be_a Hash
	# it seems, that these bonds don't got a filled sec_id_list 
#      detail.sec_id_list.should have_key "CUSIP"
 #     detail.sec_id_list.should have_key "ISIN"
      detail.valid_exchanges.should be_a String
      detail.order_types.should be_a String
      detail.min_tick.should == 0.001
    end
  end # Request Forex data
end # Contract Data


__END__
ContractData messages v.6 and 8 identical:
10-8-500-GOOG-OPT-20130118-500-C-SMART-USD-GOOG  130119C00500000-GOOG-GOOG-81032967-0.05-100-ACTIVETIM,ADJUST,ALERT,ALGO,ALLOC,AON,AVGCOST,BASKET,COND,CONDORDER,DAY,DEACT,DEACTDIS,DEACTEOD,FOK,GAT,GTC,GTD,GTT,HID,ICE,IOC,LIT,LMT,MIT,MKT,MTL,NONALGO,OCA,PAON,POSTONLY,RELSTK,SCALE,SCALERST,SMARTSTG,STP,STPLMT,TRAIL,TRAILLIT,TRAILLMT,TRAILMIT,VOLAT,WHATIF,-SMART,AMEX,BATS,BOX,CBOE,CBOE2,IBSX,ISE,MIBSX,NASDAQOM,PHLX,PSE-1-30351181-GOOGLE INC-CL A--201301-Communications-Internet-Web Portals/ISP-EST-20120428:CLOSED;20120430:0930-1600-20120428:CLOSED;20120430:0930-1600-
10-6-500-GOOG-OPT-20130118-500-C-SMART-USD-GOOG  130119C00500000-GOOG-GOOG-81032967-0.01-100-ACTIVETIM,ADJUST,ALERT,ALGO,ALLOC,AON,AVGCOST,BASKET,COND,CONDORDER,DAY,DEACT,DEACTDIS,DEACTEOD,FOK,GAT,GTC,GTD,GTT,HID,ICE,IOC,LIT,LMT,MIT,MKT,MTL,NONALGO,OCA,PAON,POSTONLY,RELSTK,SCALE,SCALERST,SMARTSTG,STP,STPLMT,TRAIL,TRAILLIT,TRAILLMT,TRAILMIT,VOLAT,WHATIF,-SMART,AMEX,BATS,BOX,CBOE,CBOE2,IBSX,ISE,MIBSX,NASDAQOM,PHLX,PSE-1-30351181-GOOGLE INC-CL A--201301-Communications-Internet-Web Portals/ISP-EST-20120428:CLOSED;20120430:0930-1600-20120428:CLOSED;20120430:0930-1600-
