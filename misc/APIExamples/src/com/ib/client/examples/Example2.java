package com.ib.client.examples;

import com.ib.client.Contract;
import com.ib.client.Contract;
import com.ib.client.ContractDetails;
import com.ib.client.EWrapperMsgGenerator;
import com.ib.client.Order;
import com.ib.client.TickType;
import com.ib.client.examples.model.UnderlyingData;
import com.ib.client.examples.util.DateUtil;
import com.ib.client.examples.util.RequestIDManager;
import java.util.ArrayList;
import java.util.ArrayList;
import java.util.List;

/**
 * This example will request market data for a given underlying.  Based on the
 * minimum implied volatily and implied volatility to historical volatility ratio
 * limit provided, decision is made whether or not to place a buy straddle order.
 * 
 * API requests:
 *  eConnect
 *  reqMktData
 *  cancelMktData
 *  reqContractDetails
 *  placeOrder
 *  eDisconnect
 * 
 * API callbacks:
 *  tickPrice
 *  tickGeneric
 *  contractDetails
 *  contractDetailsEnd
 *  orderStatus
 *  nextValidId
 * 
 * $Id$
 */
public class Example2 extends ExampleBase {

    private final static String GENERIC_TICKS = "104, 106"; // Hist Vol, Imp Vol
    private UnderlyingData underlyingData = null;
    private List<Contract> optionContracts = new ArrayList<Contract>();

    public Example2(String symbol, String minImpVol, String volRatioLimit) {
        this.underlyingData = new UnderlyingData(symbol, Double.parseDouble(minImpVol), Double.parseDouble(volRatioLimit));
    }

    public static void main(String[] args) {
        if (args.length != 3) {
            System.out.println(" Usage: java Example2 <symbol> <minImpVol> <volRatioLimit>");
            System.exit(1);
        } else {
            new Example2(args[0], args[1], args[2]).start();
        }
    }

    public void run() {
        try {
            connectToTWS();

            // Retrieve underlying data (last price, hist vol, imp vol)
            if (retrieveUnderlyingData()) {
                if (underlyingData.isOrderCriteriaMet()) {
                    // Retrieve option contracts for underlying
                    if (retrieveOptionContracts()) {
                        // Find the one that is 1) closest strike to underlying last price, 2) expiry not within 15 days
                        Contract callContract = filterContracts("C");
                        Contract putContract = filterContracts("P");
                        
                        if (RequestIDManager.singleton().isOrderIdInitialized()) {
                            // Place buy straddle for 1 contract as market order
                            Order callOrder = createOrder("BUY", 1, "MKT");
                            Order putOrder = createOrder("BUY", 1, "MKT");
                        
                            eClientSocket.placeOrder(RequestIDManager.singleton().getNextOrderId(), callContract, callOrder);
                            eClientSocket.placeOrder(RequestIDManager.singleton().getNextOrderId(), putContract, putOrder);
                            System.out.println(" [Info] Buy straddle market order submitted for: " + underlyingData.toString());
                            sleep(WAIT_TIME * 30); // Hang around for order status updates...
                        } else {
                            System.out.println(" [Error] Failed to initialize order ID for: " + underlyingData.toString());
                        }
                    } else {
                        System.out.println(" [Error] Failed to retrieve option contracts for: " + underlyingData.toString());
                    }
                } else {
                    System.out.println(" [Info] Underlying does NOT meet order criteria: " + underlyingData.toString());
                }
            } else {
                System.out.println(" [Error] Failed to retrieve underlying data: " + underlyingData.toString());
            }
        } catch (Throwable t) {
            System.out.println(" [Error] Example2.run() :: Problem occurred during processing: " + t.getMessage());
        } finally {
            disconnectFromTWS();
        }
    }

    private boolean retrieveUnderlyingData() throws InterruptedException {
        boolean isSuccess = false;
        int waitCount = 0;

        // Create a contract, with defaults...
        Contract contract = createContract(underlyingData.getSymbol(), "STK", "SMART", "USD");

        // Requests market data
        int requestId = RequestIDManager.singleton().getNextRequestId();
        eClientSocket.reqMktData(requestId, contract, GENERIC_TICKS, false);

        while (!isSuccess && waitCount < MAX_WAIT_COUNT) {
            // Check if last price and volatilities loaded
            if (underlyingData.isDataReady()) {
                isSuccess = true;
            } else {
                sleep(WAIT_TIME); // Pause for 1 sec
                waitCount++;
            }
        }

        // Cancel market data
        eClientSocket.cancelMktData(requestId);

        return isSuccess;
    }

    private boolean retrieveOptionContracts() throws InterruptedException {
        boolean isSuccess = false;
        int waitCount = 0;

        // Find all option contracts for underlying, will filter strike and expiry later...
        Contract contract = createContract(underlyingData.getSymbol(), "OPT", "SMART", "USD");

        int requestId = RequestIDManager.singleton().getNextRequestId();
        eClientSocket.reqContractDetails(requestId, contract);

        while (!isSuccess && waitCount < MAX_WAIT_COUNT) {
            // Check if all contracts received
            if (RequestIDManager.singleton().isRequestComplete(requestId)) {
                isSuccess = true;
            } else {
                sleep(WAIT_TIME); // Pause for 1 sec
                waitCount++;
            }
        }

        return isSuccess;
    }

    private Contract filterContracts(String right) {
        Contract c = null;

        // First by price
        double priceDiff = 0.0;
        
        for (Contract contract : optionContracts) {
            if (contract.m_right.equals(right)) {
                if (c == null) {
                    c = contract;
                    priceDiff = Math.abs(contract.m_strike - underlyingData.getLastPrice());
                } else {
                    double tempDiff = Math.abs(contract.m_strike - underlyingData.getLastPrice());
                    if (tempDiff < priceDiff) {
                        c = contract;
                        priceDiff = tempDiff;
                    }
                }
            }
        }
        
        
        // Next find closest expiry outside 15 days
        long days = 0;

        for (Contract contract : optionContracts) {
            // This time include check to look at those matching strike
            if (contract.m_right.equals(right) && contract.m_strike == c.m_strike) {
                if (days == 0) {
                    days = DateUtil.getDeltaDays(contract.m_expiry);
                    c = contract;
                } else {
                    long tempDays = DateUtil.getDeltaDays(contract.m_expiry);
                    if (tempDays < days && tempDays > 15) {
                        days = tempDays;
                        c = contract;
                    }
                }
            }
        }

        System.out.println(" [Debug] Filtered option contract: " + c.m_symbol + " " + c.m_expiry + " " + c.m_strike + " " + c.m_right);
        
        return c;
    }
    
    public void tickPrice(int tickerId, int field, double price, int canAutoExecute) {
        System.out.println(" [API.tickPrice] " + EWrapperMsgGenerator.tickPrice(tickerId, field, price, canAutoExecute));

        if (field == TickType.LAST) {
            underlyingData.setLastPrice(price);
        }
    }

    public void tickGeneric(int tickerId, int field, double generic) {
        System.out.println(" [API.tickGeneric] " + EWrapperMsgGenerator.tickGeneric(tickerId, tickerId, generic));

        if (field == TickType.OPTION_IMPLIED_VOL) {
            underlyingData.setImpVol(generic * 100);
        } else if (field == TickType.OPTION_HISTORICAL_VOL) {
            underlyingData.setHistVol(generic * 100);
        }
    }

    public void contractDetails(int reqId, ContractDetails contractDetails) {
        // System.out.println(" [API.contractDetails] " + EWrapperMsgGenerator.contractDetails(reqId, contractDetails));

        if (contractDetails != null && contractDetails.m_summary != null && "OPT".equals(contractDetails.m_summary.m_secType)) {
            optionContracts.add(contractDetails.m_summary);
        }
    }

    public void contractDetailsEnd(int reqId) {
        System.out.println(" [API.contractDetailsEnd] " + EWrapperMsgGenerator.contractDetailsEnd(reqId));
        
        RequestIDManager.singleton().addToRequestsCompleted(reqId);
    }
    
    public void orderStatus(int orderId, String status, int filled, int remaining, double avgFillPrice, int permId, int parentId, double lastFillPrice, int clientId, String whyHeld) {
        System.out.println(" [API.orderStatus] " + EWrapperMsgGenerator.orderStatus(orderId, status, filled, remaining, avgFillPrice, permId, parentId, lastFillPrice, clientId, whyHeld));
    }
    
    public void nextValidId(int orderId) {
        System.out.println(" [API.nextValidId] " + EWrapperMsgGenerator.nextValidId(orderId));
        RequestIDManager.singleton().initializeOrderId(orderId);
    }
}
