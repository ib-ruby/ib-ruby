# Frequently used stock contracts definitions
# TODO: auto-request :ContractDetails from IB if unknown symbol is requested?
module IB
  module Symbols
    module Commodity
      extend Symbols

      def self.contracts
	  @contracts.presence || super.merge(
          :xau => IB::Contract.new( symbol: 'XAUUSD', sec_type: :commodity, currency: 'USD',
                                    :description => "London Gold ")
	   )
      end

    end
  end
end
