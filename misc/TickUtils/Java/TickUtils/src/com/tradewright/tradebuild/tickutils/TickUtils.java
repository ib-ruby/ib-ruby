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

import java.lang.String;
import java.util.Date;

/**
 * This class contains static members only. It cannot be instantiated.
 */
public final class TickUtils {

    /* ================================================================================
     * Enums
     * ================================================================================
     */

    /* ================================================================================
     * Types
     * ================================================================================
     **/

    /* ================================================================================
     * Interfaces
     * ================================================================================
     */

    /* ================================================================================
     * Constants
     * ================================================================================
     */
    static final int NEGATIVE_TICKS = 0x80;
    static final int NO_TIMESTAMP = 0x40;

    static final int OPERATION_BITS = 0x60;
    static final int OPERATION_SHIFTER = 5;
    static final int POSITION_BITS = 0x1F;
    static final int SIDE_BITS = 0x80;
    static final int SIDE_SHIFTER = 7;
    static final int SIZE_TYPE_BITS = 0x30;
    static final int SIZE_TYPE_SHIFTER = 4;
    static final int TICK_TYPE_BITS = 0xF;
    
    static final int BYTE_SIZE = 1;
    static final int UINT16_SIZE = 2;
    static final int UINT32_SIZE = 3;

    /* this is the encoding format identifier currently in use */
    static final String TICK_ENCODING_FORMAT_V2 = "urn:uid:b61df8aa-d8cc-47b1-af18-de725dee0ff5";

    /* this encoding format identifier was used in early non-public versions of this package */
    static final String TICK_ENCODING_FORMAT_V1 = "urn:tradewright.com:names.tickencodingformats.V1";

    /* the following is equivalent to TickEncodingFormatV1 (ie the encoding is identical) */
    static final String TICKFILE_FORMAT_TRADEBUILD_SQL = "urn:tradewright.com:names.tickfileformats.TradeBuildSQL";

    /* ================================================================================
     * Fields
     * ================================================================================
     */

    /*================================================================================
     * Constructors
     *================================================================================
     */

     private TickUtils() {}
     
     /* ================================================================================
     * Methods
     * ================================================================================
     */

    /**
     * Returns an object that implements the {@link com.tradewright.tradebuild.tickutils.TickDataDecoder TickDataDecoder} 
     * interface.
     * @param periodStartTime The time at the start of the period to which the encoded data segment applies. 
     * <p>
     * Note that this time is not stored in the encoded data, but all times are encoded relative to 
     * this time. Therefore it is necessary for the application to store this time along with the
     * encoded data segment to enable it to be subsequently decoded correctly.
     * <p>
     * @param tickSize The minimum tick size for the instrument to which the encoded data segment relates, 
     * at the time of the encoding.
     * <p>
     * Note that this value is not stored in the encoded data, but all prices are encoded as 
     * multiples of this value and relative to the base price. Therefore it is necessary for the 
     * application to store this time along with the encoded data segment to enable it to be 
     * subsequently decoded correctly. Note also that tick sizes can and do change from time to time,
     * so it is not sufficient to assume that the instrument's current tick size is the same as
     * the tick size at the time of encoding.
     * <p>
     * @param basePrice The first price recorded during the period to which the encoded data segment applies. 
     * <p>
     * Note that this price is not stored in the encoded data, but all prices are encoded relative to 
     * this price. Therefore it is necessary for the application to store this price along with the
     * encoded data segment to enable it to be subsequently decoded correctly. The value to be stored
     * can be obtained using the encoder object's 
     * {@link com.tradewright.tradebuild.tickutils.TickDataEncoder#getBasePrice getBasePrice} method.
     * <p>
     * @param data An encoded data segment.
     * <p>
     * @param encodingFormat A value uniquely identifying the format of the encoded data (as returned by the encoder object's
     * {@link com.tradewright.tradebuild.tickutils.TickDataEncoder#getEncodingFormatIdentifier getEncodingFormatIdentifier}
     * method).
     * <p>
     * @return An object that implements the {@link com.tradewright.tradebuild.tickutils.TickDataEncoder TickDataEncoder} 
     * interface.
     * <p>
     */
    public final static TickDataDecoder getTickDecoder( Date periodStartTime, double tickSize, double basePrice, byte[] data, String encodingFormat) {
        if (tickSize <= 0) throw new IllegalArgumentException("tickSize must be > 0");
        if (encodingFormat.equals(TICKFILE_FORMAT_TRADEBUILD_SQL)) encodingFormat = TICK_ENCODING_FORMAT_V1;
        if (encodingFormat.equals(TICK_ENCODING_FORMAT_V1) || 
            encodingFormat.equals(TICK_ENCODING_FORMAT_V2)) {
            return (TickDataDecoder) (new TickDataDecoderA(periodStartTime, basePrice, tickSize, encodingFormat, data));
        } else {
            throw new IllegalArgumentException("Invalid encoding format");
        }
    }

    /**
     * Returns an object that implements the {@link com.tradewright.tradebuild.tickutils.TickDataEncoder TickDataEncoder} 
     * interface.
     * @param periodStartTime The start of the time period for which the new encoder will encode tick data. 
     * <p>
     * Note that an encoder can only encode ticks for which the timestamp is not more than
     * 65535 milliseconds from this start time.
     * @param tickSize The minimum tick size for the instrument whose data is to be encoded.
     * @return An object that implements the {@link com.tradewright.tradebuild.tickutils.TickDataEncoder TickDataEncoder} 
     * interface.
     */
    public final static TickDataEncoder getTickEncoder( Date periodStartTime, double tickSize) {
        if (tickSize <= 0) throw new IllegalArgumentException("tickSize must be > 0");
        return (TickDataEncoder) new TickDataEncoderA(periodStartTime, tickSize);
    }

    /* ================================================================================
     * Helper Functions
     * ================================================================================
     */


}