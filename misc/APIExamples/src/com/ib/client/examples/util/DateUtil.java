package com.ib.client.examples.util;

import java.text.SimpleDateFormat;
import java.util.Date;

/**
 * Date utility
 *
 * $Id$
 */
public class DateUtil {

    private static SimpleDateFormat sdf = new SimpleDateFormat("yyyyMMdd");
    private static final long MILLI_SEC_PER_DAY = 1000 * 60 * 60 * 24;

    public static long getCurrentTime() {
        return System.currentTimeMillis();
    }

    public static long getDeltaDays(String date) {
        long deltaDays = 0;

        try {
            Date d = sdf.parse(date);
            deltaDays = (d.getTime() - getCurrentTime()) / MILLI_SEC_PER_DAY;
        } catch (Throwable t) {
            System.out.println(" [Error] Problem parsing date: " + date + ", Exception: " + t.getMessage());
        }
        return deltaDays;
    }
}
