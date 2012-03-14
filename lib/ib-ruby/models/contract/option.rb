require 'ib-ruby/models/contract'

module IB
  module Models
    class Contract
      class Option < Contract

        # For Options, this is contract's OSI (Option Symbology Initiative) name/code
        alias osi local_symbol

        def osi= value
          # Normalize to 21 char
          self.local_symbol = value.sub(/ /, ' '*(22-value.size))
        end

        # Make valid IB Contract definition from OSI (Option Symbology Initiative) code.
        # NB: Simply making a new Contract with *local_symbol* (osi) property set to a
        # valid OSI code works just as well, just do NOT set *expiry*, *right* or
        # *strike* properties at the same time.
        # This class method provided as a backup, to show how to analyse OSI codes.
        def self.from_osi osi

          # Parse contract's OSI (OCC Option Symbology Initiative) code
          args = osi.match(/(\w+)\s?(\d\d)(\d\d)(\d\d)([pcPC])(\d+)/).to_a.drop(1)
          symbol = args.shift
          year = 2000 + args.shift.to_i
          month = args.shift.to_i
          day = args.shift.to_i
          right = args.shift.upcase
          strike = args.shift.to_i/1000.0
          #p symbol, year, month, day, right, strike

          # Set correct expiry date - IB expiry date differs from OSI if expiry date
          # falls on Saturday (see https://github.com/arvicco/option_mower/issues/4)
          expiry_date = Time.new(year, month, day)
          expiry_date = Time.new(year, month, day-1) if expiry_date.saturday?

          new :symbol => symbol,
              :exchange => "SMART",
              :expiry => expiry_date.to_ib,
              :right => right,
              :strike => strike
        end

        def initialize opts = {}
          super opts
          self[:sec_type] = IB::SECURITY_TYPES[:option]
          self[:description] ||= osi ? osi : "#{symbol} #{strike} #{right} #{expiry}"
        end

        def to_human
          "<Option: " + [symbol, expiry, right, strike, exchange, currency].join("-") + ">"
        end
      end # class Option

      TYPES[IB::SECURITY_TYPES[:option]] = Option
    end # class Contract
  end # module Models
end # module IB
