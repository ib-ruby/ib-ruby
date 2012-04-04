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

import java.util.Calendar;
import java.util.Date;

final class TickDataDecoderA implements TickDataDecoder {
    
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

    private byte[] mData;
    private int mDataIndex;

    private double mTickSize;

    private Date mPeriodStartTime;   /*  timestamp at start of encoding period */
    private Date mCurrentTimestamp;

    private double mBasePrice;
    
    private int mVersion;
    
    private Calendar mCalendar = Calendar.getInstance();

    //================================================================================
    // Constructors
    //================================================================================

    TickDataDecoderA( Date periodStartTime, double basePrice, double tickSize, String encodingFormat, byte[] data) {
        mPeriodStartTime = periodStartTime;
        mCurrentTimestamp = mPeriodStartTime;
        mBasePrice = basePrice;
        mTickSize = tickSize;
        mData = data;
        
        if (tickSize <= 0) throw new IllegalArgumentException("tickSize argument must be > 0");

        if (encodingFormat.equals(TickUtils.TICK_ENCODING_FORMAT_V1)) {
            mVersion = 1;
        } else if (encodingFormat.equals(TickUtils.TICK_ENCODING_FORMAT_V2)) {
            mVersion = 2;
        } else {
            throw new IllegalArgumentException("Invalid encodingFormat argument");
        }

    }

    //================================================================================
    // TickDataDecoder Interface Members
    //================================================================================

    public Tick getNextTick() {
        Tick tick;
        byte typeByte;
        int tickType;
        int sizeType;
        Date timestamp;

        if (mDataIndex >= mData.length) return null;

        typeByte = (byte) readByte();

        timestamp = readTimestamp(typeByte);

        tickType = typeByte  &  TickUtils.TICK_TYPE_BITS;
        sizeType = (typeByte  &  TickUtils.SIZE_TYPE_BITS) >>> TickUtils.SIZE_TYPE_SHIFTER;

        switch (tickType) {
        case Tick.TICKTYPE_BID:
        case Tick.TICKTYPE_ASK:
        case Tick.TICKTYPE_TRADE:
            tick = readQuoteRecord(tickType, timestamp, typeByte, sizeType);
            break;
        case Tick.TICKTYPE_CLOSE_PRICE:
        case Tick.TICKTYPE_HIGH_PRICE:
        case Tick.TICKTYPE_LOW_PRICE:
        case Tick.TICKTYPE_OPEN_PRICE:
            tick = readPriceRecord(tickType, timestamp, typeByte);
            break;
        case Tick.TICKTYPE_MARKET_DEPTH:
            tick = readMarketDepthRecord(timestamp, typeByte, sizeType);
            break;
        case Tick.TICKTYPE_MARKET_DEPTH_RESET:
            tick = readMarketDepthResetRecord(timestamp, typeByte);
            break;
        case Tick.TICKTYPE_VOLUME:
        case Tick.TICKTYPE_OPEN_INTEREST:
            tick = readSizeRecord(tickType, timestamp, typeByte, sizeType);
            break;
        default:
            throw new IllegalStateException("Invalid ticktype");
        }
        
        return tick;

    }

    //================================================================================
    // Methods
    //================================================================================

    //================================================================================
    // Helper Functions
    //================================================================================

    private int readByte() {
        return mData[mDataIndex++] &0xFF;
    }

    private int readInt() {
        // note that this will fail (overflow) if attempting to read a negative long,
        // but this should never happen
        return  readByte() + 
                (readByte() << 8) + 
                (readByte() << 16) + 
                (readByte() << 24);
    }

    private MarketDepthTick readMarketDepthRecord( 
                    Date timestamp,
                    byte typeByte, 
                    int sizeType) {
        byte sideOperationPositionByte;

        sideOperationPositionByte = (byte) readByte();
        
        MarketDepthTick tick = new MarketDepthTick(timestamp, 
                                                    sideOperationPositionByte  &  TickUtils.POSITION_BITS,
                                                    (sideOperationPositionByte  &  TickUtils.OPERATION_BITS) >>> TickUtils.OPERATION_SHIFTER,
                                                    (sideOperationPositionByte  &  TickUtils.SIDE_BITS) >>> TickUtils.SIDE_SHIFTER,
                                                    readPrice(typeByte),
                                                    readSize(sizeType),
                                                    readString());
        return tick;
    }

    private MarketDepthResetTick readMarketDepthResetRecord(Date timestamp, byte typeByte) {
        return new MarketDepthResetTick(timestamp);
    }

    private double readPrice( byte typeByte) {
        byte mostSigByte;
        byte leastSigByte;
        int numticks;

        mostSigByte = (byte) readByte();
        if ((mostSigByte  &  0x80) == 0) {
            numticks = (int)mostSigByte;
        } else {                                
            mostSigByte = (byte)(mostSigByte  &  0x7F);
            leastSigByte = (byte)readByte();
            numticks = (mostSigByte << 8) + ((int)(leastSigByte) & 0xFF);
        }

        if ((typeByte  &  TickUtils.NEGATIVE_TICKS) != 0) {
            return mBasePrice - mTickSize * numticks;
        } else {
            return mBasePrice + mTickSize * numticks;
        }
    }

    private Tick readPriceRecord(int tickType, Date timestamp, byte typeByte) {
        double price = readPrice(typeByte);
        switch (tickType) {
        case Tick.TICKTYPE_CLOSE_PRICE:
            return new CloseTick(timestamp, price);
        case Tick.TICKTYPE_HIGH_PRICE:
            return new HighTick(timestamp, price);
        case Tick.TICKTYPE_LOW_PRICE:
            return new LowTick(timestamp, price);
        case Tick.TICKTYPE_OPEN_PRICE:
            return new OpenTick(timestamp, price);
        default:
            throw new IllegalStateException("Invalid ticktype");
        }
    }

    private Tick readQuoteRecord(int tickType, Date timestamp, byte typeByte, int sizeType) {
        double price = readPrice(typeByte);
        int size = readSize(sizeType);
        switch (tickType) {
        case Tick.TICKTYPE_ASK:
            return new AskTick(timestamp, price, size);
        case Tick.TICKTYPE_BID:
            return new BidTick(timestamp, price, size);
        case Tick.TICKTYPE_TRADE:
            return new TradeTick(timestamp, price, size);
        default:
            throw new IllegalStateException("Invalid ticktype");
        }
    }

    private int readShort() {
        return readByte() + (readByte() << 8);
    }

    private int readSize( int sizeType) {
        if (sizeType == TickUtils.BYTE_SIZE) {
            return readByte();
        } else if (sizeType == TickUtils.UINT16_SIZE) {
            return readShort();
        } else {
            return readInt();
        }
    }

    private Tick readSizeRecord(int tickType, Date timestamp, byte typeByte, int sizeType) {
        int size = readSize(sizeType);
        switch (tickType) {
        case Tick.TICKTYPE_VOLUME:
            return new VolumeTick(timestamp, size);
        case Tick.TICKTYPE_OPEN_INTEREST:
            return new OpenInterestTick(timestamp, size);
        default:
            throw new IllegalStateException("Invalid ticktype");
        }
    }

    private String readString() {
        byte[] ar;
        int length;
        int startIndex = 0;

        length = readByte();
        if (length == 0) return null;

        if (mVersion == 1) {
            // Version 1 was generated by VB6, and didn't include a Byte Order Marker.
            // But VB6 stores strings little-endian, so we need to add a little-endian BOM
            // to comply with RFC 2781 para 4.3
            ar = new byte[2 * length+2];
            ar[0] = (byte) 0xFF;
            ar[1] = (byte) 0xFE;
            startIndex=2;
        } else {
            ar = new byte[length];
        }

        for (int i = startIndex; i < ar.length; i++) {
            ar[i] = (byte) readByte();
        }
        
        try {
            return new String(ar, "UTF-16");
        } catch (java.io.UnsupportedEncodingException ex) {
            // will never happen since this encoding is supported on all platforms
            return null;
        }
        
    }

        private Date readTimestamp( byte typeByte) {
        Date timestamp;
        int diff;
        if ((typeByte  &  TickUtils.NO_TIMESTAMP) == 0) {
            diff = readShort();
            mCalendar.setTime(mPeriodStartTime);
            mCalendar.add(Calendar.MILLISECOND, diff);
            timestamp = mCalendar.getTime();
            mCurrentTimestamp = timestamp;
        } else {
            timestamp = mCurrentTimestamp;
        }
        return timestamp;
    }



}
