/*
 * ListTextFilesApp.java
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
import java.io.FilenameFilter;
import java.util.ArrayList;
import java.util.Arrays;
import java.util.Collection;
import java.util.Iterator;
import java.util.Vector;

/**
 *This is just as set of static methods to list 
 *files in a directory
 * @author Dale Furrow
 */
public class ListTextFilesApp {
    private static  final String extensionSeparator = ".";
    private static final String pathSeparator = "\\";

    public static final FilenameFilter filter = new FilenameFilter() {

            public boolean accept(File dir, String name) {
                if(dir.isDirectory() && name.endsWith("txt")) {//example filter for FilenameFilter
                    return true;
                } else {
                return false;
                }

            }
        };


    public static File[] listFilesAsArray(
            File directory,
            FilenameFilter filter,
            boolean recurse) {
        Collection<File> files = listFiles(directory,
                filter, recurse);
        //Java4: Collection files = listFiles(directory, filter, recurse);

        File[] arr = new File[files.size()];
        return files.toArray(arr);
    }

    public static Collection<File> listFiles(
            // Java4: public static Collection listFiles(
            File directory,
            FilenameFilter filter,
            boolean recurse) {
        // List of files / directories
        Vector<File> files = new Vector<File>();
        // Java4: Vector files = new Vector();

        // Get files / directories in the directory
        File[] entries = directory.listFiles();

        // Go over entries
        for (File entry : entries) {


            // If there is no filter or the filter accepts the
            // file / directory, add it to the list
            if (filter == null || filter.accept(directory, entry.getName())) {
                files.add(entry); // files.add(directory)
            }

            // If the file is a directory and the recurse flag
            // is set, recurse into the directory
            if (recurse && entry.isDirectory()) {
                files.addAll(listFiles(entry, filter, recurse));
            }
        }

        // Return collection of files
        return files;
    }

     public static String filename(String fullPath) {  // gets filename without extension
        
        int dot = 0;
        int sep = 0;

        sep = fullPath.lastIndexOf(pathSeparator);

        if (fullPath.lastIndexOf(extensionSeparator) == -1
                || fullPath.lastIndexOf(extensionSeparator) < sep
                || fullPath.lastIndexOf(extensionSeparator) - sep == 1) {
            /*filename ends with dot (but has no extension),
            or has dot in directory path (but has no extension),
            or filename begins with a dot (but has no extension) */
            dot = fullPath.length();
        } else {
            dot = fullPath.lastIndexOf(extensionSeparator);
        }
        
        return fullPath.substring(sep + 1, dot);
    }

    public static String extension(String fullPath) {

        int dot = 0;
        int sep = 0;

        sep = fullPath.lastIndexOf(pathSeparator);

        if (fullPath.lastIndexOf(extensionSeparator) == -1
                || fullPath.lastIndexOf(extensionSeparator) < sep
                || fullPath.lastIndexOf(extensionSeparator) - sep == 1) {
            /*filename ends with dot (but has no extension),
            or has dot in directory path (but has no extension),
            or filename begins with a dot (but has no extension) */
            dot = fullPath.length();
            return null;
        } else {
            dot = fullPath.lastIndexOf(extensionSeparator);
            return fullPath.substring(dot + 1);
        }
    }
    
    public static ArrayList<String> listFilenames (
            File directory,
            FilenameFilter filter,
            boolean recurse) {
        ArrayList<String> outFiles = new ArrayList<String>();
        File[] FileArray = listFilesAsArray( directory ,filter, true);
        Arrays.sort(FileArray);
        for (File file : FileArray){
            if(!file.isDirectory()) outFiles.add(filename(file.getPath()));
        }
        return outFiles;
        
    }






//    public static void main (String[] args){
//
//       ArrayList<String> outArrayList = listFilenames(new File("E:\\Temp"), filter, true);
//        for (Iterator<String> it = outArrayList.iterator(); it.hasNext();) {
//            String string = it.next();
//            System.out.println(string);
//        }
//
//    }
}

