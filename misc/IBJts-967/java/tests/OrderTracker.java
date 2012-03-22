/*
 * $Id: OrderTracker.java,v 1.2 2007/12/12 16:35:03 ptitov Exp $
 *  
 * @author Dennis Stetsenko
 * @since Nov 5, 2007
 * 
 * $Log: OrderTracker.java,v $
 * Revision 1.2  2007/12/12 16:35:03  ptitov
 * int dp2974 api performance
 *
 * Revision 1.1  2007/11/06 16:29:03  dstetsenko
 * int dp2769 Investigate TWS API latencies
 *
 */
package tests;

import java.text.NumberFormat;
import java.util.Iterator;
import java.util.LinkedHashMap;
import java.util.Map;

public class OrderTracker {
	
	private final static NumberFormat NUMBER_FORMAT = NumberFormat.getInstance();
	static{
		NUMBER_FORMAT.setMaximumFractionDigits(5);
	}
	
	private final int m_expected;
	private long m_start = 0;
	private long m_end = 0;
	private int m_current = 0;
	private final Runnable m_done;
	private final boolean m_fullStat;
	
	// summary
	private String m_avg;
	
	public String average() { return m_avg; }
	
	public OrderTracker(boolean fullStat, int expected, Runnable done){
		m_fullStat = fullStat;
		m_expected = expected;
		m_done = done;
	}
	
	
	private final Map m_map = new LinkedHashMap();
	
	public void orderPlaced(String id) {
		if ( m_start == 0 ) {
			m_start = System.nanoTime();
		}
		Tracker tracker = getOrCreateTracker(id);
		tracker.orderPlaced();
		
		checkIfDone(tracker);
	}

	public void orderStatus(String id) {
		Tracker tracker = getOrCreateTracker(id);
		tracker.orderStatus();
		
		checkIfDone(tracker);
	}
	
	public void openOrder(String id) {
		Tracker tracker = getOrCreateTracker(id);
		tracker.openOrder();
		
		checkIfDone(tracker);
	}
	
	public void duplicateOrder(String id) {
		Tracker tracker = getOrCreateTracker(id);
		tracker.duplicateOrder();
		
		checkIfDone(tracker);
	}
	
	private void checkIfDone(Tracker tracker) {		
		if ( !tracker.isCounted() && tracker.isDone() ) {
			tracker.isCounted(true);
			m_current++;
			
			if ( m_expected <= m_current && m_end == 0 /* so we do it only once */) {
				m_end = System.nanoTime();
				dumtContent();
				
				m_done.run();
			}
		}
	}

	private Tracker getOrCreateTracker(String id) {
		Tracker tracker = (Tracker) m_map.get(id);
		if ( tracker == null ) {
			tracker = new Tracker(id);
			m_map.put(id, tracker);
		}
		
		return tracker;
	}
	
	public void dumtContent() {
		StringBuffer out = new StringBuffer();
		long totalProcessingTime = 0;
			
		for (Iterator iterator = m_map.entrySet().iterator(); iterator.hasNext();) {
			Map.Entry entry = (Map.Entry) iterator.next();
			Tracker tracker = (Tracker) entry.getValue();
			if (m_fullStat) {
				out.append( tracker.stats() + "\n");
			}
			totalProcessingTime += tracker.processingTimeNano();
		}			
		
		m_avg = NUMBER_FORMAT.format( totalProcessingTime / ( m_expected * 1000000 ));
		out.append("created "+m_expected+" orders within "+ Tracker.diff(m_end, m_start)+" ms, " +
				"average "+ m_avg + " ms per order\n");
		
		System.out.println(out);
	}

	
	/* *********************************************************************************************
	 *                                  Tracker 
	 **********************************************************************************************/
	private static class Tracker {
		private static int COUNT = 0;
		
		private final int m_counter = COUNT++; 
		private final String m_id;
		private long m_placed = 0;
		private long m_status = 0;
		private long m_open = 0;
		private long m_duplicate = 0;
		private boolean m_isCounted = false;
		
		public boolean isCounted() { return m_isCounted; }
		
		public void isCounted(boolean v) { m_isCounted = v; }
		
		public Tracker(String id) {
			m_id = id;
		}
		
		public long processingTimeNano() {
			if (m_status == 0 && m_placed == 0 ) {
				System.err.println("problem with order ["+m_id+"]");
			}
			
			return m_status != 0 && m_placed != 0 
				? m_status - m_placed
				: 0;
		}

		public String stats() {
			return "count: "+m_counter+"\t " +
				   "status: "+ diff(m_status, m_placed) + "\t" +
				   "opend: "+ diff(m_open, m_placed)+ "\t" +
			   	   "dup: "+ diff(m_duplicate, m_placed) + "\t";
		}


		static String diff(long n1, long n2) {
			return n1 != 0 
				? NUMBER_FORMAT.format( (n1 - n2) / 1000000 )
				: "NA";
		}
		
		
		
		public void openOrder() {
			if ( m_open != 0 ) {
				//System.err.println("dup for open order "+m_id+", ignored");
			} else {
				m_open = System.nanoTime();
			}
			
		}
		
		public void duplicateOrder() {
			if ( m_duplicate != 0 ) {
				//System.err.println("dup for open order "+m_id+", ignored");
			} else {
				m_duplicate = System.nanoTime();
			}
		}
		
		public void orderStatus() {
			if ( m_status != 0 ) {
				//System.err.println("dup for order status "+m_id+", ignored");
			} else {
				m_status = System.nanoTime();
			}
		}

		public void orderPlaced() {
			if ( m_placed != 0 ) {
				//System.err.println("dup for order placed "+m_id+", ignored");
			} else {
				m_placed = System.nanoTime();
			}
		}
		
		public boolean isDone() {
			return m_duplicate != 0 || m_status != 0;
		}
	}
}
