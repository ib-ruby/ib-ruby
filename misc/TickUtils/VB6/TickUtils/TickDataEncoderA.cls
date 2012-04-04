VERSION 1.0 CLASS
BEGIN
  MultiUse = -1  'True
  Persistable = 0  'NotPersistable
  DataBindingBehavior = 0  'vbNone
  DataSourceBehavior  = 0  'vbNone
  MTSTransactionMode  = 0  'NotAnMTSObject
END
Attribute VB_Name = "TickDataEncoderA"
Attribute VB_GlobalNameSpace = False
Attribute VB_Creatable = False
Attribute VB_PredeclaredId = False
Attribute VB_Exposed = False
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
' Description here
'
'
'   The first byte of each record has the following structure:
'
'    TickType (Bits 0-3)
'    SizeType (Bits 4-5)
'    NoTimestamp (bit 6)
'    NegativeTicks (bit 7)
'
'@/

'@================================================================================
' Interfaces
'@================================================================================

Implements TickDataEncoder

'@================================================================================
' Events
'@================================================================================

'@================================================================================
' Enums
'@================================================================================

'@================================================================================
' Types
'@================================================================================

'@================================================================================
' Constants
'@================================================================================

Private Const ProjectName                   As String = "TickUtils26"
Private Const ModuleName                    As String = "TickDataEncoderv1"

'@================================================================================
' Member variables
'@================================================================================

Private mTimestamp As Date          ' current timestamp
Private mBasePrice As Double        ' first price encountered at start of encoding period
Private mPeriodStartTime As Date   ' timestamp at start of encoding period

Private mData() As Byte
Private mDataIndex As Long

Private mTickSize As Double

Private mVersion As Long

'@================================================================================
' Class Event Handlers
'@================================================================================

Private Sub Class_Initialize()
mBasePrice = MaxDoubleValue
End Sub

'@================================================================================
' TickDataEncoder Interface Members
'@================================================================================

Private Property Get TickDataEncoder_basePrice() As Double
TickDataEncoder_basePrice = mBasePrice
End Property

Private Sub TickDataEncoder_encodeAsk( _
                ByVal timestamp As Date, _
                ByVal price As Double, _
                ByVal size As Long)
Dim failpoint As Long

On Error GoTo Err

If size < 0 Then Err.Raise ErrInvalidProcedureCall, , "Size cannot be negative"

WriteQuoteRecord TickTypes.TickTypeAsk, timestamp, price, size

Exit Sub

Err:
Err.Raise Err.Number, _
        ProjectName & "." & ModuleName & ":" & "TickDataEncoder_encodeAsk" & "." & failpoint & _
        IIf(Err.Source <> "", vbCrLf & Err.Source, ""), _
        Err.Description

End Sub

Private Sub TickDataEncoder_encodeBid( _
                ByVal timestamp As Date, _
                ByVal price As Double, _
                ByVal size As Long)
Dim failpoint As Long
On Error GoTo Err

If size < 0 Then Err.Raise ErrInvalidProcedureCall, , "Size cannot be negative"

WriteQuoteRecord TickTypes.TickTypeBid, timestamp, price, size

Exit Sub

Err:
Err.Raise Err.Number, _
        ProjectName & "." & ModuleName & ":" & "TickDataEncoder_encodeBid" & "." & failpoint & _
        IIf(Err.Source <> "", vbCrLf & Err.Source, ""), _
        Err.Description

End Sub

Private Sub TickDataEncoder_encodeClose( _
                ByVal timestamp As Date, _
                ByVal price As Double)
Dim failpoint As Long
On Error GoTo Err

WritePriceRecord TickTypes.TickTypeClosePrice, timestamp, price

Exit Sub

Err:
Err.Raise Err.Number, _
        ProjectName & "." & ModuleName & ":" & "TickDataEncoder_encodeClose" & "." & failpoint & _
        IIf(Err.Source <> "", vbCrLf & Err.Source, ""), _
        Err.Description

End Sub

Private Property Get TickDataEncoder_encodedData() As Byte()
If mDataIndex = 0 Then Exit Property

If UBound(mData) > (mDataIndex - 1) Then
    ReDim Preserve mData(mDataIndex - 1) As Byte
End If

TickDataEncoder_encodedData = mData
End Property

Private Property Get TickDataEncoder_encodedDataLength() As Long
TickDataEncoder_encodedDataLength = mDataIndex
End Property

Private Sub TickDataEncoder_encodeHigh( _
                ByVal timestamp As Date, _
                ByVal price As Double)
Dim failpoint As Long
On Error GoTo Err

WritePriceRecord TickTypes.TickTypeHighPrice, timestamp, price

Exit Sub

Err:
Err.Raise Err.Number, _
        ProjectName & "." & ModuleName & ":" & "TickDataEncoder_encodeHigh" & "." & failpoint & _
        IIf(Err.Source <> "", vbCrLf & Err.Source, ""), _
        Err.Description

End Sub

Private Sub TickDataEncoder_encodeLow( _
                ByVal timestamp As Date, _
                ByVal price As Double)
Dim failpoint As Long
On Error GoTo Err

WritePriceRecord TickTypes.TickTypeLowPrice, timestamp, price

Exit Sub

Err:
Err.Raise Err.Number, _
        ProjectName & "." & ModuleName & ":" & "TickDataEncoder_encodeLow" & "." & failpoint & _
        IIf(Err.Source <> "", vbCrLf & Err.Source, ""), _
        Err.Description

End Sub

Private Sub TickDataEncoder_encodeMarketDepthData( _
                ByVal timestamp As Date, _
                ByVal position As Long, _
                ByVal marketmaker As String, _
                ByVal operation As Long, _
                ByVal side As Long, _
                ByVal price As Double, _
                ByVal size As Long)
Dim typeByte As Byte
Dim sizeType As SizeTypes
Dim sideOperationPositionByte As Byte

Dim failpoint As Long
On Error GoTo Err

If size < 0 Then Err.Raise ErrInvalidProcedureCall, , "Size cannot be negative"

typeByte = TickTypes.TickTypeMarketDepth

sizeType = GetSizeType(size)
typeByte = typeByte Or (sizeType * SizeTypeShifter)

If timestamp = mTimestamp Then typeByte = typeByte Or NoTimestamp

If mBasePrice = MaxDoubleValue Then mBasePrice = price
If price < mBasePrice Then typeByte = typeByte Or NegativeTicks

WriteByte typeByte
WriteTimestamp timestamp
sideOperationPositionByte = CByte(position)
sideOperationPositionByte = sideOperationPositionByte Or CByte(operation * OperationShifter)
sideOperationPositionByte = sideOperationPositionByte Or CByte(side * SideShifter)
WriteByte sideOperationPositionByte

WritePrice price
WriteSize size, sizeType
WriteString marketmaker

Exit Sub

Err:
Err.Raise Err.Number, _
        ProjectName & "." & ModuleName & ":" & "TickDataEncoder_encodeMarketDepthData" & "." & failpoint & _
        IIf(Err.Source <> "", vbCrLf & Err.Source, ""), _
        Err.Description

End Sub

Private Sub TickDataEncoder_encodeMarketDepthReset( _
                ByVal timestamp As Date)
Dim typeByte As Byte

Dim failpoint As Long
On Error GoTo Err

typeByte = TickTypes.TickTypeMarketDepthReset

If timestamp = mTimestamp Then typeByte = typeByte Or NoTimestamp

WriteByte typeByte
WriteTimestamp timestamp

Exit Sub

Err:
Err.Raise Err.Number, _
        ProjectName & "." & ModuleName & ":" & "TickDataEncoder_encodeMarketDepthReset" & "." & failpoint & _
        IIf(Err.Source <> "", vbCrLf & Err.Source, ""), _
        Err.Description

End Sub

Private Sub TickDataEncoder_encodeOpen(ByVal timestamp As Date, ByVal price As Double)
Dim failpoint As Long
On Error GoTo Err

WritePriceRecord TickTypes.TickTypeOpenPrice, timestamp, price

Exit Sub

Err:
Err.Raise Err.Number, _
        ProjectName & "." & ModuleName & ":" & "TickDataEncoder_encodeOpen" & "." & failpoint & _
        IIf(Err.Source <> "", vbCrLf & Err.Source, ""), _
        Err.Description

End Sub

Private Sub TickDataEncoder_encodeOpenInterest( _
                ByVal timestamp As Date, ByVal size As Long)
Dim failpoint As Long
On Error GoTo Err

If size < 0 Then Err.Raise ErrInvalidProcedureCall, , "Size cannot be negative"

WriteSizeRecord TickTypes.TickTypeOpenInterest, timestamp, size

Exit Sub

Err:
Err.Raise Err.Number, _
        ProjectName & "." & ModuleName & ":" & "TickDataEncoder_encodeOpenInterest" & "." & failpoint & _
        IIf(Err.Source <> "", vbCrLf & Err.Source, ""), _
        Err.Description

End Sub

Private Sub TickDataEncoder_encodeTrade( _
                ByVal timestamp As Date, _
                ByVal price As Double, _
                ByVal size As Long)
Dim failpoint As Long
On Error GoTo Err

If size < 0 Then Err.Raise ErrInvalidProcedureCall, , "Size cannot be negative"

WriteQuoteRecord TickTypes.TickTypeTrade, timestamp, price, size

Exit Sub

Err:
Err.Raise Err.Number, _
        ProjectName & "." & ModuleName & ":" & "TickDataEncoder_encodeTrade" & "." & failpoint & _
        IIf(Err.Source <> "", vbCrLf & Err.Source, ""), _
        Err.Description

End Sub

Private Sub TickDataEncoder_encodeVolume( _
                ByVal timestamp As Date, _
                ByVal size As Long)
Dim failpoint As Long
On Error GoTo Err

If size < 0 Then Err.Raise ErrInvalidProcedureCall, , "Size cannot be negative"

WriteSizeRecord TickTypes.TickTypeVolume, timestamp, size

Exit Sub

Err:
Err.Raise Err.Number, _
        ProjectName & "." & ModuleName & ":" & "TickDataEncoder_encodeVolume" & "." & failpoint & _
        IIf(Err.Source <> "", vbCrLf & Err.Source, ""), _
        Err.Description

End Sub

Private Property Get TickDataEncoder_encodingFormatIdentifier() As String
If mVersion = 1 Then
    TickDataEncoder_encodingFormatIdentifier = TickEncodingFormatV1
Else
    TickDataEncoder_encodingFormatIdentifier = TickEncodingFormatV2
End If
End Property

Private Property Get TickDataEncoder_periodStartTime() As Date
TickDataEncoder_periodStartTime = mPeriodStartTime
End Property

Private Property Get TickDataEncoder_tickSize() As Double
TickDataEncoder_tickSize = mTickSize
End Property

'@================================================================================
' XXXX Event Handlers
'@================================================================================

'@================================================================================
' Properties
'@================================================================================

'@================================================================================
' Methods
'@================================================================================

Friend Sub initialise( _
                ByVal periodStartTime As Date, _
                ByVal tickSize As Double, _
                ByVal encodingFormat As String)
mPeriodStartTime = periodStartTime
mTickSize = tickSize

Select Case encodingFormat
Case TickEncodingFormatV1
    mVersion = 1
Case TickEncodingFormatV2
    mVersion = 2
End Select

ReDim mData(8191) As Byte
End Sub

'@================================================================================
' Helper Functions
'@================================================================================

Private Function GetSizeType( _
                ByVal size As Long) As SizeTypes
If size < &H100 Then
    GetSizeType = SizeTypes.ByteSize
ElseIf size < &H10000 Then
    GetSizeType = SizeTypes.UInt16Size
Else
    GetSizeType = SizeTypes.UInt32Size
End If
End Function

Private Sub WriteByte( _
                ByVal theByte As Byte)
If mDataIndex > UBound(mData) Then
    ReDim Preserve mData(UBound(mData) + 8192) As Byte
End If
mData(mDataIndex) = theByte
mDataIndex = mDataIndex + 1
End Sub

Private Sub WriteInt( _
                ByVal theInt As Integer)
WriteByte CByte(theInt And &HFF)
WriteByte CByte(Int(theInt / &H100) And &HFF)
End Sub

Private Sub WriteLong( _
                ByVal theLong As Long)
WriteByte CByte(theLong And &HFF)
WriteByte CByte(Int(theLong / &H100) And &HFF)
WriteByte CByte(Int(theLong / &H10000) And &HFF)
WriteByte CByte(Int(theLong / &H1000000) And &HFF)
End Sub

Private Sub WritePrice( _
                ByVal price As Double)
Dim numticks As Integer
If price = mBasePrice Then
    WriteByte &H0
Else
    numticks = Abs(price - mBasePrice) / mTickSize
    If numticks <= 127 Then
        WriteByte CByte(numticks)
    Else
        ' won't fit in 7 bits. Write it out as an int value, with
        ' the high-order byte written first and bit 7 set.  NB: there is
        ' an implicit assumption here that we won't ever need to deal with
        ' a price which is more than 0x7FFF ticks from the base price in
        ' a single encoding period. That would be one hell of a crash!
        WriteByte CByte(Int(numticks / &H100) And &H7F) Or &H80
        WriteByte CByte(numticks And &HFF)
    End If
End If
End Sub

Private Sub WritePriceRecord( _
                ByVal tickType As TickTypes, _
                ByVal timestamp As Date, _
                ByVal price As Double)
Dim typeByte As Byte

typeByte = tickType

If timestamp = mTimestamp Then typeByte = typeByte Or NoTimestamp

If mBasePrice = MaxDoubleValue Then mBasePrice = price
If price < mBasePrice Then typeByte = typeByte Or NegativeTicks

WriteByte typeByte
WriteTimestamp timestamp
WritePrice price
End Sub

Private Sub WriteQuoteRecord( _
                ByVal tickType As TickTypes, _
                ByVal timestamp As Date, _
                ByVal price As Double, _
                ByVal size As Long)
Dim typeByte As Byte
Dim sizeType As SizeTypes

typeByte = tickType

sizeType = GetSizeType(size)
typeByte = typeByte Or (sizeType * SizeTypeShifter)

If timestamp = mTimestamp Then typeByte = typeByte Or NoTimestamp

If mBasePrice = MaxDoubleValue Then mBasePrice = price
If price < mBasePrice Then typeByte = typeByte Or NegativeTicks

WriteByte typeByte

WriteTimestamp timestamp

WritePrice price

WriteSize size, sizeType
End Sub

Private Sub WriteSize( _
                ByVal size As Long, _
                ByVal sizeType As SizeTypes)
Select Case sizeType
Case SizeTypes.ByteSize
    Debug.Assert size < &H100&
    WriteByte CByte(size)
Case SizeTypes.UInt16Size
    Debug.Assert size < &H10000
    If size < &H8000& Then
        WriteInt size
    Else
        WriteInt CInt(size - &H10000)
    End If
Case SizeTypes.UInt32Size
    WriteLong size
End Select
End Sub

Private Sub WriteSizeRecord( _
                ByVal tickType As TickTypes, _
                ByVal timestamp As Date, _
                ByVal size As Long)
Dim typeByte As Byte
Dim sizeType As SizeTypes

typeByte = tickType

sizeType = GetSizeType(size)
typeByte = typeByte Or (sizeType * SizeTypeShifter)

If timestamp = mTimestamp Then typeByte = typeByte Or NoTimestamp

WriteByte typeByte
WriteTimestamp timestamp
WriteSize size, sizeType
End Sub

Private Sub WriteString( _
                ByVal theString As String)
Dim ar() As Byte
Dim i As Long

ar = theString

If mVersion = 1 Then
    WriteByte CByte(Len(theString))
Else
    WriteByte CByte(UBound(ar) + 3)

    ' prepend a UTF-16 little-endian BOM
    ' see RFC 2781 4.3 for details of interpeting the Byte Order Marker (BOM)
    WriteByte &HFF
    WriteByte &HFE
End If
    
For i = 0 To UBound(ar)
    WriteByte ar(i)
Next

End Sub

Private Sub WriteTimestamp( _
                ByVal timestamp As Date)
Dim diff As Long
If timestamp <> mTimestamp Then
    diff = (timestamp - mPeriodStartTime) * 86400 * 1000
    Debug.Assert diff < &H10000
    If diff < &H8000& Then
        WriteInt diff
    Else
        WriteInt CInt(diff - &H10000)
    End If
    mTimestamp = timestamp
End If
End Sub




