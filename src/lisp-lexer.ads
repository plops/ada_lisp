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
      Next_Pos : out Positive)
   with
     Pre => Source'First = 1
       and then Pos in Source'Range
       and then Source'Last < Natural'Last,
     Post => Next_Pos in Pos .. Source'Last + 1
       and then Item.First > 0
       and then Item.Last in Item.First .. Source'Last + 1
       and then (if Item.Kind /= Tok_EOF then Item.First in Source'Range);
end Lisp.Lexer;
