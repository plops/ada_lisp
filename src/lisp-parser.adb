with Lisp.Config;
with Lisp.Env;
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
      Next_Pos : out Positive;
      Error    : out Lisp.Types.Error_Code)
   with
     Pre => Lisp.Symbols.Valid (RT.Symbols)
       and then Lisp.Store.Valid (RT.Store)
       and then Lisp.Env.Valid (RT.Env)
       and then Source'First = 1
       and then Pos in Source'Range
       and then Source'Last < Natural'Last,
     Post => Next_Pos > 0
       and then
       (if Lisp.Types."=" (Error, Lisp.Types.Error_None) then
           Lisp.Symbols.Valid (RT.Symbols)
           and then Lisp.Store.Valid (RT.Store)
           and then Lisp.Env.Valid (RT.Env));

   procedure Scan_Token
     (Source   : in String;
      Pos      : in Positive;
      Item     : out Lisp.Lexer.Token;
      Next_Pos : out Positive)
   with
     Pre => Source'First = 1
       and then Pos in Source'Range
       and then Source'Last < Natural'Last,
     Post => Next_Pos in Pos .. Source'Last + 1
       and then Item.First > 0
       and then Item.Last in Item.First .. Source'Last + 1
       and then (if Item.Kind /= Lisp.Lexer.Tok_EOF then Item.First in Source'Range);

   procedure Intern_Symbol
     (RT      : in out Lisp.Runtime.State;
      Source  : in String;
      First   : in Positive;
      Last    : in Natural;
      Sym_Id  : out Lisp.Types.Symbol_Id;
      Error   : out Lisp.Types.Error_Code)
   with
     Pre => Lisp.Symbols.Valid (RT.Symbols)
       and then Lisp.Store.Valid (RT.Store)
       and then Source'First = 1
       and then First in Source'Range
       and then Last in First .. Source'Last,
     Post => (if Lisp.Types."=" (Error, Lisp.Types.Error_None) then
                 Lisp.Symbols.Valid (RT.Symbols)
                 and then Lisp.Store.Valid (RT.Store));

   procedure Make_Integer_Cell
     (RT    : in out Lisp.Runtime.State;
      Value : in Lisp.Types.Lisp_Int;
      Ref   : out Lisp.Types.Cell_Ref;
      Error : out Lisp.Types.Error_Code)
   with
     Pre => Lisp.Store.Valid (RT.Store),
     Post => (if Lisp.Types."=" (Error, Lisp.Types.Error_None) then Lisp.Store.Valid (RT.Store));

   procedure Make_Symbol_Cell
     (RT    : in out Lisp.Runtime.State;
      Value : in Lisp.Types.Symbol_Id;
      Ref   : out Lisp.Types.Cell_Ref;
      Error : out Lisp.Types.Error_Code)
   with
     Pre => Lisp.Store.Valid (RT.Store),
     Post => (if Lisp.Types."=" (Error, Lisp.Types.Error_None) then Lisp.Store.Valid (RT.Store));

   procedure Make_Cons_Cell
     (RT    : in out Lisp.Runtime.State;
      Left  : in Lisp.Types.Cell_Ref;
      Right : in Lisp.Types.Cell_Ref;
      Ref   : out Lisp.Types.Cell_Ref;
      Error : out Lisp.Types.Error_Code)
   with
     Pre => Lisp.Store.Valid (RT.Store),
     Post => (if Lisp.Types."=" (Error, Lisp.Types.Error_None) then Lisp.Store.Valid (RT.Store));

   procedure Make_List
     (RT         : in out Lisp.Runtime.State;
      Elements   : in Lisp.Types.Cell_Ref_Array;
      Elem_Count : in Natural;
      Tail       : in Lisp.Types.Cell_Ref;
      Ref        : out Lisp.Types.Cell_Ref;
      Error      : out Lisp.Types.Error_Code)
   with
     Pre  => Lisp.Store.Valid (RT.Store)
       and then Elem_Count <= Elements'Length,
     Post => (if Lisp.Types."=" (Error, Lisp.Types.Error_None) then Lisp.Store.Valid (RT.Store)) is
      Result : Lisp.Types.Cell_Ref := Tail;
   begin
      for I in reverse 1 .. Elem_Count loop
         pragma Loop_Invariant (Lisp.Store.Valid (RT.Store));
         pragma Loop_Invariant (Elem_Count <= Elements'Length);
         pragma Loop_Invariant (I in 1 .. Elem_Count);
         Make_Cons_Cell (RT, Elements (I), Result, Result, Error);
         if Error /= Lisp.Types.Error_None then
            Ref := Lisp.Types.No_Ref;
            return;
         end if;
      end loop;

      Ref := Result;
     Error := Lisp.Types.Error_None;
   end Make_List;

   procedure Scan_Token
     (Source   : in String;
      Pos      : in Positive;
      Item     : out Lisp.Lexer.Token;
      Next_Pos : out Positive) is
   begin
      Lisp.Lexer.Next_Token (Source, Pos, Item, Next_Pos);
   end Scan_Token;

   procedure Intern_Symbol
     (RT      : in out Lisp.Runtime.State;
      Source  : in String;
      First   : in Positive;
      Last    : in Natural;
      Sym_Id  : out Lisp.Types.Symbol_Id;
      Error   : out Lisp.Types.Error_Code) is
   begin
      Lisp.Symbols.Intern (RT.Symbols, Source, First, Last, Sym_Id, Error);
   end Intern_Symbol;

   procedure Make_Integer_Cell
     (RT    : in out Lisp.Runtime.State;
      Value : in Lisp.Types.Lisp_Int;
      Ref   : out Lisp.Types.Cell_Ref;
      Error : out Lisp.Types.Error_Code) is
   begin
      Lisp.Store.Make_Integer (RT.Store, Value, Ref, Error);
   end Make_Integer_Cell;

   procedure Make_Symbol_Cell
     (RT    : in out Lisp.Runtime.State;
      Value : in Lisp.Types.Symbol_Id;
      Ref   : out Lisp.Types.Cell_Ref;
      Error : out Lisp.Types.Error_Code) is
   begin
      Lisp.Store.Make_Symbol (RT.Store, Value, Ref, Error);
   end Make_Symbol_Cell;

   procedure Make_Cons_Cell
     (RT    : in out Lisp.Runtime.State;
      Left  : in Lisp.Types.Cell_Ref;
      Right : in Lisp.Types.Cell_Ref;
      Ref   : out Lisp.Types.Cell_Ref;
      Error : out Lisp.Types.Error_Code) is
   begin
      Lisp.Store.Make_Cons (RT.Store, Left, Right, Ref, Error);
   end Make_Cons_Cell;

   procedure Parse_List
     (Source   : in String;
      Pos      : in Positive;
      RT       : in out Lisp.Runtime.State;
      Ref      : out Lisp.Types.Cell_Ref;
      Next_Pos : out Positive;
      Error    : out Lisp.Types.Error_Code)
   with
     Pre => Lisp.Symbols.Valid (RT.Symbols)
       and then Lisp.Store.Valid (RT.Store)
       and then Lisp.Env.Valid (RT.Env)
       and then Source'First = 1
       and then Pos in Source'Range
       and then Source'Last < Natural'Last,
     Post => Next_Pos > 0
       and then
       (if Lisp.Types."=" (Error, Lisp.Types.Error_None) then
           Lisp.Symbols.Valid (RT.Symbols)
           and then Lisp.Store.Valid (RT.Store)
           and then Lisp.Env.Valid (RT.Env)) is
      Tok       : Lisp.Lexer.Token;
      Cursor    : Positive := Pos;
      Elements  : Lisp.Types.Cell_Ref_Array (1 .. Lisp.Config.Max_List_Elements) := (others => Lisp.Types.No_Ref);
      Count     : Natural := 0;
      Tail      : Lisp.Types.Cell_Ref := Lisp.Store.Nil_Ref;
      Dotted    : Boolean := False;
      Elem_Ref  : Lisp.Types.Cell_Ref := Lisp.Types.No_Ref;
   begin
      loop
         pragma Loop_Invariant (Lisp.Symbols.Valid (RT.Symbols));
         pragma Loop_Invariant (Lisp.Store.Valid (RT.Store));
         pragma Loop_Invariant (Lisp.Env.Valid (RT.Env));
         pragma Loop_Invariant (Count <= Lisp.Config.Max_List_Elements);
         pragma Loop_Invariant (Cursor in Pos .. Source'Last + 1);
         if Cursor > Source'Last then
            Ref := Lisp.Types.No_Ref;
            Next_Pos := Cursor;
            Error := Lisp.Types.Error_Syntax;
            return;
         end if;
         Scan_Token (Source, Cursor, Tok, Cursor);
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
               Parse_Expr (Source, Cursor, RT, Tail, Cursor, Error);
               if Error /= Lisp.Types.Error_None then
                  Ref := Lisp.Types.No_Ref;
                  Next_Pos := Cursor;
                  return;
               end if;
               Dotted := True;
               Scan_Token (Source, Cursor, Tok, Cursor);
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
      Next_Pos : out Positive;
      Error    : out Lisp.Types.Error_Code) is
      Tok       : Lisp.Lexer.Token;
      Cursor    : Positive := Pos;
      Sym_Id    : Lisp.Types.Symbol_Id := 0;
      Quote_Ref : Lisp.Types.Cell_Ref := Lisp.Types.No_Ref;
      Tail_Ref  : Lisp.Types.Cell_Ref := Lisp.Types.No_Ref;
   begin
      Scan_Token (Source, Pos, Tok, Cursor);
      case Tok.Kind is
         when Lisp.Lexer.Tok_Integer =>
            Make_Integer_Cell (RT, Tok.Int_Value, Ref, Error);
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
            Intern_Symbol (RT, Source, Tok.First, Tok.Last, Sym_Id, Error);
            if Error = Lisp.Types.Error_None then
               Make_Symbol_Cell (RT, Sym_Id, Ref, Error);
            else
               Ref := Lisp.Types.No_Ref;
            end if;
            Next_Pos := Cursor;
         when Lisp.Lexer.Tok_Quote =>
            if Cursor > Source'Last then
               Ref := Lisp.Types.No_Ref;
               Next_Pos := Cursor;
               Error := Lisp.Types.Error_Syntax;
               return;
            end if;
            Parse_Expr (Source, Cursor, RT, Tail_Ref, Cursor, Error);
            if Error /= Lisp.Types.Error_None then
               Ref := Lisp.Types.No_Ref;
               Next_Pos := Cursor;
               return;
            end if;
            Make_Symbol_Cell (RT, RT.Known.Quote_Id, Quote_Ref, Error);
            if Error /= Lisp.Types.Error_None then
               Ref := Lisp.Types.No_Ref;
               Next_Pos := Cursor;
               return;
            end if;
            Make_Cons_Cell (RT, Tail_Ref, Lisp.Store.Nil_Ref, Tail_Ref, Error);
            if Error /= Lisp.Types.Error_None then
               Ref := Lisp.Types.No_Ref;
               Next_Pos := Cursor;
               return;
            end if;
            Make_Cons_Cell (RT, Quote_Ref, Tail_Ref, Ref, Error);
            Next_Pos := Cursor;
         when Lisp.Lexer.Tok_LParen =>
            if Cursor > Source'Last then
               Ref := Lisp.Types.No_Ref;
               Next_Pos := Cursor;
               Error := Lisp.Types.Error_Syntax;
               return;
            end if;
            Scan_Token (Source, Cursor, Tok, Cursor);
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
      Cursor : Positive;
   begin
      Parse_Expr (Source, Pos, RT, Ref, Cursor, Error);
      Next_Pos := Natural (Cursor);
   end Parse_One;
end Lisp.Parser;
