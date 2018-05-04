require_relative 'contract'
module IB
	class Stock < IB::Contract
		validates_format_of :sec_type, :with => /\Astock\z/,
			:message => "should be a Stock"
		def default_attributes
			super.merge :sec_type => :stock, currency:'USD', exchange:'SMART'
		end

		def to_human
			att =  [ symbol, currency, ( exchange == 'SMART' ? nil: exchange ), (primary_exchange.present? && !primary_exchange.empty? ? primary_exchange : nil)].compact
						"<Stock: " + att.join(" ") + ">"
		end

	end
end
