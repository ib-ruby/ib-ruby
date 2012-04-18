module IB
  module Messages
    module Incoming

      # The server sends this message upon accepting a Delta-Neutral DN RFQ
      # - see API Reference p. 26
      DeltaNeutralValidation = def_message 56,
                                           [:request_id, :int],
                                           [:contract, :under_con_id, :int],
                                           [:contract, :under_delta, :decimal],
                                           [:contract, :under_price, :decimal]
      class DeltaNeutralValidation
        def contract
          @contract = IB::Contract.build @data[:contract].merge(:under_comp => true)
        end
      end # DeltaNeutralValidation

    end # module Incoming
  end # module Messages
end # module IB
