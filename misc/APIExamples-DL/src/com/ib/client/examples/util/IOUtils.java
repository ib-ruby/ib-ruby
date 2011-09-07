/*
 * IOMethods.java
 *  Copyright (C) 2010 Dale Furrow
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

import java.io.BufferedReader;
import java.io.File;
import java.io.FileNotFoundException;
import java.io.FileReader;
import java.io.FileWriter;
import java.io.IOException;
import java.io.PrintStream;
import java.io.PrintWriter;
import java.util.ArrayList;
import java.util.Iterator;
import java.util.logging.Level;
import java.util.logging.Logger;

/**
 * generic methods to produce file output from ArrayLists of String Arrays
 * @author Dale Furrow
 * @version 1.0
 * @since 1.0
 */
public final class IOUtils {

    private IOUtils(){

    }

/**
 * reads CSV file into ArrayList of Strings
 * @param readFile file to be read from
 * @return ArrayList of Strings
 */
public static ArrayList<String[]> readCSVIntoArrayList(File readFile) {
        BufferedReader csvRead = null;
        ArrayList<String[]> readArray = new ArrayList<String[]>();
        String newLine = new String();
        try {
            csvRead = new BufferedReader(new FileReader(readFile));
            while ((newLine = csvRead.readLine()) != null) {
                String[] parsedNewLine = parseCSVLine(newLine);
                readArray.add(parsedNewLine);
            }
            return readArray;
        } catch (FileNotFoundException ex) {
            Logger.getLogger(IOUtils.class.getName()).log(Level.SEVERE, null, ex);
            return null;
        } catch (java.io.IOException ex1) {
            Logger.getLogger(IOUtils.class.getName()).log(Level.SEVERE, null, ex1);
            return null;
        } finally {
            try {
                csvRead.close();
            } catch (IOException ex) {
                Logger.getLogger(IOUtils.class.getName()).log(Level.SEVERE, null, ex);
            }
        }

    }

/**
 * reads ini file from home directory
 * @param readFile file to read
 * @return text of ini file (path for reporting)
 */
public static String readIniFile(File readFile) {
        BufferedReader iniRead = null;
        String filePath = new String();
        String newLine = new String();
        try {
            iniRead = new BufferedReader(new FileReader(readFile));
            while ((newLine = iniRead.readLine()) != null) {
                filePath = newLine;
            }
            return filePath;
        } catch (FileNotFoundException ex) {
            Logger.getLogger(IOUtils.class.getName()).log(Level.SEVERE, null, ex);
            return null;
        } catch (java.io.IOException ex1) {
            Logger.getLogger(IOUtils.class.getName()).log(Level.SEVERE, null, ex1);
            return null;
        } finally {
            try {
                iniRead.close();
            } catch (IOException ex) {
                Logger.getLogger(IOUtils.class.getName()).log(Level.SEVERE, null, ex);
            }
        }
    }

/**
 * write ini file
 * @param pathString String representation of report path
 */
public static void writeIniFile(String pathString) {
        PrintWriter outputStream = null;
        File iniFile = new File(new File(".").getAbsolutePath() + "invextension.ini");
        try {
            outputStream = new PrintWriter(new FileWriter(iniFile));
            outputStream.println(pathString);
        } catch (IOException ex) {
            Logger.getLogger(IOUtils.class.getName()).log(Level.SEVERE, null, ex);
        } finally {
            outputStream.close();
        }
    }

    public static String[] parseCSVLine(String s) {
        return  s.split(",\\s*");
    }

    /**
     * Writes data to CSV file
     * @param header header text for csv file
     * @param writeArrayList body of csv file
     * @param outputFile file to be written to
     */
    public static void writeArrayListToCSV(StringBuffer header ,ArrayList<String[]> writeArrayList, File outputFile) {
        PrintWriter outputStream = null;
        try {
            outputStream = new PrintWriter(new FileWriter(outputFile));
            if(!header.equals(null)) outputStream.println(header.toString());
            for (Iterator<String[]> it = writeArrayList.iterator(); it.hasNext();) {
                String outputLine = writeCSVLine(it.next());
                outputStream.println(outputLine);
            }
        } catch (IOException ex) {
            Logger.getLogger(IOUtils.class.getName()).log(Level.SEVERE, null, ex);
        } finally {
            outputStream.close();
        }
    }

    /**
     * Writes data to CSV file
     * @param writeArrayList body of csv file
     * @param outputFile file to be written to
     */
    public static void appendArrayListToCSV(ArrayList<String[]> writeArrayList, File outputFile) {
        PrintWriter outputStream = null;
        try {
            outputStream = new PrintWriter(new FileWriter(outputFile, true)); //append mode
            for (Iterator<String[]> it = writeArrayList.iterator(); it.hasNext();) {
                String outputLine = writeCSVLine(it.next());
                outputStream.println(outputLine);
            }
        } catch (IOException ex) {
            Logger.getLogger(IOUtils.class.getName()).log(Level.SEVERE, null, ex);
        } finally {
            outputStream.close();
        }
    }



    public static void writeArrayListToScreen(ArrayList<String[]> readArrrayList) {

        for (Iterator<String[]> it = readArrrayList.iterator(); it.hasNext();) {
            String[] tempStrings = it.next();
            String outputString = new String();
            for (String eachString : tempStrings) {
                outputString = outputString + eachString + " ";
            }
            System.out.println(outputString);
            outputString = null;
        }
    }

    /**
     * writes single csv line from array of strings
     * @param inputStrings input string array
     * @return string w/ commas placed between elements
     */
    public static String writeCSVLine(String[] inputStrings) {
        String outputString = new String();

        for (int i = 0; i < inputStrings.length; i++) {
            if (i == inputStrings.length - 1) {
                outputString = outputString + inputStrings[i]; // + "\b\n"
            } else {
                outputString = outputString + inputStrings[i] + ",";
            }
        }
        return outputString;
    }

    /**
     * generic method to write stringbuffer to file
     * @param writeSB StringBuffer to write
     * @param outputFile file to be written to
     */
    public static void writeResultsToFile(StringBuffer writeSB, File outputFile) {
        PrintWriter outputStream = null;

        try {
            outputStream = new PrintWriter(new FileWriter(outputFile));
            outputStream.print(writeSB.toString());

        } catch (IOException ex) { 
           PrintStream output = System.err;
           output.println("File Cannot Be Opened!");
        } finally {
            outputStream.close();
        }
    }
}
