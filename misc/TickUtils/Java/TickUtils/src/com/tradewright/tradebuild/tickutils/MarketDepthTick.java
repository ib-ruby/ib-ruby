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
 * This class represents a market depth tick.
 */
public final class MarketDepthTick extends Tick {

    /* ================================================================================
     * Constants
     * ================================================================================
     */

    // DOM Operations 
    /**
     * Indicates that this entry is to be inserted into the Depth-of-Market.
     */
    public static final int DOM_INSERT = 0;
    /**
     * Indicates that this entry in the Depth-of-Market table is to be updated.
     */
    public static final int DOM_UPDATE = 1;
    /**
     * Indicates that this entry in the Depth-of-Market table is to be deleted.
     */
    public static final int DOM_DELETE = 2;

    // DOM Sides 
    /**
     * Indicates that this entry relates to the ask side of the Depth-of-Market table.
     */
    public static final int DOM_ASK = 0;
    /**
     * Indicates that this entry relates to the bid side of the Depth-of-Market table.
     */
    public static final int DOM_BID = 1;

    /* ================================================================================
     * Fields
     * ================================================================================
     */

    private double mPrice;
    private int mSize;
    private int mPosition;
    private int mOperation;
    private int mSide;
    private String mMarketMaker;

    /*================================================================================
     * Constructors
     *================================================================================
     */

    MarketDepthTick(Date timestamp, int position, int operation, int side, double price, int size, String marketMaker) {
        super(timestamp);
        mPosition = position;
        mMarketMaker = marketMaker;
        mOperation = operation;
        mSide= side;
        mPrice = price;
        mSize = size;
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
     * Returns the position in the Depth-of-Market table that this tick relates to.
     * @return The position in the Depth-of-Market table that this tick relates to.
     */
    public final int getPosition() {
        return mPosition;
    }

    /**
     * Returns the operation to be performed in the Depth-of-Market table.
     * @return Returns the operation to be performed in the Depth-of-Market table. The value returned is one of:
     * <PRE>    
     *    DOM_INSERT
     *    DOM_UPDATE
     *    DOM_DELETE
     * </PRE>
     */
    public final int getOperation() {
        return mOperation;
    }

    /**
     * Returns a value indicating whether the operation to be performed in the Depth-of-Market table relates to the ask side or the bid side of the table.
     * @return One of the following values indicating whether the operation to be performed in the Depth-of-Market table relates to the ask side or the bid side of the table.
     * <PRE>
     *    DOM_ASK
     *    DOM_BID
     * </PRE>
     */
    public final int getSide() {
        return mSide;
    }

    /**
     * Returns the identifier for the market maker to which this tick relates.
     * @return The identifier for the market maker to which this tick relates.
     */
    public final String getMarketMaker() {
        return mMarketMaker;
    }

    /**
     * Returns a string representation of this tick.
     * @return A string representation of this tick.
     */
    public final String toString() {
        return super.toString() + "D" + "," + mPosition + "," + mMarketMaker + "," + mOperation + "," + mSide + "," + mPrice + "," + mSize;    
    }
}
