import com.ib.client.*;

/**
 * Created by IntelliJ IDEA.
 * User: Jerry Sy a.k.a. AutoTrader
 * Date: Feb 17, 2003
 * Time: 10:11:59 PM
 * Updated by Keith Kee 2005-04-16 for new TWSAPI
 * Updated by Gene Livingston 2011-05-16 for new TWSAPI
 * To change this template use Options | File Templates.
 */
public class Main implements EWrapper{
    EClientSocket m_client = new EClientSocket(this);
    int id = 0;

    public Main(String[] args) {
        String twsIPAddr = "192.168.1.67";
        m_client.eConnect(twsIPAddr,7496, 0xF00E);
        int count = 0;
        while (!m_client.isConnected()) {
            try {
                Thread.sleep(500);
                count++;
                if (count >10)
                    break;
            } catch (InterruptedException e) {
                e.printStackTrace();  //To change body of catch statement use Options | File Templates.
            }
        }
        if (!m_client.isConnected()) {
            System.exit(-1);
        }
        System.out.println("Sample TWS API Client Java code to print market data");
        System.out.println("getting quotes for AAPL STK");
        System.out.println("Press CTRL-C to quit");
        Contract contract = new Contract();
        contract.m_symbol="AAPL";
        contract.m_secType="STK";
        contract.m_exchange="SMART";
        contract.m_currency="USD";
        String gtl = "";
        boolean ss = true;
        //contract.expiry="200303";
        m_client.reqMktData(id,contract,gtl,ss);
        Thread.yield();

    }

    //public synchronized void reqMktData(int tickerId, Contract contract,
    //		String genericTickList, boolean snapshot)




    public static void main(String[] args) {
            Main main = new Main(args);

        }

    public void tickPrice(int tickerId, int field, double price,int canAutoExecute ) {
        switch (field){
            case 1:  //bid
                System.out.println("Bid Price = "+String.valueOf(price));
                break;
            case 2:  //ask
                System.out.println("Ask Price = "+String.valueOf(price));
                break;
            case 4:  //last
                System.out.println("Last Price = "+String.valueOf(price));
                break;
            case 6:  //high
                System.out.println("High Price = "+String.valueOf(price));
                break;
            case 7:  //low
                System.out.println("Low Price = "+String.valueOf(price));
                break;
            case 9:  //close
                System.out.println("Close Price = "+String.valueOf(price));
                break;
        }
    }

    public void tickSize(int tickerId, int field, int size) {
        switch (field){
            case 0:   //bid
                System.out.println("Bid Size = "+String.valueOf(size));
                break;
            case 3:   //ask
                System.out.println("Ask Size = "+String.valueOf(size));
                break;
            case 5:   //last
                System.out.println("Last Size = "+String.valueOf(size));
                break;
            case 8:   //volume
                System.out.println("Volume = "+String.valueOf(size));
                break;
        }
    }


    public void orderStatus( int orderId, String status, int filled, int remaining,
            double avgFillPrice, int permId, int parentId, double lastFillPrice, int clientId){
    }


    public void openOrder(int orderId, Contract contract, Order order) {
    }

    public void error(String str) {
    }

    public void connectionClosed() {
    }


	public void updateAccountValue(String key, String value, String currency, String accountName){
	}


    public void updatePortfolio(Contract contract, int position, double marketPrice, double marketValue) {
    }

    public void updateAccountTime(String timeStamp) {
    }

    public void nextValidId(int orderId) {
        id = orderId;
    }

    public void contractDetails(ContractDetails contractDetails) {
    }

    public void execDetails(int orderId, Contract contract, Execution execution) {
    }

    public void error(int id, int errorCode, String errorMsg) {
        System.out.println("Error id = "+String.valueOf(id)+" Error Code = "+String.valueOf(errorCode)+" "+errorMsg);
    }

    public void updateMktDepth(int tickerId, int position, int operation, int side, double price, int size) {
    }

    public void updateMktDepthL2(int tickerId, int position, String marketMaker, int operation, int side, double price, int size) {
    }

	public void updateNewsBulletin( int msgId, int msgType, String message, String origExchange){
	}

    public void managedAccounts( String accountsList){
    }

	public void receiveFA(int faDataType, String xml){
	}

	public void intradayData(int reqId, String date, double open, double high, double low, double close, int volume, double WAP, boolean hasGaps){
    }

    public void updatePortfolio(Contract contract, int position, double marketPrice, double marketValue, double averageCost, double unrealizedPNL, double realizedPNL, String accountName){
    }

//bug stomp
    public void tickSnapshotEnd(int tk){
    }

    public void deltaNeutralValidation(int reqId, UnderComp underComp) {
    }

    public void fundamentalData(int reqId, String data) {

    }

    public void currentTime(long time) {

    }

    public void realtimeBar(int reqId, long time, double open, double high, double low, double close, long volume, double wap, int count) {

    }

    public void scannerDataEnd(int reqId) {

    }

    public void scannerData(int reqId, int rank, ContractDetails contractDetails, String distance,
    		String benchmark, String projection, String legsStr) {
    }

    public void scannerParameters(String xml) {
    }

    public void historicalData(int reqId, String date, double open, double high, double low,
                      double close, int volume, int count, double WAP, boolean hasGaps) {
    }

    public void execDetailsEnd( int reqId) {
    }

    public void contractDetailsEnd(int reqId) {

    }

    public void bondContractDetails(int reqId, ContractDetails contractDetails) {

    }

    public void contractDetails(int reqId, ContractDetails contractDetails) {

    }

    public void accountDownloadEnd(String accountName) {

    }

    public void openOrderEnd() {

    }

    public void openOrder( int orderId, Contract contract, Order order, OrderState orderState) {

    }

    public void orderStatus( int orderId, String status, int filled, int remaining,
            double avgFillPrice, int permId, int parentId, double lastFillPrice,
            int clientId, String whyHeld) {

    }

    public void tickEFP(int tickerId, int tickType, double basisPoints,
			String formattedBasisPoints, double impliedFuture, int holdDays,
			String futureExpiry, double dividendImpact, double dividendsToExpiry) {
    }

    public void tickString(int tickerId, int tickType, String value) {
    }

    public void tickGeneric(int tickerId, int tickType, double value) {
    }

    public void tickOptionComputation( int tickerId, int field, double impliedVol,
    		double delta, double modelPrice, double pvDividend) {
    }

    public void error( Exception e) {

    }

        
}
