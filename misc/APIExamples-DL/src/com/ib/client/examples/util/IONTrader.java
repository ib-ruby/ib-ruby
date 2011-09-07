/*
 *  IONTrader.java
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

import java.io.File;
import java.io.FileWriter;
import java.io.PrintWriter;
import java.text.ParseException;
import java.text.SimpleDateFormat;
import java.util.ArrayList;
import java.util.Calendar;
import java.util.Date;
import java.util.GregorianCalendar;
import java.util.Iterator;

/**
 * Class which reads data from datastream, converts to string output in order
 * to append datafile. Contains static methods to  determine last data of 
 * NT-compatible text file, append NT-compatible text file.
 * @author Dale Furrow
 */
public class IONTrader {
    private int reqID;
    private String outInfo;
    
    public IONTrader(int reqId, String dateString,
             double open, double high, double low, double close, 
             int volume) throws ParseException{
        this.reqID = reqId;
        this.outInfo = NTHDLine(dateString, open, high, low, close, volume);
        
    }
    
    public String getOutInfo(){
        return this.outInfo;
    }




     /** generates NT-compatible String from IB-compatible input data.
     * @param dateString input dataString from IB
     * @param open data from IB Historical Data Stream
     * @param high data from IB Historical Data Stream
     * @param low data from IB Historical Data Stream
     * @param close data from IB Historical Data Stream
     * @param volume data from IB Historical Data Stream
     * @return String compatible with NT-data
     * @throws ParseException
     */
    static public String NTHDLine(String dateString,
             double open, double high, double low, double close,
             int volume) throws ParseException {

         
             ArrayList<String> outStringAL = new ArrayList<String>();
             SimpleDateFormat sdfIn = new SimpleDateFormat("yyyyMMdd  HH:mm:ss"); //IB brings in format w/ 2 spaces
             SimpleDateFormat sdfOut = new SimpleDateFormat("yyyyMMdd HH:mm:ss"); //programs need format w/ 1 space
             //parse input String, add one minute for compatibility w/ NTrader (minute ending convention)
             Date thisDate = sdfIn.parse(dateString);
             Long thisDateAdjustL = thisDate.getTime() + 60000L; //add one minute
             String outDateString = sdfOut.format(new Date(thisDateAdjustL));

             outStringAL.add(outDateString);
             outStringAL.add(String.valueOf(open));
             outStringAL.add(String.valueOf(high));
             outStringAL.add(String.valueOf(low));
             outStringAL.add(String.valueOf(close));
             outStringAL.add(String.valueOf(volume));
             //replace comma + space w/semicolon
             String outString = outStringAL.toString();
             String regex1 = ", ";
             String replace1 = ";";
             outString = outString.replaceAll(regex1, replace1);
             String regex2 = "[\\[\\]]"; //left or right brackets
             String replace2 = "";
             outString = outString.replaceAll(regex2, replace2);
             return outString;
     }

      /** appends string to datafile
     * @param addData line of HLOC data
     * @param outFile outfile to which data are appended 
     */
    public static void appendBaseFile(ArrayList<String> addData, File outFile) {
        PrintWriter outputStream = null;
        SimpleDateFormat sdfOut = new SimpleDateFormat("yyyyMMdd HH:mm:ss");

        try {
            outputStream = new PrintWriter(new FileWriter(outFile, true));
            Date lastDate = new Date();

            if(outFile.length() > 0L){ // file contains a last date
                lastDate = getLastNTDate(outFile);    
            } else { //last date equals the Friday after one year ago
                Long lastDateL = getLastNTDate(outFile).getTime() - 604800000L; //date minus 1 week.
                lastDate = new Date(lastDateL);
            }

            for (Iterator<String> it = addData.iterator(); it.hasNext();) {
                String inString = it.next();
                Date inDate = sdfOut.parse(inString.substring(0, 17));
                if (inDate.after(lastDate)) outputStream.println(inString);
            }
        } catch (Exception exception) {
        } finally {
            outputStream.close();
        }

    }

/**returns last date of NT-compatible  data file
 * @param ntFile File to query
 * @return Last HLOC date in data file
 * @throws Exception
 */
public static Date getLastNTDate(File ntFile) throws Exception{

        if (ntFile.length() > 0L) {
            RevFileReaderSimple revReader = new RevFileReaderSimple(ntFile.getAbsolutePath());
            String lastLine = "**";

            while (lastLine.length() < 3) {
                lastLine = revReader.readLine();
            }

            lastLine = lastLine.substring(0, 17);
            SimpleDateFormat sdfOut = new SimpleDateFormat("yyyyMMdd HH:mm:ss");
            return sdfOut.parse(lastLine);
        } else { //no "base" file, return 2 fridays from one year ago
            GregorianCalendar gc = new GregorianCalendar();
            gc.add(Calendar.YEAR, -1);
            gc.setTime(DateUtil.getFriday(gc.getTime(), 15, 0, "next"));
            gc.add(Calendar.DATE, 7);
            return gc.getTime();
        }

    }




}


