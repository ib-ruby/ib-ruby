module IB
  module Symbols
    module Forex
      extend Symbols

      # IDEALPRO is for orders over 25,000 and routes to the interbank quote stream.
      # IDEAL is for smaller orders, and has wider spreads/slower execution... generally
      # used for smaller currency conversions.
      def self.contracts
        @contracts ||= define_contracts
      end
      
      def self.define_contracts
        @contracts = {}
        
        # use combinations of these currencies for pre-defined forex contracts
        recognized_currencies = [
          "aud",
          "cad",
          "chf",
          "eur",
          "gbp",
          "hkd",
          "jpy",
          "nzd",
          "usd"
          ]

        # create fx symbol list from currency list
        fx_symbol_list = []
        all_pairs = recognized_currencies.product(recognized_currencies)
        all_pairs.each_index do |i|
          fx_symbol_list[i] = (all_pairs[i][0] + all_pairs[i][1]).downcase.to_sym unless all_pairs[i][0] == all_pairs[i][1]
        end
        # delete nil entries in fx_symbol_list array
        fx_symbol_list.compact!

        # now define each contract
        fx_symbol_list.each do |fx_sym|
          @contracts[fx_sym] = IB::Contract.new(
              :symbol => fx_sym.to_s[0..2].upcase,
              :exchange => "IDEALPRO",
              :currency => fx_sym.to_s[3..5].upcase,
              :sec_type => :forex,
              :description => fx_sym.to_s.upcase
          )
        end  
        return @contracts      
      end
    end
  end
end
                                    
                                      
                                      
                                      