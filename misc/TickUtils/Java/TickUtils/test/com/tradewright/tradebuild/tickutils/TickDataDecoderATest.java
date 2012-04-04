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

/*
 * TickDataDecoderATest.java
 * JUnit based test
 *
 * Created on 28 February 2008, 22:22
 */

package com.tradewright.tradebuild.tickutils;

import junit.framework.*;
import java.util.Calendar;
import java.util.Date;
import java.text.SimpleDateFormat;

public class TickDataDecoderATest extends TestCase {
    
    SimpleDateFormat mDf = new SimpleDateFormat("dd/MM/yyyy H:m:s.SSS");
    
    protected void setUp() throws Exception {
    }

    protected void tearDown() throws Exception {
    }

    /**
     * Test version 1 decoder
     */
    public void testDecodeV1() {
        System.out.println("decodeV1");

        try {
            byte[] data = {(byte)0x11, (byte)0x97, (byte)0x00, (byte)0x00, (byte)0x80,
                            (byte)0x21, (byte)0xE9, (byte)0x00, (byte)0x00, (byte)0x00, (byte)0x01, 
                            (byte)0xA0, (byte)0xF5, (byte)0x00, (byte)0x01, (byte)0xFF, (byte)0x7F, 
                            (byte)0x27, (byte)0x88, (byte)0x05, (byte)0x00, (byte)0x00, (byte)0x80, 
                            (byte)0x38, (byte)0x8A, (byte)0x05, (byte)0x76, (byte)0x81, (byte)0xC1, (byte)0x21, 
                            (byte)0x82, (byte)0xC4, (byte)0x05, (byte)0x32, 
                            (byte)0x51, (byte)0x01, (byte)0x0B, 
                            (byte)0x50, (byte)0x04, (byte)0x0F, 
                            (byte)0x95, (byte)0xC5, (byte)0xE7, (byte)0xA3, (byte)0x1E, (byte)0x1B, (byte)0x04, (byte)0x49, (byte)0x00, (byte)0x53, (byte)0x00, (byte)0x4C, (byte)0x00, (byte)0x44, (byte)0x00,
                            (byte)0x39, (byte)0x5F, (byte)0xEA, (byte)0x30, (byte)0xBD, (byte)0xF9, (byte)0x02};


            TickDataDecoder tdd = TickUtils.getTickDecoder(mDf.parse("14/12/2007 08:00:00.000"), 0.5, 6342.5, data, TickUtils.TICK_ENCODING_FORMAT_V1);

            StringBuilder sb = new StringBuilder(1024);

            Tick tick = tdd.getNextTick();

            while (tick != null) {
                sb.append(tick.toString());
                sb.append('\n');
                tick = tdd.getNextTick();
            }

            String expResult = "2007/12/14 08:00:00.151,A,6342.5,128" + '\n' +
                                "2007/12/14 08:00:00.233,A,6342.5,256" + '\n' +
                                "2007/12/14 08:00:00.245,B,6342.0,32767" + '\n' +
                                "2007/12/14 08:00:01.416,T,6342.5,32768" + '\n' +
                                "2007/12/14 08:00:01.418,V,566329718" + '\n' +
                                "2007/12/14 08:00:01.476,C,6317.5" + '\n' +
                                "2007/12/14 08:00:01.476,A,6343.0,11" + '\n' +
                                "2007/12/14 08:00:01.476,B,6344.5,15" + '\n' +
                                "2007/12/14 08:00:59.333,D,3,ISLD,1,1,6327.5,27" + '\n' +
                                "2007/12/14 08:00:59.999,I,49921328" + '\n' ;

            String result = new String(sb);
            assertEquals(expResult, result);
        } catch (java.text.ParseException ex) {
            fail("ParseException thrown");
        }
    }
    /**
     * Test version 2 decoder
     */
    public void testDecodeV2() {
        System.out.println("decodeV2");

        try {
            byte[] data = {(byte)0x11, (byte)0x97, (byte)0x00, (byte)0x00, (byte)0x80,
                            (byte)0x21, (byte)0xE9, (byte)0x00, (byte)0x00, (byte)0x00, (byte)0x01, 
                            (byte)0x8A, (byte)0xEE, (byte)0x00, (byte)0x82, (byte)0x83, 
                            (byte)0xA0, (byte)0xF5, (byte)0x00, (byte)0x01, (byte)0xFF, (byte)0x7F, 
                            (byte)0x27, (byte)0x88, (byte)0x05, (byte)0x00, (byte)0x00, (byte)0x80, 
                            (byte)0x38, (byte)0x8A, (byte)0x05, (byte)0x76, (byte)0x81, (byte)0xC1, (byte)0x21, 
                            (byte)0x82, (byte)0xC4, (byte)0x05, (byte)0x32, 
                            (byte)0x51, (byte)0x01, (byte)0x0B, 
                            (byte)0x50, (byte)0x04, (byte)0x0F, 
                            (byte)0x95, (byte)0xC5, (byte)0xE7, (byte)0xA3, (byte)0x1E, (byte)0x1B, (byte)0x0A, (byte)0xFE, (byte)0xFF, (byte)0x00, (byte)0x49, (byte)0x00, (byte)0x53, (byte)0x00, (byte)0x4C, (byte)0x00, (byte)0x44, 
                            (byte)0x39, (byte)0x5F, (byte)0xEA, (byte)0x30, (byte)0xBD, (byte)0xF9, (byte)0x02};


            TickDataDecoder tdd = TickUtils.getTickDecoder(mDf.parse("14/12/2007 08:00:00.000"), 0.5, 6342.5, data, TickUtils.TICK_ENCODING_FORMAT_V2);

            StringBuilder sb = new StringBuilder(1024);

            Tick tick = tdd.getNextTick();

            while (tick != null) {
                sb.append(tick.toString());
                sb.append('\n');
                tick = tdd.getNextTick();
            }

            String expResult = "2007/12/14 08:00:00.151,A,6342.5,128" + '\n' +
                                "2007/12/14 08:00:00.233,A,6342.5,256" + '\n' +
                                "2007/12/14 08:00:00.238,O,6021.0" + '\n' +
                                "2007/12/14 08:00:00.245,B,6342.0,32767" + '\n' +
                                "2007/12/14 08:00:01.416,T,6342.5,32768" + '\n' +
                                "2007/12/14 08:00:01.418,V,566329718" + '\n' +
                                "2007/12/14 08:00:01.476,C,6317.5" + '\n' +
                                "2007/12/14 08:00:01.476,A,6343.0,11" + '\n' +
                                "2007/12/14 08:00:01.476,B,6344.5,15" + '\n' +
                                "2007/12/14 08:00:59.333,D,3,ISLD,1,1,6327.5,27" + '\n' +
                                "2007/12/14 08:00:59.999,I,49921328" + '\n' ;

            String result = new String(sb);
            assertEquals(expResult, result);
        } catch (java.text.ParseException ex) {
            fail("ParseException thrown");
        }
    }
    
}
