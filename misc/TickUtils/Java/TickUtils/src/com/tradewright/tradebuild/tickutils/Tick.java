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

import java.text.SimpleDateFormat;
import java.util.Date;

/**
 * This class represents a single generic tick.
 */
public class Tick {

    /* ================================================================================
     * Constants
     * ================================================================================
     */

    // TickTypes - values used only in encoding
     static final int TICKTYPE_BID = 0;
     static final int TICKTYPE_ASK = 1;
     static final int TICKTYPE_CLOSE_PRICE = 2;
     static final int TICKTYPE_HIGH_PRICE = 3;
     static final int TICKTYPE_LOW_PRICE = 4;
     static final int TICKTYPE_MARKET_DEPTH = 5;
     static final int TICKTYPE_MARKET_DEPTH_RESET = 6;
     static final int TICKTYPE_TRADE = 7;
     static final int TICKTYPE_VOLUME = 8;
     static final int TICKTYPE_OPEN_INTEREST = 9;
     static final int TICKTYPE_OPEN_PRICE = 10;
    
    /* ================================================================================
     * Fields
     * ================================================================================
     */

    private Date mTimestamp;

    /*================================================================================
     * Constructors
     *================================================================================
     */
    
    Tick(Date timestamp) {
        mTimestamp = timestamp;
    }

    /* ================================================================================
     * Methods
     * ================================================================================
     */

    /**
     * Returns the timestamp for this tick.
     * @return The timestamp for this tick.
     */
    public final Date getTimestamp() {
        return mTimestamp;
    }

    /**
     * Returns a string representation of this tick.
     * @return A string representation of this tick.
     */
    public String toString() {
        return new SimpleDateFormat("yyyy/MM/dd HH:mm:ss.SSS").format(getTimestamp()) + ",";
    }

}
