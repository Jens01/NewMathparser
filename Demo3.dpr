program Demo3;

{$APPTYPE CONSOLE}
{$R *.res}

uses
  System.SysUtils,
  NewMathParser.Oper in 'NewMathParser.Oper.pas',
  NewMathParser in 'NewMathParser.pas';

var
  MP   : TMathParser;
  Error: TError;

begin
  try
    MP := TMathParser.Create;
    try
      MP.Expression := 'a + b';

      MP.Variables['A'] := function: Double
        begin
          Result := 3 + 3
        end;

      MP.Variables['b'] := function: Double
        begin
          Result := 4
        end;

      Error := MP.GetLastError;
      if Error.IsNoError then
        Writeln(MP.ParserResult.ToString)
      else
        Writeln(Error.ToString);
    finally
      MP.Free;
    end;
    Readln;
  except
    on E: Exception do
      Writeln(E.ClassName, ': ', E.Message);
  end;

end.
