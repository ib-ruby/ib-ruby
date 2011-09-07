package com.ib.client.examples;

import com.ib.client.Contract;
import com.ib.client.EWrapperMsgGenerator;
import com.ib.client.TickType;
import com.ib.client.examples.util.IONTrader;
import java.io.File;
import java.text.ParseException;
import java.util.ArrayList;
import java.util.Calendar;
import java.util.Date;
import java.util.GregorianCalendar;
import java.util.Iterator;
import java.util.logging.Level;
import java.util.logging.Logger;

/**
 * Simple example which will pull the Historical Data for a given symbol.
 * 
 * API requests:
 *  eConnect
 *  reqMktData (snapshot)
 *  eDisconnect
 * 
 * API callbacks:
 *  tickPrice
 * 
 * $Id$
 */
public class Example3 extends ExampleBase {

    private String symbol = null;
    private int requestId = 0;
    private double lastPrice = 0.0;
    private boolean isDone = false;
    private ArrayList<String> outString = new ArrayList<String>();

    public Example3(String symbol) {
        this.symbol = symbol;
    }

    public static void main(String[] args) {
        if (args.length != 1) {
            System.out.println(" Usage: java Example3 <symbol>");
            System.exit(1);
        } else {
            new Example3(args[0]).start();
        }
    }

    public void run() {
        try {
            boolean isSuccess = false;
            int waitCount = 0;

            // Make connection
            connectToTWS();

            // Create a contract, with defaults...
            Contract contract =
            createContract( symbol, "STK", "SMART", "USD", null, null, 0.0);
            //IND, STK
            //SMART, "NYSE"
            // Requests snapshot market data
//            eClientSocket.reqMktData(requestId++, contract, null, true);
//            eClientSocket.reqHistoricalData(requestId++, contract,
//                    "20101210 15:00:00 CST", "5 D", "1 min", "TRADES", 1, 1);
            //TRADES, MIDPOINT

            eClientSocket.reqHistoricalData(requestId++, contract,
                    "20110120 15:00:00 CST", "3 Y", "1 day", "TRADES", 1, 1);
            
            while (!isSuccess && waitCount < MAX_WAIT_COUNT) {
                // Check if last price loaded
                if (isDone) {
                    isSuccess = true;
                }

                if (!isSuccess) {
                    sleep(WAIT_TIME); // Pause for 1 second
                    waitCount++;
                }
            }
           

            // Display results
            if (isSuccess) {
                System.out.println("For Symbol: " + symbol + ", ReqID: " + requestId);
                for (Iterator<String> it = outString.iterator(); it.hasNext();) {
                    String string = it.next();
                    System.out.println(string);
                }
               
//                System.out.println(endSubStr);
            } else {
                System.out.println(" [Error] No Success " + symbol);
            }
        } catch (Throwable t) {
            System.out.println("Example3.run() :: Problem occurred during processing: " + t.getMessage());
        } finally {
            disconnectFromTWS();
        }
    }

    public void tickPrice(int tickerId, int field, double price, int canAutoExecute) {
        if (field == TickType.LAST) {
            lastPrice = price;
        }
    }

     public void historicalData(int reqId, String date, double open, double high, double low,
                               double close, int volume, int count, double WAP, boolean hasGaps) {
            outString.add(date + " " + open + " " + low + " "+ high + " " + close);
            if(date.substring(0, 8).equals("finished")) isDone = true;

    }
}
