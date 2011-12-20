require 'ib-ruby/models/contract'

module IB
  module Models
    class Contract
      # "BAG" is not really a contract, but a combination (combo) of securities.
      # AKA basket or bag of securities. Individual securities in combo are represented
      # by ComboLeg objects.
      class Bag < Contract

        def initialize opts = {}
          super opts
          @sec_type = IB::SECURITY_TYPES[:bag]
        end

        def description
          @description || to_human
        end

        def to_human
          "<Bag: " + [symbol, exchange, currency].join(" ") + " legs: " +
              (@combo_legs_description ||
                  @combo_legs.map do |leg|
                    "#{leg.action} #{leg.ratio} * #{leg.con_id}"
                  end.join('|')) + ">"
        end

      end # class Bag
      TYPES[IB::SECURITY_TYPES[:bag]] = Bag
    end # class Contract
  end # module Models
end # module IB
