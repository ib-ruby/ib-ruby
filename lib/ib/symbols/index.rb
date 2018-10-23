# Frequently used stock contracts definitions
# TODO: auto-request :ContractDetails from IB if unknown symbol is requested?
module IB
  module Symbols
    module Index
      extend Symbols

      def self.contracts
	   @contracts.presence ||  super.merge( 
		     :dax => IB::Index.new(:symbol => "DAX", :currency => "EUR", exchange: 'DTB',
                                    :description => "DAX Performance Index."),
					      
		     :stoxx => IB::Index.new(:symbol => "Estx50", :currency => "EUR", exchange: 'DTB',
                                    :description => "Dow Jones Euro STOXX50"),
		     :spx => IB::Index.new(:symbol => "SPX", :currency => "USD", exchange: 'CBOE',
                                    :description => "Dow Jones Euro STOXX50"),
		     :vstoxx => IB::Index.new(:symbol => "V2TX", :currency => "EUR", exchange: 'DTB',
                                    :description => "VSTOXX Volatility Index"),
		     :vdax => IB::Index.new(:symbol => "VDAX",
                                    :description => "German VDAX Volatility Index"),
		     :vix => IB::Index.new(:symbol => "VIX",
                                    :description => "CBOE Volatility Index"),
																		
					      )
      end

    end
  end
end
