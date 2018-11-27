require 'ib/server_versions'
module IB

  module Messages
  	# This gem supports incoming/outgoing IB messages compatible with the following
  	# IB client/server versions:
    CLIENT_VERSION = 66 #  => API V  9.71
    SERVER_VERSION =  "v"+ MIN_CLIENT_VER.to_s + ".." + MAX_CLIENT_VER.to_s  # extracted from the python-client			  
  end
end

require 'ib/messages/outgoing'
require 'ib/messages/incoming'

__END__
    // Client version history
    //
    //  6 = Added parentId to orderStatus
    //  7 = The new execDetails event returned for an order filled status and reqExecDetails
    //     Also market depth is available.
    //  8 = Added lastFillPrice to orderStatus() event and permId to execution details
    //  9 = Added 'averageCost', 'unrealizedPNL', and 'unrealizedPNL' to updatePortfolio event
    // 10 = Added 'serverId' to the 'open order' & 'order status' events.
    //      We send back all the API open orders upon connection.
    //      Added new methods reqAllOpenOrders, reqAutoOpenOrders()
    //      Added FA support - reqExecution has filter.
    //                       - reqAccountUpdates takes acct code.
    // 11 = Added permId to openOrder event.
    // 12 = requsting open order attributes ignoreRth, hidden, and discretionary
    // 13 = added goodAfterTime
    // 14 = always send size on bid/ask/last tick
    // 15 = send allocation description string on openOrder
    // 16 = can receive account name in account and portfolio updates, and fa params in openOrder
    // 17 = can receive liquidation field in exec reports, and notAutoAvailable field in mkt data
    // 18 = can receive good till date field in open order messages, and request intraday backfill
    // 19 = can receive rthOnly flag in ORDER_STATUS
    // 20 = expects TWS time string on connection after server version >= 20.
    // 21 = can receive bond contract details.
    // 22 = can receive price magnifier in version 2 contract details message
    // 23 = support for scanner
    // 24 = can receive volatility order parameters in open order messages
    // 25 = can receive HMDS query start and end times
    // 26 = can receive option vols in option market data messages
    // 27 = can receive delta neutral order type and delta neutral aux price in place order version 20: API 8.85
    // 28 = can receive option model computation ticks: API 8.9
    // 29 = can receive trail stop limit price in open order and can place them: API 8.91
    // 30 = can receive extended bond contract def, new ticks, and trade count in bars
    // 31 = can receive EFP extensions to scanner and market data, and combo legs on open orders
    //    ; can receive RT bars
    // 32 = can receive TickType.LAST_TIMESTAMP
    //    ; can receive "whyHeld" in order status messages
    // 33 = can receive ScaleNumComponents and ScaleComponentSize is open order messages
    // 34 = can receive whatIf orders / order state
    // 35 = can receive contId field for Contract objects
    // 36 = can receive outsideRth field for Order objects
    // 37 = can receive clearingAccount and clearingIntent for Order objects
    // 38 = can receive multiplier and primaryExchange in portfolio updates
    //    ; can receive cumQty and avgPrice in execution
    //    ; can receive fundamental data
    //    ; can receive underComp for Contract objects
    //    ; can receive reqId and end marker in contractDetails/bondContractDetails
    //    ; can receive ScaleInitComponentSize and ScaleSubsComponentSize for Order objects
    // 39 = can receive underConId in contractDetails
    // 40 = can receive algoStrategy/algoParams in openOrder
    // 41 = can receive end marker for openOrder
    //    ; can receive end marker for account download
    //    ; can receive end marker for executions download
    // 42 = can receive deltaNeutralValidation
    // 43 = can receive longName(companyName)
    //    ; can receive listingExchange
    //    ; can receive RTVolume tick
    // 44 = can receive end market for ticker snapshot
    // 45 = can receive notHeld field in openOrder
    // 46 = can receive contractMonth, industry, category, subcategory fields in contractDetails
    //    ; can receive timeZoneId, tradingHours, liquidHours fields in contractDetails
    // 47 = can receive gamma, vega, theta, undPrice fields in TICK_OPTION_COMPUTATION
    // 48 = can receive exemptCode in openOrder
    // 49 = can receive hedgeType and hedgeParam in openOrder
    // 50 = can receive optOutSmartRouting field in openOrder
    // 51 = can receive smartComboRoutingParams in openOrder
    // 52 = can receive deltaNeutralConId, deltaNeutralSettlingFirm, deltaNeutralClearingAccount and deltaNeutralClearingIntent in openOrder
    // 53 = can receive orderRef in execution
    // 54 = can receive scale order fields (PriceAdjustValue, PriceAdjustInterval, ProfitOffset, AutoReset,
    //      InitPosition, InitFillQty and RandomPercent) in openOrder
    // 55 = can receive orderComboLegs (price) in openOrder
    // 56 = can receive trailingPercent in openOrder
    // 57 = can receive commissionReport message
    // 58 = can receive CUSIP/ISIN/etc. in contractDescription/bondContractDescription
    // 59 = can receive evRule, evMultiplier in contractDescription/bondContractDescription/executionDetails
    //      can receive multiplier in executionDetails
    // 60 = can receive deltaNeutralOpenClose, deltaNeutralShortSale, deltaNeutralShortSaleSlot and              …deltaNeutralDesignatedLocation in openOrder
    // 61 = can receive multiplier in openOrder
    //      can receive tradingClass in openOrder, updatePortfolio, execDetails and position
    // 62 = can receive avgCost in position message
    // 63 = can receive verifyMessageAPI, verifyCompleted, displayGroupList and displayGroupUpdated messages
    // 64 = can receive solicited attrib in openOrder message
    // 65 = can receive verifyAndAuthMessageAPI and verifyAndAuthCompleted messages
    // 66 = can receive randomize size and randomize price order fields

