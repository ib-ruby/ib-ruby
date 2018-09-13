module IB
  module Messages
		module Incoming

      AccountUpdateTime = def_message 8, [:time_stamp, :string]

      ManagedAccounts =
          def_message 15, [:accounts_list, :string]

			class ManagedAccounts
				def accounts
					accounts_list.split(',').map{|a| IB::Account.new account: a}
				end

				def to_human
					"< ManagedAccounts: #{accounts.map(&:account).join(" - ")}>"
				end
			end

      # Receives previously requested FA configuration information from TWS.
      ReceiveFA =
          def_message 16, [:type, :int], # type of Financial Advisor configuration data
                      #                    being received from TWS. Valid values include:
                      #                    1 = GROUPS, 2 = PROFILE, 3 = ACCOUNT ALIASES
                      [:xml, :xml] # XML string with requested FA configuration information.

				class ReceiveFA
					def accounts
						xml[:ListOfAccountAliases][:AccountAlias].map{|x| Account.new x }
					end
				end



			class AccountMessage < AbstractMessage
        def account_value
          @account_value = IB::AccountValue.new @data[:account_value]
        end
				def account_name
					@account_name =  @data[:account]
				end

				def to_human
        "<AccountValue: #{account_name}, #{account_value}"  
				end
			end
			AccountSummary = def_message(63, AccountMessage,
																	 [:request_id, :int],
																	[ :account, :string ],
																	[:account_value, :key, :symbol],
																	[:account_value, :value, :string],
																	[:account_value, :currency, :string]
																	)
			AccountSummaryEnd = def_message(64)

			AccountValue = def_message([6, 2], AccountMessage,
																 [:account_value, :key, :symbol],
																 [:account_value, :value, :string],
																 [:account_value, :currency, :string],
																 [:account, :string]) 


			AccountUpdatesMulti =  def_message( 73,
																[ :request_id, :int ],
																[ :account , :string ],
																[ :model, :string ],
																[ :key		,  :string ],
																[ :value ,	 :decimal],
																[ :currency, :string ])

					AccountUpdatesMultiEnd =  def_message 74
    end # module Incoming
  end # module Messages
end # module IB
