with Lisp.Lexer;
with Lisp.Types;

procedure Test.Lexer is
   use type Lisp.Lexer.Token_Kind;
   Tok  : Lisp.Lexer.Token;
   Next : Natural;
begin
   Lisp.Lexer.Next_Token ("'x", 1, Tok, Next);
   pragma Assert (Tok.Kind = Lisp.Lexer.Tok_Quote);
   Lisp.Lexer.Next_Token ("-123", 1, Tok, Next);
   pragma Assert (Tok.Kind = Lisp.Lexer.Tok_Integer);
   pragma Assert (Tok.Int_Value = -123);
end Test.Lexer;
