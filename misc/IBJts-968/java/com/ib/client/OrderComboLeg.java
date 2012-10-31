/*
 * OrderComboLeg.java
 *
 */
package com.ib.client;


public class OrderComboLeg {

    public double m_price; // price per leg

    public OrderComboLeg() {
        m_price = Double.MAX_VALUE;
    }

    public OrderComboLeg(double p_price) {
        m_price = p_price;
    }

    public boolean equals(Object p_other) {
        if ( this == p_other ) {
            return true;
        }
        else if ( p_other == null ) {
            return false;
        }

        OrderComboLeg l_theOther = (OrderComboLeg)p_other;
        
        if (m_price != l_theOther.m_price) {
        	return false;
        }

        return true;
    }
}