# Sample bond contract definitions
module IB
  module Symbols
    module Bonds
      extend Symbols

      def self.contracts
        @contracts ||= {
          :abbey  => IB::Contract.new(:symbol => "ABBEY",
                                   :currency => "USD",
                                   :sec_type => :bond,
                                   :description => "Any ABBEY bond"),

          :ms => IB::Contract.new(:symbol => "MS",
                                   :currency => "USD",
                                   :sec_type => :bond,
                                   :description => "Any Morgan Stanley bond"),

          :wag => IB::Contract.new(:symbol => "WAG",
                                   :currency => "USD",
                                   :sec_type => :bond,
                                   :description => "Any Wallgreens bond"),
        }
      end

    end
  end
end
