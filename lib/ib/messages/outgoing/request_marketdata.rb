
module IB
  module Messages
    module Outgoing
      extend Messages # def_message macros


      # @data={:id => int: ticker_id - Must be a unique value. When the market data
      #                                returns, it will be identified by this tag,
			#                                if omitted, id-autogeneration process is performed
      #      :contract => IB::Contract, requested contract.
      #      :tick_list => String: comma delimited list of requested tick groups:
      #        Group ID - Description - Requested Tick Types
      #        100 - Option Volume (currently for stocks) - 29, 30
      #        101 - Option Open Interest (currently for stocks) - 27, 28
      #        104 - Historical Volatility (currently for stocks) - 23
      #	       105 - Average Opt Volume,  # new 971
      #        106 - Option Implied Volatility (impvolat) - 24
      #	       107   (climpvlt)  # new 971
      #	       125   (Bond analytic data) # new 971
      #        162 - Index Future Premium - 31
      #        165 - Miscellaneous Stats - 15, 16, 17, 18, 19, 20, 21
      #	       166  (CScreen)   # new 971,
      #        221/220 - Creditman, Mark Price (used in TWS P&L computations) - 37
      #        225 - Auction values (volume, price and imbalance) - 34, 35, 36
      #	       232/221(Pl-price )  # new 971
      #        233 - RTVolume - 48
      #        236 - Shortable (inventory) - 46
      #        256 - Inventory - ?
      #        258 - Fundamental Ratios - 47
      #        291 - (ivclose)                          
      #        292 - (Wide News)                          
      #        293 - (TradeCount)                          
      #        295 - (VolumeRate)                          
      #        318 - (iLastRTHT-Trade)                          
      #        370 - (Participation Monitor)
      #        375 - RTTrdVolumne
      #        377 - CttTickTag
      #        381 - IB-Rate
      #        384 - RfdTickRespTag
      #        387 -  DMM
      #        388 - Issuer Fundamentals
      #        391 - IBWarrantImplVolCompeteTick
      #        405 - Index Capabilities
      #        407 - Futures Margins
      #        411 - Realtime Historical Volatility - 58
      #        428 - Monetary Close
      #        439 - MonitorTicTag
      #        456/59 - IB Dividends
      #        459 - RTCLOSE
      #        460 - Bond Factor Multiplier
      #        499 - Fee and Rebate Ratge
      #        506 - midptiv
      #
      #        511(hvolrt10 (per-underlying)),
      #        512(hvolrt30 (per-underlying)),
      #        513(hvolrt50 (per-underlying)),
      #        514(hvolrt75 (per-underlying)),
      #        515(hvolrt100 (per-underlying)),
      #        516(hvolrt150 (per-underlying)),
      #        517(hvolrt200 (per-underlying)),
      #        521(fzmidptiv),
      #        545(vsiv),
      #        576(EtfNavBidAsk(navbidask)),
      #        577(EtfNavLast(navlast)),
      #        578(EtfNavClose(navclose)),
      #        584(Average Opening Vol.),
      #        585(Average Closing Vol.),
      #        587(Pl Price Delayed),
      #        588(Futures Open Interest),
      #        595(Short-Term Volume X Mins),
      #        608(EMA N),
      #        614(EtfNavMisc(hight/low)),
      #        619(Creditman Slow Mark Price),
      #        623(EtfFrozenNavLast(fznavlast)	      ## updated 2018/1/21
      #
      #      :snapshot => bool: Check to return a single snapshot of market data and
      #                   have the market data subscription canceled. Do not enter any
      #                   :tick_list values if you use snapshot. 
      #
      #      :regulatory_snapshot => bool - With the US Value Snapshot Bundle for stocks,
      #                   regulatory snapshots are available for 0.01 USD each.
      #      :mktDataOptions => (TagValueList)  For internal use only.
      #                    Use default value XYZ. 
      #
      RequestMarketData =
          def_message [1, 11], :request_id,
                      [:contract, :serialize_short, :primary_exchange],  # include primary exchange in request
                      [:contract, :serialize_legs, []],
                      [:contract, :serialize_under_comp, []],
                      [:tick_list, lambda do |tick_list|
                        tick_list.is_a?(Array) ? tick_list.join(',') : (tick_list || '')
                      end, []],
                      [:snapshot, false],
		      [:regulatory_snapshot, false],
		      [:mkt_data_options, "XYZ"]
    end
  end
end
