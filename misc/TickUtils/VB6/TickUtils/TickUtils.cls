VERSION 1.0 CLASS
BEGIN
  MultiUse = -1  'True
  Persistable = 0  'NotPersistable
  DataBindingBehavior = 0  'vbNone
  DataSourceBehavior  = 0  'vbNone
  MTSTransactionMode  = 0  'NotAnMTSObject
END
Attribute VB_Name = "TickUtils"
Attribute VB_GlobalNameSpace = True
Attribute VB_Creatable = True
Attribute VB_PredeclaredId = False
Attribute VB_Exposed = True
' Copyright 2008 Richard L King
'
' This file is part of TradeBuild Tick Utilities Package.
'
' TradeBuild Tick Utilities Package is free software: you can redistribute it
' and/or modify it under the terms of the GNU General Public License as
' published by the Free Software Foundation, either version 3 of the License,
' or (at your option) any later version.
'
' TradeBuild Tick Utilities Package is distributed in the hope that it will
' be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of
' MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
' GNU General Public License for more details.
'
' You should have received a copy of the GNU General Public License
' along with TradeBuild Tick Utilities Package.  If not, see
' <http://www.gnu.org/licenses/>.
 
Option Explicit

''
' The TickUtils class is a GlobalMultiuse class, which means that you don't have to create
' an instance of it to use its methods and properties. Simply call them directly.
'
'
' <h2>About the TickUtils26 component</h2>
'
' The TickUtils26 component provides mechanisms for encoding market tick data into a compressed binary
' format for storage in files or databases.
' <p>
' The functionality is provided by two interfaces,
' <code>TickDataEncoder</code> and <code>TickDataDecoder</code>,
' together with a pair of global factory methods that create instances of classes that
' implement these interfaces - these methods are
' <code>CreateTickEncoder</code> and <code>CreateTickDecoder</code>.
'
' <p>
' The encoding used places strict limits on the time span covered by an encoder: this
' is because tick times are recorded as a number of milliseconds from the start of the
' encoding period, and these values are recorded as 16-bit unsigned integers: the maximum
' timespan is therefore 65535 millseconds. Once this limit has been reached, the encoded
' data must be retrieved from the encoder and written to storage, and a new encoder must
' then be created.  The expectation is that tick data recording programs will limit
' individual stored segments of encoded data to an interval such as 30 seconds or 1 minute,
' and that these segments will be stored in a variable length container such as a BLOB
' (Binary Large Object) column in a database row.
'
' To summarise the use of this component:
'
' <h4>Encoding</h4>
'
' 1. At the start of each encoding interval (say at the start of each minute or each 30 seconds,
' but not longer than one minute), create a new encoder object by calling
' <code>CreateTickEncoder</code> global method.
'
' 2. As each tick arrives, encode it by calling the appropriate method of the encoder object,
' depending on the type of tick.
'
' 3. At the end of the encoding period, obtain from the encoder object the base price, the
' encoded data and the encoding format identifier, and write these to your data store along
' with the period start time and the ticksize. Then discard the existing encoder object,
' and return to step 1.
'
' <h4>Decoding</h4>
'
' 1. Retrieve from your data store the encoded data, and the corresponding period start time,
' base price, tick size and encoding format identifier.
'
' 2. Create a new decoder object using the <code>CreateTickDecoder</code> global method.
'
' 3. Extract the next tick from the decoder by calling its <code>getNextTick</code> method.
'
' 4. Process the tick as required by your program.
'
' 5. Repeat from step 3 until <code>getNextTick</code> indicates that there are no further
' ticks.
'
' <h2>Encoding format</h2>
'
' Details of the encoding scheme are provided here for completeness, and to enable developers
' to produce compatible software in other languages.
'
' No understanding of the encoding scheme is necessary to use this software.
'
' The encoding format identifier for this encoding scheme is this URN:
' <p>
'  urn:uid:b61df8aa-d8cc-47b1-af18-de725dee0ff5
' <p>
' Future enhancements to this encoding scheme, or different encoding schemes, will have
' different encoding format identifiers.
'
' An encoded data segment is a byte array, consisting of a series of variable-length records. Each
' record encodes a single tick.
' <p>
' A record consists of an initial byte, called the type byte, followed by zero or more fields
' containing the tick&#39;s attributes. The fields included in any particular record depend on the
' type of the tick encoded in the record. The following types of field are defined:
' <pre>
'      Timestamp field
'      Price field
'      Size field
'      Side/operation/position field
'      Marketmaker field
' </pre>
'
' Ask ticks, bid ticks, and trade ticks contain the following fields:
' <pre>
'      [timestamp] price size
' </pre>
'
' Close ticks, high ticks, low ticks and open ticks contain the following fields:
' <pre>
'      [timestamp] price
' </pre>
'
' Open interest and volume ticks contain the following fields:
' <pre>
'      [timestamp] size
' </pre>
'
' Market depth ticks contain the following fields:
' <pre>
'      [timestamp] side/operation/position price size marketmaker
' </pre>
'
' Market depth reset ticks contain the following fields:
' <pre>
'      [timestamp]
' </pre>
'
' <h3>Type byte format</h3>
'
' The type byte indicates the tick&#39;s type, and has some additional flags that are used to optimise
' the encoding. Its format is:
' <pre>
'      Bit 7       NegativeTicks       If set, indicates that the price for this tick is below
'                                      the segment's base price.
'
'      Bit 6       NoTimestamp         If set, indicates that this record contains no timestamp
'                                      field, meaning that the timestamp is the same as for the
'                                      previous record (or is the same as the start time for
'                                      the segment if this is the first record)
'
'      Bits 4-5    SizeTypeBits        Indicates how the size field for this record (if any) has
'                                      been encoded. The following values are used:
'
'                                      ByteSize (1)        encoded as an unsigned 8-bit value
'                                      UInt16Size (2)      encoded as an unsigned little-endian
'                                                          16-bit value
'                                      UInt32Size (3)        encoded as an unsigned little-endian
'                                                          32-bit value
'
'      Bits 0-3    TickTypeBits        The type of the tick encoded in this record. The following
'                                      values are used:
'
'                                      TickTypes.TickTypeBid (0)
'                                      TickTypes.TickTypeAsk (1)
'                                      TickTypes.TickTypeClosePrice (2)
'                                      TickTypes.TickTypeHighPrice (3)
'                                      TickTypes.TickTypeLowPrice (4)
'                                      TickTypes.TickTypeMarketDepth (5)
'                                      TickTypes.TickTypeMarketDepthReset (6)
'                                      TickTypes.TickTypeTrade (7)
'                                      TickTypes.TickTypeVolume (8)
'                                      TickTypes.TickTypeOpenInterest (9)
'                                      TickTypes.TickTypeOpenPrice (10)
'
'                                      Other tick types may be added in future. Note that the maximum
'                                      value of 'Tick type' is 15, but there may be a need for more
'                                      tick types than this. Therefore the value 15 is reserved to
'                                      indicate that the tick type is encoded using an extension
'                                      mechanism. This mechanism is not currently defined.
' </pre>
'
' <h3>Timestamp field format</h3>
'
' The timestamp field is encoded as a little-endian unsigned 16-bit integer value representing the number of
' milliseconds between the start of the encoding period and the time of the tick.
'
' <h3>Price field format</h3>
'
' The base price for an encoded segment is the first price value encountered during encoding.
'
' The price field is stored as an integer value, being the absolute value of the difference between the tick price
' and the base price, divided by the minimum tick size (call this value numTicks). If numticks is negative, then
' NEGATIVE_TICKS in the type byte is set. The absolute value of numticks (|numTicks|) is then encoded as follows:
' <p>
' - if |numTicks| is less than 128, then it is stored in a single byte
' <p>
' - otherwise, |numTicks| is stored as a big-endian 16-bit value, with bit 15 set to 1.
' <p>
' Note that this encoding scheme enables the decoder to detect whether the value is stored in one byte or two by
' examining the first bit of the first byte.
' <p>
' Note also that this scheme limits |numticks| to a maximum of 32767. Therefore should there be more than 32767 ticks between the
' first price encountered and any subsequent price during an encoding period, the encoding will fail. Given the
' very short duration of an encoding period, and the fact that no securities currently have prices that are more than
' 32767 ticks, this has a near-zero probability of occurring.
'
' <h3>Size field format</h3>
'
' The size field is encoded as follows:
' <p>
' - if the value is less than 256, it is stored as an unsigned 8-bit value and SIZE_TYPE_BITS is set to BYTE_SIZE
' <p>
' - if the value is less than 65536, it is stored as an unsigned little-endian 16-bit value and SIZE_TYPE_BITS is
' set to SHORT_SIZE
' <p>
' - otherwise it is stored as an unsigned little-endian 32-bit value and SIZE_TYPE_BITS is set to INT_SIZE.
'
' <h3>Side/operation/position field format</h3>
'
'  The Side/operation/position field is stored in a single byte with the following format:
' <pre>
'      Bits 0-4    PositionBits        The position in the Depth-of-Market (DOM) table that this tick relates to. This
'                                      allows for a maximum of 64 levels in the DOM table.
'
'      Bits 5-6    OperationBits       Indicates what operation is to be performed on the specified DOM table entry.
'                                      The following values are used:
'
'                                      DOMOperations.DOMInsert (0)
'                                      DOMOperations.DOMUpdate (1)
'                                      DOMOperations.DOMDelete (2)
'
'      Bit 7       SideBits            Indicates which side of the DOM table this tick related to. The following
'                                      values are used:
'
'                                      DOMSides.DOMAsk (0)
'                                      DOMSides.DOMBid (1)
' </pre>
'
' <h3>Marketmaker field format</h3>
'
' The marketmaker field is stored in UTF-16 format. It may be encoded either little-endian or big-endian, and must be
' preceded with the appropriate byte order marker (BOM) as specified in RFC 2781 para 4.3.
'@/


'@================================================================================
' Interfaces
'@================================================================================

'@================================================================================
' Events
'@================================================================================

'@================================================================================
' Enums
'@================================================================================

''
' Used to indicate what operation is to be performed on the Depth-of-Market table.
' @param DOMInsert Insert an entry.
' @param DOMUpdate Update an entry.
' @param DOMDelete Delete an entry.
'@/
Public Enum DOMOperations
    DOMInsert
    DOMUpdate
    DOMDelete
End Enum

''
' Used to indicate which side of the Depth-of-Market table is to be operated on.
' @param DOMAsk Operate on the ask side.
' @param DOMBid Operate on the bid side.
'@/
Public Enum DOMSides
    DOMAsk
    DOMBid
End Enum

''
' Used to indicate the type of a tick.
' @param TickTypeBid A bid tick.
' @param TickTypeAsk An ask tick.
' @param TickTypeClosePrice A close tick.
' @param TickTypeHighPrice A high tick.
' @param TickTypeLowPrice A low tick.
' @param TickTypeMarketDepth A market depth tick.
' @param TickTypeMarketDepthReset A market depth reset tick.
' @param TickTypeTrade A trade tick.
' @param TickTypeVolume A volume tick.
' @param TickTypeOpenInterest An open interest tick.
' @param TickTypeOpenPrice An open tick.
'@/
Public Enum TickTypes
    TickTypeBid
    TickTypeAsk
    TickTypeClosePrice
    TickTypeHighPrice
    TickTypeLowPrice
    TickTypeMarketDepth
    TickTypeMarketDepthReset
    TickTypeTrade
    TickTypeVolume
    TickTypeOpenInterest
    TickTypeOpenPrice
End Enum

'@================================================================================
' Types
'@================================================================================

''
' Represents any sort of tick.
' @param timestamp The time at which the tick occurred.
' @param tickType The type of tick.
' @param price The tick price where relevant.
' @param size The tick size where relevant.
' @param position The position in the Depth-of-Market table where relevant.
' @param operation The operation to be performed on the Depth-of-Market table
'                   where relevant.
' @param side The side of the Depth-of-Market table affected where relevant.
' @param marketmaker The marketmaker responsible for the quote where relevant.
Public Type GenericTick
    timestamp           As Date
    tickType            As TickTypes
    price               As Double
    size                As Long
    position            As Long
    operation           As DOMOperations
    side                As DOMSides
    marketmaker         As String
End Type

'@================================================================================
' Constants
'@================================================================================

Private Const ProjectName                   As String = "TickUtils26"
Private Const ModuleName                    As String = "TickUtils"

'@================================================================================
' Member variables
'@================================================================================

'@================================================================================
' Class Event Handlers
'@================================================================================

'@================================================================================
' XXXX Interface Members
'@================================================================================

'@================================================================================
' XXXX Event Handlers
'@================================================================================

'@================================================================================
' Properties
'@================================================================================

' this property is hidden as it is only needed by the test program
Public Property Get EncodingFormatIdentifierV1() As String
Attribute EncodingFormatIdentifierV1.VB_MemberFlags = "40"
EncodingFormatIdentifierV1 = TickEncodingFormatV1
End Property

' this property is hidden as it is only needed by the test program
Public Property Get EncodingFormatIdentifierV2() As String
Attribute EncodingFormatIdentifierV2.VB_MemberFlags = "40"
EncodingFormatIdentifierV2 = TickEncodingFormatV2
End Property

'@================================================================================
' Methods
'@================================================================================

''
' Returns an object that implements the <code>TickDataEncoder</code> interface.
'
' @param periodStartTime The time at the start of the period to which the encoded data segment applies.
' <p>
' Note that this time is not stored in the encoded data, but all times are encoded relative to
' this time. Therefore it is necessary for the application to store this time along with the
' encoded data segment to enable it to be subsequently decoded correctly.
' <p>
' @param tickSize The minimum tick size for the instrument to which the encoded data segment relates,
' at the time of the encoding.
' <p>
' Note that this value is not stored in the encoded data, but all prices are encoded as
' multiples of this value and relative to the base price. Therefore it is necessary for the
' application to store this time along with the encoded data segment to enable it to be
' subsequently decoded correctly. Note also that tick sizes can and do change from time to time,
' so it is not sufficient to assume that the instrument&#39;s current tick size is the same as
' the tick size at the time of encoding.
' <p>
' @param basePrice The first price recorded during the period to which the encoded data segment applies.
' <p>
' Note that this price is not stored in the encoded data, but all prices are encoded relative to
' this price. Therefore it is necessary for the application to store this price along with the
' encoded data segment to enable it to be subsequently decoded correctly. The value to be stored
' can be obtained using the encoder object&#39;s <code>BasePrice</code> property.
' <p>
' @param data An encoded data segment.
' <p>
' @param encodingFormat A value uniquely identifying the format of the encoded data (as returned by the encoder object&#39;s
' <code>EncodingFormatIdentifier</code> property).
' <p>
' @return An object that implements the <code>TickDataEncoder</code> interface.
' <p>
'@/
Public Function CreateTickDecoder( _
                ByVal periodStartTime As Date, _
                ByVal tickSize As Double, _
                ByVal basePrice As Double, _
                ByRef data() As Byte, _
                ByVal encodingFormat As String) As TickDataDecoder

If tickSize <= 0 Then Err.Raise ErrInvalidProcedureCall, , "tickSize must be positive"

If encodingFormat = TickfileFormatTradeBuildSQL Then
    encodingFormat = TickEncodingFormatV1
End If

Select Case encodingFormat
Case TickEncodingFormatV1, TickEncodingFormatV2
    Dim dec1 As New TickDataDecoderA
    Set CreateTickDecoder = dec1
    dec1.initialise periodStartTime, basePrice, tickSize, encodingFormat, data
End Select
End Function

''
' Returns an object that implements the <code>TickDataEncoder </code> interface.
' @param periodStartTime The start of the time period for which the new encoder will encode tick data.
' <p>
' Note that an encoder can only encode ticks for which the timestamp is not more than
' 65535 milliseconds from this start time.
' @param tickSize The minimum tick size for the instrument whose data is to be encoded.
' @return An object that implements the <code>TickDataEncoder </code> interface.
'@/
Public Function CreateTickEncoder( _
                ByVal periodStartTime As Date, _
                ByVal tickSize As Double) As TickDataEncoder

Dim enc As New TickDataEncoderA

If tickSize <= 0 Then Err.Raise ErrInvalidProcedureCall, , "tickSize must be positive"

Set CreateTickEncoder = enc
enc.initialise periodStartTime, tickSize, TickEncodingFormatV2

End Function

' This mthod is hidden. because it only exists to enable the test program
' to be able to generate Version 1 encodings. No other program should use this
' method.
Public Function CreateTickEncoderByType( _
                ByVal periodStartTime As Date, _
                ByVal tickSize As Double, _
                ByVal encodingFormat As String) As TickDataEncoder
Attribute CreateTickEncoderByType.VB_MemberFlags = "40"

If tickSize <= 0 Then Err.Raise ErrInvalidProcedureCall, , "tickSize must be positive"

If encodingFormat = TickfileFormatTradeBuildSQL Then
    encodingFormat = TickEncodingFormatV1
End If

Select Case encodingFormat
Case TickEncodingFormatV1, TickEncodingFormatV2
    Dim enc1 As New TickDataEncoderA
    Set CreateTickEncoderByType = enc1
    enc1.initialise periodStartTime, tickSize, encodingFormat
End Select
End Function

''
' Returns a string representation of a tick.
'
' The string contains each field relevant to the tick type, separated by commas.
'
' The tick&#39;s timestamp is in the form:
'   yyyy/mm/dd hh:mm:ss.nnn   (where nnn is milliseconds)
'
' @return
'   The string representation of the supplied tick.
'
' @param tick
'   The tick whose string representation is required.
'@/
Public Function GenericTickToString( _
                ByRef tick As GenericTick) As String
Dim s As String

s = formatTimestamp(tick.timestamp) & ","

Select Case tick.tickType
Case TickTypes.TickTypeBid
    s = s & "B" & "," & tick.price & "," & tick.size
Case TickTypes.TickTypeAsk
    s = s & "A" & "," & tick.price & "," & tick.size
Case TickTypes.TickTypeClosePrice
    s = s & "C" & "," & tick.price
Case TickTypes.TickTypeHighPrice
    s = s & "H" & "," & tick.price
Case TickTypes.TickTypeLowPrice
    s = s & "L" & "," & tick.price
Case TickTypes.TickTypeMarketDepth
    s = s & "D" & "," & tick.position & "," & tick.marketmaker & "," & tick.operation & "," & tick.side & "," & tick.price & "," & tick.size
Case TickTypes.TickTypeMarketDepthReset
    s = s & "R"
Case TickTypes.TickTypeTrade
    s = s & "T" & "," & tick.price & "," & tick.size
Case TickTypes.TickTypeVolume
    s = s & "V" & "," & tick.size
Case TickTypes.TickTypeOpenInterest
    s = s & "I" & "," & tick.size
Case TickTypes.TickTypeOpenPrice
    s = s & "O" & "," & tick.price
End Select

GenericTickToString = s

End Function

'@================================================================================
' Helper Functions
'@================================================================================

Private Function formatTimestamp( _
            ByVal timestamp As Date) As String
Dim timestampDays  As Long
Dim timestampSecs  As Double
Dim timestampAsDate As Date
Dim Milliseconds As Long

timestampDays = Int(timestamp)
timestampSecs = Int((timestamp - Int(timestamp)) * 86400) / 86400#
timestampAsDate = CDate(CDbl(timestampDays) + timestampSecs)
Milliseconds = CLng((timestamp - timestampAsDate) * 86400# * 1000#)

If Milliseconds >= 1000& Then
    Milliseconds = Milliseconds - 1000&
    timestampSecs = timestampSecs + (1# / 86400#)
    timestampAsDate = CDate(CDbl(timestampDays) + timestampSecs)
End If

formatTimestamp = Format(timestampAsDate, "yyyy/mm/dd hh:nn:ss") & _
                        Format(Milliseconds, "\.000")
            
End Function

