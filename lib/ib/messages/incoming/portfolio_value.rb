module  IB
  module Messages
    module Incoming

      PortfolioValue = def_message [7, 7],
                                   [:contract, :con_id, :int],
                                   [:contract, :symbol, :string],
                                   [:contract, :sec_type, :string],
                                   [:contract, :expiry, :string],
                                   [:contract, :strike, :decimal],
                                   [:contract, :right, :string],
                                   [:contract, :multiplier, :string],
                                   [:contract, :primary_exchange, :string],
                                   [:contract, :currency, :string],
                                   [:contract, :local_symbol, :string],
                                   [:position, :int],
                                   [:market_price, :decimal],
                                   [:market_value, :decimal],
                                   [:average_cost, :decimal],
                                   [:unrealized_pnl, :decimal_max], # May be nil!
                                   [:realized_pnl, :decimal_max], #   May be nil!
                                   [:account_name, :string]
      class PortfolioValue

        def contract
          @contract = IB::Contract.build @data[:contract]
        end

        def to_human
          "<PortfolioValue: #{contract.to_human} (#{position}): Market #{market_price}" +
              " price #{market_value} value; PnL: #{unrealized_pnl} unrealized," +
              " #{realized_pnl} realized; account #{account_name}>"
        end

	def portfolio_value
	  @portfolio_value =  IB::PortfolioValue.new  position: @data[:position], 
						      market_price: @data[:market_price],
						     market_value: @data[:market_value],
						     average_cost: @data[:average_cost],
						     unrealized_pnl: @data[:unrealized_pnl],
						     realized_pnl: @data[:realized_pnl],
						      contract: contract


	end
      end # PortfolioValue


    end # module Incoming
  end # module Messages
end # module IB
