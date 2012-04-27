require 'ib-ruby/models/contract'

module IB
  module Models

    # "BAG" is not really a contract, but a combination (combo) of securities.
    # AKA basket or bag of securities. Individual securities in combo are represented
    # by ComboLeg objects.
    class Bag < Contract
      # General Notes:
      # 1. :exchange for the leg definition must match that of the combination order.
      # The exception is for a STK legs, which must specify the SMART exchange.
      # 2. :symbol => "USD" For combo Contract, this is an arbitrary value (like "USD")

      validates_format_of :sec_type, :with => /^bag$/, :message => "should be a bag"
      validates_format_of :right, :with => /^none$/, :message => "should be none"
      validates_format_of :expiry, :with => /^$/, :message => "should be blank"

      def default_attributes
        super.merge :sec_type => :bag #,:legs => Array.new,

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
  end # Models
end # IB
