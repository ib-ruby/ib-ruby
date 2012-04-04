This zip file contains software in source and binary form for encoding and decoding market tick 
data to and from byte arrays, suitable for storage in databases (as BLOBs) or other file types.

IMPORTANT!!!!!!! 
This material is made available under the GNU GPL v3 license. A copy of the license may be found 
in the license.txt file.

Anyone wishing to use this software or a derivative of it in a commercial product must contact me 
for an alternative licensing arrangement. Email me at: rlking@aultan.com

Two compatible versions of the software are provided, written in VB6 and Java.


VB6 Version
-----------

The VB6 version can be found in the TickUtils\VB6 folder tree. If you don't want to have to build 
the project yourself, the compiled component is to be found at:

    TickUtils\VB6\TickUtils\TickUtils26.dll

Before using this dll, you will have to register it in Windows using the following command issued 
in the folder where the dll is located (you can move it to another folder first if you want to):

    regsvr32 TickUtils26.dll

To use this component in a VB6 or VBA project, set a reference to:

    TradeWright TradeBuild Tick Data Encoding/Decoding Utilities v2.6

This component can also be used with .Net programs. In the Add Reference dialog, click the COM tab 
and locate the component with the same name as above.

Full documentation for this component is to be found in:

    TickUtils\VB6\TickUtils\doc\TickUtils26.chm


Java Version
------------

The Java version is in the form of a NetBeans 5.5 project, located in:

    TickUtils\Java\TickUtils

If you don't want to build the project yourself, a jar file is included in:

    TickUtils\Java\TickUtils\dist\TickUtils.jar

Full JavaDoc documentation for this component is included. Open the following file in your browser:

    TickUtils\Java\TickUtils\dist\javadoc\index.html

The project includes some JUnit tests.


Support
-------

If you have any problems, comments or suggestions regarding this software, email me 
at: rlking@aultan.com



Richard King
4 March 2008