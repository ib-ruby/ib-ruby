require 'ib/messages/incoming/abstract_message'

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


      NewsBulletins =
          def_message 14, [:request_id, :int], # unique incrementing bulletin ID.
                      [:type, :int], # Type of bulletin. Valid values include:
                      #     1 = Regular news bulletin
                      #     2 = Exchange no longer available for trading
                      #     3 = Exchange is available for trading
                      [:text, :string], # The bulletin's message text.
                      [:exchange, :string] # Exchange from which this message originated.


      # Receives an converted XML document that describes the valid parameters that a scanner
      # subscription can have (for outgoing RequestScannerSubscription message).
      ScannerParameters = def_message 19, [:xml, :xml]

			class  ScannerParameters 
				# returns a List of Hashes specifing Instruments. 
				# >  C.received[:ScannerParameters].first.instruments.first
				# => {:name=>"US Stocks", 
				#     :type=>"STK", 
				#     :filters=>"AFTERHRSCHANGEPERC,AVGOPTVOLUME,AVGPRICETARGET,AVGRATING,AVGTARGET2PRICERATIO,AVGVOLUME,AVGVOLUME_USD,CHANGEOPENPERC,CHANGEPERC,EMA_20,EMA_50,EMA_100,EMA_200,PRICE_VS_EMA_20,PRICE_VS_EMA_50,PRICE_VS_EMA_100,PRICE_VS_EMA_200,DAYSTOCOVER,DIVIB,DIVYIELD,DIVYIELDIB,FEERATE,FIRSTTRADEDATE,GROWTHRATE,HALTED,HASOPTIONS,HISTDIVIB,HISTDIVYIELDIB,IMBALANCE,IMBALANCEADVRATIOPERC,IMPVOLAT,IMPVOLATOVERHIST,INSIDEROFFLOATPERC,INSTITUTIONALOFFLOATPERC,MACD,MACD_SIGNAL,MACD_HISTOGRAM,MKTCAP,MKTCAP_USD,NEXTDIVAMOUNT,NEXTDIVDATE,NUMPRICETARGETS,NUMRATINGS,NUMSHARESINSIDER,NUMSHARESINSTITUTIONAL,NUMSHARESSHORT,OPENGAPPERC,OPTVOLUME,OPTVOLUMEPCRATIO,PERATIO,PILOT,PPO,PPO_SIGNAL,PPO_HISTOGRAM,PRICE,PRICE2BK,PRICE2TANBK,PRICERANGE,PRICE_USD,QUICKRATIO,REBATERATE,REGIMBALANCE,REGIMBALANCEADVRATIOPERC,RETEQUITY,SHORTABLESHARES,SHORTOFFLOATPERC,SHORTSALERESTRICTED,SIC,ISSUER_COUNTRY_CODE,SOCSACT,SOCSNET,STKTYPE,STVOLUME_3MIN,STVOLUME_5MIN,STVOLUME_10MIN,TRADECOUNT,TRADERATE,UNSHORTABLE,VOLUME,VOLUMERATE,VOLUME_USD,RCGLTCLASS,RCGLTENDDATE,RCGLTIVALUE,RCGLTTRADE,RCGITCLASS,RCGITENDDATE,RCGITIVALUE,RCGITTRADE,RCGSTCLASS,RCGSTENDDATE,RCGSTIVALUE,RCGSTTRADE", 
				#     :group=>"STK.GLOBAL", 
				#     :shortName=>"US", 
				#     :cloudScanNotSupported=>"false"}
				def instruments
					@data[:xml][:ScanParameterResponse][:InstrumentList].first[:Instrument]
				end

				# returns a List of Hashes specifing ScanTypes
				# >  C.received[:ScannerParameters].first.scan_types.first
				# => {:displayName=>"Assets Under Management (AltaVista) Desc", 
				#			:scanCode=>"SCAN_etfAssets_DESC", 
				#			:instruments=>"ETF.EQ.US,ETF.FI.US", 
				#			:absoluteColumns=>"false", 
				#			:Columns=>{:ColumnSetRef=>{:colId=>"0", :name=>"PctPerf", :display=>"false", :displayType=>"DATA"}, 
				#			:Column=>{:colId=>"6031", :name=>"Assets Under Management", :display=>"true", :displayType=>"DATA"}}, 
				#			:supportsSorting=>"true", 
				#			:respSizeLimit=>"2147483647", :snapshotSizeLimit=>"2147483647", 
				#			:searchDefault=>"false", :access=>"unrestricted"} 
# 

				def scan_types
					@data[:xml][:ScanParameterResponse][:ScanTypeList][:ScanType]
				end
			end

      # Receives the current system time on the server side.
      CurrentTime = def_message 49, [:time, :int] # long!


			HeadTimeStamp = def_message( [88, 0], [:request_id, :int], [:date,  :int_date] ) do
				# def to_human
					"<#{self.message_type}:" +
						"Request #{request_id}, First Historical Datapoint @ #{date.to_s}«"
			end

      # Receive Reuters global fundamental market data. There must be a subscription to
      # Reuters Fundamental set up in Account Management before you can receive this data.
      FundamentalData = def_message 51, [:request_id, :int], [:xml, :xml]

      ContractDataEnd = def_message 52, [:request_id, :int]

      OpenOrderEnd = def_message 53

      AccountDownloadEnd = def_message 54, [:account_name, :string]

      ExecutionDataEnd = def_message 55, [:request_id, :int]

      MarketDataType = def_message 58, [:request_id, :int], [:market_data_type, :int] do
					"<#{self.message_type}:" +
						" switched to »#{MARKET_DATA_TYPES[market_data_type]}«" # to_human
				end

      CommissionReport =
          def_message 59, [:exec_id, :string],
                      [:commission, :decimal], # Commission amount.
                      [:currency, :string], # Commission currency
                      [:realized_pnl, :decimal_max],
                      [:yield, :decimal_max],
                      [:yield_redemption_date, :int] # YYYYMMDD format

			SecurityDefinitionOptionParameter = OptionChainDefinition = def_message [75,0] , 
																[:request_id, :int],
																[:exchange, :string],
																[:con_id, :int],   # underlying_con_id
																[:trading_class, :string],
																[:multiplier, :int]

			class OptionChainDefinition
					using IBSupport   # defines tws-method for Array  (socket.rb)
					def load
						super
						load_map 	[:expirations, :array, proc {  @buffer.read_date }],
											[:strikes, :array, proc {  @buffer.read_decimal } ]
					end
					def expirations
						@data[:expirations]
					end
					def strikes
						@data[:strikes]
					end

					def to_human
						"OptionChainDefinition #{trading_class}@#{exchange} [#{multiplier} X ] strikes: #{strikes.first} - #{strikes.last} expirations: #{expirations.first} - #{expirations.last}"
					end
			end
																


			 OptionChainDefinitionEnd  = SecurityDefinitionOptionParameterEnd = def_message [76,0 ],
																[ :request_id, :int ]


      #<- 1-9-789--USD-CASH-----IDEALPRO--CAD------
      #-> ---81-123-5.0E-5--0-

			MarketDepthExchanges =  def_message [80,0], 
																[ :request_id, :int ]

      TickRequestParameters = def_message [81, 0], [ :ticker_id, :int ],
					      [ :min_tick, :decimal],
					      [ :exchange, :string ],
					      [ :snapshot_prermissions, :int ]
#      class TickRequestParameters 
#	def load
#	  simple_load
#	end
 #     end

      ### Require standalone source files for more complex message classes:

      require 'ib/messages/incoming/alert'
      require 'ib/messages/incoming/contract_data'
      require 'ib/messages/incoming/delta_neutral_validation'
      require 'ib/messages/incoming/execution_data'
      require 'ib/messages/incoming/historical_data'
      require 'ib/messages/incoming/market_depths'
      require 'ib/messages/incoming/next_valid_id'
      require 'ib/messages/incoming/open_order'
      require 'ib/messages/incoming/order_status'
      require 'ib/messages/incoming/account_value'
      require 'ib/messages/incoming/portfolio_value'
      require 'ib/messages/incoming/real_time_bar'
      require 'ib/messages/incoming/scanner_data'
      require 'ib/messages/incoming/ticks'

    end # module Incoming
  end # module Messages
end # module IB


__END__
    // incoming msg id's
    ## api 9.71v (python)
    # incoming msg id's
    class IN:
        TICK_PRICE                = 1
        TICK_SIZE                 = 2
        ORDER_STATUS              = 3
        ERR_MSG                   = 4
        OPEN_ORDER                = 5
        ACCT_VALUE                = 6
        PORTFOLIO_VALUE           = 7
        ACCT_UPDATE_TIME          = 8
        NEXT_VALID_ID             = 9
        CONTRACT_DATA             = 10
        EXECUTION_DATA            = 11
        MARKET_DEPTH              = 12
        MARKET_DEPTH_L2           = 13
        NEWS_BULLETINS            = 14
        MANAGED_ACCTS             = 15
        RECEIVE_FA                = 16
        HISTORICAL_DATA           = 17
        BOND_CONTRACT_DATA        = 18
        SCANNER_PARAMETERS        = 19
        SCANNER_DATA              = 20
        TICK_OPTION_COMPUTATION   = 21
        TICK_GENERIC              = 45
        TICK_STRING               = 46
        TICK_EFP                  = 47
        CURRENT_TIME              = 49
        REAL_TIME_BARS            = 50
        FUNDAMENTAL_DATA          = 51
        CONTRACT_DATA_END         = 52
        OPEN_ORDER_END            = 53
        ACCT_DOWNLOAD_END         = 54
        EXECUTION_DATA_END        = 55
        DELTA_NEUTRAL_VALIDATION  = 56
        TICK_SNAPSHOT_END         = 57
        MARKET_DATA_TYPE          = 58
        COMMISSION_REPORT         = 59   ## 
	### const below are new in api 9.71
        POSITION_DATA             = 61
        POSITION_END              = 62
        ACCOUNT_SUMMARY           = 63
        ACCOUNT_SUMMARY_END       = 64
        VERIFY_MESSAGE_API        = 65
        VERIFY_COMPLETED          = 66
        DISPLAY_GROUP_LIST        = 67
        DISPLAY_GROUP_UPDATED     = 68
        VERIFY_AND_AUTH_MESSAGE_API = 69
        VERIFY_AND_AUTH_COMPLETED   = 70
        POSITION_MULTI            = 71
        POSITION_MULTI_END        = 72
        ACCOUNT_UPDATE_MULTI      = 73
        ACCOUNT_UPDATE_MULTI_END  = 74
        SECURITY_DEFINITION_OPTION_PARAMETER = 75
        SECURITY_DEFINITION_OPTION_PARAMETER_END = 76
        SOFT_DOLLAR_TIERS         = 77
        FAMILY_CODES              = 78
        SYMBOL_SAMPLES            = 79
        MKT_DEPTH_EXCHANGES       = 80
        TICK_REQ_PARAMS           = 81
        SMART_COMPONENTS          = 82
        NEWS_ARTICLE              = 83
        TICK_NEWS                 = 84
        NEWS_PROVIDERS            = 85
        HISTORICAL_NEWS           = 86
        HISTORICAL_NEWS_END       = 87
        HEAD_TIMESTAMP            = 88
        HISTOGRAM_DATA            = 89
        HISTORICAL_DATA_UPDATE    = 90
        REROUTE_MKT_DATA_REQ      = 91
        REROUTE_MKT_DEPTH_REQ     = 92
        MARKET_RULE               = 93
        PNL                       = 94
        PNL_SINGLE                = 95
        HISTORICAL_TICKS          = 96
        HISTORICAL_TICKS_BID_ASK  = 97
        HISTORICAL_TICKS_LAST     = 98
        TICK_BY_TICK              = 99
    
