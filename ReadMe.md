#NewMathparser

Mathparser interprets and calculates mathematical strings in Delphi.

Faster than Parser10

Uses „Reverse Polish Notation“ (RPN)

With Unittesting!

32/64-bit, XE7 and newer

inspired by cyMathparser (Cindy Components )

Operators:
* '+' '-' '*' '/' : plus, minus, multiplication, division
* '^'             : power
* '%'             : mod

[How to use on wiki :](https://github.com/Jens01/NewMathparser/wiki)
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
 end;
end;
```
