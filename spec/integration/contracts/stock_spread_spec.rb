require 'combo_helper'

RSpec.describe "IB::StockSpread" do
	let ( :the_bag ){ IB::StockSpread.new IB::Stock.new( symbol:'T' ), IB::Stock.new(symbol: 'GE') }
  before(:all) do
    verify_account
    IB::Connection.new OPTS[:connection].merge(:logger => mock_logger) do |gw|
			gw.subscribe( :Alert ){|y|  puts y.to_human }
		end
  end

  after(:all) do
    close_connection
  end


	context "initialize without ratio" do
		subject { IB::StockSpread.new IB::Stock.new( symbol:'T' ), IB::Stock.new(symbol: 'GE') }
		it{ is_expected.to be_a IB::StockSpread }
#		it_behaves_like 'a valid Estx Combo'
		
		its(:symbol){ is_expected.to eq "GE,T" }
		its( :legs ){ is_expected.to have(2).elements}
		its( :market_price ){ is_expected.to be_a BigDecimal }
			
	end

	context "initialize with ratio" do
		subject { IB::StockSpread.new IB::Stock.new( symbol:'T' ), IB::Stock.new(symbol: 'GE'), ratio:[1,-3] }
		it{ is_expected.to be_a IB::StockSpread }
#		it_behaves_like 'a valid Estx Combo'
		
		its(:symbol){ is_expected.to eq "GE,T" }
		its( :legs ){ is_expected.to have(2).elements}
		its( :market_price ){ is_expected.to be_a BigDecimal }
			
	end
	context "initialize with (reverse) ratio" do
		subject { IB::StockSpread.new IB::Stock.new( symbol:'GE' ), IB::Stock.new(symbol: 'T'), ratio:[1, -3] }
		it{ is_expected.to be_a IB::StockSpread }
#		it_behaves_like 'a valid Estx Combo'
		
		its(:symbol){ is_expected.to eq "GE,T" }
		its( :legs ){ is_expected.to have(2).elements}
		its( :market_price ){ is_expected.to be_a BigDecimal }
			
	end
end
