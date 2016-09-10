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
 end;
end;
```
How to use variables:
```delphi
var
 MP : TMathParser;
 Error: TError;
begin
 MP := TMathParser.Create;
 try
   MP.Expression := 'a + b';
   MP.Variables.Add('A', 5);
   MP.Variables.Add('b', 3);   
   Error := MP.GetLastError;
   if Error.IsNoError then
     ShowMessage(MP.ParserResult.ToString)
   else
     ShowMessage(Error.ToString);
     
   // change variable :
   MP.Variables['A'] := 7;
   ShowMessage(MP.ParserResult.ToString);
 finally
  MP.Free;
 end;
end;
```
How to use dynamic variables:
```delphi
var
 MP : TMathParser;
 Error: TError;
begin
 MP := TMathParser.Create;
 try
   MP.Expression := 'a + b';
   MP.Variables.Add('A',
      function: Double
      begin
        Result := 3 + 3
      end);
   MP.Variables.Add('b',
      function: Double
      begin
        Result := 4
      end);  
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
