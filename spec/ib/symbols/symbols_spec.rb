require 'spec_helper'

describe IB::Symbols, focus: true  do

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
    wfc = IB::Symbols::Options[:ge20]
    wfc.should be_an IB::Contract
    wfc.sec_type.should == :option
    wfc.symbol.should == "GE"
    wfc.expiry.should == "201901"
    wfc.right.should == :call
    wfc.strike.should == 20
    wfc.description.should == "General Electric 20 Call 2019-01"
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

  it 'references pre-defined IB futures Contracts' do
    fx = IB::Symbols::Futures[:gbp]
    fx.should be_an IB::Contract
    fx.expiry.should == IB::Symbols::Futures.next_expiry
    fx.sec_type.should == :future
    fx.symbol.should == "GBP"
    fx.currency.should == "USD"
    fx.multiplier.should == 62500
    fx.exchange.should == "GLOBEX"
    fx.description.should =~ /British Pounds/
  end

  it 'raises an error if requested contract symbol is not defined' do
    expect {stk = IB::Symbols::Stocks[:xyz]}.
      to raise_error "Unknown symbol :xyz, please pre-define it in lib/ib/symbols/stocks.rb"
    expect {opt = IB::Symbols::Options[:xyz20]}.
      to raise_error "Unknown symbol :xyz20, please pre-define it in lib/ib/symbols/options.rb"
    expect {fx = IB::Symbols::Forex[:abcdef]}.
      to raise_error "Unknown symbol :abcdef, please pre-define it in lib/ib/symbols/forex.rb"
    expect {fut = IB::Symbols::Futures[:abc]}.
      to raise_error "Unknown symbol :abc, please pre-define it in lib/ib/symbols/futures.rb"
  end

end # describe IB::Symbols
