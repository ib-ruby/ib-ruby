/*
 * MarketDataType.java
 *
 */
package com.ib.client;

public class MarketDataType {
    // constants - market data types
    public static final int REALTIME   = 1;
    public static final int FROZEN     = 2;
    
    public static String getField( int marketDataType) {
        switch( marketDataType) {
            case REALTIME:                    return "Real-Time";
            case FROZEN:                      return "Frozen";
             
            default:                          return "Unknown";
        }
    }
    
    public static String[] getFields(){
    	int totalFields = MarketDataType.class.getFields().length;
    	String [] fields = new String[totalFields];
    	for (int i = 0; i < totalFields; i++){
    		fields[i] = MarketDataType.getField(i + 1);
    	}
    	return fields;
    }
}