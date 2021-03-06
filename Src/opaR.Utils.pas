unit opaR.Utils;

{-------------------------------------------------------------------------------

opaR: object pascal for R

Copyright (C) 2015-2016 Sigma Sciences Ltd.

Originator: Robert L S Devine

Unless you have received this program directly from Sigma Sciences Ltd under
the terms of a commercial license agreement, then this program is licensed
to you under the terms of version 3 of the GNU Affero General Public License.
Please refer to the AGPL licence document at:
http://www.gnu.org/licenses/agpl-3.0.txt for more details.

This program is distributed WITHOUT ANY EXPRESS OR IMPLIED WARRANTY, INCLUDING
THOSE OF NON-INFRINGEMENT, MERCHANTABILITY OR FITNESS FOR A PARTICULAR PURPOSE.

-------------------------------------------------------------------------------}

interface

uses
  System.SysUtils,
  System.Types;

type
  TPAnsiCharArray = array of PAnsiChar;
  PPAnsiCharArray = ^TPAnsiCharArray;

  EopaRException = class(Exception);

  TDynMatrix<T> = array of TArray<T>;

// -- C and C++ libraries, usually store enumerated types as words or double words.
// -- Use the {$MINENUMSIZE 4} directive to store the TSymbolicExpressionType
// -- enumeration type as an unsigned double-word. {$Z4} in older Delphi versions.
{$MINENUMSIZE 4}

  TSymbolicExpressionType = (
        Null = 0,                       // -- Null.
        Symbol = 1,                     // -- Symbols.
        Pairlist = 2,                   // -- Pairlists.
        Closure = 3,                    // -- Closures.
        Environment = 4,                // -- Environments.
        Promise = 5,                    // -- To be evaluated.
        LanguageObject = 6,             // -- Pairlists for function calls.
        SpecialFunction = 7,            // -- Special functions.
        BuiltinFunction = 8,            // -- Builtin functions.
        InternalCharacterString = 9,    // -- Internal character string.   (CHARSXP)
        LogicalVector = 10,             // -- Boolean vectors.
        IntegerVector = 13,             // -- Integer vectors.
        NumericVector = 14,             // -- Numeric vectors.
        ComplexVector = 15,             // -- Complex number vectors.
        CharacterVector = 16,           // -- Character vectors.
        DotDotDotObject = 17,           // -- Dot-dot-dot object.
        Any = 18,                       // -- Place holders for any type.
        List = 19,                      // -- Generic vectors.
        ExpressionVector = 20,          // -- Expression vectors.
        ByteCode = 21,                  // -- Byte code.
        ExternalPointer = 22,           // -- External pointer.
        WeakReference = 23,             // -- Weak reference.
        RawVector = 24,                 // -- Raw vectors.
        S4 = 25);                       // -- S4 classes.

  TStartupRestoreAction = (
        NoRestore = 0,
        Restore = 1,
        Default = 2);

  TStartupSaveAction = (
        Default_ = 2,       { TODO : Can we define same name for different enums? }
        NoSave = 3,
        Save = 4,
        Ask = 5,
        Suicide = 6);

  TYesNoCancel = (
        Yes = 1,
        No = 2,
        Cancel = 0);

  TBusyType = (
        None = 0,
        ExtendedComputation = 1);

  TConsoleOutputType = (None_ = 0);

  TUiMode = (
        RGui,
        RTerminal,
        LinkDll);

  TParseStatus = (
        Null_,
        OK,
        Incomplete,
        Error,
        EOF);

{$MINENUMSIZE 1}              // -- Restore the default enum size.


  // -- See http://praxis-velthuis.de/rdc/articles/articles-convert.html#propertyindex
  // -- for details on the bit field implementation.
  // -- Note that for type_ we're using an integer so will need to cast to TSymbolicExpressionType.
  Tsxpinfo = packed record
  private
    Flags: DWord;
    {$IFDEF CPUX64}    // -- SizeOf(VECTOR_SEXPREC) in R.NET x64 = 40
    Pad: array[0..3] of byte;
    {$ENDIF}
    function GetBits(const aIndex: Integer): Integer;
    procedure SetBits(const aIndex: Integer; const aValue: Integer);
  public
    property type_: Integer index $0005 read GetBits write SetBits;     // 5 bits at offset 0  (TSymbolicExpressionType)
    property obj: Integer index $0501 read GetBits write SetBits;       // 1 bit at offset 5 ($05)
    property named: Integer index $0602 read GetBits write SetBits;     // 2 bits at offset 6 ($06)
    property gp: Integer index $0810 read GetBits write SetBits;        // 16 bits  at offset 8 ($08)
    property mark: Integer index $1801 read GetBits write SetBits;      // 1 bit at offset 24 ($18)
    property debug: Integer index $1901 read GetBits write SetBits;     // 1 bit  at offset 25 ($19)
    property trace: Integer index $1A01 read GetBits write SetBits;     // 1 bit  at offset 26 ($1A)
    property spare: Integer index $1B01 read GetBits write SetBits;     // 1 bit  at offset 27 ($1B)
    property gcgen: Integer index $1C01 read GetBits write SetBits;     // 1 bit  at offset 28 ($1C)
    property gccls: Integer index $1D03 read GetBits write SetBits;     // 3 bits at offset 29 ($18)
  end;



implementation

//------------------------------------------------------------------------------
function GetDWordBits(const Bits: DWORD; const aIndex: Integer): Integer;
begin
  Result := (Bits shr (aIndex shr 8))       // offset
            and ((1 shl Byte(aIndex)) - 1); // mask
end;
//------------------------------------------------------------------------------
procedure SetDWordBits(var Bits: DWORD; const aIndex: Integer; const aValue: Integer);
var
  Offset: Byte;
  Mask: Integer;
begin
  Mask := ((1 shl Byte(aIndex)) - 1);
  Assert(aValue <= Mask);

  Offset := aIndex shr 8;
  Bits := (Bits and (not (Mask shl Offset)))
          or DWORD(aValue shl Offset);
end;
//------------------------------------------------------------------------------



{ Tsxpinfo }

//------------------------------------------------------------------------------
function Tsxpinfo.GetBits(const aIndex: Integer): Integer;
begin
  result := GetDWordBits(Flags, aIndex);
end;
//------------------------------------------------------------------------------
procedure Tsxpinfo.SetBits(const aIndex, aValue: Integer);
begin
  SetDWordBits(Flags, aIndex, aValue);
end;

end.
