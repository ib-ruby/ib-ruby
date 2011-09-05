package com.ib.client.examples;

import com.ib.client.Contract;
import com.ib.client.TickType;

/**
 * Simple example which will pull the last price for a given symbol. 
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
public class Example1 extends ExampleBase {

    private String symbol = null;
    private int requestId = 0;
    private double lastPrice = 0.0;

    public Example1(String symbol) {
        this.symbol = symbol;
    }

    public static void main(String[] args) {
        if (args.length != 1) {
            System.out.println(" Usage: java Example1 <symbol>");
            System.exit(1);
        } else {
            new Example1(args[0]).start();
        }
    }

    public void run() {
        try {
            boolean isSuccess = false;
            int waitCount = 0;

            // Make connection
            connectToTWS();

            // Create a contract, with defaults...
            Contract contract = createContract(symbol, "STK", "SMART", "USD");

            // Requests snapshot market data
            eClientSocket.reqMktData(requestId++, contract, null, true);

            while (!isSuccess && waitCount < MAX_WAIT_COUNT) {
                // Check if last price loaded
                if (lastPrice != 0.0) {
                    isSuccess = true;
                }

                if (!isSuccess) {
                    sleep(WAIT_TIME); // Pause for 1 second
                    waitCount++;
                }
            }

            // Display results
            if (isSuccess) {
                System.out.println(" [Info] Last price for " + symbol + " was: " + lastPrice);
            } else {
                System.out.println(" [Error] Failed to retrieve last price for " + symbol);
            }
        } catch (Throwable t) {
            System.out.println("Example1.run() :: Problem occurred during processing: " + t.getMessage());
        } finally {
            disconnectFromTWS();
        }
    }

    public void tickPrice(int tickerId, int field, double price, int canAutoExecute) {
        if (field == TickType.LAST) {
            lastPrice = price;
        }
    }
}
