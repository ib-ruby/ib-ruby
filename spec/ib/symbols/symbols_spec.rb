require 'spec_helper'

describe IB::Symbols do

  it 'references pre-defined IB stock Contracts' do
    wfc = IB::Symbols::Stocks[:wfc]
    wfc.should be_an IB::Contract
    wfc.sec_type.should == :stock
    wfc.symbol.should == "WFC"
    wfc.exchange.should == "NYSE"
    wfc.currency.should == "USD"
    wfc.description.should == "Wells Fargo"
  end

  it 'references pre-defined IB option Contracts' do
    wfc = IB::Symbols::Options[:wfc20]
    wfc.should be_an IB::Contract
    wfc.sec_type.should == :option
    wfc.symbol.should == "WFC"
    wfc.expiry.should == "201301"
    wfc.right.should == :call
    wfc.strike.should == 20
    wfc.description.should == "Wells Fargo 20 Call 2013-01"
  end

  it 'references pre-defined IB forex Contracts' do
    fx = IB::Symbols::Forex[:gbpusd]
    fx.should be_an IB::Contract
    fx.sec_type.should == :forex
    fx.symbol.should == "GBP"
    fx.currency.should == "USD"
    fx.exchange.should == "IDEALPRO"
    fx.description.should == "GBPUSD"
  end
  
  it 'references pre-defined IB forex Contracts' do
    # this tests whether new symbols can be added to currency list to create new forex symbols.
    # first add the new symbols "abc" & "def" to the currency list (in lib/ib/symbols/forex.rb), 
    # then run this test.
    pending("can we add new symbols to the currency list?")
    fx = IB::Symbols::Forex[:abcdef]
    fx.should be_an IB::Contract
    fx.sec_type.should == :forex
    fx.symbol.should == "ABC"
    fx.currency.should == "DEF"
    fx.exchange.should == "IDEALPRO"
    fx.description.should == "ABCDEF"
  end

  it 'references pre-defined IB futures Contracts' do
    fx = IB::Symbols::Futures[:gbp]
    fx.should be_an IB::Contract
    fx.expiry.should == IB::Symbols::Futures.next_expiry
    fx.sec_type.should == :future
    fx.symbol.should == "GBP"
    fx.currency.should == "USD"
    fx.multiplier.should == 62500
    fx.exchange.should == "GLOBEX"
    fx.description.should == "British Pounds"
  end


end # describe IB::Symbols
