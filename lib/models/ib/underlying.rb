module IB

  # Calculated characteristics of underlying Contract (volatile)
  class Underlying < IB::Model
    include BaseProperties

    has_one :contract

    prop :con_id, # Id of the Underlying Contract
      :delta, # double: The underlying stock or future delta.
      :price #  double: The price of the underlying.

      validates_numericality_of :con_id, :delta, :price #, :allow_nil => true

    def default_attributes
      super.merge :con_id => 0
    end

    # Serialize under_comp parameters
    def serialize
      [true, con_id, delta, price]
    end

    # Comparison
    def == other
      super(other) ||
        other.is_a?(self.class) &&
        con_id == other.con_id && delta == other.delta && price == other.price
    end

  end # class Underlying
  UnderComp = Underlying

end # module IB
