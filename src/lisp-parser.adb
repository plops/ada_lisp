with Lisp.Config;
with Lisp.Lexer;
with Lisp.Store;
with Lisp.Symbols;

package body Lisp.Parser with SPARK_Mode is
   use type Lisp.Types.Error_Code;
   use type Lisp.Lexer.Token_Kind;

   procedure Parse_Expr
     (Source   : in String;
      Pos      : in Positive;
      RT       : in out Lisp.Runtime.State;
      Ref      : out Lisp.Types.Cell_Ref;
      Next_Pos : out Natural;
      Error    : out Lisp.Types.Error_Code)
   with
     Pre => Lisp.Runtime.Valid (RT),
     Post => Lisp.Runtime.Valid (RT);

   procedure Make_List
     (RT         : in out Lisp.Runtime.State;
      Elements   : in Lisp.Types.Cell_Ref_Array;
      Elem_Count : in Natural;
      Tail       : in Lisp.Types.Cell_Ref;
      Ref        : out Lisp.Types.Cell_Ref;
      Error      : out Lisp.Types.Error_Code) is
      Result : Lisp.Types.Cell_Ref := Tail;
   begin
      for I in reverse 1 .. Elem_Count loop
         Lisp.Store.Make_Cons (RT.Store, Elements (I), Result, Result, Error);
         if Error /= Lisp.Types.Error_None then
            Ref := Lisp.Types.No_Ref;
            return;
         end if;
      end loop;

      Ref := Result;
      Error := Lisp.Types.Error_None;
   end Make_List;

   procedure Parse_List
     (Source   : in String;
      Pos      : in Positive;
      RT       : in out Lisp.Runtime.State;
      Ref      : out Lisp.Types.Cell_Ref;
      Next_Pos : out Natural;
      Error    : out Lisp.Types.Error_Code) is
      Tok       : Lisp.Lexer.Token;
      Cursor    : Natural := Pos;
      Elements  : Lisp.Types.Cell_Ref_Array (1 .. Lisp.Config.Max_List_Elements) := (others => Lisp.Types.No_Ref);
      Count     : Natural := 0;
      Tail      : Lisp.Types.Cell_Ref := Lisp.Store.Nil_Ref;
      Dotted    : Boolean := False;
      Elem_Ref  : Lisp.Types.Cell_Ref := Lisp.Types.No_Ref;
   begin
      loop
         pragma Loop_Invariant (Lisp.Runtime.Valid (RT));
         pragma Loop_Invariant (Count <= Lisp.Config.Max_List_Elements);
         pragma Loop_Invariant (Cursor >= Pos);
         Lisp.Lexer.Next_Token (Source, Positive (Cursor), Tok, Cursor);
         case Tok.Kind is
            when Lisp.Lexer.Tok_RParen =>
               Make_List (RT, Elements, Count, Tail, Ref, Error);
               Next_Pos := Cursor;
               return;
            when Lisp.Lexer.Tok_Dot =>
               if Count = 0 or else Dotted then
                  Ref := Lisp.Types.No_Ref;
                  Next_Pos := Cursor;
                  Error := Lisp.Types.Error_Syntax;
                  return;
               end if;
               Parse_Expr (Source, Positive (Cursor), RT, Tail, Cursor, Error);
               if Error /= Lisp.Types.Error_None then
                  Ref := Lisp.Types.No_Ref;
                  Next_Pos := Cursor;
                  return;
               end if;
               Dotted := True;
               Lisp.Lexer.Next_Token (Source, Positive (Cursor), Tok, Cursor);
               if Tok.Kind /= Lisp.Lexer.Tok_RParen then
                  Ref := Lisp.Types.No_Ref;
                  Next_Pos := Cursor;
                  Error := Lisp.Types.Error_Syntax;
                  return;
               end if;
               Make_List (RT, Elements, Count, Tail, Ref, Error);
               Next_Pos := Cursor;
               return;
            when Lisp.Lexer.Tok_EOF =>
               Ref := Lisp.Types.No_Ref;
               Next_Pos := Cursor;
               Error := Lisp.Types.Error_Syntax;
               return;
            when others =>
               if Count = Lisp.Config.Max_List_Elements then
                  Ref := Lisp.Types.No_Ref;
                  Next_Pos := Cursor;
                  Error := Lisp.Types.Error_Arena_Full;
                  return;
               end if;
               Parse_Expr (Source, Tok.First, RT, Elem_Ref, Cursor, Error);
               if Error /= Lisp.Types.Error_None then
                  Ref := Lisp.Types.No_Ref;
                  Next_Pos := Cursor;
                  return;
               end if;
               Count := Count + 1;
               Elements (Count) := Elem_Ref;
         end case;
      end loop;
   end Parse_List;

   procedure Parse_Expr
     (Source   : in String;
      Pos      : in Positive;
      RT       : in out Lisp.Runtime.State;
      Ref      : out Lisp.Types.Cell_Ref;
      Next_Pos : out Natural;
      Error    : out Lisp.Types.Error_Code) is
      Tok       : Lisp.Lexer.Token;
      Cursor    : Natural;
      Sym_Id    : Lisp.Types.Symbol_Id := 0;
      Sym_Ref   : Lisp.Types.Cell_Ref := Lisp.Types.No_Ref;
      Quote_Ref : Lisp.Types.Cell_Ref := Lisp.Types.No_Ref;
      Tail_Ref  : Lisp.Types.Cell_Ref := Lisp.Types.No_Ref;
   begin
      Lisp.Lexer.Next_Token (Source, Pos, Tok, Cursor);
      case Tok.Kind is
         when Lisp.Lexer.Tok_Integer =>
            Lisp.Store.Make_Integer (RT.Store, Tok.Int_Value, Ref, Error);
            Next_Pos := Cursor;
         when Lisp.Lexer.Tok_Nil =>
            Ref := Lisp.Store.Nil_Ref;
            Next_Pos := Cursor;
            Error := Lisp.Types.Error_None;
         when Lisp.Lexer.Tok_True =>
            Ref := Lisp.Store.True_Ref;
            Next_Pos := Cursor;
            Error := Lisp.Types.Error_None;
         when Lisp.Lexer.Tok_Symbol =>
            Lisp.Symbols.Intern (RT.Symbols, Source, Tok.First, Tok.Last, Sym_Id, Error);
            if Error = Lisp.Types.Error_None then
               Lisp.Store.Make_Symbol (RT.Store, Sym_Id, Ref, Error);
            else
               Ref := Lisp.Types.No_Ref;
            end if;
            Next_Pos := Cursor;
         when Lisp.Lexer.Tok_Quote =>
            Parse_Expr (Source, Positive (Cursor), RT, Tail_Ref, Cursor, Error);
            if Error /= Lisp.Types.Error_None then
               Ref := Lisp.Types.No_Ref;
               Next_Pos := Cursor;
               return;
            end if;
            Lisp.Store.Make_Symbol (RT.Store, RT.Known.Quote_Id, Quote_Ref, Error);
            if Error /= Lisp.Types.Error_None then
               Ref := Lisp.Types.No_Ref;
               Next_Pos := Cursor;
               return;
            end if;
            Lisp.Store.Make_Cons (RT.Store, Tail_Ref, Lisp.Store.Nil_Ref, Tail_Ref, Error);
            if Error /= Lisp.Types.Error_None then
               Ref := Lisp.Types.No_Ref;
               Next_Pos := Cursor;
               return;
            end if;
            Lisp.Store.Make_Cons (RT.Store, Quote_Ref, Tail_Ref, Ref, Error);
            Next_Pos := Cursor;
         when Lisp.Lexer.Tok_LParen =>
            Lisp.Lexer.Next_Token (Source, Positive (Cursor), Tok, Cursor);
            if Tok.Kind = Lisp.Lexer.Tok_RParen then
               Ref := Lisp.Store.Nil_Ref;
               Next_Pos := Cursor;
               Error := Lisp.Types.Error_None;
            else
               Parse_List (Source, Tok.First, RT, Ref, Next_Pos, Error);
            end if;
         when others =>
            Ref := Lisp.Types.No_Ref;
            Next_Pos := Cursor;
            Error := Lisp.Types.Error_Syntax;
      end case;
   end Parse_Expr;

   procedure Parse_One
     (Source   : in String;
      Pos      : in Positive;
      RT       : in out Lisp.Runtime.State;
      Ref      : out Lisp.Types.Cell_Ref;
      Next_Pos : out Natural;
      Error    : out Lisp.Types.Error_Code) is
   begin
      Parse_Expr (Source, Pos, RT, Ref, Next_Pos, Error);
   end Parse_One;
end Lisp.Parser;
