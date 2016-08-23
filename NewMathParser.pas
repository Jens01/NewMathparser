// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

/// Viel geändert von Jens Biermann am 07.02.2012
/// Viel geändert von Jens Biermann am 29.01.2015
/// Änderungen von Jens Biermann am 23.08.2016

unit NewMathParser;

interface

uses System.Classes, System.Generics.Collections, NewMathParser.Oper, System.SysUtils;

type
  TNotifyError = Procedure(Sender: TObject; Error: TError) of object;

  TProzessbasis = class(TObject)
  strict protected
    FStack     : TStack<TParserItem>;
    FError     : PError;
    FOperations: TOperatoren;
  public
    constructor Create(AStack: TStack<TParserItem>; AOperations: TOperatoren; AError: PError);
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
    FPos         : Integer;
    FValidateList: TList<TParserItem>;
    procedure ValidateRightBracket;
    procedure ValidateSeparator;
    procedure ValidateOperator;
    procedure ListToStack;
    procedure CheckBracketError;
    procedure Clear;
    procedure Loop;
    procedure CleanPlusMinus;
    procedure InsertMulti;
  public
    constructor Create(AStack: TStack<TParserItem>; AOperations: TOperatoren; AError: PError);
    destructor Destroy; override;
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
    constructor Create(AStack: TStack<TParserItem>; AOperations: TOperatoren; AError: PError);
    destructor Destroy; override;
    procedure Prozess; override;
  end;

  TCountArguments = class(TProzessbasis)
  strict private
    SS: TArray<TParserItem>;
    function AgrumentCount(APos: Integer): Integer;
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
    constructor Create(AStack: TStack<TParserItem>; AOperations: TOperatoren; AError: PError);
    destructor Destroy; override;
    function calcResult: Double;
    property Variables: TVariables read FVariables write FVariables;
  end;

  TMathParser = class(TObject)
  private
    FResult    : Double;
    FError     : TError;
    FTmpStack  : TObjectList<TParserItem>;
    FMainStack : TStack<TParserItem>;
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
    function ContainsVariable: Boolean;
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
    procedure SaveToStream(S: TStream);
    procedure LoadFromStream(S: TStream);
    property Expression: string read FExpression write SetExpression;
    property ParserResult: Double read GetParserResult;
    property Variables: TVariables read FVariables write FVariables;
    property OnError: TNotifyError read FOnError write FOnError;
  end;

implementation

constructor TMathParser.Create;
begin
  inherited;
  FExpression := '';
  FError.Clear;
  FIsToCalc   := False;
  FOperations := TOperatoren.Create;
  FMainStack  := TStack<TParserItem>.Create;
  FTmpStack   := TObjectList<TParserItem>.Create;
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
  FTmpStack.Free;
  ClearAndFreeStack(FMainStack);
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
    FTmpStack.Clear;
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
  if FIsToCalc or ContainsVariable then
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

function TMathParser.ContainsVariable: Boolean;
var
  iItem: TParserItem;
begin
  for iItem in FMainStack do
    if iItem.TypeStack = tsVariable then
      Exit(True);
  for iItem in FTmpStack do
    if iItem.TypeStack = tsVariable then
      Exit(True);
  Result := False;
end;

procedure TMathParser.SaveStack;
var
  iItem, tmp: TParserItem;
begin
  FTmpStack.Clear;
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
    FMainStack.Push(tmp);
  end;
end;

procedure TMathParser.SaveToStream(S: TStream);
var
  c     : Integer;
  SI    : TParserItem;
  SS    : TArray<TParserItem>;
  StrBuf: TBytes;
begin
  StrBuf := TEncoding.UTF8.GetBytes(FExpression);
  c      := Length(StrBuf);
  S.WriteBuffer(c, SizeOf(Integer));
  S.WriteBuffer(StrBuf, c);

  S.WriteBuffer(FError, SizeOf(Integer));
  c := FMainStack.Count;
  S.WriteBuffer(c, SizeOf(Integer));
  SS := FMainStack.ToArray;
  for SI in SS do
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
  ClearAndFreeStack(FMainStack);
  S.ReadBuffer(c, SizeOf(Integer));
  for i := 0 to c - 1 do
  begin
    SI := TParserItem.Create;
    SI.Read(S);
    FMainStack.Push(SI);
  end;
end;

procedure TMathParser.CreateStack;
begin
  ClearAndFreeStack(FMainStack);
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

constructor TValidate.Create(AStack: TStack<TParserItem>; AOperations: TOperatoren; AError: PError);
begin
  inherited;
  FValidateList := TList<TParserItem>.Create;
end;

destructor TValidate.Destroy;
begin
  FValidateList.Free;
  inherited;
end;

procedure TValidate.Prozess;
begin
  if FError^.IsNoError then
  begin
    Clear;
    CheckBracketError;
    CleanPlusMinus;
    InsertMulti;
    Loop;
    ListToStack;
  end;
end;

procedure TValidate.CleanPlusMinus;
const
  STypes = [tsOperator, tsLeftBracket, tsSeparator];
var
  i: Integer;
begin
  for i := FValidateList.Count - 1 downto 0 do
    if ((i = 0) or (FValidateList[i - 1].TypeStack in STypes)) then
      if SameStr(FValidateList[i].Name, '+') then
        FValidateList.Extract(FValidateList[i]).Free
      else if SameStr(FValidateList[i].Name, '-') then
        FValidateList[i].Name := 'neg';
end;

procedure TValidate.Clear;
begin
  FValidateList.Clear;
  FValidateList.AddRange(FStack);
end;

procedure TValidate.CheckBracketError;
var
  SI                : TParserItem;
  LeftBracketCount  : Integer;
  FRightBracketCount: Integer;
begin
  LeftBracketCount   := 0;
  FRightBracketCount := 0;
  for SI in FValidateList do
    case SI.TypeStack of
      tsLeftBracket:
        Inc(LeftBracketCount);
      tsRightBracket:
        Inc(FRightBracketCount);
    end;

  if LeftBracketCount > FRightBracketCount then
  begin
    FError^.Code     := cErrorMissingRightBrackets;
    FError^.Position := -1;
  end

  else if LeftBracketCount < FRightBracketCount then
  begin
    FError^.Code     := cErrorMissingLeftBrackets;
    FError^.Position := -1;
  end;
end;

procedure TValidate.ListToStack;
var
  iPI: TParserItem;
begin
  FStack.Clear;
  for iPI in FValidateList do
    FStack.Push(iPI);
end;

procedure TValidate.InsertMulti;
const
  Types1 = [tsLeftBracket, tsValue, tsVariable, tsFunction];
  Types2 = [tsValue, tsVariable, tsRightBracket];
var
  i: Integer;
begin
  for i := 1 to FValidateList.Count - 1 do
    if (FValidateList[i].TypeStack in Types1) and (FValidateList[i - 1].TypeStack in Types2) then
      FValidateList.Insert(i, TParserItem.Create('*', FValidateList[i].TextPos));
end;

procedure TValidate.Loop;
begin
  FPos := 0;
  while (FError^.IsNoError) and (FPos < FValidateList.Count) do
  begin
    case FValidateList[FPos].TypeStack of
      tsRightBracket:
        ValidateRightBracket;

      tsSeparator:
        ValidateSeparator;

      tsOperator:
        ValidateOperator;
    end;
    Inc(FPos);
  end;
end;

procedure TValidate.ValidateOperator;
begin
  if (FPos = 0) or (FValidateList[FPos - 1].TypeStack in [tsOperator, tsLeftBracket, tsSeparator]) then
  begin
    if (FValidateList[FPos].Name.Length = 1) and CharInSet(FValidateList[FPos].Name[1], ['/', '*', '^', '%']) then
    begin
      FError^.Code     := cErrorOperator;
      FError^.Position := FValidateList[FPos].TextPos;
    end;
  end

  else if (FPos = FValidateList.Count - 1) then
  begin
    FError^.Code     := cErrorOperatorNeedArgument;
    FError^.Position := FValidateList[FPos].TextPos;
  end;
end;

procedure TValidate.ValidateRightBracket;
begin
  if (FPos > 0) and (FValidateList[FPos - 1].TypeStack in [tsFunction, tsOperator, tsSeparator]) then
  begin
    FError^.Code     := cErrorRightBracket;
    FError^.Position := FValidateList[FPos].TextPos;
  end;
end;

procedure TValidate.ValidateSeparator;
begin
  if FPos = 0 then
  begin
    FError^.Code     := cErrorSeparator;
    FError^.Position := FValidateList[FPos].TextPos;
  end
  else
    case FValidateList[FPos - 1].TypeStack of
      tsSeparator:
        begin
          FError^.Code     := cErrorSeparatorNeedArgument;
          FError^.Position := FValidateList[FPos].TextPos;
        end;
      tsOperator, tsLeftBracket:
        begin
          FError^.Code     := cErrorSeparator;
          FError^.Position := FValidateList[FPos].TextPos;
        end;
    end;
end;

{ TProzessbasis }

constructor TProzessbasis.Create(AStack: TStack<TParserItem>; AOperations: TOperatoren; AError: PError);
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
    FStack.Push(TParserItem.Create(v, FPos));
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
            Push(TParserItem.Create(FExpression[FPos], FPos));
            Inc(FPos);
          end;

        ')', '}', ']':
          begin
            Push(TParserItem.Create(FExpression[FPos], FPos));
            Inc(FPos);
          end;

        'a' .. 'z', '_':
          ParseFunctions;

        '0' .. '9', '.', ',':
          ParseNumbers;

        ';':
          begin
            Push(TParserItem.Create(tsSeparator, FPos));
            Inc(FPos);
          end;

        '-', '+', '/', '*', '^', '%':
          begin
            Push(TParserItem.Create(FExpression[FPos], FPos));
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
  FStack.Push(TParserItem.Create('*', FPos));
  FStack.Push(TParserItem.Create(AExponent, FPos));
  FStack.Push(TParserItem.Create('^', FPos));
end;

procedure TParser.PushFunctionVariable(AText: string);
var
  Op: TOperator;
begin
  Op := FOperations[AText];
  if Assigned(Op) then
    FStack.Push(TParserItem.Create(Op.Name, FPos - Length(AText)))
  else
    FStack.Push(TParserItem.Create(tsVariable, FPos - Length(AText), AText));
end;

{ TPostProzess_Priority }

constructor TPriority.Create(AStack: TStack<TParserItem>; AOperations: TOperatoren; AError: PError);
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
  SS : TArray<TParserItem>;
  iSS: TParserItem;
begin
  if FError^.IsNoError then
  begin
    FTmpStack.Clear;
    FPStack.Clear;
    SS := FStack.ToArray;
    for iSS in SS do
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
  for SI in FPStack.ToArray do
    FStack.Push(SI);
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

function TCountArguments.AgrumentCount(APos: Integer): Integer;
var
  c: Integer;
  i: Integer;
begin
  c      := 0;
  Result := 0;
  i      := APos + 1;
  while (i < Length(SS)) and (c > 0) or (i = APos + 1) do
  begin
    case SS[i].TypeStack of
      tsSeparator:
        if c = 1 then
          Inc(Result);
      tsLeftBracket:
        Inc(c);
      tsRightBracket:
        begin
          if c = 1 then
            Inc(Result);
          Dec(c);
        end;
    end;
    Inc(i);
  end;
end;

procedure TCountArguments.CheckError;
var
  i, c: Integer;
begin
  for i := 0 to Length(SS) - 1 do
    if (FError^.IsNoError) and (SS[i].TypeStack in [tsFunction, tsOperator]) then
    begin
      c := FOperations[SS[i].Name].Arguments;
      if (SS[i].ArgumentsCount > c) and (c > -1) or (c > -1) and (SS[i].ArgumentsCount = 0) then
      begin
        FError^.Code     := cErrorToManyArgs;
        FError^.Position := SS[i].TextPos;
      end

      else if SS[i].ArgumentsCount < c then
      begin
        FError^.Code     := cErrorNotEnoughArgs;
        FError^.Position := SS[i].TextPos;
      end

      else if (i < Length(SS) - 2) and (SS[i + 1].TypeStack = tsLeftBracket) and (SS[i + 2].TypeStack = tsRightBracket) then
      begin
        SS[i].ArgumentsCount := 0;
        FError^.Code         := cErrorNotEnoughArgs;
        FError^.Position     := SS[i].TextPos;
      end;
    end;
end;

procedure TCountArguments.Prozess;
begin
  if FError^.IsNoError then
  begin
    SS := FStack.ToArray;
    CountArg;
    CheckError;
  end;
end;

procedure TCountArguments.CountArg;
var
  i  : Integer;
  iSS: TParserItem;
begin
  i := 0;
  for iSS in SS do
  begin
    case iSS.TypeStack of
      tsFunction:
        iSS.ArgumentsCount := AgrumentCount(i);
      tsOperator:
        iSS.ArgumentsCount := FOperations[iSS.Name].Arguments;
    end;
    Inc(i);
  end;
end;

{ TCalculator }

constructor TCalculator.Create(AStack: TStack<TParserItem>; AOperations: TOperatoren; AError: PError);
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
  O: TOperator;
  R: TParserItem;
  i: Integer;
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
    FError^.Code := Error;
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
    FError^.Code := cErrorUnknownName;
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
    FError^.Code := cInternalError;
    FError^.Position := -1;
  end
  else
    ClearAndFreeStack(FResultStack);
end;

end.
