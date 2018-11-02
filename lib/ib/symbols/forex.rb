module IB
  module Symbols
    module Forex
      extend Symbols

      def self.contracts
        @contracts ||= define_contracts
      end

      private

      # IDEALPRO is for orders over 20,000 and routes to the interbank quote stream.
      # IDEAL is for smaller orders, and has wider spreads/slower execution... generally
      # used for smaller currency conversions. IB::Symbols::Forex contracts are pre-defined
      # on IDEALPRO, if you need something else please define forex contracts manually.
      def self.define_contracts
        @contracts = {}

        # use combinations of these currencies for pre-defined forex contracts
        currencies = [ "aud", "cad", "chf", "eur", "gbp", "hkd", "jpy", "nzd", "usd" ]

        # create pairs list from currency list
        pairs = currencies.product(currencies).
          map { |pair| pair.join.upcase unless pair.first == pair.last }.compact

        # now define each contract
        pairs.each do |pair|
          @contracts[pair.downcase.to_sym] = IB::Forex.new(
            :symbol => pair[0..2],
            :exchange => "IDEALPRO",
            :currency => pair[3..5],
						:local_symbol => pair[0..2]+'.'+pair[3..5],
            :description => pair
          )
        end
        
        @contracts
      end
    end
  end
end
