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

import java.io.ByteArrayOutputStream;
import java.util.ArrayList;
import java.util.Calendar;
import java.util.Date;

final class TickDataEncoderA implements TickDataEncoder {

    //================================================================================
    // Enums
    //================================================================================

    //================================================================================
    // Types
    //================================================================================

    //================================================================================
    // Constants
    //================================================================================

    //================================================================================
    // Member variables
    //================================================================================

    /* current timestamp */
    private Date mTimestamp;          
    
    /* first price encountered at start of encoding period */
    private double mBasePrice = Double.MAX_VALUE;
    
    /* timestamp at start of encoding period */
    private Date mPeriodStartTime;    
    
    private long mPeriodStartTimeMillisecs;   

    private ByteArrayOutputStream mData = new ByteArrayOutputStream(4096);

    private double mTickSize;
    
    private Calendar mCalendar = Calendar.getInstance();

    //================================================================================
    // Constructors
    //================================================================================

    TickDataEncoderA( Date periodStartTime, double tickSize) {
        mPeriodStartTime = periodStartTime;
        mCalendar.setTime(mPeriodStartTime);
        mPeriodStartTimeMillisecs = mCalendar.getTimeInMillis();
        mTickSize = tickSize;
    }

    //================================================================================
    // TickDataEncoder Interface Members
    //================================================================================

    public final void encodeAsk( Date timestamp, double price, int size) {
        if (size < 0) throw new IllegalArgumentException("size cannot be negative");
        writeQuoteRecord(Tick.TICKTYPE_ASK, timestamp, price, size);
    }

    public final void encodeBid( Date timestamp, double price, int size) {
        if (size < 0) throw new IllegalArgumentException("size cannot be negative");
        writeQuoteRecord(Tick.TICKTYPE_BID, timestamp, price, size);
    }

    public final void encodeClose( Date timestamp, double price) {
        writePriceRecord(Tick.TICKTYPE_CLOSE_PRICE, timestamp, price);
    }

    public final void encodeHigh( Date timestamp, double price) {
        writePriceRecord(Tick.TICKTYPE_HIGH_PRICE, timestamp, price);
    }

    public final void encodeLow( Date timestamp, double price) {
        writePriceRecord(Tick.TICKTYPE_LOW_PRICE, timestamp, price);
    }

    public final void encodeMarketDepthData( Date timestamp, int position, String marketmaker, int operation, int side, double price, int size) {
        byte typeByte;
        int sizeType;
        byte sideOperationPositionByte;

        if (size < 0) throw new IllegalArgumentException("size cannot be negative");

        typeByte = Tick.TICKTYPE_MARKET_DEPTH;

        sizeType = getSizeType(size);
        typeByte = (byte)(typeByte | (sizeType << TickUtils.SIZE_TYPE_SHIFTER));

        if (timestamp == mTimestamp) typeByte = (byte)(typeByte | TickUtils.NO_TIMESTAMP);

        if (mBasePrice == Double.MAX_VALUE) mBasePrice = price;
        if (price < mBasePrice) typeByte = (byte)(typeByte | TickUtils.NEGATIVE_TICKS);

        writeByte(typeByte);
        writeTimestamp(timestamp);
        sideOperationPositionByte = (byte) (position | (operation << TickUtils.OPERATION_SHIFTER) | (side << TickUtils.SIDE_SHIFTER));
        writeByte(sideOperationPositionByte);

        writePrice(price);
        writeSize(size, sizeType);
        writeString(marketmaker);

    }

    public final void encodeMarketDepthReset( Date timestamp) {
        byte typeByte;

        typeByte = Tick.TICKTYPE_MARKET_DEPTH_RESET;

        if (timestamp == mTimestamp) typeByte = (byte) (typeByte | TickUtils.NO_TIMESTAMP);

        writeByte(typeByte);
        writeTimestamp(timestamp);

    }

    public final void encodeOpen( Date timestamp, double price) {
        writePriceRecord(Tick.TICKTYPE_OPEN_PRICE, timestamp, price);
    }

    public final void encodeOpenInterest( Date timestamp, int size) {
        writeSizeRecord(Tick.TICKTYPE_OPEN_INTEREST, timestamp, size);
    }

    public final void encodeTrade( Date timestamp, double price, int size) {
        if (size < 0) throw new IllegalArgumentException("size cannot be negative");
        writeQuoteRecord(Tick.TICKTYPE_TRADE, timestamp, price, size);
    }

    public final void encodeVolume( Date timestamp, int size) {
        writeSizeRecord(Tick.TICKTYPE_VOLUME, timestamp, size);
    }

    public final double getBasePrice() {
        return mBasePrice;
    }

    public final byte[] getEncodedData() {
        return mData.toByteArray();
    }

    public final int getEncodedDataLength() {
        return mData.size();
    }

    public final String getEncodingFormatIdentifier() {
        return  TickUtils.TICK_ENCODING_FORMAT_V2;
    }

    public final Date getPeriodStartTime() {
        return  mPeriodStartTime;
    }

    public final double getTickSize() {
        return mTickSize;
    }

    //================================================================================
    // Methods
    //================================================================================

    //================================================================================
    // Helper Functions
    //================================================================================

    private final int getSizeType( int size) {
        if (size < 0x100) {
            return TickUtils.BYTE_SIZE;
        } else if (size < 0x10000) {
            return TickUtils.UINT16_SIZE;
        } else {
            return TickUtils.UINT32_SIZE;
        }
    }

    private final void writeByte( byte value) {
        mData.write(value);
    }
    
    private final void writeShort( short value) {
        writeByte((byte)(value & 0xFF));
        writeByte((byte)((value >>> 8) & 0xFF));
    }

        private final void writeInt( int value) {
        writeByte((byte)(value & 0xFF));
        writeByte((byte)((value >>> 8) & 0xFF));
        writeByte((byte)((value >>> 16) & 0xFF));
        writeByte((byte)((value >>> 24) & 0xFF));
    }

    private final void writePrice( double price) {
        int numticks;
        if (price == mBasePrice) {
            writeByte((byte)0);
        } else {
            numticks = (int) (java.lang.Math.abs(price - mBasePrice) / mTickSize);
            if (numticks <= 127) {
                writeByte((byte)numticks);
            } else {
                /*  won't fit in 7 bits. write it out as a short value, with 
                 *  the high-order byte written first and bit 7 set. NB: there is
                 *  an implicit assumption here that we won't ever need to deal with
                 *  a price which is more than 0x7FFF ticks from the base price in
                 *  a single encoding period. That would be one hell of a crash!
                 */
                writeByte((byte)(((numticks >>> 8) & 0x7F) | 0x80));
                writeByte((byte)(numticks & 0xFF));
            }
        }
    }

    private final void writePriceRecord( int tickType, Date timestamp, double price) {
        byte typeByte;

        typeByte = (byte)tickType;

        if (timestamp.equals(mTimestamp)) typeByte = (byte) (typeByte | TickUtils.NO_TIMESTAMP);

        if (mBasePrice == Double.MAX_VALUE) mBasePrice = price;
        if (price < mBasePrice) typeByte = (byte) (typeByte | TickUtils.NEGATIVE_TICKS);

        writeByte(typeByte);
        writeTimestamp(timestamp);
        writePrice(price);
    }

    private final void writeQuoteRecord( int tickType, Date timestamp, double price, int size) {
        byte typeByte;
        int sizeType;

        typeByte = (byte)tickType;

        sizeType = getSizeType(size);
        typeByte = (byte) (typeByte | (sizeType << TickUtils.SIZE_TYPE_SHIFTER));

        if (timestamp.equals(mTimestamp)) typeByte = (byte) (typeByte | TickUtils.NO_TIMESTAMP);

        if (mBasePrice == Double.MAX_VALUE) mBasePrice = price;
        if (price < mBasePrice) typeByte = (byte) (typeByte | TickUtils.NEGATIVE_TICKS);

        writeByte(typeByte);

        writeTimestamp(timestamp);

        writePrice(price);

        writeSize(size, sizeType);
    }

    private final void writeSize( int size, int sizeType) {
        if (sizeType == TickUtils.BYTE_SIZE) {
            writeByte((byte) size);
        } else if (sizeType == TickUtils.UINT16_SIZE) {
            if (size < 0x8000) {
                writeShort((short)size);
            } else {
                writeShort((short)(size - 0x10000));
            }
        } else {
            writeInt(size);
        }
    }

    private final void writeSizeRecord( int tickType, Date timestamp, int size) {
        byte typeByte;
        int sizeType;

        typeByte = (byte)tickType;

        sizeType = getSizeType(size);
        typeByte = (byte) (typeByte | (sizeType << TickUtils.SIZE_TYPE_SHIFTER));

        if (timestamp.equals(mTimestamp)) typeByte = (byte) (typeByte | TickUtils.NO_TIMESTAMP);

        writeByte(typeByte);
        writeTimestamp(timestamp);
        writeSize(size, sizeType);
    }

    private final void writeString( String theString) {
        try {
            byte[] ar = theString.getBytes("UTF-16");
            int i;

            writeByte((byte)ar.length);

            for (i =0; i < ar.length; i++) {
                writeByte(ar[i]);
            }
        } catch (java.io.UnsupportedEncodingException ex) {
            // will never happen since this encoding is supported on all platforms
        }
    }

    private final void writeTimestamp( Date timestamp) {
        long diff;
        if (!timestamp.equals(mTimestamp)) {
            mCalendar.setTime(timestamp);
            diff = mCalendar.getTimeInMillis() - mPeriodStartTimeMillisecs;
            
            if (diff >= 0x10000) throw new IllegalStateException("Max tick encoding period exceeded");
            
            if (diff < 0x8000) {
                writeShort((short)diff);
            } else {
                writeShort((short)(diff - 0x10000));
            }
            mTimestamp = timestamp;
        }
    }




}
