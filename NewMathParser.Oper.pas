// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

/// Viel geändert von Jens Biermann am 07.02.2012
/// Viel geändert von Jens Biermann am 29.01.2015
/// Änderungen von Jens Biermann am 23.08.2016
/// Items in TVariables - Jens Biermann am 10.09.2016

unit NewMathParser.Oper;

interface

uses System.Generics.Collections, System.SysUtils, System.Classes;

const
  cNoError = 0;
  // Internal error:
  cInternalError = 1;
  // Expression errors:
  cErrorInvalidCar   = 2;
  cErrorUnknownName  = 3;
  cErrorInvalidFloat = 4;
  cErrorOperator     = 5;
  // cErrorFxNeedLeftBracket     = 6; deprecated
  cErrorNotEnoughArgs         = 7;
  cErrorSeparatorNeedArgument = 8;
  cErrorMissingLeftBrackets   = 9;
  cErrorMissingRightBrackets  = 10;
  cErrorLeftBracket           = 11;
  cErrorRightBracket          = 12;
  cErrorSeparator             = 13;
  cErrorOperatorNeedArgument  = 14;
  cErrorToManyArgs            = 15;
  // Calc errors:
  cErrorCalc           = 100;
  cErrorDivByZero      = 101;
  cErrorPower          = 102;
  cErrorFxInvalidValue = 103;
  cErrorTan            = 104;

type

  PError = ^TError;

  TError = record
  private
    FCode    : Integer;
    FPosition: Integer;
  public
    constructor Create(ACode, APosition: Integer);
    procedure Clear;
    function ToString: string;
    function IsNoError: Boolean;
    property Code: Integer read FCode write FCode;
    property Position: Integer read FPosition write FPosition;
  end;

  TOpFunc    = reference to function(Values: TArray<Double>): Double;
  TErrorFunc = reference to function(Values: TArray<Double>): Integer;

  TOperator = class(TObject)
  private
    FErrorFunc: TErrorFunc;
    FPriority : Integer;
    FArguments: Integer;
    FName     : string;
    FFunc     : TOpFunc;
  public
    constructor Create(aPriority: Integer; aArguments: Integer; aName: string); overload;
    constructor Create(aPriority: Integer; aArguments: Integer; aName: string; aOpF: TOpFunc); overload;
    constructor Create(aPriority: Integer; aArguments: Integer; aName: string; aOpF: TOpFunc; aIsError: TErrorFunc);
      overload;
    function IsError(Values: TArray<Double>; var Error: Integer): Boolean;
    property Name: string read FName write FName;
    property Func: TOpFunc read FFunc write FFunc;
    property Priority: Integer read FPriority write FPriority;
    property Arguments: Integer read FArguments write FArguments;
  end;

  TOperatoren = class(TObjectList<TOperator>)
  private
    procedure AddOpNone;
    procedure AddOpNeg;
    function ValidVariableName(Name: string): Boolean;
    function GetOp(aName: string): TOperator;
  public
    constructor Create;
    // destructor Destroy; override;
    function AddCustomOperation(Name: string; Arguments: Integer; Priority: byte): Boolean;
    function IndexOfName(aName: string): Integer;
    function Contains(Name: string): Boolean;
    function RenameOperation(CurrentName, NewName: string): Boolean;
    property Op[aName: string]: TOperator read GetOp; default;
  end;

procedure AddOperatoren(AOperatoren: TOperatoren);
procedure AddMath(AOperatoren: TOperatoren);
procedure AddTrigonometry(AOperatoren: TOperatoren);
procedure AddTrigonometryDeg(AOperatoren: TOperatoren);
procedure AddLogarithm(AOperatoren: TOperatoren);

type

  TTypeStack = (tsValue, tsOperator, tsFunction, tsLeftBracket, tsRightBracket, tsSeparator, tsVariable);

  TParserItem = class
  strict private
    FValue         : Double;
    FTypeStack     : TTypeStack;
    FName          : string;
    FArgumentsCount: Integer;
    FTextPos       : Integer;
  public
    constructor Create(AName: string; APos: Integer); overload;
    constructor Create(aTypeStack: TTypeStack; APos: Integer; aName: string = ''); overload;
    constructor Create(aValue: Double; APos: Integer); overload;
    procedure Assign(Source: TObject);
    procedure Write(S: TStream);
    procedure Read(S: TStream);
    property Name: string read FName write FName;
    property ArgumentsCount: Integer read FArgumentsCount write FArgumentsCount;
    property Value: Double read FValue write FValue;
    property TypeStack: TTypeStack read FTypeStack write FTypeStack;
    property TextPos: Integer read FTextPos write FTextPos;
  end;

  TVar = record
  private
    FValue    : Double;
    FValueFunc: TFunc<Double>;
    FName     : string;
    function GetIsFunc: Boolean;
    function GetValue: Double;
    procedure SetValue(const Value: Double);
  public
    constructor Create(aName: string; aValue: Double); overload;
    constructor Create(aName: string; aValue: TFunc<Double>); overload;
    property Name: string read FName write FName;
    property IsFunc: Boolean read GetIsFunc;
  public
    class operator Implicit(a: Double): TVar; overload; inline;
    class operator Implicit(a: TFunc<Double>): TVar; overload; inline;
    class operator Implicit(a: TVar): Double; overload; inline;
  end;

  TVariables = class(TDictionary<string, TVar>)
  private
    function GetItem(const Key: string): TVar;
    procedure SetItem(const Key: string; const Value: TVar);
  public
    procedure Add(Name: string; Value: Double); overload;
    procedure Add(Name: string; Value: TFunc<Double>); overload;
    property Items[const Key: string]: TVar read GetItem write SetItem; default;
  end;

procedure ClearAndFreeStack(S: TStack<TParserItem>);

implementation

uses
  System.Math;

{ TOperator }

constructor TOperator.Create(aPriority: Integer; aArguments: Integer; aName: string);
begin
  inherited Create;
  FPriority  := aPriority;
  FArguments := aArguments;
  FName      := aName;
end;

constructor TOperator.Create(aPriority: Integer; aArguments: Integer; aName: string; aOpF: TOpFunc);
begin
  Create(aPriority, aArguments, aName);
  FFunc      := aOpF;
  FErrorFunc := nil;
end;

constructor TOperator.Create(aPriority: Integer; aArguments: Integer; aName: string; aOpF: TOpFunc; aIsError: TErrorFunc);
begin
  Create(aPriority, aArguments, aName, aOpF);
  FErrorFunc := aIsError;
end;

function TOperator.IsError(Values: TArray<Double>; var Error: Integer): Boolean;
begin
  if not Assigned(FErrorFunc) then
  begin
    Error  := cNoError;
    Result := False;
  end
  else
  begin
    Error  := FErrorFunc(Values);
    Result := not(Error = cNoError);
  end;
end;

{ TOperationen }

constructor TOperatoren.Create;
begin
  inherited Create(True);
  AddOpNone;
  AddOpNeg;
end;

function TOperatoren.Contains(Name: string): Boolean;
begin
  Result := IndexOfName(Name) <> -1;
end;

function TOperatoren.IndexOfName(aName: string): Integer;
var
  i: Integer;
begin
  for i := 0 to Count - 1 do
    if SameText(Self.Items[i].FName, aName) then
      Exit(i);
  Result := -1;
end;

function TOperatoren.GetOp(aName: string): TOperator;
var
  iP: TOperator;
begin
  for iP in Self do
    if SameText(iP.FName, aName) then
      Exit(iP);

  Result := nil;
end;

function TOperatoren.RenameOperation(CurrentName, NewName: string): Boolean;
var
  i: Integer;
begin
  Result := False;
  if NewName = '' then
    Exit;
  NewName := AnsiLowerCase(NewName);
  if not ValidVariableName(NewName) then
    Exit;

  i := IndexOfName(AnsiLowerCase(CurrentName));

  if i <> -1 then
  begin
    Self.Items[i].FName := NewName;
    Result              := True;
  end;
end;

function TOperatoren.ValidVariableName(Name: string): Boolean;
/// Determine if variable Name is defined with 'a'..'z', '_'
/// and does not enter in conflict with function Names:
var
  i: Integer;
begin
  Result := False;
  Name   := trim(AnsiLowerCase(Name));
  if (Name = '') or (Name = 'e') then
    Exit; // ex: 5E3 = 5 * 10*10*10
  if IndexOfName(Name) <> -1 then
    Exit;
  if not CharInSet(Name[1], ['_', 'a' .. 'z']) then
    Exit;

  for i := 2 to Length(Name) do
    if not CharInSet(Name[i], ['_', 'a' .. 'z', '0' .. '9']) then
      Exit(True);
end;

procedure TOperatoren.AddOpNone;
begin
  Add(TOperator.Create(0, 0, ''));
end;

procedure TOperatoren.AddOpNeg;
begin
  // Internal functions
  // OpNeg (negative value, used for diferenciate with substract operator)
  Add(TOperator.Create(4, 1, 'neg',
    function(Values: TArray<Double>): Double
    begin
      Result := -Values[0];
    end));
end;

function TOperatoren.AddCustomOperation(Name: string; Arguments: Integer; Priority: byte): Boolean;
begin
  Name := AnsiLowerCase(Name);
  if ValidVariableName(Name) then
  begin
    Add(TOperator.Create(Priority, Arguments, Name));
    Exit(True);
  end;
  Result := False;
end;

procedure AddOperatoren(AOperatoren: TOperatoren);
begin
  // Add
  AOperatoren.Add(TOperator.Create(1, 2, '+',
    function(Values: TArray<Double>): Double
    begin
      Result := Values[0] + Values[1];
    end));

  // subtract
  AOperatoren.Add(TOperator.Create(1, 2, '-',
    function(Values: TArray<Double>): Double
    begin
      Result := Values[0] - Values[1];
    end));

  // Multi
  AOperatoren.Add(TOperator.Create(2, 2, '*',
    function(Values: TArray<Double>): Double
    begin
      Result := Values[0] * Values[1];
    end));

  // Divide
  AOperatoren.Add(TOperator.Create(2, 2, '/',
    function(Values: TArray<Double>): Double
    begin
      Result := Values[0] / Values[1];
    end,
    function(Values: TArray<Double>): Integer
    begin
      if Values[1] = 0 then
        Result := cErrorDivByZero
      else
        Result := cNoError;
    end));

  // Power
  AOperatoren.Add(TOperator.Create(3, 2, '^',
    function(Values: TArray<Double>): Double
    begin
      Result := Power(Values[0], Values[1]);
    end,
    function(Values: TArray<Double>): Integer
    begin
      if (frac(Values[1]) <> 0) and (Values[0] < 0) then
        Result := cErrorPower
      else
        Result := cNoError;
    end));

  // Mod
  AOperatoren.Add(TOperator.Create(2, 2, '%',
    function(Values: TArray<Double>): Double
    var
      x, y: Double;
    begin
      x := Values[0];
      y := Values[1];
      Result := x - int(x / y) * y;
    end,
    function(Values: TArray<Double>): Integer
    begin
      if Values[1] = 0 then
        Result := cErrorDivByZero
      else
        Result := cNoError;
    end));
end;

procedure AddMath(AOperatoren: TOperatoren);
begin
  // Absolute
  AOperatoren.Add(TOperator.Create(0, 1, 'abs',
    function(Values: TArray<Double>): Double
    begin
      Result := Abs(Values[0]);
    end,
    function(Values: TArray<Double>): Integer
    begin
      if (Length(Values) > 1) then
        Result := cErrorToManyArgs
      else
        Result := cNoError;
    end));

  // Max
  AOperatoren.Add(TOperator.Create(0, -1, 'max',
    function(Values: TArray<Double>): Double
    begin
      Result := MaxValue(Values);
    end,
    function(Values: TArray<Double>): Integer
    begin
      if (Length(Values) < 2) then
        Result := cErrorNotEnoughArgs
      else
        Result := cNoError;
    end));

  // Min
  AOperatoren.Add(TOperator.Create(0, -1, 'min',
    function(Values: TArray<Double>): Double
    begin
      Result := MinValue(Values);
    end,
    function(Values: TArray<Double>): Integer
    begin
      if (Length(Values) < 2) then
        Result := cErrorNotEnoughArgs
      else
        Result := cNoError;
    end));

  // RoundTo
  AOperatoren.Add(TOperator.Create(0, 2, 'roundto',
    function(Values: TArray<Double>): Double
    begin
      Result := RoundTo(Values[0], round(Values[1]));
    end));

  // Sqrt
  AOperatoren.Add(TOperator.Create(0, 1, 'sqrt',
    function(Values: TArray<Double>): Double
    begin
      Result := sqrt(Values[0]);
    end,
    function(Values: TArray<Double>): Integer
    begin
      if (Values[0] < 0) then
        Result := cErrorFxInvalidValue
      else
        Result := cNoError;
    end));

  // Sqr
  AOperatoren.Add(TOperator.Create(0, 1, 'sqr',
    function(Values: TArray<Double>): Double
    begin
      Result := sqr(Values[0]);
    end));

  // Sum
  AOperatoren.Add(TOperator.Create(0, -1, 'sum',
    function(Values: TArray<Double>): Double
    begin
      Result := Sum(Values);
    end,
    function(Values: TArray<Double>): Integer
    begin
      if (Length(Values) < 2) then
        Result := cErrorNotEnoughArgs
      else
        Result := cNoError;
    end));

  // Ceil
  AOperatoren.Add(TOperator.Create(0, 1, 'ceil',
    function(Values: TArray<Double>): Double
    begin
      Result := Ceil(Values[0]);
    end));

  // Floor
  AOperatoren.Add(TOperator.Create(0, 1, 'floor',
    function(Values: TArray<Double>): Double
    begin
      Result := Floor(Values[0]);
    end));

  // Sign
  AOperatoren.Add(TOperator.Create(0, 1, 'sign',
    function(Values: TArray<Double>): Double
    begin
      Result := Sign(Values[0]);
    end));

  // Int;
  AOperatoren.Add(TOperator.Create(0, 1, 'int',
    function(Values: TArray<Double>): Double
    begin
      Result := int(Values[0]);
    end));

  // Frac;
  AOperatoren.Add(TOperator.Create(0, 1, 'frac',
    function(Values: TArray<Double>): Double
    begin
      Result := frac(Values[0]);
    end));
end;

procedure AddTrigonometry(AOperatoren: TOperatoren);
begin
  // sin
  AOperatoren.Add(TOperator.Create(0, 1, 'sin',
    function(Values: TArray<Double>): Double
    begin
      Result := Sin(Values[0]);
    end));

  // cos
  AOperatoren.Add(TOperator.Create(0, 1, 'cos',
    function(Values: TArray<Double>): Double
    begin
      Result := Cos(Values[0]);
    end));

  // tan
  AOperatoren.Add(TOperator.Create(0, 1, 'tan',
    function(Values: TArray<Double>): Double
    begin
      Result := Tan(Values[0]);
    end,
    function(Values: TArray<Double>): Integer
    begin
      if (Values[0] = pi / 2) or (Values[0] = 1.5 * pi) then
        Result := cErrorTan
      else
        Result := cNoError;
    end));

  // arcsin
  AOperatoren.Add(TOperator.Create(0, 1, 'asin',
    function(Values: TArray<Double>): Double
    begin
      Result := arcsin(Values[0]);
    end,
    function(Values: TArray<Double>): Integer
    begin
      if (Values[0] < -1) or (Values[0] > 1) then
        Result := cErrorFxInvalidValue
      else
        Result := cNoError;
    end));

  // arccos
  AOperatoren.Add(TOperator.Create(0, 1, 'acos',
    function(Values: TArray<Double>): Double
    begin
      Result := arccos(Values[0]);
    end,
    function(Values: TArray<Double>): Integer
    begin
      if (Values[0] < -1) or (Values[0] > 1) then
        Result := cErrorFxInvalidValue
      else
        Result := cNoError;
    end));

  // arctan
  AOperatoren.Add(TOperator.Create(0, 1, 'atan',
    function(Values: TArray<Double>): Double
    begin
      Result := arctan(Values[0]);
    end));

  // RadToDeg
  AOperatoren.Add(TOperator.Create(0, 1, 'radtodeg',
    function(Values: TArray<Double>): Double
    begin
      Result := RadToDeg(Values[0]);
    end));

  // DegToRad
  AOperatoren.Add(TOperator.Create(0, 1, 'degtorad',
    function(Values: TArray<Double>): Double
    begin
      Result := DegToRad(Values[0]);
    end));
end;

procedure AddTrigonometryDeg(AOperatoren: TOperatoren);
begin
  // Sin deg
  AOperatoren.Add(TOperator.Create(0, 1, 'sind',
    function(Values: TArray<Double>): Double
    begin
      Result := Sin(DegToRad(Values[0]));
    end));
  // Cos deg
  AOperatoren.Add(TOperator.Create(0, 1, 'cosd',
    function(Values: TArray<Double>): Double
    begin
      Result := Cos(DegToRad(Values[0]));
    end));

  // Tan deg
  AOperatoren.Add(TOperator.Create(0, 1, 'tand',
    function(Values: TArray<Double>): Double
    begin
      Result := Tan(DegToRad(Values[0]));
    end,
    function(Values: TArray<Double>): Integer
    begin
      if SameValue(DegToRad(Values[0]), pi / 2, 0.0001) or SameValue(DegToRad(Values[0]), 1.5 * pi, 0.0001) then
        Result := cErrorTan
      else
        Result := cNoError;
    end));

  // arcSin deg
  AOperatoren.Add(TOperator.Create(0, 1, 'asind',
    function(Values: TArray<Double>): Double
    begin
      Result := RadToDeg(arcsin(Values[0]));
    end,
    function(Values: TArray<Double>): Integer
    begin
      if (Values[0] < RadToDeg(-1)) or (Values[0] > RadToDeg(1)) then
        Result := cErrorFxInvalidValue
      else
        Result := cNoError;
    end));

  // arcCos deg
  AOperatoren.Add(TOperator.Create(0, 1, 'acosd',
    function(Values: TArray<Double>): Double
    begin
      Result := RadToDeg(arccos(Values[0]));
    end,
    function(Values: TArray<Double>): Integer
    begin
      if (Values[0] < RadToDeg(-1)) or (Values[0] > RadToDeg(1)) then
        Result := cErrorFxInvalidValue
      else
        Result := cNoError;
    end));

  // arcTan deg
  AOperatoren.Add(TOperator.Create(0, 1, 'atand',
    function(Values: TArray<Double>): Double
    begin
      Result := RadToDeg(arctan(Values[0]));
    end));
end;

procedure AddLogarithm(AOperatoren: TOperatoren);
begin
  // Ln
  AOperatoren.Add(TOperator.Create(0, 1, 'ln',
    function(Values: TArray<Double>): Double
    begin
      Result := ln(Values[0]);
    end,
    function(Values: TArray<Double>): Integer
    begin
      if (Values[0] <= 0) then
        Result := cErrorFxInvalidValue
      else
        Result := cNoError;
    end));

  // lnxp1
  AOperatoren.Add(TOperator.Create(0, 1, 'lnxp1',
    function(Values: TArray<Double>): Double
    begin
      Result := LnXP1(Values[0]);
    end,
    function(Values: TArray<Double>): Integer
    begin
      if (Values[0] <= -1) then
        Result := cErrorFxInvalidValue
      else
        Result := cNoError;
    end));

  // ldexp
  AOperatoren.Add(TOperator.Create(0, 2, 'ldexp',
    function(Values: TArray<Double>): Double
    begin
      Result := Ldexp(Values[0], round(Values[1]));
    end));

  // Log
  AOperatoren.Add(TOperator.Create(0, 1, 'log10',
    function(Values: TArray<Double>): Double
    begin
      Result := log10(Values[0]);
    end,
    function(Values: TArray<Double>): Integer
    begin
      if (Values[0] <= 0) then
        Result := cErrorFxInvalidValue
      else
        Result := cNoError;
    end));

  // LogN
  AOperatoren.Add(TOperator.Create(0, 2, 'logn',
    function(Values: TArray<Double>): Double
    begin
      Result := LogN(Values[0], Values[1]);
    end,
    function(Values: TArray<Double>): Integer
    begin
      if (Values[0] <= 0) or (Values[1] <= 0) or (Log2(Values[0]) = 0) then
        Result := cErrorFxInvalidValue
      else
        Result := cNoError;
    end));

  // Exp
  AOperatoren.Add(TOperator.Create(0, 1, 'exp',
    function(Values: TArray<Double>): Double
    begin
      Result := exp(Values[0]);
    end));
end;

{ TParserItem }

constructor TParserItem.Create(aTypeStack: TTypeStack; APos: Integer; aName: string);
begin
  inherited Create;
  FValue     := 0;
  FTypeStack := aTypeStack;
  FName      := aName;
  FTextPos   := APos;
end;

procedure TParserItem.Assign(Source: TObject);
begin
  if Source is TParserItem then
  begin
    FValue          := TParserItem(Source).FValue;
    FTypeStack      := TParserItem(Source).FTypeStack;
    FName           := TParserItem(Source).FName;
    FArgumentsCount := TParserItem(Source).FArgumentsCount;
    FTextPos        := TParserItem(Source).FTextPos;
  end;
  inherited;
end;

constructor TParserItem.Create(aValue: Double; APos: Integer);
begin
  inherited Create;
  FValue     := aValue;
  FTypeStack := tsValue;
  FName      := '';
  FTextPos   := APos;
end;

constructor TParserItem.Create(AName: string; APos: Integer);
begin
  inherited Create;
  FName    := AName;
  FTextPos := APos;
  if (Length(AName) = 1) then
  begin
    case AName[1] of
      '-', '+', '/', '*', '^', '%':
        FTypeStack := tsOperator;
      '(':
        FTypeStack := tsLeftBracket;
      ')':
        FTypeStack := tsRightBracket;
    else
      FTypeStack := tsFunction;
    end;
  end
  else
    FTypeStack := tsFunction;
end;

procedure TParserItem.Read(S: TStream);
var
  c     : Integer;
  StrBuf: TBytes;
begin
  S.ReadBuffer(FValue, SizeOf(Double));
  S.ReadBuffer(FTypeStack, SizeOf(TTypeStack));

  S.ReadBuffer(c, SizeOf(Integer));
  SetLength(StrBuf, c);
  S.ReadBuffer(StrBuf, c);
  FName := TEncoding.UTF8.GetString(StrBuf);

  S.ReadBuffer(FArgumentsCount, SizeOf(Integer));
end;

procedure TParserItem.Write(S: TStream);
var
  c     : Integer;
  StrBuf: TBytes;
begin
  S.WriteBuffer(FValue, SizeOf(Double));
  S.WriteBuffer(FTypeStack, SizeOf(TTypeStack));

  StrBuf := TEncoding.UTF8.GetBytes(FName);
  c      := Length(StrBuf);
  S.WriteBuffer(c, SizeOf(Integer));
  S.WriteBuffer(StrBuf, c);

  S.WriteBuffer(FArgumentsCount, SizeOf(Integer));
end;

procedure ClearAndFreeStack(S: TStack<TParserItem>);
begin
  while S.Count > 0 do
    S.Pop.Free;
end;

{ TVar }

constructor TVar.Create(aName: string; aValue: TFunc<Double>);
begin
  FName      := aName;
  FValueFunc := aValue;
end;

constructor TVar.Create(aName: string; aValue: Double);
begin
  FName  := aName;
  FValue := aValue;
end;

function TVar.GetIsFunc: Boolean;
begin
  Result := Assigned(FValueFunc);
end;

function TVar.GetValue: Double;
begin
  if GetIsFunc then
    Result := FValueFunc
  else
    Result := FValue;
end;

class operator TVar.Implicit(a: TFunc<Double>): TVar;
begin
  Result.FValueFunc := a;
end;

class operator TVar.Implicit(a: Double): TVar;
begin
  Result.SetValue(a);
end;

class operator TVar.Implicit(a: TVar): Double;
begin
  Result := a.GetValue;
end;

procedure TVar.SetValue(const Value: Double);
begin
  if GetIsFunc then
    raise Exception.Create('Fehler: Value is a function')
  else
    FValue := Value;
end;

{ TVariables }

procedure TVariables.Add(Name: string; Value: Double);
begin
  inherited AddOrSetValue(Name.ToUpper, TVar.Create(Name, Value));
end;

procedure TVariables.Add(Name: string; Value: TFunc<Double>);
begin
  inherited AddOrSetValue(Name.ToUpper, TVar.Create(Name, Value));
end;

function TVariables.GetItem(const Key: string): TVar;
begin
  Result := Self.Items[Key.ToUpper];
end;

procedure TVariables.SetItem(const Key: string; const Value: TVar);
begin
  AddOrSetValue(Key.ToUpper, Value);
end;

{ TError }

procedure TError.Clear;
begin
  FCode     := cNoError;
  FPosition := -1;
end;

constructor TError.Create(ACode, APosition: Integer);
begin
  FCode     := ACode;
  FPosition := APosition;
end;

function TError.IsNoError: Boolean;
begin
  Result := FCode = cNoError;
end;

function TError.ToString: string;
begin
  case FCode of
    cNoError:
      Result := '';

    cInternalError:
      Result := 'Cannot parse';

    cErrorInvalidCar:
      Result := 'Invalid car';
    cErrorUnknownName:
      Result := 'Unknown function or variable';
    cErrorInvalidFloat:
      Result := 'Invalid float number';
    cErrorOperator:
      Result := 'Operator cannot be placed here';
    cErrorNotEnoughArgs:
      Result := 'Not enough arguments or operands';
    cErrorSeparatorNeedArgument:
      Result := 'Missing argument after separator';
    cErrorMissingLeftBrackets:
      Result := 'Missing at least one left Bracket';
    cErrorMissingRightBrackets:
      Result := 'Missing at least one right Bracket';
    cErrorLeftBracket:
      Result := 'Left Bracket cannot be placed here';
    cErrorRightBracket:
      Result := 'Right Bracket cannot be placed here';
    cErrorSeparator:
      Result := 'Separator cannot be placed here';
    cErrorOperatorNeedArgument:
      Result := 'Operator must be followed by argument';

    cErrorCalc:
      Result := 'Invalid operation';
    cErrorDivByZero:
      Result := 'Division by zero';
    cErrorPower:
      Result := 'Invalid use of power function';
    cErrorFxInvalidValue:
      Result := 'Invalid parameter value for function';
    cErrorTan:
      Result := 'Invalid parameter value for tangens-function';
  end;
end;

end.
