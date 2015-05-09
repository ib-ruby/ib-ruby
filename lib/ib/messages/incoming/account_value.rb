module IB
  module Messages
    module Incoming

	AccountValue = def_message([6, 2], [:account_value, :key, :string],
				           [:account_value, :value, :string],
                                       [:account_value, :currency, :string],
                                       [:account_name, :string])
      class AccountValue

        def account_value
          @account_value = IB::AccountValue.new @data[:account_value]
        end

      end # AccountValue


    end # module Incoming
  end # module Messages
end # module IB
