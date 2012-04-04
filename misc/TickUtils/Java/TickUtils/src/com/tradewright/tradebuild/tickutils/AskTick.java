/* Copyright 2008 Richard L King
 *
 * This file is part of TradeBuild Tick Utilities Package.
 *
 * TradeBuild Tick Utilities Package is free software: you can redistribute it
 * and/or modify it under the terms of the GNU General Public License as
 * published by the Free Software Foundation, either version 3 of the License, 
 * or (at your option) any later version.
 *
 * TradeBuild Tick Utilities Package is distributed in the hope that it will 
 * be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with TradeBuild Tick Utilities Package.  If not, see 
 * <http://www.gnu.org/licenses/>.
 */

package com.tradewright.tradebuild.tickutils;

import java.util.Date;

/**
 * This class represents an ask tick.
 */
public final class AskTick extends Tick {
    
    /* ================================================================================
     * Enums
     * ================================================================================
     */
    
    /* ================================================================================
     * Inner Classes
     * ================================================================================
     */
    
    /* ================================================================================
     * Constants
     * ================================================================================
     */
    
    /* ================================================================================
     * Interfaces
     * ================================================================================
     */
    
    /* ================================================================================
     * Fields
     * ================================================================================
     */
    
    private double mPrice;
    private int mSize;

    /* ================================================================================
     * Initialisers
     * ================================================================================
     */
    
    /* ================================================================================
     * Constructors
     * ================================================================================
     */
    
    AskTick(Date timestamp, double price, int size) {
        super(timestamp);
        this.mPrice = price;
        this.mSize = size;
    }
    
    /* ================================================================================
     * Methods
     * ================================================================================
     */
    
    /**
     * Returns the price for this tick.
     * @return The price for this tick.
     */
    public final double getPrice() {
        return mPrice;
    }

    /**
     * Returns the size for this tick.
     * @return The size for this tick.
     */
    public final int getSize() {
        return mSize;
    }

    /**
     * Returns a string representation of this tick.
     * @return A string representation of this tick.
     */
    public final String toString() {
        return super.toString() + "A" + "," + mPrice + "," + mSize;
    }
    
}
