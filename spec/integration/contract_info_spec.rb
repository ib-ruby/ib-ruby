require 'integration_helper'

describe "Request Contract Info", :connected => true, :integration => true do

  before(:all) { verify_account }

 after(:all) { close_connection }

  context "Request Stock data" do

    before(:all) do
      @contract = IB::Stock.new :symbol => 'AAPL'
      @ib.send_message :RequestContractData, :id => 111, :contract => @contract
      @ib.wait_for :ContractDataEnd, 3 # sec
      # java: 15:33:16:159 <- 9-6-111-0-AAPL-STK--0.0---     ---0-- -
      # ruby: 15:36:15:736 <- 9-6-111-0-AAPL-STK--0.0---SMART--- --0-
    end

    after(:all) { clean_connection } # Clear logs and message collector

    it { expect( @ib.received[:ContractData]).to have_exactly(1).contract_data }
    it { expect( @ib.received[:ContractDataEnd]).to have_exactly(1).contract_data_end }

    it 'receives Contract Data for requested contract' do
      msg = @ib.received[:ContractData].first
     expect(  msg.request_id).to eq 111
     expect(  msg.contract).to eq @contract
     expect(  msg.contract).to be_valid
    end

    it 'receives Contract Data with extended fields' do
      # Returns 2 contracts, one for NASDAQ and one for IBIS - internal crossing?

      @ib.received[:ContractData].each do |msg|
        contract = msg.contract
        detail = msg.contract_detail

       expect( contract.symbol).to  eq 'AAPL'
      expect( contract.local_symbol).to  match /AAPL|APC/
      expect( contract.con_id).to  be_an Integer
      expect( contract.expiry).to  eq ''
      expect( contract.exchange).to  eq 'SMART'

      expect( detail.market_name).to  match /NMS|USSTARS/
      expect( detail.trading_class).to  match /NMS|USSTARS/
      expect( detail.long_name).to  eq 'APPLE INC'
      expect( detail.industry).to  eq 'Technology'
      expect( detail.category).to  eq 'Computers'
      expect( detail.subcategory).to  eq 'Computers'
      expect( detail.trading_hours).to  match /\d{8}:\d{4}-\d{4}/
      expect( detail.liquid_hours).to  match /\d{8}:\d{4}-\d{4}/
      expect( detail.valid_exchanges).to  match /ISLAND|IBIS/
      expect( detail.order_types).to  be_a String
      expect( detail.price_magnifier).to  eq 1
      expect( detail.min_tick).to  be <= 0.01
      end
    end
  end # Stock

  context "Request Option contract data" do
    before(:all) do
     @contract= IB::Option.new( symbol:'F', strike:15, right: :put, expiry:'201509' ) 
     @contract.verify
    end



    after(:all) { clean_connection } # Clear logs and message collector

    subject { @contract }

    it { expect( @contract ).to be_a IB::Option }
    it {  expect( @contract ).to be_valid }

    it 'receives Contract Data with extended fields' do
      detail = @contract.contract_detail

      expect( @contract.symbol).to eq 'F'
      expect( @contract.local_symbol).to eq 'F     150918P00015000'
      expect( @contract.expiry).to eq '20150918'
      expect( @contract.exchange).to eq 'SMART'
      expect( @contract.con_id).to  be_an Integer

      expect( detail.market_name).to  eq 'F'
      expect( detail.trading_class).to  eq 'F'
      expect( detail.long_name).to  eq 'FORD MOTOR CO'
      expect( detail.industry).to  eq 'Consumer, Cyclical'
      expect( detail.category).to  eq 'Auto Manufacturers'
      expect( detail.subcategory).to  eq 'Auto-Cars/Light Trucks'
      expect( detail.trading_hours).to  match /\d{8}:\d{4}-\d{4}/
      expect( detail.liquid_hours).to  match /\d{8}:\d{4}-\d{4}/
      expect( detail.valid_exchanges).to  match /CBOE/
      expect( detail.order_types).to  be_a String
      expect( detail.price_magnifier).to  eq 1
      expect( detail.min_tick).to  eq 0.01
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
      subject.contract.should be_valid
    end

    it 'receives Contract Data with extended fields' do
	    contract = subject.contract
	    detail = subject.contract_detail

	    expect( contract.symbol).to  eq 'EUR'
	    expect( contract.local_symbol).to  eq 'EUR.USD'
	    expect( contract.expiry).to  eq ''
	    expect( contract.exchange).to  eq 'IDEALPRO'
	    expect( contract.con_id).to  be_an Integer

	    expect( detail.market_name).to  eq 'EUR.USD'
	    expect( detail.trading_class).to  eq 'EUR.USD'
	    expect( detail.long_name).to  match /European Monetary Union [Ee]uro/
	    expect( detail.industry).to  eq ''
	    expect( detail.category).to  eq ''
	    expect( detail.subcategory).to  eq ''
	    expect( detail.trading_hours).to  match /\d{8}:\d{4}-\d{4}/
	    expect( detail.liquid_hours).to  match /\d{8}:\d{4}-\d{4}/
	    expect( detail.valid_exchanges).to match /IDEALPRO/
	    expect( detail.order_types).to  be_a String
	    expect( detail.price_magnifier).to  eq 1
	    expect( detail.min_tick).to  be <= 0.0001
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

    it { expect( @ib.received[:ContractData]).to  have_exactly(1).contract_data }
    it { expect( @ib.received[:ContractDataEnd]).to have_exactly(1).contract_data_end }

    it 'receives Contract Data for requested contract' do
      expect( subject.request_id).to eq 147
      expect( subject.contract).to be_valid
    end

    it 'receives Contract Data with extended fields' do
      contract = subject.contract
      detail = subject.contract_detail

     expect( contract.symbol).to  eq 'YM'
     expect( contract.local_symbol).to  match /YM/
     expect( contract.expiry).to  match Regexp.new(IB::Symbols::Futures.next_expiry)
     expect( contract.exchange).to  eq 'ECBOT'
     expect( contract.con_id).to  be_an Integer

    expect( detail.market_name).to  eq 'YM'
    expect( detail.trading_class).to  eq 'YM'
    expect( detail.long_name).to  eq 'Mini Sized Dow Jones Industrial Average $5'
    expect( detail.industry).to  eq ''
    expect( detail.category).to  eq ''
    expect( detail.subcategory).to  eq ''
    expect( detail.trading_hours).to  match /\d{8}:\d{4}-\d{4}/
    expect( detail.liquid_hours).to  match /\d{8}:\d{4}-\d{4}/
    expect( detail.valid_exchanges).to  match /ECBOT/
    expect( detail.order_types).to  be_a String
    expect( detail.price_magnifier).to  eq 1
    expect( detail.min_tick).to  eq 1
    end
  end # Request Forex data

  context "Request Bond data", :pending => 'bond daten anpassen!' do

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
      detail.sec_id_list.should have_key "CUSIP"
      detail.sec_id_list.should have_key "ISIN"
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
