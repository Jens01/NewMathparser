// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

unit NewMathParser.Test;

interface

uses
  TestFramework, NewMathParser, System.Classes, System.Math, System.SysUtils, NewMathParser.Oper;

type

  TestTcyMathParser = class(TTestCase)
  strict private
    FcyMathParser: TMathParser;
    FResultError : TError;
    procedure OnE(Sender: TObject; Error: TError);
    procedure SetUp; override;
    procedure TearDown; override;
    procedure CheckError(AExpected, AResult: TError; Msg: string = '');
  published
    procedure Test1;
    procedure TestAdd;
    procedure TestSub;
    procedure TestMulty;
    procedure TestDiv;
    procedure TestDiv2;
    procedure TestCos;
    procedure TestSin;
    procedure TestTan;
    procedure TestACos;
    procedure TestACos2;
    procedure TestASin;
    procedure TestASin2;
    procedure TestATan;
    procedure TestNeg;
    procedure TestMod;
    procedure TestMod2;
    procedure TestVariables;
    procedure TestPower;
    procedure TestPower2;
    procedure TestLog10;
    procedure TestLog102;
    procedure TestLn;
    procedure TestLn2;
    procedure TestExp;
    procedure TestSqrt;
    procedure TestSqrt2;
    procedure TestSqr;
    procedure TestLogN;
    procedure TestLogN2;
    procedure TestInt;
    procedure TestFrac;
    procedure TestAbs;
    procedure TestCeil;
    procedure TestFloor;
    procedure TestLdexp;
    procedure TestLnXP1;
    procedure TestLnXP12;
    procedure TestMax;
    procedure TestMin;
    procedure TestRoundTo;
    procedure TestPower10;
    procedure TestSign;
    procedure TestSum;
    procedure Teste10;
    procedure TestDegToRad;
    procedure TestRadToDeg;
    procedure TestCosD;
    procedure TestSinD;
    procedure TestTanD;
    procedure TestACosD;
    procedure TestACosD2;
    procedure TestASinD;
    procedure TestASinD2;
    procedure TestATanD;
    procedure TestStream;
    procedure TestError;
  end;

implementation

procedure TestTcyMathParser.SetUp;
begin
  FcyMathParser         := TMathParser.Create;
  FcyMathParser.OnError := OnE;
end;

procedure TestTcyMathParser.TearDown;
begin
  FcyMathParser.Free;
  FcyMathParser := nil;
end;

procedure TestTcyMathParser.TestMax;
var
  R                      : Double;
  EExpected, EReturnValue: TError;
  Expected, ReturnValue  : Double;
begin
  with FcyMathParser do
  begin
    Expression  := 'Max(3, 4, 4,5)';
    Expected    := 4.5;
    ReturnValue := ParserResult;
    CheckEquals(Expected, ReturnValue, Expression);
  end;
  with FcyMathParser do
  begin
    Expression         := 'Max(4,5)';
    R                  := ParserResult;
    EExpected.Code     := cErrorNotEnoughArgs;
    EExpected.Position := 1;
    EReturnValue       := GetLastError;
    CheckError(EExpected, EReturnValue, Expression);
  end;
end;

procedure TestTcyMathParser.TestMin;
var
  R                      : Double;
  EExpected, EReturnValue: TError;
  Expected, ReturnValue  : Double;
begin
  with FcyMathParser do
  begin
    Expression  := 'Min(3, 4, 4,5)';
    Expected    := 3;
    ReturnValue := ParserResult;
    CheckEquals(Expected, ReturnValue, Expression);
  end;
  with FcyMathParser do
  begin
    Expression         := 'Min(4,5)';
    R                  := ParserResult;
    EExpected.Code     := cErrorNotEnoughArgs;
    EExpected.Position := 1;
    EReturnValue       := GetLastError;
    CheckError(EExpected, EReturnValue, Expression);
  end;
end;

procedure TestTcyMathParser.TestMod;
var
  Expected, ReturnValue: Double;
begin
  with FcyMathParser do
  begin
    Expression  := '19 % 4';
    Expected    := 3;
    ReturnValue := ParserResult;
    CheckEquals(Expected, ReturnValue, Expression);
  end;
end;

procedure TestTcyMathParser.TestMod2;
var
  R                      : Double;
  EExpected, EReturnValue: TError;
begin
  with FcyMathParser do
  begin
    Expression         := '19 % 0';
    R                  := ParserResult;
    EExpected.Code     := cErrorDivByZero;
    EExpected.Position := 4;
    EReturnValue       := GetLastError;
    CheckEquals(EExpected.Code, EReturnValue.Code, Expression);
    CheckEquals(EExpected.Position, EReturnValue.Position, Expression);
  end;
end;

procedure TestTcyMathParser.TestMulty;
var
  Expected, ReturnValue: Double;
begin
  with FcyMathParser do
  begin
    Expression  := '3 * 4';
    Expected    := 12;
    ReturnValue := ParserResult;
    CheckEquals(Expected, ReturnValue, Expression);
  end;
end;

procedure TestTcyMathParser.TestNeg;
var
  Expected, ReturnValue: Double;
begin
  with FcyMathParser do
  begin
    Expression  := '-2 + 5';
    Expected    := 3;
    ReturnValue := ParserResult;
    CheckEquals(Expected, ReturnValue, Expression);
  end;
end;

procedure TestTcyMathParser.CheckError(AExpected, AResult: TError; Msg: string);
begin
  CheckEquals(AExpected.Code, AResult.Code, Msg + ' Code: ');
  CheckEquals(AExpected.Position, AResult.Position, Msg + ' Pos: ');
end;

procedure TestTcyMathParser.OnE(Sender: TObject; Error: TError);
begin
  FResultError := Error;
end;

procedure TestTcyMathParser.Test1;
var
  R                      : Double;
  Expected, ReturnValue  : Double;
  EExpected, EReturnValue: TError;
begin
  with FcyMathParser do
  begin
    Expression  := '((4+5)6)7 + Min(3, 4, 5)';
    Expected    := 381;
    ReturnValue := ParserResult;
    CheckEquals(Expected, ReturnValue, Expression);
  end;

  with FcyMathParser do
  begin
    Expression  := 'Max(3+5, 4, 5) + Min(3, 4, 5)';
    Expected    := 11;
    ReturnValue := ParserResult;
    CheckEquals(Expected, ReturnValue, Expression);
  end;

  with FcyMathParser do
  begin
    Expression  := 'Max(3, 4, 5) + Min(3, 4, 5)';
    Expected    := 8;
    ReturnValue := ParserResult;
    CheckEquals(Expected, ReturnValue, Expression);
  end;
  with FcyMathParser do
  begin
    Expression         := '25 + Max(3,4)';
    R                  := ParserResult;
    EExpected.Code     := cErrorNotEnoughArgs;
    EExpected.Position := 6;
    EReturnValue       := GetLastError;
    CheckError(EExpected, EReturnValue, Expression);
  end;
  with FcyMathParser do
  begin
    Variables.Add('a', 12);
    Expression  := 'Max(3, a, 5)';
    Expected    := 12;
    ReturnValue := ParserResult;
    CheckEquals(Expected, ReturnValue, Expression);
  end;
  with FcyMathParser do
  begin
    Variables.Add('a', 12);
    Expression  := 'Max(3, a/2, 5)';
    Expected    := 6;
    ReturnValue := ParserResult;
    CheckEquals(Expected, ReturnValue, Expression);
  end;
  with FcyMathParser do
  begin
    Variables.Add('a', 12);
    Expression  := 'Max(3, 2a/2, 5)';
    Expected    := 12;
    ReturnValue := ParserResult;
    CheckEquals(Expected, ReturnValue, Expression);
  end;
  with FcyMathParser do
  begin
    Variables.Add('a', 6);
    Expression  := 'Max(3, 2a, 5)';
    Expected    := 12;
    ReturnValue := ParserResult;
    CheckEquals(Expected, ReturnValue, Expression);
  end;
  with FcyMathParser do
  begin
    Expression  := 'Max(3, Min(20, 21), 5)';
    Expected    := 20;
    ReturnValue := ParserResult;
    CheckEquals(Expected, ReturnValue, Expression);
  end;
  with FcyMathParser do
  begin
    Variables.Add('a', 3);
    Expression  := 'a(3+5)';
    Expected    := 24;
    ReturnValue := ParserResult;
    CheckEquals(Expected, ReturnValue, Expression);
  end;
  with FcyMathParser do
  begin
    Variables.Add('a', 3);
    Expression  := '(3+5)a';
    Expected    := 24;
    ReturnValue := ParserResult;
    CheckEquals(Expected, ReturnValue, Expression);
  end;
  with FcyMathParser do
  begin
    Variables.Add('a', 4);
    Expression  := '3a';
    Expected    := 12;
    ReturnValue := ParserResult;
    CheckEquals(Expected, ReturnValue, Expression);
  end;
  with FcyMathParser do
  begin
    Variables.Add('a', 4);
    Expression         := 'a3';
    R                  := ParserResult;
    EExpected.Code     := cErrorUnknownName;
    EExpected.Position := 1;
    EReturnValue       := GetLastError;
    CheckError(EExpected, EReturnValue, Expression);
  end;
  with FcyMathParser do
  begin
    Expression  := '+3';
    Expected    := 3;
    ReturnValue := ParserResult;
    CheckEquals(Expected, ReturnValue, Expression);
  end;
  with FcyMathParser do
  begin
    Expression  := 'Max(+3, -3)';
    Expected    := 3;
    ReturnValue := ParserResult;
    CheckEquals(Expected, ReturnValue, Expression);
  end;
end;

procedure TestTcyMathParser.TestAbs;
var
  R                      : Double;
  Expected, ReturnValue  : Double;
  EExpected, EReturnValue: TError;
begin
  with FcyMathParser do
  begin
    Expression         := 'Abs(-2, 2, 4)';
    R                  := ParserResult;
    EExpected.Code     := cErrorToManyArgs;
    EExpected.Position := 1;
    EReturnValue       := GetLastError;
    CheckEquals(EExpected.Code, EReturnValue.Code, Expression);
    CheckEquals(EExpected.Position, EReturnValue.Position, Expression);

    Expression  := 'Abs(2)';
    Expected    := 2;
    ReturnValue := ParserResult;
    CheckEquals(Expected, ReturnValue, Expression);

    Expression  := 'Abs(-2)';
    Expected    := 2;
    ReturnValue := ParserResult;
    CheckEquals(Expected, ReturnValue, Expression);
  end;
end;

procedure TestTcyMathParser.TestACos;
var
  Expected, ReturnValue: Double;
begin
  with FcyMathParser do
  begin
    Expression  := 'ACos(0.5)';
    Expected    := 1.0472;
    ReturnValue := ParserResult;
    CheckEquals(Expected, ReturnValue, 0.0001, Expression);
  end;
end;

procedure TestTcyMathParser.TestACos2;
var
  R                      : Double;
  EExpected, EReturnValue: TError;
begin
  with FcyMathParser do
  begin
    Expression         := 'ACos(-1.1)';
    R                  := ParserResult;
    EExpected.Code     := cErrorFxInvalidValue;
    EExpected.Position := 1;
    EReturnValue       := GetLastError;
    CheckEquals(EExpected.Code, EReturnValue.Code, Expression);
    CheckEquals(EExpected.Position, EReturnValue.Position, Expression);

    Expression         := 'ACos(1.1)';
    R                  := ParserResult;
    EExpected.Code     := cErrorFxInvalidValue;
    EExpected.Position := 1;
    EReturnValue       := GetLastError;
    CheckEquals(EExpected.Code, EReturnValue.Code, Expression);
    CheckEquals(EExpected.Position, EReturnValue.Position, Expression);
  end;
end;

procedure TestTcyMathParser.TestACosD;
var
  Expected, ReturnValue: Double;
begin
  with FcyMathParser do
  begin
    Expression  := 'ACosD(0.5)';
    Expected    := 60;
    ReturnValue := ParserResult;
    CheckEquals(Expected, ReturnValue, 0.0001, Expression);
  end;
end;

procedure TestTcyMathParser.TestACosD2;
var
  R                      : Double;
  EExpected, EReturnValue: TError;
begin
  with FcyMathParser do
  begin
    Expression         := 'ACosD(RadToDeg(-1.1))';
    R                  := ParserResult;
    EExpected.Code     := cErrorFxInvalidValue;
    EExpected.Position := 1;
    EReturnValue       := GetLastError;
    CheckEquals(EExpected.Code, EReturnValue.Code, Expression);
    CheckEquals(EExpected.Position, EReturnValue.Position, Expression);

    Expression         := 'ACosD(RadToDeg(1.1))';
    R                  := ParserResult;
    EExpected.Code     := cErrorFxInvalidValue;
    EExpected.Position := 1;
    EReturnValue       := GetLastError;
    CheckEquals(EExpected.Code, EReturnValue.Code, Expression);
    CheckEquals(EExpected.Position, EReturnValue.Position, Expression);
  end;
end;

procedure TestTcyMathParser.TestAdd;
var
  Expected, ReturnValue: Double;
begin
  with FcyMathParser do
  begin
    Expression  := '2 + 2';
    Expected    := 4;
    ReturnValue := ParserResult;
    CheckEquals(Expected, ReturnValue, Expression);
  end;
end;

procedure TestTcyMathParser.TestASin;
var
  Expected, ReturnValue: Double;
begin
  with FcyMathParser do
  begin
    Expression  := 'ASin(0.5)';
    Expected    := 0.5236;
    ReturnValue := ParserResult;
    CheckEquals(Expected, ReturnValue, 0.0001, Expression);
  end;
end;

procedure TestTcyMathParser.TestASin2;
var
  R                      : Double;
  EExpected, EReturnValue: TError;
begin
  with FcyMathParser do
  begin
    Expression         := 'ASin(-1.1)';
    R                  := ParserResult;
    EExpected.Code     := cErrorFxInvalidValue;
    EExpected.Position := 1;
    EReturnValue       := GetLastError;
    CheckEquals(EExpected.Code, EReturnValue.Code, Expression);
    CheckEquals(EExpected.Position, EReturnValue.Position, Expression);

    Expression         := 'ASin(1.1)';
    R                  := ParserResult;
    EExpected.Code     := cErrorFxInvalidValue;
    EExpected.Position := 1;
    EReturnValue       := GetLastError;
    CheckEquals(EExpected.Code, EReturnValue.Code, Expression);
    CheckEquals(EExpected.Position, EReturnValue.Position, Expression);
  end;
end;

procedure TestTcyMathParser.TestASinD;
var
  Expected, ReturnValue: Double;
begin
  with FcyMathParser do
  begin
    Expression  := 'ASinD(0.5)';
    Expected    := 30;
    ReturnValue := ParserResult;
    CheckEquals(Expected, ReturnValue, 0.0001, Expression);
  end;
end;

procedure TestTcyMathParser.TestASinD2;
var
  R                      : Double;
  EExpected, EReturnValue: TError;
begin
  with FcyMathParser do
  begin
    Expression         := 'ASinD(RadToDeg(-1.1))';
    R                  := ParserResult;
    EExpected.Code     := cErrorFxInvalidValue;
    EExpected.Position := 1;
    EReturnValue       := GetLastError;
    CheckEquals(EExpected.Code, EReturnValue.Code, Expression);
    CheckEquals(EExpected.Position, EReturnValue.Position, Expression);

    Expression         := 'ASinD(RadToDeg(1.1))';
    R                  := ParserResult;
    EExpected.Code     := cErrorFxInvalidValue;
    EExpected.Position := 1;
    EReturnValue       := GetLastError;
    CheckEquals(EExpected.Code, EReturnValue.Code, Expression);
    CheckEquals(EExpected.Position, EReturnValue.Position, Expression);
  end;
end;

procedure TestTcyMathParser.TestATan;
var
  Expected, ReturnValue: Double;
begin
  with FcyMathParser do
  begin
    Expression  := 'ATan(0.5)';
    Expected    := 0.46365;
    ReturnValue := ParserResult;
    CheckEquals(Expected, ReturnValue, 0.0001, Expression);
  end;
end;

procedure TestTcyMathParser.TestATanD;
var
  Expected, ReturnValue: Double;
begin
  with FcyMathParser do
  begin
    Expression  := 'ATanD(0.5)';
    Expected    := 26.56505;
    ReturnValue := ParserResult;
    CheckEquals(Expected, ReturnValue, 0.0001, Expression);
  end;
end;

procedure TestTcyMathParser.TestCeil;
var
  Expected, ReturnValue: Double;
begin
  with FcyMathParser do
  begin
    Expression  := 'Ceil(2,1)';
    Expected    := 3;
    ReturnValue := ParserResult;
    CheckEquals(Expected, ReturnValue, Expression);
  end;

  with FcyMathParser do
  begin
    Expression  := 'Ceil(-2,1)';
    Expected    := -2;
    ReturnValue := ParserResult;
    CheckEquals(Expected, ReturnValue, Expression);
  end;
end;

procedure TestTcyMathParser.TestCos;
var
  Expected, ReturnValue: Double;
begin
  with FcyMathParser do
  begin
    Expression  := 'Cos(2*pi)';
    Expected    := 1;
    ReturnValue := ParserResult;
    CheckEquals(Expected, ReturnValue, Expression);
  end;
end;

procedure TestTcyMathParser.TestCosD;
var
  Expected, ReturnValue: Double;
begin
  with FcyMathParser do
  begin
    Expression  := 'CosD(360)';
    Expected    := 1;
    ReturnValue := ParserResult;
    CheckEquals(Expected, ReturnValue, Expression);
  end;
end;

procedure TestTcyMathParser.TestDegToRad;
var
  Expected, ReturnValue: Double;
begin
  with FcyMathParser do
  begin
    Expression  := 'DegToRad(90)';
    Expected    := pi / 2;
    ReturnValue := ParserResult;
    CheckEquals(Expected, ReturnValue, 0.00001, Expression);
  end;
  with FcyMathParser do
  begin
    Expression  := 'Sin(DegToRad(90))';
    Expected    := 1;
    ReturnValue := ParserResult;
    CheckEquals(Expected, ReturnValue, Expression);
  end;
end;

procedure TestTcyMathParser.TestDiv;
var
  Expected, ReturnValue: Double;
begin
  with FcyMathParser do
  begin
    Expression  := '3 / 2';
    Expected    := 1.5;
    ReturnValue := ParserResult;
    CheckEquals(Expected, ReturnValue, Expression);
  end;
end;

procedure TestTcyMathParser.TestDiv2;
var
  R                      : Double;
  EExpected, EReturnValue: TError;
begin
  with FcyMathParser do
  begin
    Expression         := '3 / 0';
    R                  := ParserResult;
    EExpected.Code     := cErrorDivByZero;
    EExpected.Position := 3;
    EReturnValue       := GetLastError;
    CheckEquals(EExpected.Code, EReturnValue.Code, Expression);
    CheckEquals(EExpected.Position, EReturnValue.Position, Expression);
  end;
end;

procedure TestTcyMathParser.Teste10;
var
  Expected, ReturnValue: Double;
begin
  with FcyMathParser do
  begin
    Expression  := '1e3';
    Expected    := 1000;
    ReturnValue := ParserResult;
    CheckEquals(Expected, ReturnValue, 0.00001, Expression);
  end;
  with FcyMathParser do
  begin
    Expression  := '1e10';
    Expected    := 10000000000;
    ReturnValue := ParserResult;
    CheckEquals(Expected, ReturnValue, 0.00001, Expression);
  end;

  with FcyMathParser do
  begin
    Expression  := 'Max(1, 2)e3';
    Expected    := 2000;
    ReturnValue := ParserResult;
    CheckEquals(Expected, ReturnValue, 0.00001, Expression);
  end;
end;

procedure TestTcyMathParser.TestError;
var
  R                      : Double;
  EExpected, EReturnValue: TError;
begin
  with FcyMathParser do
  begin
    Expression := 'Abs(3, 4, 5) + Abs(4, 5)';
    R          := ParserResult;

    EExpected.Code     := cErrorToManyArgs;
    EExpected.Position := 1;
    EReturnValue       := GetLastError;
    CheckError(EExpected, FResultError);
    CheckError(EExpected, EReturnValue, Expression);
  end;
  with FcyMathParser do
  begin
    Expression := 'Abs()';
    R          := ParserResult;

    EExpected.Code     := cErrorNotEnoughArgs;
    EExpected.Position := 1;
    EReturnValue       := GetLastError;
    CheckError(EExpected, FResultError, Expression);
    CheckError(EExpected, EReturnValue, Expression);
  end;
  with FcyMathParser do
  begin
    Expression := '*3';
    R          := ParserResult;

    EExpected.Code     := cErrorOperator;
    EExpected.Position := 1;
    EReturnValue       := GetLastError;
    CheckError(EExpected, FResultError, Expression);
    CheckError(EExpected, EReturnValue, Expression);
  end;
  with FcyMathParser do
  begin
    Expression := '(*3)';
    R          := ParserResult;

    EExpected.Code     := cErrorOperator;
    EExpected.Position := 2;
    EReturnValue       := GetLastError;
    CheckError(EExpected, FResultError, Expression);
    CheckError(EExpected, EReturnValue, Expression);
  end;
  with FcyMathParser do
  begin
    FResultError.Clear;
    Expression := 'Abs +5)';
    R          := ParserResult;

    EExpected.Code     := cErrorMissingLeftBrackets;
    EExpected.Position := -1;
    EReturnValue       := GetLastError;
    CheckError(EExpected, FResultError, Expression);
    CheckError(EExpected, EReturnValue, Expression);
  end;

  with FcyMathParser do
  begin
    FResultError.Clear;
    Expression := 'Abs )';
    R          := ParserResult;

    EExpected.Code     := cErrorMissingLeftBrackets;
    EExpected.Position := -1;
    EReturnValue       := GetLastError;
    CheckError(EExpected, FResultError, Expression);
    CheckError(EExpected, EReturnValue, Expression);
  end;
  with FcyMathParser do
  begin
    FResultError.Clear;
    Expression := 'Abs 5)';
    R          := ParserResult;

    EExpected.Code     := cErrorMissingLeftBrackets;
    EExpected.Position := -1;
    EReturnValue       := GetLastError;
    CheckError(EExpected, FResultError, Expression);
    CheckError(EExpected, EReturnValue, Expression);
  end;
  with FcyMathParser do
  begin
    FResultError.Clear;
    Variables.Add('a', 12);
    Expression := 'Abs a)';
    R          := ParserResult;

    EExpected.Code     := cErrorMissingLeftBrackets;
    EExpected.Position := -1;
    EReturnValue       := GetLastError;
    CheckError(EExpected, FResultError, Expression);
    CheckError(EExpected, EReturnValue, Expression);
  end;
  with FcyMathParser do
  begin
    FResultError.Clear;
    Expression := 'Abs +3)';
    R          := ParserResult;

    EExpected.Code     := cErrorMissingLeftBrackets;
    EExpected.Position := -1;
    EReturnValue       := GetLastError;
    CheckError(EExpected, FResultError, Expression);
    CheckError(EExpected, EReturnValue, Expression);
  end;
  with FcyMathParser do
  begin
    FResultError.Clear;
    Expression := 'Max ,3)';
    R          := ParserResult;

    EExpected.Code     := cErrorMissingLeftBrackets;
    EExpected.Position := -1;
    EReturnValue       := GetLastError;
    CheckError(EExpected, FResultError, Expression);
    CheckError(EExpected, EReturnValue, Expression);
  end;
  with FcyMathParser do
  begin
    FResultError.Clear;
    Expression := 'Abs(5*)';
    R          := ParserResult;

    EExpected.Code     := cErrorRightBracket;
    EExpected.Position := 7;
    EReturnValue       := GetLastError;
    CheckError(EExpected, FResultError, Expression);
    CheckError(EExpected, EReturnValue, Expression);
  end;
  with FcyMathParser do
  begin
    FResultError.Clear;
    Expression := 'Abs(5,)';
    R          := ParserResult;

    EExpected.Code     := cErrorRightBracket;
    EExpected.Position := 7;
    EReturnValue       := GetLastError;
    CheckError(EExpected, FResultError, Expression);
    CheckError(EExpected, EReturnValue, Expression);
  end;

  with FcyMathParser do
  begin
    FResultError.Clear;
    Expression := '(5 (3)';

    R                  := ParserResult;
    EExpected.Code     := cErrorMissingRightBrackets;
    EExpected.Position := -1;
    CheckError(EExpected, FResultError, Expression);
    EReturnValue := GetLastError;
    CheckError(EExpected, EReturnValue, Expression);
  end;
  with FcyMathParser do
  begin
    FResultError.Clear;
    Expression := '(5 + 3))';

    R                  := ParserResult;
    EExpected.Code     := cErrorMissingLeftBrackets;
    EExpected.Position := -1;
    CheckError(EExpected, FResultError, Expression);
    EReturnValue := GetLastError;
    CheckError(EExpected, EReturnValue, Expression);
  end;

  with FcyMathParser do
  begin
    FResultError.Clear;
    Expression := '5 +';

    R                  := ParserResult;
    EExpected.Code     := cErrorOperatorNeedArgument;
    EExpected.Position := 3;
    CheckError(EExpected, FResultError, Expression);
    EReturnValue := GetLastError;
    CheckError(EExpected, EReturnValue, Expression);
  end;

  with FcyMathParser do
  begin
    FResultError.Clear;
    Expression := ', 5';
    R          := ParserResult;

    EExpected.Code     := cErrorSeparator;
    EExpected.Position := 1;
    EReturnValue       := GetLastError;
    CheckError(EExpected, FResultError, Expression);
    CheckError(EExpected, EReturnValue, Expression);
  end;

  with FcyMathParser do
  begin
    FResultError.Clear;
    Expression := '(,)';
    R          := ParserResult;

    EExpected.Code     := cErrorSeparator;
    EExpected.Position := 2;
    EReturnValue       := GetLastError;
    CheckError(EExpected, FResultError, Expression);
    CheckError(EExpected, EReturnValue, Expression);
  end;

  with FcyMathParser do
  begin
    FResultError.Clear;
    Expression := '+,';
    R          := ParserResult;

    EExpected.Code     := cErrorSeparator;
    EExpected.Position := 2;
    EReturnValue       := GetLastError;
    CheckError(EExpected, FResultError, Expression);
    CheckError(EExpected, EReturnValue, Expression);
  end;

  with FcyMathParser do
  begin
    FResultError.Clear;
    Expression := '(5,,)';
    R          := ParserResult;

    EExpected.Code     := cErrorRightBracket;
    EExpected.Position := 5;
    EReturnValue       := GetLastError;
    CheckError(EExpected, FResultError, Expression);
    CheckError(EExpected, EReturnValue, Expression);
  end;

  with FcyMathParser do
  begin
    FResultError.Clear;
    Expression := 'Abs(5, 6, 7)';
    R          := ParserResult;

    EExpected.Code     := cErrorToManyArgs;
    EExpected.Position := 1;
    EReturnValue       := GetLastError;
    CheckError(EExpected, FResultError, Expression);
    CheckError(EExpected, EReturnValue, Expression);
  end;
end;

procedure TestTcyMathParser.TestExp;
var
  Expected, ReturnValue: Double;
begin
  with FcyMathParser do
  begin
    Expression  := 'Exp(1)';
    Expected    := 2.718281;
    ReturnValue := ParserResult;
    CheckEquals(Expected, ReturnValue, 0.00001, Expression);
  end;
end;

procedure TestTcyMathParser.TestFloor;
var
  Expected, ReturnValue: Double;
begin
  with FcyMathParser do
  begin
    Expression  := 'Floor(2.2)';
    Expected    := 2;
    ReturnValue := ParserResult;
    CheckEquals(Expected, ReturnValue, Expression);
  end;

  with FcyMathParser do
  begin
    Expression  := 'Floor(-2.2)';
    Expected    := -3;
    ReturnValue := ParserResult;
    CheckEquals(Expected, ReturnValue, Expression);
  end;
end;

procedure TestTcyMathParser.TestFrac;
var
  Expected, ReturnValue: Double;
begin
  with FcyMathParser do
  begin
    Expression  := 'Frac(1.501)';
    Expected    := 0.501;
    ReturnValue := ParserResult;
    CheckEquals(Expected, ReturnValue, 0.00001, Expression);
  end;
end;

procedure TestTcyMathParser.TestInt;
var
  Expected, ReturnValue: Double;
begin
  with FcyMathParser do
  begin
    Expression  := 'Int(1.501)';
    Expected    := 1;
    ReturnValue := ParserResult;
    CheckEquals(Expected, ReturnValue, Expression);
  end;
end;

procedure TestTcyMathParser.TestLdexp;
var
  Expected, ReturnValue: Double;
begin
  with FcyMathParser do
  begin
    Expression  := 'Ldexp(2, 3)';
    Expected    := 16;
    ReturnValue := ParserResult;
    CheckEquals(Expected, ReturnValue, 0.00001, Expression);
  end;
end;

procedure TestTcyMathParser.TestLn;
var
  Expected, ReturnValue: Double;
begin
  with FcyMathParser do
  begin
    Expression  := 'Ln(1000)';
    Expected    := 6.90775;
    ReturnValue := ParserResult;
    CheckEquals(Expected, ReturnValue, 0.00001, Expression);
  end;
end;

procedure TestTcyMathParser.TestLn2;
var
  R                      : Double;
  EExpected, EReturnValue: TError;
begin
  with FcyMathParser do
  begin
    Expression         := 'Ln(0)';
    R                  := ParserResult;
    EExpected.Code     := cErrorFxInvalidValue;
    EExpected.Position := 1;
    EReturnValue       := GetLastError;
    CheckError(EExpected, EReturnValue, Expression);
  end;
end;

procedure TestTcyMathParser.TestLnXP1;
var
  Expected, ReturnValue: Double;
begin
  with FcyMathParser do
  begin
    Expression  := 'LnXP1(1)';
    Expected    := 0.69315;
    ReturnValue := ParserResult;
    CheckEquals(Expected, ReturnValue, 0.00001, Expression);
  end;
end;

procedure TestTcyMathParser.TestLnXP12;
var
  R                      : Double;
  EExpected, EReturnValue: TError;
begin
  with FcyMathParser do
  begin
    Expression         := 'LnXP1(-1)';
    R                  := ParserResult;
    EExpected.Code     := cErrorFxInvalidValue;
    EExpected.Position := 1;
    EReturnValue       := GetLastError;
    CheckError(EExpected, EReturnValue, Expression);
  end;
end;

procedure TestTcyMathParser.TestLog10;
var
  Expected, ReturnValue: Double;
begin
  with FcyMathParser do
  begin
    Expression  := 'Log10(1000)';
    Expected    := 3;
    ReturnValue := ParserResult;
    CheckEquals(Expected, ReturnValue, Expression);
  end;
end;

procedure TestTcyMathParser.TestLog102;
var
  R                      : Double;
  EExpected, EReturnValue: TError;
begin
  with FcyMathParser do
  begin
    Expression         := 'Log10(0)';
    R                  := ParserResult;
    EExpected.Code     := cErrorFxInvalidValue;
    EExpected.Position := 1;
    EReturnValue       := GetLastError;
    CheckError(EExpected, EReturnValue, Expression);
  end;
end;

procedure TestTcyMathParser.TestLogN;
var
  Expected, ReturnValue: Double;
begin
  with FcyMathParser do
  begin
    Expression  := 'LogN(3, 2)';
    Expected    := 0.63093;
    ReturnValue := ParserResult;
    CheckEquals(Expected, ReturnValue, 0.0001, Expression);
  end;
end;

procedure TestTcyMathParser.TestLogN2;
var
  R                      : Double;
  EExpected, EReturnValue: TError;
begin
  with FcyMathParser do
  begin
    Expression         := 'LogN(0, 1)';
    R                  := ParserResult;
    EExpected.Code     := cErrorFxInvalidValue;
    EExpected.Position := 1;
    EReturnValue       := GetLastError;
    CheckError(EExpected, EReturnValue, Expression);
  end;
  with FcyMathParser do
  begin
    Expression         := 'LogN(1, 0)';
    R                  := ParserResult;
    EExpected.Code     := cErrorFxInvalidValue;
    EExpected.Position := 1;
    EReturnValue       := GetLastError;
    CheckError(EExpected, EReturnValue, Expression);
  end;
end;

procedure TestTcyMathParser.TestPower;
var
  Expected, ReturnValue: Double;
begin
  with FcyMathParser do
  begin
    Expression  := '6^2';
    Expected    := 36;
    ReturnValue := ParserResult;
    CheckEquals(Expected, ReturnValue, Expression);
  end;
  with FcyMathParser do
  begin
    Expression  := 'Max(2, 3)^2';
    Expected    := 9;
    ReturnValue := ParserResult;
    CheckEquals(Expected, ReturnValue, Expression);
  end;
end;

procedure TestTcyMathParser.TestPower10;
var
  Expected, ReturnValue: Double;
begin
  with FcyMathParser do
  begin
    Expression  := '-2^-2';
    Expected    := 0.25;
    ReturnValue := ParserResult;
    CheckEquals(Expected, ReturnValue, Expression);
  end;
end;

procedure TestTcyMathParser.TestPower2;
var
  R                      : Double;
  EExpected, EReturnValue: TError;
begin
  with FcyMathParser do
  begin
    Expression         := '-2^2.2';
    R                  := ParserResult;
    EExpected.Code     := cErrorPower;
    EExpected.Position := 3;
    EReturnValue       := GetLastError;
    CheckError(EExpected, EReturnValue, Expression);
  end;
end;

procedure TestTcyMathParser.TestRadToDeg;
var
  Expected, ReturnValue: Double;
begin
  with FcyMathParser do
  begin
    Expression  := 'RadToDeg(pi/2)';
    Expected    := 90;
    ReturnValue := ParserResult;
    CheckEquals(Expected, ReturnValue, 0.00001, Expression);
  end;
  with FcyMathParser do
  begin
    Expression  := 'SinD(RadToDeg(pi/2))';
    Expected    := 1;
    ReturnValue := ParserResult;
    CheckEquals(Expected, ReturnValue, Expression);
  end;
end;

procedure TestTcyMathParser.TestRoundTo;
var
  Expected, ReturnValue: Double;
begin
  with FcyMathParser do
  begin
    Expression  := 'RoundTo(-25,346 , -2)';
    Expected    := -25.35;
    ReturnValue := ParserResult;
    CheckEquals(Expected, ReturnValue, Expression);
  end;
end;

procedure TestTcyMathParser.TestSign;
var
  Expected, ReturnValue: Double;
begin
  with FcyMathParser do
  begin
    Expression  := 'Sign(50,22)';
    Expected    := 1;
    ReturnValue := ParserResult;
    CheckEquals(Expected, ReturnValue, Expression);
  end;
  with FcyMathParser do
  begin
    Expression  := 'Sign(-50,22)';
    Expected    := -1;
    ReturnValue := ParserResult;
    CheckEquals(Expected, ReturnValue, Expression);
  end;
  with FcyMathParser do
  begin
    Expression  := 'Sign(0)';
    Expected    := 0;
    ReturnValue := ParserResult;
    CheckEquals(Expected, ReturnValue, Expression);
  end;
end;

procedure TestTcyMathParser.TestSin;
var
  Expected, ReturnValue: Double;
begin
  with FcyMathParser do
  begin
    Expression  := 'Sin(pi/2)';
    Expected    := 1;
    ReturnValue := ParserResult;
    CheckEquals(Expected, ReturnValue, Expression);
  end;
end;

procedure TestTcyMathParser.TestSinD;
var
  Expected, ReturnValue: Double;
begin
  with FcyMathParser do
  begin
    Expression  := 'SinD(90)';
    Expected    := 1;
    ReturnValue := ParserResult;
    CheckEquals(Expected, ReturnValue, Expression);
  end;
end;

procedure TestTcyMathParser.TestSqr;
var
  Expected, ReturnValue: Double;
begin
  with FcyMathParser do
  begin
    Expression  := 'Sqr(2)';
    Expected    := 4;
    ReturnValue := ParserResult;
    CheckEquals(Expected, ReturnValue, 0.001, Expression);
  end;
end;

procedure TestTcyMathParser.TestSqrt;
var
  Expected, ReturnValue: Double;
begin
  with FcyMathParser do
  begin
    Expression  := 'Sqrt(2)';
    Expected    := 1.41442;
    ReturnValue := ParserResult;
    CheckEquals(Expected, ReturnValue, 0.001, Expression);
  end;
end;

procedure TestTcyMathParser.TestSqrt2;
var
  R                      : Double;
  EExpected, EReturnValue: TError;
begin
  with FcyMathParser do
  begin
    Expression         := 'Sqrt(-1)';
    R                  := ParserResult;
    EExpected.Code     := cErrorFxInvalidValue;
    EExpected.Position := 1;
    EReturnValue       := GetLastError;
    CheckError(EExpected, EReturnValue, Expression);
  end;
end;

procedure TestTcyMathParser.TestStream;
const
  cFormel = '5 - 2';
var
  ExpectedString: string;
  ReturnString  : string;
  Expected      : Double;
  ReturnValue   : Double;
  s             : TMemoryStream;
begin
  with FcyMathParser do
  begin
    Expression := cFormel;
    s          := TMemoryStream.Create;
    try
      SaveToStream(s);
      Expression := '';
      LoadFromStream(s);
    finally
      s.Free;
    end;
    ReturnString   := Expression;
    ExpectedString := cFormel;
    CheckEquals(ExpectedString, ReturnString);
  end;

  with FcyMathParser do
  begin
    Expression := cFormel;
    s          := TMemoryStream.Create;
    try
      SaveToStream(s);
      Expression := '';
      LoadFromStream(s);
    finally
      s.Free;
    end;
    Expected    := 3;
    ReturnValue := ParserResult;
    CheckEquals(Expected, ReturnValue, Expression);
  end;
end;

procedure TestTcyMathParser.TestSub;
var
  Expected, ReturnValue: Double;
begin
  with FcyMathParser do
  begin
    Expression  := '5 - 2';
    Expected    := 3;
    ReturnValue := ParserResult;
    CheckEquals(Expected, ReturnValue, Expression);
  end;
end;

procedure TestTcyMathParser.TestSum;
var
  Expected, ReturnValue: Double;
begin
  with FcyMathParser do
  begin
    Expression  := 'Sum(3, 2,55, 3.2)';
    Expected    := 8.75;
    ReturnValue := ParserResult;
    CheckEquals(Expected, ReturnValue, 0.001, Expression);
  end;
end;

procedure TestTcyMathParser.TestTan;
var
  Expected, ReturnValue: Double;
begin
  with FcyMathParser do
  begin
    Expression  := 'Tan(pi/4)';
    Expected    := 1;
    ReturnValue := ParserResult;
    CheckEquals(Expected, ReturnValue, 0.001, Expression);
  end;
end;

procedure TestTcyMathParser.TestTanD;
var
  Expected, ReturnValue: Double;
begin
  with FcyMathParser do
  begin
    Expression  := 'TanD(45)';
    Expected    := 1;
    ReturnValue := ParserResult;
    CheckEquals(Expected, ReturnValue, 0.001, Expression);
  end;
end;

procedure TestTcyMathParser.TestVariables;
var
  Expected, ReturnValue: Double;
  Test                 : Double;
begin
  with FcyMathParser do
  begin
    Variables.Add('A', 5);
    Variables.Add('b', 3);
    Expression  := 'a + b';
    Expected    := 8;
    ReturnValue := ParserResult;
    CheckEquals(Expected, ReturnValue, Expression);
  end;
  with FcyMathParser do
  begin
    Variables.Add('A',
      function: Double
      begin
        Result := 3 + 3
      end);
    Variables.Add('b',
      function: Double
      begin
        Result := 4
      end);
    Expression  := 'a + b';
    Expected    := 10;
    ReturnValue := ParserResult;
    CheckEquals(Expected, ReturnValue, Expression);
  end;
  with FcyMathParser do
  begin
    Variables.Add('A',
      function: Double
      begin
        Result := 3 + 2
      end);
    Variables.Add('b', 3);
    Expression  := 'a + b';
    Expected    := 8;
    ReturnValue := ParserResult;
    CheckEquals(Expected, ReturnValue, Expression);
  end;

  with FcyMathParser do
  begin
    Variables.Add('A',
      function: Double
      begin
        Result := Test
      end);
    Test := 3 + 2;
    Variables.Add('b', 3);
    Expression  := 'a + b';
    Expected    := 8;
    ReturnValue := ParserResult;
    CheckEquals(Expected, ReturnValue, Expression);

    Variables.Add('b', 4);
    Test        := 10;
    Expected    := 14;
    ReturnValue := ParserResult;
    CheckEquals(Expected, ReturnValue, Expression);
  end;
end;

initialization

ReportMemoryLeaksOnShutdown := True;
RegisterTest(TestTcyMathParser.Suite);

end.
