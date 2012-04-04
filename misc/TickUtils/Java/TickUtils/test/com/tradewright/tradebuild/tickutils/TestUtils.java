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
 * TestUtils.java
 *
 * Created on 28 February 2008, 14:46
 *
 */

package com.tradewright.tradebuild.tickutils;

public class TestUtils {
    
    static final String hexChars[] = {"0", "1", "2", "3", 
                        "4", "5", "6", "7", 
                        "8", "9", "A", "B", 
                        "C", "D", "E", "F"};
    
    static String byteArrayToHexString(byte[] ar) {
        if (ar == null || ar.length <= 0)
            return null;

        StringBuilder sb = new StringBuilder(ar.length * 2);

        for (int i =0; i < ar.length; i++) {
            sb.append(hexChars[(ar[i] & 0xF0) >>> 4]);
            sb.append(hexChars[ar[i] & 0x0F]);
        }
        return new String(sb);
    }
}
