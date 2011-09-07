/*
 *  DateUtil.java
 *  Copyright (C) 2011 Dale Furrow
 *  dkfurrow@google.com
 *
 *  This program is free software; you can redistribute it and/or
 *  modify it under the terms of the GNU Lesser General Public License
 *  as published by the Free Software Foundation; either version 3
 *  of the License, or (at your option) any later version.
 *
 *  This program is distributed in the hope that it will be useful,
 *  but WITHOUT ANY WARRANTY; without even the implied warranty of
 *  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 *  GNU Lesser General Public License for more details.
 *
 *  You should have received a copy of the GNU Lesser General Public License
 *  along with this program; if not, a copy may be found at
 *  http://www.gnu.org/licenses/lgpl.html
 */
package com.ib.client.examples.util;

import java.text.SimpleDateFormat;
import java.util.ArrayList;
import java.util.Calendar;
import java.util.Date;
import java.util.GregorianCalendar;

/**
 * Set of Useful date utilities.
 *
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

     
    /**Returns set of Fridays between two dates
     * @param fromDate
     * @param toDate
     * @return
     * @throws Exception
     */
    public static ArrayList<Date> getFridays(Date fromDate, Date toDate) throws Exception{
        ArrayList<Date> Fridays = new ArrayList<Date>();
        // gets first friday after date, with hour equal to 15 (closing time
        // for NYSE, Central Time)
        Date firstFriday = getFriday(fromDate, 15, 0, "next"); 
        GregorianCalendar gcF = new GregorianCalendar();
        gcF.setTime(firstFriday);

        if(toDate.after(firstFriday)) Fridays.add(firstFriday);
        //accounts for case of no Friday between fromDate and toDate

        Integer daysBetwI = new Integer(getDaysBetween(firstFriday, toDate));
        int numFridays = (int) Math.floor(daysBetwI.doubleValue() / 7.0);
        for (int i = 0; i < numFridays; i++) {
            gcF.add(Calendar.DATE, 7);
            Fridays.add(gcF.getTime());
        }
        return Fridays;
    }

    
    /**Returns either the previous or next friday, with specified hour and
     * minute
     * @param inDate input date
     * @param outHour output hour
     * @param outMinute output minute
     * @param retType either "next" or "previous"
     * @return Date of applicable Friday at specified hour and minute
     * @throws Exception
     */
    public static Date getFriday(Date inDate, int outHour, int outMinute, String retType) throws Exception{
        Date Friday = new Date();
        GregorianCalendar gc = new GregorianCalendar();
        gc.setTime(inDate);
        gc.set(gc.get(Calendar.YEAR), gc.get(Calendar.MONTH),
                gc.get(Calendar.DAY_OF_MONTH), outHour, outMinute, 0);

        if(retType.equals("next")){
            if(gc.get(Calendar.DAY_OF_WEEK) == Calendar.FRIDAY){
                return gc.getTime();
            } else {
                gc.add(Calendar.DATE, gc.get(Calendar.DAY_OF_WEEK) == Calendar.SATURDAY ? 6
                        : Calendar.FRIDAY - gc.get(Calendar.DAY_OF_WEEK) );
                return gc.getTime();
            }
        } else if(retType.equals("previous")){
            if(gc.get(Calendar.DAY_OF_WEEK) == Calendar.FRIDAY){
                return gc.getTime();
            } else {
                gc.add(Calendar.DATE, gc.get(Calendar.DAY_OF_WEEK) == Calendar.SATURDAY ? -1
                        : -gc.get(Calendar.DAY_OF_WEEK) - 1 );
                return gc.getTime();
            }
        } else {
            throw new Exception("Invalid Entry");
        }
    }

     /**
     * gets days between any two dates (integer form) regardless of order
     * @param date1 first date (Date)
     * @param date2 second date (Date)
     * @return
     */
    public static int getDaysBetween( Date date1, Date date2 ) {
	GregorianCalendar d1 = new GregorianCalendar();
        d1.setTime(date1);
        GregorianCalendar d2 = new GregorianCalendar();
        d2.setTime(date2);

            if ( d1.after(d2) ) {
			// swap dates so that d1 is start and d2 is end
			GregorianCalendar swap = d1;
			d1 = d2;
			d2 = swap;
		}

		int days = d2.get(Calendar.DAY_OF_YEAR) - d1.get(Calendar.DAY_OF_YEAR);
		int y2   = d2.get(Calendar.YEAR);
		if (d1.get(Calendar.YEAR) != y2) {
			d1 = (GregorianCalendar) d1.clone();
			do {
				days += d1.getActualMaximum(Calendar.DAY_OF_YEAR);
				d1.add(Calendar.YEAR, 1);
			} while (d1.get(Calendar.YEAR) != y2);
		}
		return days;
	}



}



