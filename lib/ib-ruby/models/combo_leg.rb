module IB
  module Models

    # ComboLeg objects represent individual securities in a "BAG" contract - which
    # is not really a contract, but a combination (combo) of securities. AKA basket
    # or bag of securities.
    class ComboLeg < Model
      # General Notes:
      # 1. The exchange for the leg definition must match that of the combination order.
      # The exception is for a STK leg definition, which must specify the SMART exchange.

      # // open/close leg value is same as combo
      # Specifies whether the order is an open or close order. Valid values are:
      SAME = 0 #  Same as the parent security. The only option for retail customers.
      OPEN = 1 #  Open. This value is only valid for institutional customers.
      CLOSE = 2 # Close. This value is only valid for institutional customers.
      UNKNOWN = 3

      prop :con_id, # int: The unique contract identifier specifying the security.
           :ratio, # int: Select the relative number of contracts for the leg you
           #              are constructing. To help determine the ratio for a
           #              specific combination order, refer to the Interactive
           #              Analytics section of the User's Guide.

           :action, # String: BUY/SELL/SSHORT/SSHORTX The side (buy or sell) for the leg.
           :exchange, # String: exchange to which the complete combo order will be routed.
           :open_close, # int: Specifies whether the order is an open or close order.
           #              Valid values: ComboLeg::SAME/OPEN/CLOSE/UNKNOWN

           # For institutional customers only! For stock legs when doing short sale
           :short_sale_slot, # int: 0 - retail, 1 = clearing broker, 2 = third party
           :designated_location, # String: Only for shortSaleSlot == 2.
           #                    Otherwise leave blank or orders will be rejected.
           :exempt_code # int: ?

      DEFAULT_PROPS = {:con_id => 0,
                       :open_close => SAME,
                       :short_sale_slot => 0,
                       :designated_location => '',
                       :exempt_code => -1, }

      #  Leg's weight is a combination of action and ratio
      def weight
        action == 'BUY' ? ratio : -ratio
      end

      def weight= value
        value = value.to_i
        if value > 0
          self.action = 'BUY'
          self.ratio = value
        else
          self.action = 'SELL'
          self.ratio = -value
        end
      end

      # Some messages include open_close, some don't. wtf.
      def serialize *fields
        [con_id,
         ratio,
         action,
         exchange,
         (fields.include?(:extended) ? [open_close, short_sale_slot,
                                        designated_location, exempt_code] : [])
        ].flatten
      end
    end # ComboLeg

  end # module Models
end # module IB
