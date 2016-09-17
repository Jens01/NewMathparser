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
 R: Double;
begin
 MP := TMathParser.Create;
 try
   MP.Expression := '((4+5)6)7 + Min(3, 4, 5)';
   R := MP.ParserResult;
   if MP.Error.IsNoError then
     ShowMessage(R.ToString)
   else
     ShowMessage(MP.Error.ToString); 
 finally
  MP.Free;
 end;
end;
```
