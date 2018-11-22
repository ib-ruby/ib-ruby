module IB
  module Messages
    module Incoming

      ExecutionData =
          def_message [11, 0] , # [8, 9]],
                      # The reqID that was specified previously in the call to reqExecution()
                      [:request_id, :int],
                      [:execution, :local_id, :int],
                      [:contract, :contract],
                      [:execution, :exec_id, :string], # Weird format
                      [:execution, :time, :datetime],
                      [:execution, :account_name, :string],
                      [:execution, :exchange, :string],
                      [:execution, :side, :string],
                      [:execution, :quantity, :decimal],
                      [:execution, :price, :decimal],
                      [:execution, :perm_id, :int],
                      [:execution, :client_id, :int],
                      [:execution, :liquidation, :int],
                      [:execution, :cumulative_quantity, :int],
                      [:execution, :average_price, :decimal],
                      [:execution, :order_ref, :string],
                      [:execution, :ev_rule, :string],
                      [:execution, :ev_multiplier, :decimal],
                      [:execution, :model_code, :string],
                      [:execution, :last_liquidity, :int]

      class ExecutionData

	def load
	  simple_load
	end

        def contract
          @contract = IB::Contract.build @data[:contract]
        end

        def execution
          @execution = IB::Execution.new @data[:execution]
        end

        def to_human
          "<ExecutionData #{request_id}: #{contract.to_human}, #{execution}>"
        end

      end # ExecutionData
    end # module Incoming
  end # module Messages
end # module IB
