#ifndef order_def
#define order_def

#include "TagValue.h"

#include <float.h>
#include <limits.h>

#define UNSET_DOUBLE DBL_MAX
#define UNSET_INTEGER INT_MAX

enum Origin { CUSTOMER,
              FIRM,
              UNKNOWN };

enum AuctionStrategy { AUCTION_UNSET = 0,
                       AUCTION_MATCH = 1,
                       AUCTION_IMPROVEMENT = 2,
                       AUCTION_TRANSPARENT = 3 };

struct OrderComboLeg
{
	OrderComboLeg()
	{
		price = UNSET_DOUBLE;
	}

	double price;

	bool operator==( const OrderComboLeg &other) const
	{
		return (price == other.price);
	}
};

typedef shared_ptr<OrderComboLeg> OrderComboLegSPtr;

struct Order
{
	Order()
	{
		// order identifier
		orderId  = 0;
		clientId = 0;
		permId   = 0;

		// main order fields
		totalQuantity = 0;
		lmtPrice      = UNSET_DOUBLE;
		auxPrice      = UNSET_DOUBLE;

		// extended order fields
		ocaType        = 0;
		transmit       = true;
		parentId       = 0;
		blockOrder     = false;
		sweepToFill    = false;
		displaySize    = 0;
		triggerMethod  = 0;
		outsideRth     = false;
		hidden         = false;
		allOrNone      = false;
		minQty         = UNSET_INTEGER;
		percentOffset  = UNSET_DOUBLE;
		overridePercentageConstraints = false;
		trailStopPrice = UNSET_DOUBLE;
		trailingPercent = UNSET_DOUBLE;

		// institutional (ie non-cleared) only
		openClose     = "O";
		origin        = CUSTOMER;
		shortSaleSlot = 0;
		exemptCode    = -1;

		// SMART routing only
		discretionaryAmt = 0;
		eTradeOnly       = true;
		firmQuoteOnly    = true;
		nbboPriceCap     = UNSET_DOUBLE;
		optOutSmartRouting = false;

		// BOX exchange orders only
		auctionStrategy = AUCTION_UNSET;
		startingPrice   = UNSET_DOUBLE;
		stockRefPrice   = UNSET_DOUBLE;
		delta           = UNSET_DOUBLE;

		// pegged to stock and VOL orders only
		stockRangeLower = UNSET_DOUBLE;
		stockRangeUpper = UNSET_DOUBLE;

		// VOLATILITY ORDERS ONLY
		volatility            = UNSET_DOUBLE;
		volatilityType        = UNSET_INTEGER;     // 1=daily, 2=annual
		deltaNeutralOrderType = "";
		deltaNeutralAuxPrice  = UNSET_DOUBLE;
		deltaNeutralConId     = 0;
		deltaNeutralSettlingFirm = "";
		deltaNeutralClearingAccount = "";
		deltaNeutralClearingIntent = "";
		deltaNeutralOpenClose = "";
		deltaNeutralShortSale = false;
		deltaNeutralShortSaleSlot = 0;
		deltaNeutralDesignatedLocation = "";
		continuousUpdate      = false;
		referencePriceType    = UNSET_INTEGER; // 1=Average, 2 = BidOrAsk

		// COMBO ORDERS ONLY
		basisPoints     = UNSET_DOUBLE;  // EFP orders only
		basisPointsType = UNSET_INTEGER; // EFP orders only

		// SCALE ORDERS ONLY
		scaleInitLevelSize  = UNSET_INTEGER;
		scaleSubsLevelSize  = UNSET_INTEGER;
		scalePriceIncrement = UNSET_DOUBLE;
		scalePriceAdjustValue = UNSET_DOUBLE;
		scalePriceAdjustInterval = UNSET_INTEGER;
		scaleProfitOffset = UNSET_DOUBLE;
		scaleAutoReset = false;
		scaleInitPosition = UNSET_INTEGER;
		scaleInitFillQty = UNSET_INTEGER;
		scaleRandomPercent = false;

		// What-if
		whatIf = false;

		// Not Held
		notHeld = false;
	}

	// order identifier
	long     orderId;
	long     clientId;
	long     permId;

	// main order fields
	IBString action;
	long     totalQuantity;
	IBString orderType;
	double   lmtPrice;
	double   auxPrice;

	// extended order fields
	IBString tif;           // "Time in Force" - DAY, GTC, etc.
	IBString ocaGroup;      // one cancels all group name
	int      ocaType;       // 1 = CANCEL_WITH_BLOCK, 2 = REDUCE_WITH_BLOCK, 3 = REDUCE_NON_BLOCK
	IBString orderRef;      // order reference
	bool     transmit;      // if false, order will be created but not transmited
	long     parentId;      // Parent order Id, to associate Auto STP or TRAIL orders with the original order.
	bool     blockOrder;
	bool     sweepToFill;
	int      displaySize;
	int      triggerMethod; // 0=Default, 1=Double_Bid_Ask, 2=Last, 3=Double_Last, 4=Bid_Ask, 7=Last_or_Bid_Ask, 8=Mid-point
	bool     outsideRth;
	bool     hidden;
	IBString goodAfterTime;    // Format: 20060505 08:00:00 {time zone}
	IBString goodTillDate;     // Format: 20060505 08:00:00 {time zone}
	IBString rule80A; // Individual = 'I', Agency = 'A', AgentOtherMember = 'W', IndividualPTIA = 'J', AgencyPTIA = 'U', AgentOtherMemberPTIA = 'M', IndividualPT = 'K', AgencyPT = 'Y', AgentOtherMemberPT = 'N'
	bool     allOrNone;
	int      minQty;
	double   percentOffset; // REL orders only
	bool     overridePercentageConstraints;
	double   trailStopPrice; // TRAILLIMIT orders only
	double   trailingPercent;

	// financial advisors only
	IBString faGroup;
	IBString faProfile;
	IBString faMethod;
	IBString faPercentage;

	// institutional (ie non-cleared) only
	IBString openClose; // O=Open, C=Close
	Origin   origin;    // 0=Customer, 1=Firm
	int      shortSaleSlot; // 1 if you hold the shares, 2 if they will be delivered from elsewhere.  Only for Action="SSHORT
	IBString designatedLocation; // set when slot=2 only.
	int      exemptCode;

	// SMART routing only
	double   discretionaryAmt;
	bool     eTradeOnly;
	bool     firmQuoteOnly;
	double   nbboPriceCap;
	bool     optOutSmartRouting;

	// BOX exchange orders only
	int      auctionStrategy; // AUCTION_MATCH, AUCTION_IMPROVEMENT, AUCTION_TRANSPARENT
	double   startingPrice;
	double   stockRefPrice;
	double   delta;

	// pegged to stock and VOL orders only
	double   stockRangeLower;
	double   stockRangeUpper;

	// VOLATILITY ORDERS ONLY
	double   volatility;
	int      volatilityType;     // 1=daily, 2=annual
	IBString deltaNeutralOrderType;
	double   deltaNeutralAuxPrice;
	long     deltaNeutralConId;
	IBString deltaNeutralSettlingFirm;
	IBString deltaNeutralClearingAccount;
	IBString deltaNeutralClearingIntent;
	IBString deltaNeutralOpenClose;
	bool     deltaNeutralShortSale;
	int      deltaNeutralShortSaleSlot;
	IBString deltaNeutralDesignatedLocation;
	bool     continuousUpdate;
	int      referencePriceType; // 1=Average, 2 = BidOrAsk

	// COMBO ORDERS ONLY
	double   basisPoints;      // EFP orders only
	int      basisPointsType;  // EFP orders only

	// SCALE ORDERS ONLY
	int      scaleInitLevelSize;
	int      scaleSubsLevelSize;
	double   scalePriceIncrement;
	double   scalePriceAdjustValue;
	int      scalePriceAdjustInterval;
	double   scaleProfitOffset;
	bool     scaleAutoReset;
	int      scaleInitPosition;
	int      scaleInitFillQty;
	bool     scaleRandomPercent;

	// HEDGE ORDERS
	IBString hedgeType;  // 'D' - delta, 'B' - beta, 'F' - FX, 'P' - pair
	IBString hedgeParam; // 'beta=X' value for beta hedge, 'ratio=Y' for pair hedge

	// Clearing info
	IBString account; // IB account
	IBString settlingFirm;
	IBString clearingAccount; // True beneficiary of the order
	IBString clearingIntent; // "" (Default), "IB", "Away", "PTA" (PostTrade)

	// ALGO ORDERS ONLY
	IBString algoStrategy;

	TagValueListSPtr algoParams;
	TagValueListSPtr smartComboRoutingParams;

	// What-if
	bool     whatIf;

	// Not Held
	bool     notHeld;

	// order combo legs
	typedef std::vector<OrderComboLegSPtr> OrderComboLegList;
	typedef shared_ptr<OrderComboLegList> OrderComboLegListSPtr;

	OrderComboLegListSPtr orderComboLegs;

public:

	// Helpers
	static void CloneOrderComboLegs(OrderComboLegListSPtr& dst, const OrderComboLegListSPtr& src);
};

inline void
Order::CloneOrderComboLegs(OrderComboLegListSPtr& dst, const OrderComboLegListSPtr& src)
{
	if (!src.get())
		return;

	dst->reserve(src->size());

	OrderComboLegList::const_iterator iter = src->begin();
	const OrderComboLegList::const_iterator iterEnd = src->end();

	for (; iter != iterEnd; ++iter) {
		const OrderComboLeg* leg = iter->get();
		if (!leg)
			continue;
		dst->push_back(OrderComboLegSPtr(new OrderComboLeg(*leg)));
	}
}

#endif
