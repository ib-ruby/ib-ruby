package com.sample.realtimebars;

import java.util.ArrayList;
import java.util.Enumeration;
import java.util.Hashtable;

import com.ib.client.Contract;
import com.ib.client.ContractDetails;
import com.ib.client.EClientSocket;
import com.ib.client.EWrapper;
import com.ib.client.Execution;
import com.ib.client.Order;
import com.ib.client.OrderState;

public class TestRealTimeBars implements EWrapper
{
    public Hashtable<Integer, DataHolder> ht = new Hashtable<Integer, DataHolder> (); 
    private int nextSymbolID = -1;
    private EClientSocket client = null;
    
    public TestRealTimeBars ()
    {
        client = new EClientSocket (this);
        client.eConnect (null, 7600, 0);
        try {Thread.sleep (1000);} catch (Exception e) {};
    }

    public void bondContractDetails (int reqId, ContractDetails contractDetails)
    {
    }

    public void contractDetails (int reqId, ContractDetails contractDetails)
    {
    }

    public void contractDetailsEnd (int reqId)
    {
    }

    public void fundamentalData (int reqId, String data)
    {
    }

    public void bondContractDetails (ContractDetails contractDetails)
    {
    }

    public void contractDetails (ContractDetails contractDetails)
    {
    }

    public void currentTime (long time)
    {
    }

    public void execDetails (int orderId, Contract contract, Execution execution)
    {
    }

    public void historicalData (int reqId, String date, double open,
            double high, double low, double close, int volume, int count,
            double WAP, boolean hasGaps)
    {
    }

    public void managedAccounts (String accountsList)
    {
    }

    public void openOrder (int orderId, Contract contract, Order order,
            OrderState orderState)
    {
    }

    public void orderStatus (int orderId, String status, int filled,
            int remaining, double avgFillPrice, int permId, int parentId,
            double lastFillPrice, int clientId, String whyHeld)
    {
    }

    public void receiveFA (int faDataType, String xml)
    {
    }

    public void scannerData (int reqId, int rank,
            ContractDetails contractDetails, String distance, String benchmark,
            String projection, String legsStr)
    {
    }

    public void scannerDataEnd (int reqId)
    {
    }

    public void scannerParameters (String xml)
    {
    }

    public void tickEFP (int symbolId, int tickType, double basisPoints,
            String formattedBasisPoints, double impliedFuture, int holdDays,
            String futureExpiry, double dividendImpact, double dividendsToExpiry)
    {
    }

    public void tickGeneric (int symbolId, int tickType, double value)
    {
    }

    public void tickOptionComputation (int symbolId, int field,
            double impliedVol, double delta, double modelPrice,
            double pvDividend)
    {
    }

    public void tickPrice (int symbolId, int field, double price,
            int canAutoExecute)
    {
    }

    public void tickSize (int symbolId, int field, int size)
    {
    }

    public void tickString (int symbolId, int tickType, String value)
    {
    }

    public void updateAccountTime (String timeStamp)
    {
    }

    public void updateAccountValue (String key, String value, String currency,
            String accountName)
    {
    }

    public void updateMktDepth (int symbolId, int position, int operation,
            int side, double price, int size)
    {
    }

    public void updateMktDepthL2 (int symbolId, int position,
            String marketMaker, int operation, int side, double price, int size)
    {
    }

    public void updateNewsBulletin (int msgId, int msgType, String message,
            String origExchange)
    {
    }

    public void updatePortfolio (Contract contract, int position,
            double marketPrice, double marketValue, double averageCost,
            double unrealizedPNL, double realizedPNL, String accountName)
    {
    }

    public void connectionClosed ()
    {
    }

    public void error (Exception e)
    {
        e.printStackTrace ();
    }

    public void error (String str)
    {
        System.err.println (str);
    }

    public void error (int id, int errorCode, String errorMsg)
    {
        System.err.println ("error (id, errorCode, errorMsg): id=" + id + ".  errorCode=" + errorCode + ".  errorMsg=" + errorMsg);
    }
    
    public void nextValidId (int orderId)
    {
        nextSymbolID = orderId;
    }

    public synchronized int getNextID ()
    {
        return (nextSymbolID++);
    }

    public void realtimeBar (int reqId, long time, double open, double high,
            double low, double close, long volume, double wap, int count)
    {
        try
        {
            DataHolder holder = ht.get (reqId);
            if (holder != null)
                holder.newBar ();
        }
        catch (Exception e)
        {
            e.printStackTrace ();
        }
    }

    private class DataHolder
    {
        private int requestID = 0;
        private Contract contract = null;
        private long lastBarReceived = 0;
        
        public DataHolder (Contract contract, int requestID)
        {
            this.requestID = requestID;
            this.contract = contract;
        }
        
        public void newBar ()
        {
            lastBarReceived = System.currentTimeMillis ();
        }
        
        public long getLastBarReceived ()
        {
            return (lastBarReceived);
        }
        public int getRequestID ()
        {
            return (requestID);
        }
        
        public Contract getContract ()
        {
            return (contract);
        }
    }

    // This simply requests to monitor all symbols (calling reqRealTimeBars () every
    // 300 millis).
    public void doit ()
    {
        String symbols[] = getSymbols ();
        System.out.println ("ATTEMPTING TO MONITOR " + symbols.length + " SYMBOLS");
        for (int i=0; i<symbols.length; i++)
        {
            Contract contract = new Contract ();
            contract.m_symbol = symbols[i];
            contract.m_exchange = "SMART";
            contract.m_secType = "STK";
            DataHolder holder = new DataHolder (contract, getNextID ());
            try {Thread.sleep (300);} catch (Exception e) {};

            System.out.println ("Requesting: " + holder.getRequestID () + ". " + holder.getContract ().m_symbol);
            client.reqRealTimeBars (holder.getRequestID (), holder.getContract (), 5, "TRADES", false);
            ht.put (holder.getRequestID (), holder);
        }
        
        // Now that all symbols are being monitored, let's just watch to how many
        // are actually receiving data.
        while (true)
        {
            try {Thread.sleep (1000);} catch (Exception e) {};
            System.out.println (getSymbolsReceivingData ().size () + " symbols receiving data");
        }
    }
    
    public static void main (String args[])
    {
        try
        {
            TestRealTimeBars test = new TestRealTimeBars ();
            test.doit ();
        }
        catch (Exception e)
        {
            e.printStackTrace ();
        }
    }

    private ArrayList<String> getSymbolsReceivingData () 
    {
        Enumeration<Integer> en = ht.keys ();
        ArrayList<String> symbols = new ArrayList<String> (); 
        
        try
        {
            while (en.hasMoreElements ())
            {
                DataHolder holder = ht.get (en.nextElement ());
                if (holder != null)
                {
                    if (holder.getLastBarReceived () != 0)
                    {
                        if (holder.getLastBarReceived () + 1000*30 >= System.currentTimeMillis ())
                            symbols.add (holder.getContract ().m_symbol);
                    }
                }
            }
        }
        catch (Exception e)
        {
            return (symbols);
        }
        
        return (symbols);
    }
    
    public static String[] getSymbols ()
    {
        String str[] = {
            "MSFT",
            "INTC",
            "ORCL",
            "WNR",
            "WMT",
            "WM",
            "WFR",
            "WFC",
            "WDC",
            "WB",  // 10
            "WAG",
            "VOD",
            "VLO",
            "VIV",
            "USB",
            "UPL",
            "UNP",
            "UNM",
            "UNH",
            "UMC",  // 20
            "UIS",
            "UFS",
            "UBS",
            "TYC",
            "TMA",
            "TLM",
            "TJX",
            "TIN",
            "TIF",
            "TIE",  // 30
            "THC",
            "TGT",
            "TEX",
            "TER",
            "TCB",
            "TAP",
            "YUM",
            "YGE", 
            "XTO",
            "XRX",  // 40
            "XOM",
            "XL",
            "T",
            "SYY",
            "SWY",
            "SWN",
            "SWC",
            "SUN",
            "SU",
            "STX",  // 50
            "STT",
            "STP",
            "STM",
            "STI",
            "SRP",
            "SPR",
            "SPF",
            "SOV",
            "SO",
            "SNV",  //60
            "SNE",
            "SLW",
            "SLT",
            "SLM",
            "SLE",
            "SLB"   // 66
        };
        
        return (str);
    }
}
