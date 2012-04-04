Attribute VB_Name = "Globals"
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

'@================================================================================
' Events
'@================================================================================

'@================================================================================
' Enums
'@================================================================================

Public Enum SizeTypes
    ByteSize = 1
    UInt16Size
    UInt32Size
End Enum

'@================================================================================
' Types
'@================================================================================

'@================================================================================
' Constants
'@================================================================================

Private Const ProjectName                   As String = "TickUtils26"
Private Const ModuleName                    As String = "Globals"

Public Const ErrInvalidProcedureCall        As Long = 5

Public Const MaxDoubleValue                 As Double = (2 - 2 ^ -52) * 2 ^ 1023

Public Const NegativeTicks                  As Byte = &H80
Public Const NoTimestamp                    As Byte = &H40

Public Const OperationBits                  As Byte = &H60
Public Const OperationShifter               As Byte = &H20
Public Const PositionBits                   As Byte = &H1F
Public Const SideBits                       As Byte = &H80
Public Const SideShifter                    As Byte = &H80
Public Const SizeTypeBits                   As Byte = &H30
Public Const SizeTypeShifter                As Byte = &H10
Public Const TickTypeBits                   As Byte = &HF

' this is the encoding format identifier currently in use
Public Const TickEncodingFormatV2           As String = "urn:uid:b61df8aa-d8cc-47b1-af18-de725dee0ff5"

' this encoding format identifier was used in early non-public versions of this package
Public Const TickEncodingFormatV1           As String = "urn:tradewright.com:names.tickencodingformats.V1"

' the following is equivalent to TickEncodingFormatV1 (ie the encoding is identical)
Public Const TickfileFormatTradeBuildSQL    As String = "urn:tradewright.com:names.tickfileformats.TradeBuildSQL"

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

'@================================================================================
' Methods
'@================================================================================

'@================================================================================
' Helper Functions
'@================================================================================


