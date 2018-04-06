module IB
  module Messages
    module Incoming

			class ContractMessage < AbstractMessage
				def contract
					@contract = IB::Contract.build @data[:contract]
				end
			end

			PortfolioValue = def_message( [7, 8], ContractMessage,
						[:contract, :contract], # read standard-contract 
						#																	 [ con_id, symbol,. sec_type, expiry, strike, right, multiplier,
						# primary_exchange, currency, local_symbol, trading_class ] 
						[:portfolio_value, :position, :decimal],   # changed from int after Server Vers. MIN_SERVER_VER_FRACTIONAL_POSITIONS
						[:portfolio_value,:market_price, :decimal],
						[:portfolio_value,:market_value, :decimal],
						[:portfolio_value,:average_cost, :decimal],
						[:portfolio_value,:unrealized_pnl, :decimal], # May be nil!
						[:portfolio_value,:realized_pnl, :decimal], #   May be nil!
						[:account_name, :string] ) do
				#def to_human
					"<PortfolioValue: #{contract.to_human} (#{position}): Market #{market_price}" +
					" price #{market_value} value; PnL: #{unrealized_pnl} unrealized," +
					" #{realized_pnl} realized; account #{account_name}>"
				end


				class PortfolioValue


#					def to_human
#						"<PortfolioValue: #{contract.to_human} (#{position}): Market #{market_price}" +
#						" price #{market_value} value; PnL: #{unrealized_pnl} unrealized," +
#						" #{realized_pnl} realized; account #{account_name}>"
#					end
#
					def portfolio_value
						@portfolio_value =  IB::PortfolioValue.new   @data[:portfolio_value], 
						@contract = @data[:contract]
						@account_name =  @data[:account_name]
					end
				end # PortfolioValue



			PositionData =
				def_message( [61,3] , ContractMessage,
					[:account, :string],
          [:contract, :contract], # read standard-contract 
#																	 [ con_id, symbol,. sec_type, expiry, strike, right, multiplier,
																	 # primary_exchange, currency, local_symbol, trading_class ] 
          [:position, :decimal],   # changed from int after Server Vers. MIN_SERVER_VER_FRACTIONAL_POSITIONS
					[:price, :decimal]
									 ) do 
#        def to_human
          "<PositionValue: #{account} ->  #{contract.to_human} ( Amount #{position}) : Market-Price #{price} >"
        end

			PositionDataEnd = def_message( 62 )
			PositionsMulti =  def_message( 71, ContractMessage,
																		[ :request_id, :int ], 
																		[ :account, :string ],
																		[:contract, :contract], # read standard-contract 
          [ :position, :decimal],   # changed from int after Server Vers. MIN_SERVER_VER_FRACTIONAL_POSITIONS
					[ :average_cost, :decimal],
					[ :model_code, :string ])

			PositionsMultiEnd =  def_message 72
	
					
					AccountUpdatesMulti =  def_message( 73,
							[ :request_id, :int ],
							[ :account , :string ],
							[ :key		,  :string ],
							[ :value ,	 :decimal],
							[ :currency, :string ])

					AccountUpdatesMultiEnd =  def_message 74



    end # module Incoming
  end # module Messages
end # module IB
