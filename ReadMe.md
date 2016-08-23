#NewMathparser

Mathparser interprets and calculates mathematical strings in Delphi.

Faster than Parser10

Uses „Reverse Polish Notation“ (RPN)

With Unittesting!

How to use :
```delphi
var
 MP : TMathParser;
 Error: TError;
begin
 MP := TMathParser.Create;
 try
   MP.Expression := '((4+5)6)7 + Min(3, 4, 5)';
   Error := MP.GetLastError;
   if Error.IsNoError then
     ShowMessage(MP.ParserResult.ToString)
   else
     ShowMessage(Error.ToString); 
 finally
  MP.Free;
 end;*
end;
```
