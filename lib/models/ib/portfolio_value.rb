module IB
class PortfolioValue < IB::Model
    include BaseProperties
#	belongs_to :currency
	belongs_to :account
	belongs_to :contract

#	scope :single, ->(key) { where :schluessel => key } rescue nil

    prop :position, 
	:market_price, 
	:market_value, 
	:average_cost, 
	:unrealized_pnl, 
	:realized_pnl


    # Order comparison
    def == other
      super(other) ||
        other.is_a?(self.class) &&
        market_price == other.market_price &&
        average_cost == other.average_cost &&
        position == other.position &&
	unrealized_pnl == other.unrealized_pnl  &&
	realized_pnl == other.realized_pnl &&
        contract == other.contract
    end
    def to_human
      "<PortfolioValue: #{contract.to_human} (#{position}): Market #{market_price}" +
      " price #{market_value} value; PnL: #{unrealized_pnl} unrealized," +
      " #{realized_pnl} realized;>"
    end
    alias to_s to_human


#	def to_invest
#		a=attributes
#		a.delete "created_at"
#		a.delete "updated_at"
#		a.delete "id"
#		a.delete "account_id"
#		a.delete "currency_id"
#		a[:currency] = currency.symbol.presence || currency.name.presence  || nil   unless currency.nil?
#		a  #return_value
#
#
#	end
end # class
end # module
