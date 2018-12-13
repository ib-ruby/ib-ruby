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
				 :asx => IB::Index.new( :symbol  => 'AP', :currency => 'AUD', exchange: 'ASX',
																		:description => "ASX 200 Index" ),
				 :hsi => IB::Index.new( :symbol  => 'HSI', :currency => 'HKD', exchange: 'HKFE',
																		:description => "Hang Seng Index" ),
				 :minihsi => IB::Index.new( :symbol  => 'MHI', :currency => 'HKD', exchange: 'HKFE',
																		:description => "Mini Hang Seng Index" ),
		     :stoxx => IB::Index.new(:symbol => "Estx50", :currency => "EUR", exchange: 'DTB',
                                    :description => "Dow Jones Euro STOXX50"),
		     :spx => IB::Index.new(:symbol => "SPX", :currency => "USD", exchange: 'CBOE',
                                    :description => "Dow Jones Euro STOXX50"),
				 :vhsi =>  IB::Index.new( symbol: 'VHSI',
																		:description => "Hang Seng Volatility Index"),
				 :vasx  =>  IB::Index.new( symbol: 'XVI', 
																		:description => "ASX 200 Volatility Index")	, 													
		     :vstoxx => IB::Index.new(:symbol => "V2TX", :currency => "EUR", exchange: 'DTB',
                                    :description => "VSTOXX Volatility Index"),
		     :vdax => IB::Index.new(:symbol => "VDAX",
                                    :description => "German VDAX Volatility Index"),
		     :vix => IB::Index.new(:symbol => "VIX",
                                    :description => "CBOE Volatility Index"),
				:volume => IB::Index.new( symbol: 'VOL-NYSE', exchange: 'NYSE',
																	 description: "NYSE Volume Index" ),
				:trin => IB::Index.new( symbol: 'TRIN-NYSE', exchange: 'NYSE',
																   description: "NYSE TRIN (or arms) Index"),
				:tick => IB::Index.new( symbol: 'TICK-NYSE', exchange: 'NYSE',
																   description: "NYSE TICK Index"),
				:a_d => IB::Index.new( symbol: 'AD-NYSE', exchange: 'NYSE',
																	 description: "NYSE Advance Decline Index")	      )
      end

    end
  end
end
