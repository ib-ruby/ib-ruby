module IB
  module Models

    # ComboLeg is essentially a join Model between Combo (BAG) Contract and
    # individual Contracts (securities) that this BAG contains.
    class ComboLeg < Model.for(:combo_leg)
      include ModelProperties

      # BAG Combo Contract that contains this Leg
      belongs_to :combo, :class_name => 'Contract'
      # Contract that constitutes this Leg
      belongs_to :leg_contract, :class_name => 'Contract', :foreign_key => :leg_contract_id

      # General Notes:
      # 1. The exchange for the leg definition must match that of the combination order.
      # The exception is for a STK leg definition, which must specify the SMART exchange.

      prop :con_id, # int: The unique contract identifier specifying the security.
           :ratio, # int: Select the relative number of contracts for the leg you
           #              are constructing. To help determine the ratio for a
           #              specific combination order, refer to the Interactive
           #              Analytics section of the User's Guide.

           :exchange, # String: exchange to which the complete combo order will be routed.
           # For institutional customers only! For stock legs when doing short sale
           :short_sale_slot, # int: 0 - retail(default), 1 = clearing broker, 2 = third party
           :designated_location, # String: Only for shortSaleSlot == 2.
           #                    Otherwise leave blank or orders will be rejected.
           :exempt_code, # int: ?
           [:side, :action] => PROPS[:side], # String: Action/side: BUY/SELL/SSHORT/SSHORTX
           :open_close => PROPS[:open_close]
      # int: Whether the order is an open or close order. Values:
      # SAME = 0 Same as the parent security. The only option for retail customers.
      # OPEN = 1 Open. This value is only valid for institutional customers.
      # CLOSE = 2 Close. This value is only valid for institutional customers.
      # UNKNOWN = 3

      # Extra validations
      validates_numericality_of :ratio, :con_id
      validates_format_of :designated_location, :with => /^$/,
                          :message => "should be blank or orders will be rejected"

      def default_attributes
        super.merge :con_id => 0,
                    :ratio => 1,
                    :side => :buy,
                    :open_close => :same, # The only option for retail customers.
                    :short_sale_slot => :default,
                    :designated_location => '',
                    :exchange => 'SMART', # Unless SMART, Order modification fails
                    :exempt_code => -1
      end

      #  Leg's weight is a combination of action and ratio
      def weight
        side == :buy ? ratio : -ratio
      end

      def weight= value
        value = value.to_i
        if value > 0
          self.side = :buy
          self.ratio = value
        else
          self.side = :sell
          self.ratio = -value
        end
      end

      # Some messages include open_close, some don't. wtf.
      def serialize *fields
        [con_id,
         ratio,
         side.to_sup,
         exchange,
         (fields.include?(:extended) ?
             [self[:open_close],
              self[:short_sale_slot],
              designated_location,
              exempt_code] :
             [])
        ].flatten
      end

      def to_human
        "<ComboLeg: #{side} #{ratio} con_id #{con_id} at #{exchange}>"
      end

      # Order comparison
      def == other
        other && other.is_a?(ComboLeg) &&
            con_id == other.con_id &&
            ratio == other.ratio &&
            open_close == other.open_close &&
            short_sale_slot == other.short_sale_slot&&
            exempt_code == other.exempt_code &&
            side == other.side &&
            exchange == other.exchange &&
            designated_location == other.designated_location
      end

    end # ComboLeg
  end # module Models
end # module IB
