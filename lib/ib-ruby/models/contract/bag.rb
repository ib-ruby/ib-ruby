require 'ib-ruby/models/contract'

module IB
  module Models
    class Contract

      # "BAG" is not really a contract, but a combination (combo) of securities.
      # AKA basket or bag of securities. Individual securities in combo are represented
      # by ComboLeg objects.
      class Bag < Contract
        # General Notes:
        # 1. :exchange for the leg definition must match that of the combination order.
        # The exception is for a STK legs, which must specify the SMART exchange.
        # 2. :symbol => "USD" For combo Contract, this is an arbitrary value (like “USD”)

        def initialize opts = {}
          super opts
          @sec_type = IB::SECURITY_TYPES[:bag]
        end

        def description
          @description || to_human
        end

        def to_human
          "<Bag: #{[symbol, exchange, currency].join(' ')} legs: #{legs_description} >"
        end

      end # class Bag

      TYPES[IB::SECURITY_TYPES[:bag]] = Bag

    end # class Contract
  end # module Models
end # module IB
