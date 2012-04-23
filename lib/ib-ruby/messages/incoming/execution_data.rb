module IB
  module Messages
    module Incoming

      ExecutionData =
          def_message [11, 8],
                      # The reqID that was specified previously in the call to reqExecution()
                      [:request_id, :int],
                      [:execution, :local_id, :int],
                      [:contract, :con_id, :int],
                      [:contract, :symbol, :string],
                      [:contract, :sec_type, :string],
                      [:contract, :expiry, :string],
                      [:contract, :strike, :decimal],
                      [:contract, :right, :string],
                      [:contract, :exchange, :string],
                      [:contract, :currency, :string],
                      [:contract, :local_symbol, :string],

                      [:execution, :exec_id, :string], # Weird format
                      [:execution, :time, :string],
                      [:execution, :account_name, :string],
                      [:execution, :exchange, :string],
                      [:execution, :side, :string],
                      [:execution, :quantity, :int],
                      [:execution, :price, :decimal],
                      [:execution, :perm_id, :int],
                      [:execution, :client_id, :int],
                      [:execution, :liquidation, :int],
                      [:execution, :cumulative_quantity, :int],
                      [:execution, :average_price, :decimal]

      class ExecutionData

        def contract
          @contract = IB::Contract.build @data[:contract]
        end

        def execution
          @execution = IB::Execution.new @data[:execution]
        end

        def load
          super

          # As of client v.53, we can receive orderRef in ExecutionData
          load_map [proc { | | @server[:client_version] >= 53 },
                    [:execution, :order_ref, :string]
                   ]
        end

        def to_human
          "<ExecutionData #{request_id}: #{contract.to_human}, #{execution}>"
        end

      end # ExecutionData
    end # module Incoming
  end # module Messages
end # module IB
