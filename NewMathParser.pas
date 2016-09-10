// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

/// Viel geändert von Jens Biermann am 07.02.2012
/// Viel geändert von Jens Biermann am 29.01.2015
/// Änderungen von Jens Biermann am 23.08.2016
/// TParserStack to TList and Bugfix 10.09.2016

unit NewMathParser;

interface

uses System.Classes, System.Generics.Collections, NewMathParser.Oper, System.SysUtils;

type
  TNotifyError = Procedure(Sender: TObject; Error: TError) of object;

  TParserStack = class(TList<TParserItem>)
  strict private
  public
    procedure ClearAndFree;
    procedure SetArgCount;
    function ArgCount(const SI: TParserItem): Integer;
    function CountLeftBracket: Integer;
    function CountRightBracket: Integer;
    function ContainsVariable: Boolean;
  end;

  TProzessbasis = class(TObject)
  strict protected
    FStack     : TParserStack;
    FError     : PError;
    FOperations: TOperatoren;
  public
    constructor Create(AStack: TParserStack; AOperations: TOperatoren; AError: PError);
    // destructor Destroy; override;
    procedure Prozess; virtual; abstract;
    property Error: PError read FError;
  end;

  TParser = class(TProzessbasis)
  strict private
    FPos       : Integer;
    FExpression: string;
    procedure PushExponent(AExponent: Integer = 10);
    procedure PushFunctionVariable(AText: string);
    procedure ParseNumbers;
    procedure ParseFunctions;
    function FunctionOfExpression: string;
    function NumberOfExpression: string;
  public
    procedure Prozess; override;
    property Expression: string read FExpression write FExpression;
  end;

  TValidate = class(TProzessbasis)
  strict private
    procedure ValidateRightBracket(const Pos: Integer);
    procedure ValidateSeparator(const Pos: Integer);
    procedure ValidateOperator(const Pos: Integer);
    procedure CheckBracketError;
    procedure Loop;
    procedure CleanPlusMinus;
    procedure InsertMulti;
  public
    procedure Prozess; override;
  end;

  TPriority = class(TProzessbasis)
  strict private
    FTmpStack: TStack<TParserItem>;
    FPStack  : TStack<TParserItem>;
    procedure MoveRightBracket(Current: TParserItem);
    procedure MoveSeparator(Current: TParserItem);
    procedure MoveOperator(Current: TParserItem);
    procedure CreateNewStack;
  public
    constructor Create(AStack: TParserStack; AOperations: TOperatoren; AError: PError);
    destructor Destroy; override;
    procedure Prozess; override;
  end;

  TCountArguments = class(TProzessbasis)
  strict private
    procedure CheckError;
    procedure CountArg;
  public
    procedure Prozess; override;
  end;

  TCalculator = class(TProzessbasis)
  strict private
    FVariables  : TVariables;
    FResultStack: TStack<TParserItem>;
    FValues     : TList<Double>;
    procedure StackToResult_Operation(ACurrent: TParserItem);
    procedure StackToResult;
    function SetResult: Double;
    procedure StackToResult_Variable(Current: TParserItem);
  public
    constructor Create(AStack: TParserStack; AOperations: TOperatoren; AError: PError);
    destructor Destroy; override;
    function calcResult: Double;
    property Variables: TVariables read FVariables write FVariables;
  end;

  TMathParser = class(TObject)
  private
    FResult    : Double;
    FError     : TError;
    FTmpStack  : TParserStack;
    FMainStack : TParserStack;
    FExpression: string;
    FOnError   : TNotifyError;
    FVariables : TVariables;
    FCalculator: TCalculator;
    FIsToCalc  : Boolean;
    FValidate  : TValidate;
    FParser    : TParser;
    FPriority  : TPriority;
    FCountArgs : TCountArguments;
    FOperations: TOperatoren;
    procedure SaveStack;
    procedure tmpToStack;
    function GetParserResult: Double;
    procedure SetExpression(const Value: string);
    procedure DoError(AError: TError);
    procedure CreateStack;
  public
    constructor Create;
    destructor Destroy; override;
    function GetLastError: TError;
    function GetLastErrorString: string;
    // dont use stream!
    procedure SaveToStream(S: TStream);
    procedure LoadFromStream(S: TStream);
    property Expression: string read FExpression write SetExpression;
    property ParserResult: Double read GetParserResult;
    property Variables: TVariables read FVariables write FVariables;
    property OnError: TNotifyError read FOnError write FOnError;
  end;

implementation

// var
// MP   : TMathParser;
// Error: TError;
// begin
// MP := TMathParser.Create;
// try
// MP.Expression := '((4+5)6)7 + Min(3, 4, 5)';
// Error         := TError;
// if Error.IsNoError then
// ShowMessage(MP.ParserResult.ToString);
// finally
// MP.Free;
// end;
// end;

constructor TMathParser.Create;
begin
  inherited;
  FExpression := '';
  FError.Clear;
  FIsToCalc   := False;
  FOperations := TOperatoren.Create;
  FMainStack  := TParserStack.Create;
  FTmpStack   := TParserStack.Create;
  FVariables  := TVariables.Create;
  FVariables.Add('pi', Pi);
  FCalculator           := TCalculator.Create(FMainStack, FOperations, @FError);
  FCalculator.Variables := FVariables;

  AddOperatoren(FOperations);
  AddMath(FOperations);
  AddTrigonometry(FOperations);
  AddTrigonometryDeg(FOperations);
  AddLogarithm(FOperations);

  FValidate  := TValidate.Create(FMainStack, FOperations, @FError);
  FParser    := TParser.Create(FMainStack, FOperations, @FError);
  FPriority  := TPriority.Create(FMainStack, FOperations, @FError);
  FCountArgs := TCountArguments.Create(FMainStack, FOperations, @FError);
end;

destructor TMathParser.Destroy;
begin
  FCountArgs.Free;
  FPriority.Free;
  FParser.Free;
  FValidate.Free;

  FCalculator.Free;
  FTmpStack.ClearAndFree;
  FTmpStack.Free;
  FMainStack.ClearAndFree;
  FMainStack.Free;

  FVariables.Free;
  FOperations.Free;
  inherited;
end;

procedure TMathParser.DoError(AError: TError);
begin
  if Assigned(FOnError) and not AError.IsNoError then
    FOnError(Self, FError);
end;

procedure TMathParser.SetExpression(const Value: string);
begin
  if not SameStr(FExpression, Value) then
  begin
    FTmpStack.ClearAndFree;
    FResult     := 0;
    FExpression := Value;
    FError.Clear;
    if (FExpression.Length > 0) then
    begin
      CreateStack;
      FIsToCalc := True;
    end;
  end;
end;

function TMathParser.GetParserResult: Double;
begin
  if FIsToCalc or FMainStack.ContainsVariable or FTmpStack.ContainsVariable then
  begin
    if FMainStack.Count > 0 then
      SaveStack
    else
      tmpToStack;
    FResult := FCalculator.calcResult;
    DoError(FError);
    FIsToCalc := False;
  end;
  Result := FResult;
end;

procedure TMathParser.SaveStack;
var
  iItem, tmp: TParserItem;
begin
  FTmpStack.ClearAndFree;
  for iItem in FMainStack do
  begin
    tmp := TParserItem.Create;
    tmp.Assign(iItem);
    FTmpStack.Add(tmp);
  end;
end;

procedure TMathParser.tmpToStack;
var
  iItem, tmp: TParserItem;
begin
  for iItem in FTmpStack do
  begin
    tmp := TParserItem.Create;
    tmp.Assign(iItem);
    FMainStack.Add(tmp);
  end;
end;

procedure TMathParser.SaveToStream(S: TStream);
var
  c     : Integer;
  SI    : TParserItem;
  StrBuf: TBytes;
begin
  StrBuf := TEncoding.UTF8.GetBytes(FExpression);
  c      := Length(StrBuf);
  S.WriteBuffer(c, SizeOf(Integer));
  S.WriteBuffer(StrBuf, c);

  S.WriteBuffer(FError, SizeOf(Integer));
  c := FMainStack.Count;
  S.WriteBuffer(c, SizeOf(Integer));
  for SI in FMainStack do
    SI.Write(S);
end;

procedure TMathParser.LoadFromStream(S: TStream);
var
  c     : Integer;
  i     : Integer;
  SI    : TParserItem;
  StrBuf: TBytes;
  Exp   : string;
begin
  S.Position := 0;

  S.ReadBuffer(c, SizeOf(Integer));
  SetLength(StrBuf, c);
  S.ReadBuffer(StrBuf, c);
  Exp := TEncoding.UTF8.GetString(StrBuf);
  if not SameStr(Exp, FExpression) then
  begin
    FExpression := Exp;
    FResult     := 0;
    FIsToCalc   := True;
  end;

  S.ReadBuffer(FError, SizeOf(Integer));
  FMainStack.ClearAndFree;

  S.ReadBuffer(c, SizeOf(Integer));
  for i := 0 to c - 1 do
  begin
    SI := TParserItem.Create;
    SI.Read(S);
    FMainStack.Add(SI);
  end;
end;

procedure TMathParser.CreateStack;
begin
  FMainStack.ClearAndFree;

  FParser.Expression := FExpression.ToLower;
  FParser.Prozess;
  FValidate.Prozess;
  FCountArgs.Prozess;
  FPriority.Prozess;
  DoError(FError);
end;

function TMathParser.GetLastError: TError;
begin
  Result := FError;
end;

function TMathParser.GetLastErrorString: string;
begin
  Result := FError.ToString;
end;

{ TPostProzess_Validate }

procedure TValidate.Prozess;
begin
  if FError^.IsNoError then
  begin
    CheckBracketError;
    CleanPlusMinus;
    InsertMulti;
    Loop;
  end;
end;

procedure TValidate.CleanPlusMinus;
const
  STypes = [tsOperator, tsLeftBracket, tsSeparator];
var
  i: Integer;
begin
  for i := FStack.Count - 1 downto 0 do
    if (i = 0) or (FStack[i - 1].TypeStack in STypes) then
      if SameStr(FStack[i].Name, '+') then
        FStack.Extract(FStack[i]).Free
      else if SameStr(FStack[i].Name, '-') then
        FStack[i].Name := 'neg';
end;

procedure TValidate.CheckBracketError;
var
  LeftBracketCount : Integer;
  RightBracketCount: Integer;
begin
  LeftBracketCount  := FStack.CountLeftBracket;
  RightBracketCount := FStack.CountRightBracket;

  if LeftBracketCount > RightBracketCount then
  begin
    FError^.Code     := cErrorMissingRightBrackets;
    FError^.Position := -1;
  end

  else if LeftBracketCount < RightBracketCount then
  begin
    FError^.Code     := cErrorMissingLeftBrackets;
    FError^.Position := -1;
  end;
end;

procedure TValidate.InsertMulti;
const
  Types1 = [tsLeftBracket, tsValue, tsVariable, tsFunction];
  Types2 = [tsValue, tsVariable, tsRightBracket];
var
  i: Integer;
begin
  for i := FStack.Count - 2 downto 0 do
    if (FStack[i].TypeStack in Types2) and (FStack[i + 1].TypeStack in Types1) then
      FStack.Insert(i + 1, TParserItem.Create('*', FStack[i].TextPos));
end;

procedure TValidate.Loop;
var
  i: Integer;
begin
  i := 0;
  while (FError^.IsNoError) and (i < FStack.Count) do
  begin
    case FStack[i].TypeStack of
      tsRightBracket:
        ValidateRightBracket(i);

      tsSeparator:
        ValidateSeparator(i);

      tsOperator:
        ValidateOperator(i);
    end;
    Inc(i);
  end;
end;

procedure TValidate.ValidateOperator(const Pos: Integer);
begin
  if (Pos = 0) or (FStack[Pos - 1].TypeStack in [tsOperator, tsLeftBracket, tsSeparator]) then
  begin
    if (FStack[Pos].Name.Length = 1) and CharInSet(FStack[Pos].Name[1], ['/', '*', '^', '%']) then
    begin
      FError^.Code     := cErrorOperator;
      FError^.Position := FStack[Pos].TextPos;
    end;
  end

  else if (Pos = FStack.Count - 1) then
  begin
    FError^.Code     := cErrorOperatorNeedArgument;
    FError^.Position := FStack[Pos].TextPos;
  end;
end;

procedure TValidate.ValidateRightBracket(const Pos: Integer);
begin
  if (Pos > 0) and (FStack[Pos - 1].TypeStack in [tsFunction, tsOperator, tsSeparator]) then
  begin
    FError^.Code     := cErrorRightBracket;
    FError^.Position := FStack[Pos].TextPos;
  end;
end;

procedure TValidate.ValidateSeparator(const Pos: Integer);
begin
  if Pos = 0 then
  begin
    FError^.Code     := cErrorSeparator;
    FError^.Position := FStack[Pos].TextPos;
  end
  else
    case FStack[Pos - 1].TypeStack of
      tsSeparator:
        begin
          FError^.Code     := cErrorSeparatorNeedArgument;
          FError^.Position := FStack[Pos].TextPos;
        end;
      tsOperator, tsLeftBracket:
        begin
          FError^.Code     := cErrorSeparator;
          FError^.Position := FStack[Pos].TextPos;
        end;
    end;
end;

{ TProzessbasis }

constructor TProzessbasis.Create(AStack: TParserStack; AOperations: TOperatoren; AError: PError);
begin
  inherited Create;
  FOperations := AOperations;
  FStack      := AStack;
  FError      := AError;
end;

{ TPraeProzess }

procedure TParser.ParseFunctions;
var
  S: string;
begin
  S := FunctionOfExpression;
  if (Length(S) > 1) and CharInSet(S[1], ['e']) and CharInSet(S[2], ['0' .. '9', ' ']) then
  begin
    Inc(FPos);
    PushExponent;
  end
  else if Length(S) > 0 then
  begin
    FPos := FPos + Length(S);
    PushFunctionVariable(S);
  end;
end;

procedure TParser.ParseNumbers;
var
  S: string;
  v: Double;
begin
  S    := NumberOfExpression;
  FPos := FPos + Length(S);
  if CharInSet(S[Length(S)], [',']) then
  begin
    Dec(FPos);
    FExpression[FPos] := ';';
    System.Delete(S, Length(S), 1);
  end;

  if TryStrToFloat(S, v) then
    FStack.Add(TParserItem.Create(v, FPos));
end;

procedure TParser.Prozess;
var
  len: Integer;
begin
  len  := Length(FExpression);
  FPos := 1;

  while FError^.IsNoError and (FPos <= len) do
    with FStack do
    begin
      case FExpression[FPos] of
        '(', '{', '[':
          begin
            Add(TParserItem.Create(FExpression[FPos], FPos));
            Inc(FPos);
          end;

        ')', '}', ']':
          begin
            Add(TParserItem.Create(FExpression[FPos], FPos));
            Inc(FPos);
          end;

        'a' .. 'z', '_':
          ParseFunctions;

        '0' .. '9', '.', ',':
          ParseNumbers;

        ';':
          begin
            Add(TParserItem.Create(tsSeparator, FPos));
            Inc(FPos);
          end;

        '-', '+', '/', '*', '^', '%':
          begin
            Add(TParserItem.Create(FExpression[FPos], FPos));
            Inc(FPos);
          end;

        ' ':
          Inc(FPos);

      else
        begin
          FError^.Code     := cErrorInvalidCar;
          FError^.Position := FPos;
        end;
      end;
    end;
end;

function TParser.NumberOfExpression: string;
var
  i: Integer;
begin
  Result := '';
  for i  := FPos to Length(FExpression) do
    case FExpression[i] of
      '0' .. '9':
        Result := Result + FExpression[i];
      '.', ',':
        Result := Result + FormatSettings.DecimalSeparator;
    else
      Break;
    end;
end;

function TParser.FunctionOfExpression: string;
var
  i: Integer;
begin
  Result := '';
  for i  := FPos to Length(FExpression) do
    if CharInSet(FExpression[i], ['a' .. 'z', '0' .. '9', '_']) then
      Result := Result + FExpression[i]
    else
      Break;
end;

procedure TParser.PushExponent(AExponent: Integer);
begin
  FStack.Add(TParserItem.Create('*', FPos));
  FStack.Add(TParserItem.Create(AExponent, FPos));
  FStack.Add(TParserItem.Create('^', FPos));
end;

procedure TParser.PushFunctionVariable(AText: string);
var
  Op: TOperator;
begin
  Op := FOperations[AText];
  if Assigned(Op) then
    FStack.Add(TParserItem.Create(Op.Name, FPos - Length(AText)))
  else
    FStack.Add(TParserItem.Create(tsVariable, FPos - Length(AText), AText));
end;

{ TPostProzess_Priority }

constructor TPriority.Create(AStack: TParserStack; AOperations: TOperatoren; AError: PError);
begin
  inherited;
  FPStack   := TStack<TParserItem>.Create;
  FTmpStack := TStack<TParserItem>.Create;
end;

destructor TPriority.Destroy;
begin
  FTmpStack.Free;
  FPStack.Free;
  inherited;
end;

procedure TPriority.Prozess;
var
  iSS: TParserItem;
begin
  if FError^.IsNoError then
  begin
    FTmpStack.Clear;
    FPStack.Clear;
    for iSS in FStack do
    begin
      case iSS.TypeStack of
        tsValue, tsVariable:
          FPStack.Push(iSS);

        tsFunction, tsLeftBracket:
          FTmpStack.Push(iSS);

        tsRightBracket:
          MoveRightBracket(iSS);

        tsSeparator:
          MoveSeparator(iSS);

        tsOperator:
          MoveOperator(iSS);
      end;
    end;
    CreateNewStack;
  end;
end;

procedure TPriority.CreateNewStack;
var
  SI: TParserItem;
begin
  while FTmpStack.Count > 0 do
    FPStack.Push(FTmpStack.Pop);
  FStack.Clear;
  FStack.AddRange(FPStack);
end;

procedure TPriority.MoveOperator(Current: TParserItem);
var
  Prio: Integer;
begin
  Prio := FOperations[Current.Name].Priority;
  with FTmpStack do
    while (Count > 0) and (Peek.TypeStack = tsOperator) and (Prio <= FOperations[Peek.Name].Priority) do
      FPStack.Push(FTmpStack.Pop);
  FTmpStack.Push(Current);
end;

procedure TPriority.MoveSeparator(Current: TParserItem);
begin
  while (FTmpStack.Count > 0) and (FTmpStack.Peek.TypeStack <> tsLeftBracket) do
    FPStack.Push(FTmpStack.Pop);
  Current.Free;
end;

procedure TPriority.MoveRightBracket(Current: TParserItem);
begin
  while (FTmpStack.Count > 0) and (FTmpStack.Peek.TypeStack <> tsLeftBracket) do
    FPStack.Push(FTmpStack.Pop);
  FTmpStack.Pop.Free;
  if (FTmpStack.Count > 0) and (FTmpStack.Peek.TypeStack = tsFunction) then
    FPStack.Push(FTmpStack.Pop);
  Current.Free;
end;

{ TPostProzess_CountArguments }

procedure TCountArguments.CheckError;
var
  i, c: Integer;
begin
  for i := 0 to FStack.Count - 1 do
    if (FError^.IsNoError) and (FStack[i].TypeStack in [tsFunction, tsOperator]) then
    begin
      c := FOperations[FStack[i].Name].Arguments;
      if (FStack[i].ArgumentsCount > c) and (c > -1) or (c > -1) and (FStack[i].ArgumentsCount = 0) then
      begin
        FError^.Code     := cErrorToManyArgs;
        FError^.Position := FStack[i].TextPos;
      end

      else if FStack[i].ArgumentsCount < c then
      begin
        FError^.Code     := cErrorNotEnoughArgs;
        FError^.Position := FStack[i].TextPos;
      end

      else if (i < FStack.Count - 2) and (FStack[i + 1].TypeStack = tsLeftBracket) and
        (FStack[i + 2].TypeStack = tsRightBracket) then
      begin
        FStack[i].ArgumentsCount := 0;
        FError^.Code             := cErrorNotEnoughArgs;
        FError^.Position         := FStack[i].TextPos;
      end;
    end;
end;

procedure TCountArguments.Prozess;
begin
  if FError^.IsNoError then
  begin
    FStack.SetArgCount;
    CountArg;
    CheckError;
  end;
end;

procedure TCountArguments.CountArg;
var
  iSS: TParserItem;
begin
  for iSS in FStack do
    if iSS.TypeStack = tsOperator then
      iSS.ArgumentsCount := FOperations[iSS.Name].Arguments;
end;

{ TCalculator }

constructor TCalculator.Create(AStack: TParserStack; AOperations: TOperatoren; AError: PError);
begin
  inherited;
  FResultStack := TStack<TParserItem>.Create;
  FValues      := TList<Double>.Create;
end;

destructor TCalculator.Destroy;
begin
  FValues.Free;
  FResultStack.Free;
  inherited;
end;

procedure TCalculator.StackToResult;
var
  Current: TParserItem;
begin
  for Current in FStack do
    if FError^.IsNoError then
      case Current.TypeStack of
        tsValue:
          FResultStack.Push(Current);

        tsVariable:
          StackToResult_Variable(Current);

        tsOperator, tsFunction:
          StackToResult_Operation(Current);
      end
    else
      Current.Free;

  FStack.Clear;
end;

procedure TCalculator.StackToResult_Operation(ACurrent: TParserItem);
var
  O    : TOperator;
  R    : TParserItem;
  i    : Integer;
  Error: Integer;
begin
  FValues.Clear;
  for i := 0 to ACurrent.ArgumentsCount - 1 do
  begin
    R := FResultStack.Pop;
    FValues.Add(R.Value);
    R.Free;
  end;

  FValues.Reverse;
  O := FOperations[ACurrent.Name];
  if not O.IsError(FValues.ToArray, Error) then
    FResultStack.Push(TParserItem.Create(O.Func(FValues.ToArray), ACurrent.TextPos))
  else
  begin
    FError^.Code     := Error;
    FError^.Position := ACurrent.TextPos;
  end;
  ACurrent.Free;
end;

function TCalculator.calcResult: Double;
begin
  if FError^.IsNoError then
  begin
    FResultStack.Clear;
    StackToResult;
    Result := SetResult;
  end;
end;

procedure TCalculator.StackToResult_Variable(Current: TParserItem);
var
  aValue: TVar;
begin
  if FVariables.TryGetValue(Current.Name.ToUpper, aValue) then
    FResultStack.Push(TParserItem.Create(aValue, Current.TextPos))
  else
  begin
    FError^.Code     := cErrorUnknownName;
    FError^.Position := Current.TextPos;
  end;
  Current.Free;
end;

function TCalculator.SetResult: Double;
var
  R: TParserItem;
begin
  Result := 0;
  if (FResultStack.Count = 1) and FError^.IsNoError then
  begin
    R      := FResultStack.Pop;
    Result := R.Value;
    R.Free;
  end
  else if FError^.IsNoError then
  begin
    FError^.Code     := cInternalError;
    FError^.Position := -1;
  end
  else
    ClearAndFreeStack(FResultStack);
end;

{ TParserStack }

function TParserStack.ArgCount(const SI: TParserItem): Integer;
var
  Pos: Integer;
  c  : Integer;
  i  : Integer;
begin
  Pos    := IndexOf(SI);
  c      := 0;
  Result := 0;
  for i  := Pos + 1 to Count - 1 do
  begin
    case Self[i].TypeStack of
      tsSeparator:
        if c = 1 then
          Inc(Result);
      tsLeftBracket:
        Inc(c);
      tsRightBracket:
        begin
          if c = 1 then
          begin
            Inc(Result);
            Break;
          end;
          Dec(c);
        end;
    end;
  end;
end;

procedure TParserStack.ClearAndFree;
var
  iItems: TParserItem;
begin
  for iItems in Self do
    iItems.Free;
  Clear;
end;

function TParserStack.ContainsVariable: Boolean;
var
  iItem: TParserItem;
begin
  for iItem in Self do
    if iItem.TypeStack = tsVariable then
      Exit(True);
  Result := False;
end;

function TParserStack.CountLeftBracket: Integer;
var
  iItems: TParserItem;
begin
  Result := 0;
  for iItems in Self do
    if iItems.TypeStack = tsLeftBracket then
      Inc(Result);
end;

function TParserStack.CountRightBracket: Integer;
var
  iItems: TParserItem;
begin
  Result := 0;
  for iItems in Self do
    if iItems.TypeStack = tsRightBracket then
      Inc(Result);
end;

procedure TParserStack.SetArgCount;
var
  iItems: TParserItem;
begin
  for iItems in Self do
    if iItems.TypeStack = tsFunction then
      iItems.ArgumentsCount := ArgCount(iItems);
end;

end.
