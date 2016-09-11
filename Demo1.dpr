program Demo1;

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
      MP.Expression := '((4+5)6)7 + Min(3, 4, 5)';
      Error         := MP.Error;
      if Error.IsNoError then
        write(MP.ParserResult.ToString)
      else
        write(Error.ToString);
    finally
      MP.Free;
    end;
    Readln;
  except
    on E: Exception do
      Writeln(E.ClassName, ': ', E.Message);
  end;

end.
