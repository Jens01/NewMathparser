program Demo2;

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
      MP.Expression     := 'a + b';
      MP.Variables['A'] := 5;
      MP.Variables['b'] := 3;
      Error             := MP.Error;
      if Error.IsNoError then
        Writeln(MP.ParserResult.ToString)
      else
        Writeln(Error.ToString);

      // change variable :
      MP.Variables['A'] := 7;
      Writeln(MP.ParserResult.ToString);
    finally
      MP.Free;
    end;
    Readln;
  except
    on E: Exception do
      Writeln(E.ClassName, ': ', E.Message);
  end;

end.
