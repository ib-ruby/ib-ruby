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
 * TickDataEncoderATest.java
 * JUnit based test
 *
 * Created on 28 February 2008, 15:02
 */

package com.tradewright.tradebuild.tickutils;

import junit.framework.*;
import java.io.ByteArrayOutputStream;
import java.util.ArrayList;
import java.util.Calendar;
import java.util.Date;
import java.text.SimpleDateFormat;

public class TickDataEncoderATest extends TestCase {
    
    SimpleDateFormat mDf = new SimpleDateFormat("dd/MM/yyyy H:m:s.SSS");
    
    public TickDataEncoderATest(String testName) {
        super(testName);
    }

    protected void setUp() throws Exception {
    }

    protected void tearDown() throws Exception {
    }

    /**
     * Test of encodeAsk method, of class com.tradewright.tradebuild.tickutils.TickDataEncoderV1.
     */
    public void testEncode() {
        System.out.println("encode");
        
        try {
            TickDataEncoder tde = TickUtils.getTickEncoder(mDf.parse("14/12/7 08:00:00.000"), 0.5);
            tde.encodeAsk(mDf.parse("14/12/7 08:00:00.151"), 6342.5, 128);
            tde.encodeAsk(mDf.parse("14/12/7 08:00:00.233"), 6342.5, 256);
            tde.encodeOpen(mDf.parse("14/12/7 08:00:00.238"), 6021);
            tde.encodeBid(mDf.parse("14/12/7 08:00:00.245"), 6342.0, 32767);
            tde.encodeTrade(mDf.parse("14/12/7 08:00:01.416"), 6342.5, 32768);
            tde.encodeVolume(mDf.parse("14/12/7 08:00:01.418"), 566329718);
            tde.encodeClose(mDf.parse("14/12/7 08:00:01.476"), 6317.5);
            tde.encodeAsk(mDf.parse("14/12/7 08:00:01.476"), 6343, 11);
            tde.encodeBid(mDf.parse("14/12/7 08:00:01.476"), 6344.5, 15);
            tde.encodeMarketDepthData(mDf.parse("14/12/7 08:00:59.333"), 3, "ISLD", 1, 1, 6327.5, 27);
            tde.encodeOpenInterest(mDf.parse("14/12/7 08:00:59.999"), 49921328);

            String expResult = "119700008021E9000000018AEE008283A0F50001FF7F278805000080388A057681C12182C4053251010B50040F95C5E7A31E1B0AFEFF00490053004C0044395FEA30BDF902";
            String result = TestUtils.byteArrayToHexString(tde.getEncodedData());

            assertEquals(expResult, result);
        } catch (java.text.ParseException ex) {
            fail("ParseException thrown");
        }
    }

}