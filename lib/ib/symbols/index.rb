# Frequently used stock contracts definitions
# TODO: auto-request :ContractDetails from IB if unknown symbol is requested?
module IB
  module Symbols
    module Index
      extend Symbols

      def self.contracts
	   @contracts.presence ||  super.merge( 
		     :dax => IB::Contract.new(:symbol => "DAX", sec_type: :index,
                                    :currency => "EUR", exchange: 'DTB',
                                    :description => "DAX Performance Index.")
					      )
      end

    end
  end
end
