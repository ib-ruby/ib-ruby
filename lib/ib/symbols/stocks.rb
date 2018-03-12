# Frequently used stock contracts definitions
# TODO: auto-request :ContractDetails from IB if unknown symbol is requested?
module IB
  module Symbols
    module Stocks
      extend Symbols

      def self.contracts
 @contracts.presence || super.merge(
	 :ib_smart =>   IB::Stock.new( symbol: 'IBKR', 
																:description  => 'Interactive Brokers Stock with smart exchange setting'),
	 :ib =>   IB::Stock.new( symbol: 'IBKR', exchange: 'ISLAND', 
															 :description  => 'Interactive Brokers Stock'),
	 :aapl => IB::Stock.new(:symbol => "AAPL",
																:currency => "USD",
																:description => "Apple Inc."),

	 :msft => IB::Stock.new( symbol: 'MSFT', primary_exchange: 'ISLAND',
																description: 'Apple, primary trading @ ISLAND'), ## primary exchange set
	 :vxx =>	IB::Stock.new(:symbol => "VXX",
																:exchange => "ARCA",
																:description => "iPath S&P500 VIX short term Futures ETN"),
	 :wfc =>	IB::Stock.new(:symbol => "WFC",
																:exchange => "NYSE",
																:currency => "USD",
																:description => "Wells Fargo"),
	:sie =>		IB::Stock.new( symbol: 'SIE', currency: 'EUR', 
																description: 'Siemes AG'),
	:wrong => IB::Stock.new(:symbol => "QEEUUE",
															:exchange => "NYSE",
															:currency => "USD",
															:description => "Non-existent stock")
														)
			end

		end
	end
end
