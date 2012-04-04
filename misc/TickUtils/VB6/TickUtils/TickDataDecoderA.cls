VERSION 1.0 CLASS
BEGIN
  MultiUse = -1  'True
  Persistable = 0  'NotPersistable
  DataBindingBehavior = 0  'vbNone
  DataSourceBehavior  = 0  'vbNone
  MTSTransactionMode  = 0  'NotAnMTSObject
END
Attribute VB_Name = "TickDataDecoderA"
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
'@/

'@================================================================================
' Interfaces
'@================================================================================

Implements TickDataDecoder

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
Private Const ModuleName                    As String = "TickDataDecoderV1"

'@================================================================================
' Member variables
'@================================================================================

Private mData()                     As Byte
Private mDataIndex                  As Long

Private mTickSize                   As Double

Private mPeriodStartTime            As Date   ' timestamp at start of encoding period
Private mCurrentTimestamp           As Date

Private mBasePrice                  As Double

Private mVersion                    As Long

'@================================================================================
' Class Event Handlers
'@================================================================================

'@================================================================================
' TickDataDecoder Interface Members
'@================================================================================

Private Function TickDataDecoder_getNextTick( _
                ByRef tick As GenericTick) As Boolean
Dim typeByte As Byte
Dim sizeType As SizeTypes

If mDataIndex > UBound(mData) Then Exit Function

typeByte = readByte

tick.timestamp = readTimestamp(typeByte)

tick.tickType = typeByte And TickTypeBits
sizeType = (typeByte And SizeTypeBits) / SizeTypeShifter

Select Case tick.tickType
Case TickTypes.TickTypeBid
    readQuoteRecord typeByte, sizeType, tick
Case TickTypes.TickTypeAsk
    readQuoteRecord typeByte, sizeType, tick
Case TickTypes.TickTypeClosePrice
    readPriceRecord typeByte, tick
Case TickTypes.TickTypeHighPrice
    readPriceRecord typeByte, tick
Case TickTypes.TickTypeLowPrice
    readPriceRecord typeByte, tick
Case TickTypes.TickTypeMarketDepth
    readMarketDepthRecord typeByte, sizeType, tick
Case TickTypes.TickTypeMarketDepthReset
    readMarketDepthResetRecord typeByte, tick
Case TickTypes.TickTypeTrade
    readQuoteRecord typeByte, sizeType, tick
Case TickTypes.TickTypeVolume
    readSizeRecord typeByte, sizeType, tick
Case TickTypes.TickTypeOpenInterest
    readSizeRecord typeByte, sizeType, tick
Case TickTypes.TickTypeOpenPrice
    readPriceRecord typeByte, tick
End Select

TickDataDecoder_getNextTick = True

End Function

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
                ByVal basePrice As Double, _
                ByVal tickSize As Double, _
                ByVal encodingFormat As String, _
                ByRef data() As Byte)
mPeriodStartTime = periodStartTime
mCurrentTimestamp = mPeriodStartTime
mBasePrice = basePrice
mTickSize = tickSize

Select Case encodingFormat
Case TickEncodingFormatV1
    mVersion = 1
Case TickEncodingFormatV2
    mVersion = 2
End Select

mData = data
End Sub

'@================================================================================
' Helper Functions
'@================================================================================

Private Function readByte() As Byte
readByte = mData(mDataIndex)
mDataIndex = mDataIndex + 1
End Function

Private Function readInt() As Long
readInt = readByte + (readByte * &H100&)
End Function

Private Function readLong() As Long
' note that this will fail (overflow) if attempting to read a negative long,
' but this should never happen
readLong = CLng(readByte) + _
            &H100& * CLng(readByte) + _
            &H10000 * CLng(readByte) + _
            &H1000000 * CLng(readByte)
End Function

Private Sub readMarketDepthRecord( _
                ByVal typeByte As Byte, _
                ByVal sizeType As SizeTypes, _
                ByRef tick As GenericTick)
Dim sideOperationPositionByte As Byte

sideOperationPositionByte = readByte
tick.position = sideOperationPositionByte And PositionBits
tick.operation = (sideOperationPositionByte And OperationBits) / OperationShifter
tick.side = (sideOperationPositionByte And SideBits) / SideShifter
tick.price = readPrice(typeByte)
tick.side = readSize(sizeType)
tick.marketmaker = readString
End Sub

Private Sub readMarketDepthResetRecord( _
                ByVal typeByte As Byte, _
                ByRef tick As GenericTick)
' nothing to do
End Sub

Private Function readPrice( _
                ByVal typeByte As Byte) As Double
Dim mostSigByte As Byte
Dim leastSigByte As Byte
Dim numticks As Integer

mostSigByte = readByte
If (mostSigByte And &H80) = 0 Then
    numticks = CInt(mostSigByte)
Else
    mostSigByte = mostSigByte And &H7F
    leastSigByte = readByte
    numticks = CInt(mostSigByte) * &H100 + CInt(leastSigByte)
End If
    
If (typeByte And NegativeTicks) <> 0 Then
    readPrice = mBasePrice - mTickSize * numticks
Else
    readPrice = mBasePrice + mTickSize * numticks
End If
End Function

Private Sub readPriceRecord( _
                ByVal typeByte As Byte, _
                ByRef tick As GenericTick)
tick.price = readPrice(typeByte)
End Sub

Private Sub readQuoteRecord( _
                ByVal typeByte As Byte, _
                ByVal sizeType As SizeTypes, _
                ByRef tick As GenericTick)
tick.price = readPrice(typeByte)
tick.size = readSize(sizeType)
End Sub

Private Function readSize( _
                ByVal sizeType As SizeTypes) As Long
Select Case sizeType
Case ByteSize
    readSize = readByte
Case UInt16Size
    readSize = readInt
Case UInt32Size
    readSize = readLong
End Select
End Function

Private Sub readSizeRecord( _
                ByVal typeByte As Byte, _
                ByVal sizeType As SizeTypes, _
                ByRef tick As GenericTick)
tick.size = readSize(sizeType)
End Sub

Private Function readString() As String
Dim ar() As Byte
Dim length As Long
Dim i As Long
Dim startIndex As Long
Dim b0 As Byte
Dim b1 As Byte
Dim bigEndian As Boolean

length = readByte
If length = 0 Then Exit Function

If mVersion = 1 Then
    ' version 1 wrote length of string instead of length of array
    ReDim ar(2 * length - 1) As Byte
Else

    b0 = readByte
    b1 = readByte
    
    ' see RFC 2781 4.3 for details of interpeting the Byte Order Marker (BOM)
    If b0 = &HFE And b1 = &HFF Then
        bigEndian = True
        ReDim ar(length - 3) As Byte
    ElseIf b0 = &HFF And b1 = &HFE Then
        bigEndian = False
        ReDim ar(length - 3) As Byte
    Else
        bigEndian = True
        ReDim ar(length - 1) As Byte
        ar(0) = b0
        ar(1) = b1
        startIndex = 2
    End If
    
End If

If bigEndian Then
    ' we need to change it to little-endian, because that's how
    ' VB stores strings
    For i = startIndex To UBound(ar)
        If i Mod 2 = 0 Then
            ar(i + 1) = readByte
        Else
            ar(i - 1) = readByte
        End If
    Next
Else
    For i = startIndex To UBound(ar)
        ar(i) = readByte
    Next
End If

readString = ar
End Function

Private Function readTimestamp( _
                ByVal typeByte As Byte) As Date
Dim diff As Long
If (typeByte And NoTimestamp) = 0 Then
    diff = readInt
    readTimestamp = mPeriodStartTime + (diff / (86400 * 1000))
    mCurrentTimestamp = readTimestamp
Else
    readTimestamp = mCurrentTimestamp
End If
End Function



