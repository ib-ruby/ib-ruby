require 'ib-ruby/messages/incoming/abstract_message'

# EClientSocket.java uses sendMax() rather than send() for a number of these.
# It sends an EOL rather than a number if the value == Integer.MAX_VALUE (or Double.MAX_VALUE).
# These fields are initialized to this MAX_VALUE.
# This has been implemented with nils in Ruby to represent the case where an EOL should be sent.

# TODO: Don't instantiate messages, use their classes as just namespace for .encode/decode
# TODO: realize Message#fire method that raises EWrapper events

module IB
  module Messages

    # Incoming IB messages (received from TWS/Gateway)
    module Incoming
      extend Messages # def_message macros

      ### Define short message classes in-line:

      AccountValue = def_message([6, 2], [:key, :string],
                                 [:value, :string],
                                 [:currency, :string],
                                 [:account_name, :string]) do
        "<AccountValue: #{account_name}, #{key}=#{value} #{currency}>"
      end

      AccountUpdateTime = def_message 8, [:time_stamp, :string]

      NewsBulletins =
          def_message 14, [:request_id, :int], # unique incrementing bulletin ID.
                      [:type, :int], # Type of bulletin. Valid values include:
                      #     1 = Regular news bulletin
                      #     2 = Exchange no longer available for trading
                      #     3 = Exchange is available for trading
                      [:text, :string], # The bulletin's message text.
                      [:exchange, :string] # Exchange from which this message originated.

      ManagedAccounts =
          def_message 15, [:accounts_list, :string]

      # Receives previously requested FA configuration information from TWS.
      ReceiveFA =
          def_message 16, [:type, :int], # type of Financial Advisor configuration data
                      #                    being received from TWS. Valid values include:
                      #                    1 = GROUPS, 2 = PROFILE, 3 = ACCOUNT ALIASES
                      [:xml, :string] # XML string with requested FA configuration information.

      # Receives an XML document that describes the valid parameters that a scanner
      # subscription can have (for outgoing RequestScannerSubscription message).
      ScannerParameters = def_message 19, [:xml, :string]

      # Receives the current system time on the server side.
      CurrentTime = def_message 49, [:time, :int] # long!

      # Receive Reuters global fundamental market data. There must be a subscription to
      # Reuters Fundamental set up in Account Management before you can receive this data.
      FundamentalData = def_message 51, [:request_id, :int], [:data, :string]

      ContractDataEnd = def_message 52, [:request_id, :int]

      OpenOrderEnd = def_message 53

      AccountDownloadEnd = def_message 54, [:account_name, :string]

      ExecutionDataEnd = def_message 55, [:request_id, :int]

      MarketDataType = def_message 58, [:request_id, :int], [:market_data_type, :int]

      CommissionReport =
          def_message 59, [:exec_id, :int],
                      [:commission, :decimal], # Commission amount.
                      [:currency, :int], #       Commission currency
                      [:realized_pnl, :decimal],
                      [:yield, :decimal],
                      [:yield_redemption_date, :int]

      ### Require standalone source files for more complex message classes:

      require 'ib-ruby/messages/incoming/alert'
      require 'ib-ruby/messages/incoming/contract_data'
      require 'ib-ruby/messages/incoming/delta_neutral_validation'
      require 'ib-ruby/messages/incoming/execution_data'
      require 'ib-ruby/messages/incoming/historical_data'
      require 'ib-ruby/messages/incoming/market_depths'
      require 'ib-ruby/messages/incoming/next_valid_id'
      require 'ib-ruby/messages/incoming/open_order'
      require 'ib-ruby/messages/incoming/order_status'
      require 'ib-ruby/messages/incoming/portfolio_value'
      require 'ib-ruby/messages/incoming/real_time_bar'
      require 'ib-ruby/messages/incoming/scanner_data'
      require 'ib-ruby/messages/incoming/ticks'

    end # module Incoming
  end # module Messages
end # module IB


__END__
    // incoming msg id's
    static final int TICK_PRICE		= 1; *
    static final int TICK_SIZE		= 2; *
    static final int ORDER_STATUS	= 3; *
    static final int ERR_MSG		= 4;   *
    static final int OPEN_ORDER         = 5;  *
    static final int ACCT_VALUE         = 6;  *
    static final int PORTFOLIO_VALUE    = 7;  *
    static final int ACCT_UPDATE_TIME   = 8;  *
    static final int NEXT_VALID_ID      = 9;  *
    static final int CONTRACT_DATA      = 10; *
    static final int EXECUTION_DATA     = 11; ?
    static final int MARKET_DEPTH     	= 12; *
    static final int MARKET_DEPTH_L2    = 13; *
    static final int NEWS_BULLETINS    	= 14; *
    static final int MANAGED_ACCTS    	= 15; *
    static final int RECEIVE_FA    	    = 16; *
    static final int HISTORICAL_DATA    = 17; *
    static final int BOND_CONTRACT_DATA = 18; *
    static final int SCANNER_PARAMETERS = 19; *
    static final int SCANNER_DATA       = 20; *
    static final int TICK_OPTION_COMPUTATION = 21; *
    static final int TICK_GENERIC = 45;       *
    static final int TICK_STRING = 46;        *
    static final int TICK_EFP = 47;           *
    static final int CURRENT_TIME = 49;       *
    static final int REAL_TIME_BARS = 50;     *
    static final int FUNDAMENTAL_DATA = 51;   *
    static final int CONTRACT_DATA_END = 52;  *
    static final int OPEN_ORDER_END = 53;     *
    static final int ACCT_DOWNLOAD_END = 54;  *
    static final int EXECUTION_DATA_END = 55; *
    static final int DELTA_NEUTRAL_VALIDATION = 56; *
    static final int TICK_SNAPSHOT_END = 57;  *
    static final int MARKET_DATA_TYPE = 58;   ?
    static final int COMMISSION_REPORT = 59;  ?
