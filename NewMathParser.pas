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

  TParserStack = class(TObjectList<TParserItem>)
  strict private
  public
    procedure Clear(const ST: TTypeStack); overload;
    procedure SetArgCount;
    function ArgCount(const SI: TParserItem): Integer;
    function CountType(const ST: TTypeStack): Integer; overload;
    function Contains(const ST: TTypeStack): Boolean;
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

  TValidate = class(TProzessbasis)
  strict private
    procedure ValidateRightBracket(const Pos: Integer);
    procedure ValidateSeparator(const Pos: Integer);
    procedure ValidateOperator(const Pos: Integer);
    procedure CheckBracketError;
    procedure Loop;
    procedure CleanPlusMinus;
    procedure InsertMulti;
    procedure CountArg;
    procedure CheckError;
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

  TParser = class(TObject)
  strict private
  const
    Numbers = ['0' .. '9'];
    Letters = ['a' .. 'z'];
  strict private
    FStack        : TList<TParserItem>;
    FError        : PError;
    FOperations   : TOperatoren;
    FParsePosition: Integer;
    FExpression   : string;
    procedure ParseExponent;
    procedure ParseNumbers;
    procedure ParseFunctions;
    procedure Parse;
  public
    constructor Create(AOperations: TOperatoren; AError: PError);
    destructor Destroy; override;
    function ExpressionToStack(const Expression: string): TArray<TParserItem>;
  end;

  TCalculator = class(TObject)
  strict private
    FVariables  : TVariables;
    FResultStack: TStack<TParserItem>;
    FValues     : TList<Double>;
    FError      : PError;
    FOperations : TOperatoren;
    procedure StackToResult_Operation(ACurrent: TParserItem);
    procedure StackToResult(const AStack: TArray<TParserItem>);
    function SetResult: Double;
    procedure StackToResult_Variable(Current: TParserItem);
  public
    constructor Create(AOperations: TOperatoren; AVariables: TVariables; AError: PError);
    destructor Destroy; override;
    function calcResult(const AStack: TArray<TParserItem>): Double;
  end;

  TMathParser = class(TObject)
  private
    FResult    : Double;
    FError     : TError;
    FMainStack : TParserStack;
    FExpression: string;
    FOnError   : TNotifyError;
    FVariables : TVariables;
    FCalculator: TCalculator;
    FIsToCalc  : Boolean;
    FValidate  : TValidate;
    FParser    : TParser;
    FPriority  : TPriority;
    FOperations: TOperatoren;
    function GetParserResult: Double;
    procedure SetExpression(const Value: string);
    procedure DoError(AError: TError);
    procedure CreateStack;
  public
    constructor Create;
    destructor Destroy; override;
    function GetLastError: TError; deprecated 'use Error';
    // dont use stream! Is quicker to save the Expressionstring
    procedure SaveToStream(S: TStream);
    procedure LoadFromStream(S: TStream);
    property Expression: string read FExpression write SetExpression;
    property ParserResult: Double read GetParserResult;
    property Variables: TVariables read FVariables write FVariables;
    property OnError: TNotifyError read FOnError write FOnError;
    property Error: TError read FError;
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
  FVariables  := TVariables.Create;
  FVariables.Add('pi', Pi);
  FCalculator := TCalculator.Create(FOperations, FVariables, @FError);

  AddOperatoren(FOperations);
  AddMath(FOperations);
  AddTrigonometry(FOperations);
  AddTrigonometryDeg(FOperations);
  AddLogarithm(FOperations);

  FValidate := TValidate.Create(FMainStack, FOperations, @FError);
  FParser   := TParser.Create(FOperations, @FError);
  FPriority := TPriority.Create(FMainStack, FOperations, @FError);
end;

destructor TMathParser.Destroy;
begin
  FPriority.Free;
  FParser.Free;
  FValidate.Free;

  FCalculator.Free;
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
    FResult     := 0;
    FExpression := Value;
    FError.Clear;
    FIsToCalc := True;
    if (FExpression.Length > 0) then
      CreateStack;
  end;
end;

function TMathParser.GetParserResult: Double;
begin
  if FIsToCalc or FMainStack.Contains(tsVariable) then
  begin
    FResult := FCalculator.calcResult(FMainStack.ToArray);
    DoError(FError);
    FIsToCalc := False;
  end;
  Result := FResult;
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
  FMainStack.Clear;

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
  FMainStack.Clear;
  FMainStack.AddRange(FParser.ExpressionToStack(FExpression));
  FValidate.Prozess;
  FPriority.Prozess;
  FMainStack.Clear(tsLeftBracket);
  FMainStack.Clear(tsRightBracket);
  FMainStack.Clear(tsSeparator);
  DoError(FError);
end;

function TMathParser.GetLastError: TError;
begin
  Result := FError;
end;

{ TPostProzess_Validate }

procedure TValidate.Prozess;
begin
  if FError^.IsNoError then
  begin
    CheckBracketError;
    if FError.IsNoError then
      FStack.SetArgCount;
    CleanPlusMinus;
    InsertMulti;
    Loop;
    if FError.IsNoError then
    begin
      CountArg;
      CheckError;
    end;
  end;
end;

procedure TValidate.CheckError;
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
      end
    end;
end;

procedure TValidate.CountArg;
var
  iSS: TParserItem;
begin
  for iSS in FStack do
    if iSS.TypeStack = tsOperator then
      iSS.ArgumentsCount := FOperations[iSS.Name].Arguments;
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
  LeftBracketCount  := FStack.CountType(tsLeftBracket);
  RightBracketCount := FStack.CountType(tsRightBracket);

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

constructor TParser.Create(AOperations: TOperatoren; AError: PError);
begin
  inherited Create;
  FOperations := AOperations;
  FStack      := TList<TParserItem>.Create;
  FError      := AError;
end;

destructor TParser.Destroy;
begin
  FStack.Free;
  inherited;
end;

procedure TParser.ParseFunctions;
var
  S : string;
  Op: TOperator;

  function FunctionOfExpression: string;
  var
    i: Integer;
  begin
    Result := '';
    for i  := FParsePosition to Length(FExpression) do
      if CharInSet(FExpression[i], Letters + Numbers + ['_']) then
        Result := Result + FExpression[i]
      else
        Break;
  end;

begin
  S := FunctionOfExpression;
  if Length(S) > 0 then
  begin
    Op := FOperations[S];
    if Assigned(Op) then
      FStack.Add(TParserItem.Create(Op.Name, FParsePosition))
    else
      FStack.Add(TParserItem.Create(tsVariable, FParsePosition, S));

    FParsePosition := FParsePosition + Length(S);
  end;
end;

procedure TParser.ParseNumbers;
var
  s: string;
  v: Double;

  function NumberInString: string;
  var
    i: Integer;
  begin
    Result := '';
    for i  := FParsePosition to Length(FExpression) do
      if CharInSet(FExpression[i], Numbers) then
        Result := Result + FExpression[i]
      else if CharInSet(FExpression[i], ['.', ',']) then
        Result := Result + FormatSettings.DecimalSeparator
      else
        Break;
  end;

begin
  s              := NumberInString;
  FParsePosition := FParsePosition + Length(s);

  if CharInSet(s[Length(s)], [',']) then
  begin
    Dec(FParsePosition);
    FExpression[FParsePosition] := ';';

    System.Delete(s, Length(s), 1);
    if s = '' then
      Exit;
  end;

  if TryStrToFloat(s, v) then
    FStack.Add(TParserItem.Create(v, FParsePosition))
  else
  begin
    FError^.Code     := cErrorInvalidFloat;
    FError^.Position := FParsePosition;
  end;
end;

procedure TParser.Parse;
begin
  FParsePosition := 1;
  ParseExponent;

  while FError^.IsNoError and (FParsePosition <= Length(FExpression)) do
    with FStack do
    begin
      case FExpression[FParsePosition] of
        '(', '{', '[':
          begin
            Add(TParserItem.Create(FExpression[FParsePosition], FParsePosition));
            Inc(FParsePosition);
          end;

        ')', '}', ']':
          begin
            Add(TParserItem.Create(FExpression[FParsePosition], FParsePosition));
            Inc(FParsePosition);
          end;

        'a' .. 'z', '_':
          ParseFunctions;

        '0' .. '9', '.', ',':
          ParseNumbers;

        ';':
          begin
            Add(TParserItem.Create(tsSeparator, FParsePosition));
            Inc(FParsePosition);
          end;

        '-', '+', '/', '*', '^', '%':
          begin
            Add(TParserItem.Create(FExpression[FParsePosition], FParsePosition));
            Inc(FParsePosition);
          end;

        ' ':
          Inc(FParsePosition);

      else
        begin
          FError^.Code     := cErrorInvalidCar;
          FError^.Position := FParsePosition;
        end;
      end;
    end;
end;

procedure TParser.ParseExponent;
var
  Len: Integer;
  i  : Integer;
begin
  Len   := Length(FExpression);
  for i := 2 to Len - 1 do
    if FExpression[i] = 'e' then
    begin
      if CharInSet(FExpression[i - 1], Numbers + [')', ']']) and
        (CharInSet(FExpression[i + 1], Numbers) or CharInSet(FExpression[i + 1], ['+', '-']) and
        CharInSet(FExpression[i + 2], Numbers)) then
      begin
        Delete(FExpression, i, 1);
        Insert('*10^', FExpression, i);
      end;
    end;
end;

function TParser.ExpressionToStack(const Expression: string): TArray<TParserItem>;
begin
  FExpression := Expression.ToLower;
  FStack.Clear;
  Parse;
  Result := FStack.ToArray;
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
begin
  while FTmpStack.Count > 0 do
    FPStack.Push(FTmpStack.Pop);

  FStack.OwnsObjects := False;
  try
    FStack.Clear;
  finally
    FStack.OwnsObjects := True;
  end;
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

{ TCalculator }

constructor TCalculator.Create(AOperations: TOperatoren; AVariables: TVariables; AError: PError);
begin
  inherited Create;
  FOperations  := AOperations;
  FVariables   := AVariables;
  FError       := AError;
  FResultStack := TStack<TParserItem>.Create;
  FValues      := TList<Double>.Create;
end;

destructor TCalculator.Destroy;
begin
  FValues.Free;
  FResultStack.Free;
  inherited;
end;

procedure TCalculator.StackToResult(const AStack: TArray<TParserItem>);
var
  Current: TParserItem;
begin
  for Current in AStack do
    if FError^.IsNoError then
      case Current.TypeStack of
        tsValue:
          FResultStack.Push(TParserItem.Create(Current));

        tsVariable:
          StackToResult_Variable(Current);

        tsOperator, tsFunction:
          StackToResult_Operation(Current);
      end;
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
  O     := FOperations[ACurrent.Name];
  Error := O.Error(FValues.ToArray);
  if Error = cNoError then
    FResultStack.Push(TParserItem.Create(O.Func(FValues.ToArray), ACurrent.TextPos))
  else
  begin
    FError^.Code     := Error;
    FError^.Position := ACurrent.TextPos;
  end;
end;

function TCalculator.calcResult(const AStack: TArray<TParserItem>): Double;
begin
  FResultStack.Clear;
  StackToResult(AStack);
  Result := SetResult;
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

procedure TParserStack.Clear(const ST: TTypeStack);
var
  i: Integer;
begin
  for i := Count - 1 downto 0 do
    if Self[i].TypeStack = ST then
      Delete(i);
end;

function TParserStack.Contains(const ST: TTypeStack): Boolean;
var
  iItem: TParserItem;
begin
  for iItem in Self do
    if iItem.TypeStack = ST then
      Exit(True);
  Result := False;
end;

function TParserStack.CountType(const ST: TTypeStack): Integer;
var
  iItems: TParserItem;
begin
  Result := 0;
  for iItems in Self do
    if iItems.TypeStack = ST then
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
