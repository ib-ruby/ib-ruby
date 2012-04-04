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
 * This class represents a low tick (the lowest value reached during the current trading session).
 */
public final class LowTick extends Tick {
    
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

    /* ================================================================================
     * Initialisers
     * ================================================================================
     */
    
    /* ================================================================================
     * Constructors
     * ================================================================================
     */
    
    LowTick(Date timestamp, double price) {
        super(timestamp);
        this.mPrice = price;
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
     * Returns a string representation of this tick.
     * @return A string representation of this tick.
     */
    public final String toString() {
        return super.toString() + "L" + "," + mPrice;
    }
    
}
