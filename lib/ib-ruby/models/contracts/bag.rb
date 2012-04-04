require 'ib-ruby/models/contracts/contract'

module IB
  module Models
    module Contracts

      # "BAG" is not really a contract, but a combination (combo) of securities.
      # AKA basket or bag of securities. Individual securities in combo are represented
      # by ComboLeg objects.
      class Bag < Contract
        # General Notes:
        # 1. :exchange for the leg definition must match that of the combination order.
        # The exception is for a STK legs, which must specify the SMART exchange.
        # 2. :symbol => "USD" For combo Contract, this is an arbitrary value (like “USD”)

        def initialize opts = {}
          @legs = Array.new
          self[:sec_type] = IB::SECURITY_TYPES[:bag]
          super opts
        end

        def description
          self[:description] || to_human
        end

        def to_human
          "<Bag: #{[symbol, exchange, currency].join(' ')} legs: #{legs_description} >"
        end

        ### Leg-related methods
        # TODO: Rewrite with legs and legs_description being strictly in sync...

        # TODO: Find a way to serialize legs without references...
        # IB-equivalent leg description.
        def legs_description
          self[:legs_description] || legs.map { |leg| "#{leg.con_id}|#{leg.weight}" }.join(',')
        end

        def serialize_legs *fields
          return [0] if legs.empty?
          [legs.size, legs.map { |leg| leg.serialize *fields }]
        end

        # Check if two Contracts have same legs (maybe in different order)
        def same_legs? other
          legs == other.legs ||
              legs_description.split(',').sort == other.legs_description.split(',').sort
        end

        # Contract comparison
        def == other
          super && same_legs?(other)
        end

      end # class Bag
    end # Contracts
  end # Models
end # IB
