/*
 *  Example4.java
 *  Copyright (C) 2011 Dale Furrow
 *  dkfurrow@google.com
 *
 *  This program is free software; you can redistribute it and/or
 *  modify it under the terms of the GNU Lesser General Public License
 *  as published by the Free Software Foundation; either version 3
 *  of the License, or (at your option) any later version.
 *
 *  This program is distributed in the hope that it will be useful,
 *  but WITHOUT ANY WARRANTY; without even the implied warranty of
 *  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 *  GNU Lesser General Public License for more details.
 *
 *  You should have received a copy of the GNU Lesser General Public License
 *  along with this program; if not, a copy may be found at
 *  http://www.gnu.org/licenses/lgpl.html
 */
package com.ib.client.examples;

import com.ib.client.Contract;
import com.ib.client.TickType;
import com.ib.client.examples.util.Console;
import com.ib.client.examples.util.DateUtil;
import com.ib.client.examples.util.IONTrader;
import java.io.File;
import java.text.ParseException;
import java.text.SimpleDateFormat;
import java.util.ArrayList;
import java.util.Calendar;
import java.util.Date;
import java.util.GregorianCalendar;
import java.util.Iterator;
import com.ib.client.examples.util.ListTextFilesApp;

/**
 * Looks in directory, compliles list of all ".txt" files, looks in each file
 * for last date of standard historical output.  Generates query from file last date
 * to present day (by Fridays)...queries TWS, and appends files
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
public class Example4 extends ExampleBase {

    private String symbol = null;
    private int requestId = 0;
    private double lastPrice = 0.0;
    private boolean isSuccess = false;
    private ArrayList<String> outString = new ArrayList<String>();

    public Example4() {
        
    }

    public static void main(String[] args) {
         Console thisConole = new Console();
         new Example4().start();
    }

    public void run() {
	try {

	    ArrayList<String> symbolAL = new ArrayList<String>();

	    String directoryString = "C:\\Users\\Dale Furrow\\"
		    + "My Documents\\NinjaTrader 7\\import";
	    symbolAL = ListTextFilesApp.listFilenames(
		    new File(directoryString), ListTextFilesApp.filter, true);

	    // Make connection
	    connectToTWS();

	    // iterate through files in directory
	    for (Iterator<String> it1 = symbolAL.iterator(); it1.hasNext();) {
		String thisSymbol = it1.next();

		this.symbol = thisSymbol;

		String extension = ".txt";
		File addFile = new File(directoryString + "\\" + this.symbol
			+ extension);
		Date lastFileDate = IONTrader.getLastNTDate(addFile);

		// prepare dates (break down time gap by Fridays
		SimpleDateFormat sdf = new SimpleDateFormat("yyyyMMdd HH:mm:ss");
		GregorianCalendar gc = new GregorianCalendar();
		gc.setTime(new Date());
		gc.set(Calendar.MINUTE, 0);
		gc.set(Calendar.SECOND, 0);
		ArrayList<Date> datesToQuery = DateUtil.getFridays(
			lastFileDate, gc.getTime());
		datesToQuery.add(gc.getTime());

		// Create a contract, with defaults...
		Contract contract = createContract(symbol);

		// iterate through dates
		for (Iterator<Date> it = datesToQuery.iterator(); it.hasNext();) {
		    Date queryDate = it.next();
		    String queryDateString = sdf.format(queryDate) + " CST";
		    // initialize variables
		    isSuccess = false;
		    int waitCount = 0;
		    outString.clear();
		    // Request snapshot market data
		    eClientSocket.reqHistoricalData(requestId++, contract,
			    queryDateString, "5 D", "1 min", "TRADES", 1, 1);
		    // test for success, if not, wait for a second and try again
		    while (!isSuccess && waitCount < MAX_WAIT_COUNT) {
			// Check to see if last price loaded
			if (!isSuccess) {
			    sleep(WAIT_TIME); // Pause for 1 second
			    waitCount++;
			}
		    }
		    // Display results
		    if (isSuccess) {
			System.out.println("Symbol: " + symbol + " ReqID: "
				+ requestId + " date: " + queryDateString
				+ " String Size: " + outString.size());
			IONTrader.appendBaseFile(outString, addFile);
			// initialize variables for next iteration
			outString.clear();
			isSuccess = false;
			waitCount = 0;
			// sleep for 11 seconds to avoid pacing violation
			sleep(WAIT_TIME * 11);
		    } else {
			System.out.println(" [Error] No Success " + symbol
				+ " " + queryDateString);
		    }
		} // end iterative date loop
	    }

	} catch (Throwable t) {
	    System.out
		    .println("Example4.run() :: Problem occurred during processing: "
			    + t.getMessage());
	} finally {
	    disconnectFromTWS();
	}
    }

    public void tickPrice(int tickerId, int field, double price, int canAutoExecute) {
        if (field == TickType.LAST) {
            lastPrice = price;
        }
    }

    /* Custom implementation of  historicalData method from ExampleBase
     * processes historical data for this implementation of EWrapper which
     * is in turn part of a created EReader object
     */
    public void historicalData(int reqId, String date, double open,
	    double high, double low, double close, int volume, int count,
	    double WAP, boolean hasGaps) {

	try {
	    if (date.substring(0, 8).equals("finished")) {
		// end of data stream for historical data
		isSuccess = true;
	    }
	    if (!isSuccess) { // data stream still flowing
		// generate individual HLOC element
		IONTrader thisOutput = new IONTrader(reqId, date, open, high,
			low, close, volume);
		// add to array list of strings
		outString.add(thisOutput.getOutInfo());
	    }
	} catch (ParseException ex) {
	    outString.add("Parse Exception");
	}
    }

}
