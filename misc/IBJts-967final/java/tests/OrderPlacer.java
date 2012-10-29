/*
 * $Id: OrderPlacer.java,v 1.3 2007/12/12 16:35:03 ptitov Exp $
 *  
 * @author Dennis Stetsenko
 * @since Nov 5, 2007
 * 
 * $Log: OrderPlacer.java,v $
 * Revision 1.3  2007/12/12 16:35:03  ptitov
 * int dp2974 api performance
 *
 * Revision 1.2  2007/11/21 17:34:31  dstetsenko
 * int dp0000 minor
 *
 * Revision 1.1  2007/11/06 16:29:03  dstetsenko
 * int dp2769 Investigate TWS API latencies
 *
 */
package tests;

import java.util.ArrayList;
import java.util.Iterator;
import java.util.List;

import tests.Fuse.Bomb;

import com.ib.client.Contract;
import com.ib.client.EClientSocket;
import com.ib.client.Order;
import com.ib.client.OrderState;

public class OrderPlacer {
	
	private static int BATCH_SIZE = 100; // controlled via startup script
	private static int NEXT_VALID_ID = 1;	
	private static int ITER = 0;

	private final List m_stat = new ArrayList();
	private final EClientSocket m_client;	
	private OrderTracker m_tracker;
	
	private ApiCallback callback = new ApiCallback() {
		
		public void orderStatus(int orderId, String status, int filled, int remaining, double avgFillPrice, int permId, int parentId, double lastFillPrice, int clientId, String whyHeld) {
			super.orderStatus(orderId, status, filled, remaining, avgFillPrice, permId, parentId, lastFillPrice, clientId, whyHeld);
			
			m_tracker.orderStatus(""+orderId);
		}
		
		public void openOrder(int orderId, Contract contract, Order order, OrderState orderState) {
			super.openOrder(orderId, contract, order, orderState);
			
			m_tracker.openOrder(""+orderId);
		}
		
		public void error(int id, int errorCode, String errorMsg) {
			super.error(id, errorCode, errorMsg);
			
			if ( id != -1 ) {
				m_tracker.duplicateOrder(""+id);
			}
		}
		
		public void nextValidId(int orderId) {
			super.nextValidId(orderId);
			
			NEXT_VALID_ID = orderId;
		}
	};
	
	public OrderPlacer() {
		m_client = new EClientSocket( callback );
		m_client.eConnect("localhost", 7496, 1);
		
		init();
	}
	
	private void init() {				
		Fuse.light("1s", 1000, new Bomb(){
			public void explode(Fuse fuse) {
				NEXT_VALID_ID += BATCH_SIZE;
				placeOrder(m_client);
			}
		});		
	}	
	
	private void restart() {
		for (int i = NEXT_VALID_ID; i < NEXT_VALID_ID + BATCH_SIZE ; i++) {
			m_client.cancelOrder(i);
		}
		
		Fuse.light("1b", 10 * BATCH_SIZE, new Bomb() {
			public void explode(Fuse fuse) {
				init();				
			}
		});
	}
	
	private void shutdown() {
		System.out.println("Shut down...");
		for (int i = NEXT_VALID_ID; i < NEXT_VALID_ID + BATCH_SIZE ; i++) {
			m_client.cancelOrder(i);
		}
		
		// dump stat
		System.out.println("Averages...");
		for (Iterator itr = m_stat.iterator(); itr.hasNext();) {
			System.out.println(itr.next());			
		}
		
		Fuse.light("1b", 10 * BATCH_SIZE, new Bomb() {
			public void explode(Fuse fuse) {
				m_client.eDisconnect();				
			}
		});
	}

	private void placeOrder(final EClientSocket client) {
		System.out.println("placing "+BATCH_SIZE +" orders. Iteration:" + ITER);
		
		if (m_tracker != null) {
			m_stat.add(m_tracker.average());			
		}
		
		m_tracker = new OrderTracker(false, BATCH_SIZE, new Runnable(){
			public void run() {
				if (ITER++ < 10) {
					restart();
				} else {
					shutdown();
				}
			}
		});		
		
		for (int i = NEXT_VALID_ID; i < NEXT_VALID_ID + BATCH_SIZE ; i++) {
			placeOrder(client, i);			
		}
		System.out.println("\ndone placing orders");
	}
	
	private void placeOrder(final EClientSocket client, int count) {
		System.out.print(".");
		
		Contract contract = new Contract();
		contract.m_conId = 8314;
        contract.m_symbol = "IBM";
        contract.m_secType = "STK";
        contract.m_expiry = "";
       	contract.m_strike = 0.0;
        contract.m_right = "";
        contract.m_multiplier = "0";
        contract.m_exchange = "SMART";
        contract.m_primaryExch = "ISLAND";
        contract.m_currency = "USD";
        contract.m_localSymbol = "IBM";

        Order order = new Order();
        order.m_action = "BUY";
        order.m_totalQuantity = 100;
        order.m_orderType = "LMT";
        order.m_lmtPrice = 99.10;
        order.m_outsideRth = true;

        m_tracker.orderPlaced(""+count);
        client.placeOrder( count, contract, order );
	}
	
	public static void main(String[] args) {
		if ( args.length == 1 ) {
			try {
				BATCH_SIZE = Integer.parseInt(args[0]);
			} catch (Exception e) {
				e.printStackTrace();
			}
			
		}
		new OrderPlacer();
	}
}
