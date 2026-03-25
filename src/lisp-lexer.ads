with Lisp.Types;

package Lisp.Lexer with SPARK_Mode is
   type Token_Kind is
     (Tok_LParen,
      Tok_RParen,
      Tok_Dot,
      Tok_Quote,
      Tok_Integer,
      Tok_Nil,
      Tok_True,
      Tok_Symbol,
      Tok_EOF,
      Tok_Bad);

   type Token is record
      Kind      : Token_Kind := Tok_Bad;
      First     : Natural := 0;
      Last      : Natural := 0;
      Int_Value : Lisp.Types.Lisp_Int := 0;
   end record;

   procedure Next_Token
     (Source   : in String;
      Pos      : in Positive;
      Item     : out Token;
      Next_Pos : out Natural)
   with
     Pre => Source'First = 1
       and then Pos in Source'Range
       and then Source'Last < Natural'Last;
end Lisp.Lexer;
