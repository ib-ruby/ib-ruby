require 'models/ib/contract'
require 'models/ib/option_detail'

module IB
  class Option < Contract

    validates_numericality_of :strike, :greater_than => 0
    validates_format_of :sec_type, :with => /\Aoption\z/,
      :message => "should be an option"
    validates_format_of :local_symbol, :with => /\A\w+\s*\d{6}[pcPC]\d{8}$|\A\z/,
      :message => "invalid OSI code"
    validates_format_of :right, :with => /\Aput$|^call\z/,
      :message => "should be put or call"


		# introduce Option.greek with reference to IB::OptionDetail-dataset
		#
		has_one :greek , as: :option_detail
    # For Options, this is contract's OSI (Option Symbology Initiative) name/code
    alias osi local_symbol

    def osi= value
      # Normalize to 21 char
      self.local_symbol = value.sub(/ /, ' '*(22-value.size))
    end

    # Make valid IB Contract definition from OSI (Option Symbology Initiative) code.
    # NB: Simply making a new Contract with *local_symbol* (osi) property set to a
    # valid OSI code works just as well, just do NOT set *expiry*, *right* or
    # *strike* properties in this case.
    # This class method provided as a backup and shows how to analyse OSI codes.
    def self.from_osi osi

      # Parse contract's OSI (OCC Option Symbology Initiative) code
      args = osi.match(/(\w+)\s?(\d\d)(\d\d)(\d\d)([pcPC])(\d+)/).to_a.drop(1)
      symbol = args.shift
      year = 2000 + args.shift.to_i
      month = args.shift.to_i
      day = args.shift.to_i
      right = args.shift.upcase
      strike = args.shift.to_i/1000.0

      # Set correct expiry date - IB expiry date differs from OSI if expiry date
      # falls on Saturday (see https://github.com/arvicco/option_mower/issues/4)
      expiry_date = Time.utc(year, month, day)
      expiry_date = Time.utc(year, month, day-1) if expiry_date.wday == 6

      new :symbol => symbol,
        :exchange => "SMART",
        :expiry => expiry_date.to_ib[2..7], # YYMMDD
        :right => right,
        :strike => strike
    end

    def default_attributes
      super.merge :sec_type => :option
      #self[:description] ||= osi ? osi : "#{symbol} #{strike} #{right} #{expiry}"
    end
		def == other
      super(other) || (  # finish positive, if contract#== is true
												  # otherwise, we most probably compare the response from IB with our selfmade input
			exchange == other.exchange &&
			include_expired == other.include_expired &&
			sec_type == other.sec_type  &&
			multiplier == other.multiplier &&
			strike == other.strike &&
			right == other.right &&
			multiplier == other.multiplier &&
			expiry == other.expiry )

		end

    def to_human
      "<Option: " + [symbol, expiry, right, strike, exchange, currency].join(" ") + ">"
    end

  end # class Option
end # module IB
