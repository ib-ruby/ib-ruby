package com.ib.client.examples.util;

import java.util.ArrayList;
import java.util.List;

/**
 * Utility to manage requests
 * 
 * $Id$
 */
public class RequestIDManager {

    private static RequestIDManager singleton = null;
    private int requestId = 0;
    private int orderId = -1;
    private List<Integer> requestsCompleted = new ArrayList<Integer>();

    private RequestIDManager() {
    }

    public static RequestIDManager singleton() {
        if (singleton == null) {
            singleton = new RequestIDManager();
        }
        return singleton;
    }

    public int getNextOrderId() {
        return orderId++;
    }

    public int getNextRequestId() {
        return requestId++;
    }

    public void addToRequestsCompleted(int requestId) {
        requestsCompleted.add(Integer.valueOf(requestId));
    }

    public void initializeOrderId(int orderId) {
        this.orderId = orderId;
    }

    public boolean isOrderIdInitialized() {
        if (orderId == -1) {
            return false;
        } else {
            return true;
        }
    }

    public boolean isRequestComplete(int requestId) {
        if (requestsCompleted.contains(Integer.valueOf(requestId))) {
            return true;
        } else {
            return false;
        }
    }
}
