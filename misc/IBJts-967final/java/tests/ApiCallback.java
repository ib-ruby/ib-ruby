/*
 * $Id: ApiCallback.java,v 1.12 2012/02/23 21:51:14 ademeshk Exp $
 *  
 * @author Dennis Stetsenko
 * @since Nov 5, 2007
 * 
 * $Log: ApiCallback.java,v $
 * Revision 1.12  2012/02/23 21:51:14  ademeshk
 * dp14963 - API: send commission reports to API
 *
 * Revision 1.11  2011/09/22 15:56:13  ademeshk
 * dp13440: support frozen md
 *
 * Revision 1.10  2010/04/15 17:41:11  ademeshk
 * dp7239: greeks and underlying price in tickOptionComputation message
 *
 * Revision 1.9  2008/10/01 08:07:20  vaivanov
 * ext dp5336 Extend API interface to allow send the end market for tick snapshot
 *
 * Revision 1.8  2008/08/13 15:25:00  norlov
 * missing chunks for DN RFQ (deltaNeutralValidation)
 *
 * Revision 1.7  2008/08/12 19:55:13  norlov
 * end-of-download marker for executionDetails
 *
 * Revision 1.6  2008/08/08 20:02:06  norlov
 * end-of-download marker for account data
 *
 * Revision 1.5  2008/08/07 17:37:26  norlov
 * end-of-download marker for openOrder
 *
 * Revision 1.4  2008/04/25 21:20:02  norlov
 * test case for connect/disconnect (bug #9766)
 *
 * Revision 1.3  2008/04/02 16:30:50  norlov
 * end-of-download marker for contractDetails
 *
 * Revision 1.2  2008/03/31 22:33:50  norlov
 * support for fundamental data requests
 *
 * Revision 1.1  2007/11/06 16:29:03  dstetsenko
 * int dp2769 Investigate TWS API latencies
 *
 */
package tests;

import com.ib.client.Contract;
import com.ib.client.ContractDetails;
import com.ib.client.EWrapper;
import com.ib.client.Execution;
import com.ib.client.Order;
import com.ib.client.OrderState;
import com.ib.client.UnderComp;
import com.ib.client.CommissionReport;

public class ApiCallback implements EWrapper {

	public void accountDownloadEnd(String accountName) {
		System.out.println("accountDownloadEnd: "+accountName);
	}
	
	public void bondContractDetails(int reqId, ContractDetails contractDetails) {
		System.out.println("bondContractDetails: "+reqId+contractDetails); 
	}

	public void contractDetails(int reqId, ContractDetails contractDetails) {
		System.out.println("contractDetails: "+reqId+contractDetails); 
	}
	public void contractDetailsEnd(int reqId) {
		System.out.println("contractDetailsEnd: "+reqId); 
	}

	public void currentTime(long time) {
		System.out.println("currentTime: "+time); 	
	}

	public void fundamentalData(int reqId, String data) {
		System.out.println("fundamentalData ...");
	}

	public void historicalData(int reqId, String date, double open,
			double high, double low, double close, int volume, int count,
			double WAP, boolean hasGaps) {
		
		System.out.println("historicalData ...");
	}

	public void managedAccounts(String accountsList) {
		System.out.println("managedAccounts: "+accountsList);
	}

	public void nextValidId(int orderId) {
		System.out.println("nextValidId: "+orderId);
	}

	public void realtimeBar(int reqId, long time, double open, double high,
			double low, double close, long volume, double wap, int count) {
		System.out.println("realtimeBar ...");
	}

	public void receiveFA(int faDataType, String xml) {
		System.out.println("receiveFA ...");
	}

	public void scannerData(int reqId, int rank,
			ContractDetails contractDetails, String distance, String benchmark,
			String projection, String legsStr) {
		System.out.println("scannerData ...");
	}

	public void scannerDataEnd(int reqId) {
		System.out.println("scannerDataEnd ...");
	}

	public void scannerParameters(String xml) {
		System.out.println("scannerParameters ...");
	}

	public void tickEFP(int tickerId, int tickType, double basisPoints,
			String formattedBasisPoints, double impliedFuture, int holdDays,
			String futureExpiry, double dividendImpact, double dividendsToExpiry) {
		System.out.println("tickEFP ...");
	}

	public void tickGeneric(int tickerId, int tickType, double value) {
		System.out.println("tickGeneric ...");
	}

	public void tickOptionComputation(int tickerId, int field,
			double impliedVol, double delta, double optPrice,
			double pvDividend, double gamma, double vega, 
			double theta, double undPrice) {
		System.out.println("tickOptionComputation ...");
	}

	public void tickPrice(int tickerId, int field, double price,
			int canAutoExecute) {
		System.out.println("tickPrice ...");
	}

	public void tickSize(int tickerId, int field, int size) {
		System.out.println("tickSize ...");
	}

	public void tickString(int tickerId, int tickType, String value) {
		System.out.println("tickString ...");
	}
	
	public void tickSnapshotEnd(int tickerId) {
		System.out.println("tickSnapshotEnd ...");
	}	

	public void updateAccountTime(String timeStamp) {
		System.out.println("updateAccountTime: "+timeStamp);
	}

	public void updateAccountValue(String key, String value, String currency,
			String accountName) {
		System.out.println("updateAccountValue...");
	}

	public void updateMktDepth(int tickerId, int position, int operation,
			int side, double price, int size) {
		System.out.println("updateMktDepth...");
	}

	public void updateMktDepthL2(int tickerId, int position,
			String marketMaker, int operation, int side, double price, int size) {
		System.out.println("updateMktDepthL2...");
	}

	public void updateNewsBulletin(int msgId, int msgType, String message,
			String origExchange) {
		System.out.println("updateNewsBulletin...");
	}

	public void updatePortfolio(Contract contract, int position,
			double marketPrice, double marketValue, double averageCost,
			double unrealizedPNL, double realizedPNL, String accountName) {
		System.out.println("updatePortfolio...");
	}

	public void marketDataType(int reqId, int marketDataType) {
		System.out.println("marketDataType...");
	}

	public void commissionReport(CommissionReport commissionReport) {
		System.out.println("commissionReport...");
	}

	public void connectionClosed() {
		System.out.println("connectionClosed...");
	}

	public void error(Exception e) {
		System.out.println("error: "+e);
	}

	public void error(String str) {
		System.out.println("error: "+str);
	}

	/* *********************************************************************************************
	 *                                  important for placing orders
	 **********************************************************************************************/
	public void openOrder(int orderId, Contract contract, Order order, OrderState orderState) {
		//System.out.println("openOrder: "+orderId+", "+contract+", "+order+", "+orderState);
	}
	public void openOrderEnd() {
		//System.out.println("openOrderEnd:");
	}

	public void orderStatus(int orderId, String status, int filled,
			int remaining, double avgFillPrice, int permId, int parentId,
			double lastFillPrice, int clientId, String whyHeld) {
		
		//System.out.println("orderStatus: "+orderId+", "+status+", "+filled+", "+remaining);
		
	}
	public void deltaNeutralValidation(int reqId, UnderComp underComp) {
		System.out.println("deltaNeutralValidation: "+reqId+", "+underComp);
	}
	public void execDetails(int reqId, Contract contract, Execution execution) {
		System.out.println("execDetails: "+reqId+", "+contract+", "+execution);
	}
	public void execDetailsEnd(int reqId) {
		System.out.println("execDetailsEnd: "+reqId);
	}

	public void error(int id, int errorCode, String errorMsg) {
		System.out.println("error: "+id+", "+errorCode+", "+errorMsg);
	}
}
