# Frequently used stock contracts definitions
# TODO: auto-request :ContractDetails from IB if unknown symbol is requested?
module IB
  module Symbols
    module CFD
      extend Symbols

      def self.contracts
	@contracts.presence || super.merge(
          :dax => IB::Contract.new(:symbol => "IBDE30", sec_type: :cfd,
                                    :currency => "EUR",
                                    :description => "DAX  CFD."),

 )
      end

    end
  end
end
