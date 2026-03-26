with Lisp.Config;
with Lisp.Env;
with Lisp.Lexer;
with Lisp.Store;
with Lisp.Symbols;

package body Lisp.Parser with SPARK_Mode is
   use type Lisp.Types.Error_Code;
   use type Lisp.Lexer.Token_Kind;

   subtype List_Element_Count is Natural range 0 .. Lisp.Config.Max_List_Elements;

   type Element_Buffer is
     array (Positive range 1 .. Lisp.Config.Max_List_Elements) of Lisp.Types.Cell_Ref;

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
       and then Source'First = 1
       and then Pos in Source'Range
       and then Source'Last < Natural'Last,
     Post => Next_Pos in Pos .. Source'Last + 1
       and then Lisp.Symbols.Valid (RT.Symbols)
       and then Lisp.Store.Valid (RT.Store)
       and then
       (if Lisp.Types."=" (Error, Lisp.Types.Error_None) then
           Lisp.Store.Is_Valid_Ref (RT.Store, Ref)
        else
           Ref = Lisp.Types.No_Ref);

   function Element_Prefix_Valid
     (RT       : Lisp.Runtime.State;
      Elements : Element_Buffer;
      Count    : List_Element_Count) return Boolean is
     (for all I in 1 .. Count => Lisp.Store.Is_Valid_Ref (RT.Store, Elements (I)));

   function Suffix_Valid
     (RT       : Lisp.Runtime.State;
      Elements : Element_Buffer;
      First    : Positive;
      Last     : List_Element_Count) return Boolean is
     (if First <= Last then
         (for all I in First .. Last => Lisp.Store.Is_Valid_Ref (RT.Store, Elements (I)))
      else
         True);

   function Valid_Result
     (RT     : Lisp.Runtime.State;
      Result : Lisp.Types.Cell_Ref) return Boolean is
     (Result = Lisp.Store.Nil_Ref or else Lisp.Store.Is_Valid_Ref (RT.Store, Result));

   procedure Parse_Token_Expr
     (Source : in String;
      Tok    : in Lisp.Lexer.Token;
      Cursor : in out Positive;
      RT     : in out Lisp.Runtime.State;
      Ref    : out Lisp.Types.Cell_Ref;
      Error  : out Lisp.Types.Error_Code)
   with
     Pre => Lisp.Symbols.Valid (RT.Symbols)
       and then Lisp.Store.Valid (RT.Store)
       and then Source'First = 1
       and then Source'Last < Natural'Last
       and then Tok.First > 0
       and then Cursor in Tok.First .. Source'Last + 1,
     Post => Cursor in Tok.First .. Source'Last + 1
       and then Lisp.Symbols.Valid (RT.Symbols)
       and then Lisp.Store.Valid (RT.Store)
       and then
       (if Lisp.Types."=" (Error, Lisp.Types.Error_None) then
           Lisp.Store.Is_Valid_Ref (RT.Store, Ref)
        else
           Ref = Lisp.Types.No_Ref);

   procedure Make_List
     (RT         : in out Lisp.Runtime.State;
      Elements   : in Element_Buffer;
      Elem_Count : in List_Element_Count;
      Tail       : in Lisp.Types.Cell_Ref;
      Ref        : out Lisp.Types.Cell_Ref;
      Error      : out Lisp.Types.Error_Code)
   with
     Pre  => Lisp.Store.Valid (RT.Store)
       and then Element_Prefix_Valid (RT, Elements, Elem_Count)
       and then Valid_Result (RT, Tail),
     Post => Lisp.Store.Valid (RT.Store)
       and then
       (if Lisp.Types."=" (Error, Lisp.Types.Error_None) then
           Lisp.Store.Is_Valid_Ref (RT.Store, Ref)
        else
           Ref = Lisp.Types.No_Ref) is
      Result : Lisp.Types.Cell_Ref := Tail;
      Index  : List_Element_Count := Elem_Count;
   begin
      pragma Assert (Lisp.Store.Valid (RT.Store));
      while Index > 0 loop
         pragma Loop_Invariant (Lisp.Store.Valid (RT.Store));
         pragma Loop_Invariant (Index <= Elem_Count);
         pragma Loop_Invariant (Element_Prefix_Valid (RT, Elements, Elem_Count));
         pragma Loop_Invariant
           (if Index > 0 then Suffix_Valid (RT, Elements, Positive (Index), Elem_Count));
         pragma Loop_Invariant (Valid_Result (RT, Result));
         declare
            Current : constant Positive := Positive (Index);
         begin
            Lisp.Store.Make_Cons (RT.Store, Elements (Current), Result, Result, Error);
         end;
         if Error /= Lisp.Types.Error_None then
            Ref := Lisp.Types.No_Ref;
            return;
         end if;
         Index := Index - 1;
      end loop;

      Ref := Result;
      Error := Lisp.Types.Error_None;
   end Make_List;

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
       and then (if Item.Kind /= Lisp.Lexer.Tok_EOF then Item.First in Source'Range) is
   begin
      Lisp.Lexer.Next_Token (Source, Pos, Item, Next_Pos);
   end Scan_Token;

   procedure Parse_Atom
     (Source : in String;
      Tok    : in Lisp.Lexer.Token;
      RT     : in out Lisp.Runtime.State;
      Ref    : out Lisp.Types.Cell_Ref;
      Error  : out Lisp.Types.Error_Code)
   with
     Pre => Lisp.Symbols.Valid (RT.Symbols)
       and then Lisp.Store.Valid (RT.Store)
       and then Source'First = 1
       and then Tok.First in Source'Range
       and then (Tok.Kind = Lisp.Lexer.Tok_Integer
                 or else Tok.Kind = Lisp.Lexer.Tok_Nil
                 or else Tok.Kind = Lisp.Lexer.Tok_True
                 or else Tok.Kind = Lisp.Lexer.Tok_Symbol)
       and then
       (if Tok.Kind = Lisp.Lexer.Tok_Symbol then
           Tok.First in Source'Range
           and then Tok.Last in Tok.First .. Source'Last),
     Post => Lisp.Symbols.Valid (RT.Symbols)
       and then Lisp.Store.Valid (RT.Store)
       and then
       (if Lisp.Types."=" (Error, Lisp.Types.Error_None) then
           Lisp.Store.Is_Valid_Ref (RT.Store, Ref)
        else
           Ref = Lisp.Types.No_Ref) is
      Sym_Id : Lisp.Types.Symbol_Id;
   begin
      pragma Assert (Lisp.Symbols.Valid (RT.Symbols));
      pragma Assert (Lisp.Store.Valid (RT.Store));
      case Tok.Kind is
         when Lisp.Lexer.Tok_Integer =>
            Lisp.Store.Make_Integer (RT.Store, Tok.Int_Value, Ref, Error);
         when Lisp.Lexer.Tok_Nil =>
            Ref := Lisp.Store.Nil_Ref;
            Error := Lisp.Types.Error_None;
         when Lisp.Lexer.Tok_True =>
            Ref := Lisp.Store.True_Ref;
            Error := Lisp.Types.Error_None;
         when Lisp.Lexer.Tok_Symbol =>
            Lisp.Symbols.Intern (RT.Symbols, Source, Tok.First, Tok.Last, Sym_Id, Error);
            if Error = Lisp.Types.Error_None then
               Lisp.Store.Make_Symbol (RT.Store, Sym_Id, Ref, Error);
            else
               Ref := Lisp.Types.No_Ref;
            end if;
         when others =>
            Ref := Lisp.Types.No_Ref;
            Error := Lisp.Types.Error_Syntax;
      end case;
   end Parse_Atom;

   procedure Parse_List_Element
     (Source   : in String;
      Tok      : in Lisp.Lexer.Token;
      RT       : in out Lisp.Runtime.State;
      Cursor   : in out Positive;
      Elements : in out Element_Buffer;
      Count    : in out List_Element_Count;
      Error    : out Lisp.Types.Error_Code)
   with
     Pre => Lisp.Symbols.Valid (RT.Symbols)
       and then Lisp.Store.Valid (RT.Store)
       and then Source'First = 1
       and then Source'Last < Natural'Last
       and then Tok.First in Source'Range
       and then Cursor in Tok.First .. Source'Last + 1
       and then Count < Lisp.Config.Max_List_Elements
       and then Element_Prefix_Valid (RT, Elements, Count),
     Post => Lisp.Symbols.Valid (RT.Symbols)
       and then Lisp.Store.Valid (RT.Store)
       and then Element_Prefix_Valid (RT, Elements, Count)
       and then Cursor in Tok.First .. Source'Last + 1 is
      Elem_Ref : Lisp.Types.Cell_Ref;
   begin
      pragma Assert (Lisp.Symbols.Valid (RT.Symbols));
      pragma Assert (Lisp.Store.Valid (RT.Store));
      Parse_Token_Expr (Source, Tok, Cursor, RT, Elem_Ref, Error);
      if Error /= Lisp.Types.Error_None then
         return;
      end if;

      pragma Assert (Count < List_Element_Count'Last);
      Count := Count + 1;
      Elements (Count) := Elem_Ref;
   end Parse_List_Element;

   procedure Parse_Dotted_Tail
     (Source   : in String;
      Cursor   : in Positive;
      RT       : in out Lisp.Runtime.State;
      Elements : in Element_Buffer;
      Count    : in List_Element_Count;
      Ref      : out Lisp.Types.Cell_Ref;
      Next_Pos : out Positive;
      Error    : out Lisp.Types.Error_Code)
   with
     Pre => Lisp.Symbols.Valid (RT.Symbols)
       and then Lisp.Store.Valid (RT.Store)
       and then Source'First = 1
       and then Source'Last < Natural'Last
       and then Cursor in Source'Range
       and then Count > 0
       and then Element_Prefix_Valid (RT, Elements, Count),
     Post => Next_Pos in Cursor .. Source'Last + 1
       and then Lisp.Symbols.Valid (RT.Symbols)
       and then Lisp.Store.Valid (RT.Store)
       and then
       (if Lisp.Types."=" (Error, Lisp.Types.Error_None) then
           Lisp.Store.Is_Valid_Ref (RT.Store, Ref)
        else
           Ref = Lisp.Types.No_Ref) is
      Tail      : Lisp.Types.Cell_Ref;
      Close_Tok : Lisp.Lexer.Token;
      Tail_Pos  : Positive;
   begin
      pragma Assert (Lisp.Symbols.Valid (RT.Symbols));
      pragma Assert (Lisp.Store.Valid (RT.Store));
      Parse_Expr (Source, Cursor, RT, Tail, Tail_Pos, Error);
      if Error /= Lisp.Types.Error_None then
         Ref := Lisp.Types.No_Ref;
         Next_Pos := Tail_Pos;
         return;
      end if;

      if Tail_Pos > Source'Last then
         Ref := Lisp.Types.No_Ref;
         Next_Pos := Tail_Pos;
         Error := Lisp.Types.Error_Syntax;
         return;
      end if;

      Scan_Token (Source, Tail_Pos, Close_Tok, Next_Pos);
      if Close_Tok.Kind /= Lisp.Lexer.Tok_RParen then
         Ref := Lisp.Types.No_Ref;
         Error := Lisp.Types.Error_Syntax;
         return;
      end if;

      Make_List (RT, Elements, Count, Tail, Ref, Error);
      if Error /= Lisp.Types.Error_None then
         Next_Pos := Tail_Pos;
      end if;
   end Parse_Dotted_Tail;

   procedure Parse_Quoted
     (Source   : in String;
      Cursor   : in Positive;
      RT       : in out Lisp.Runtime.State;
      Ref      : out Lisp.Types.Cell_Ref;
      Next_Pos : out Positive;
      Error    : out Lisp.Types.Error_Code)
   with
     Pre => Lisp.Symbols.Valid (RT.Symbols)
       and then Lisp.Store.Valid (RT.Store)
       and then Source'First = 1
       and then Source'Last < Natural'Last
       and then Cursor in Source'Range,
     Post => Next_Pos in Cursor .. Source'Last + 1
       and then Lisp.Symbols.Valid (RT.Symbols)
       and then Lisp.Store.Valid (RT.Store)
       and then
       (if Lisp.Types."=" (Error, Lisp.Types.Error_None) then
           Lisp.Store.Is_Valid_Ref (RT.Store, Ref)
        else
           Ref = Lisp.Types.No_Ref) is
      Quote_Ref : Lisp.Types.Cell_Ref;
      Tail_Ref  : Lisp.Types.Cell_Ref;
   begin
      pragma Assert (Lisp.Symbols.Valid (RT.Symbols));
      pragma Assert (Lisp.Store.Valid (RT.Store));
      Parse_Expr (Source, Cursor, RT, Tail_Ref, Next_Pos, Error);
      if Error /= Lisp.Types.Error_None then
         Ref := Lisp.Types.No_Ref;
         return;
      end if;

      Lisp.Store.Make_Symbol (RT.Store, RT.Known.Quote_Id, Quote_Ref, Error);
      if Error /= Lisp.Types.Error_None then
         Ref := Lisp.Types.No_Ref;
         return;
      end if;

      Lisp.Store.Make_Cons (RT.Store, Tail_Ref, Lisp.Store.Nil_Ref, Tail_Ref, Error);
      if Error /= Lisp.Types.Error_None then
         Ref := Lisp.Types.No_Ref;
         return;
      end if;

      Lisp.Store.Make_Cons (RT.Store, Quote_Ref, Tail_Ref, Ref, Error);
   end Parse_Quoted;

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
       and then Source'First = 1
       and then Pos in Source'Range
       and then Source'Last < Natural'Last,
     Post => Next_Pos in Pos .. Source'Last + 1
       and then Lisp.Symbols.Valid (RT.Symbols)
       and then Lisp.Store.Valid (RT.Store)
       and then
       (if Lisp.Types."=" (Error, Lisp.Types.Error_None) then
           Lisp.Store.Is_Valid_Ref (RT.Store, Ref)
        else
           Ref = Lisp.Types.No_Ref) is
      Tok       : Lisp.Lexer.Token;
      Cursor    : Positive := Pos;
      Elements  : Element_Buffer := (others => Lisp.Types.No_Ref);
      Count     : List_Element_Count := 0;
   begin
      pragma Assert (Lisp.Symbols.Valid (RT.Symbols));
      pragma Assert (Lisp.Store.Valid (RT.Store));
      loop
         pragma Loop_Invariant (Lisp.Symbols.Valid (RT.Symbols));
         pragma Loop_Invariant (Lisp.Store.Valid (RT.Store));
         pragma Loop_Invariant (Element_Prefix_Valid (RT, Elements, Count));
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
               Make_List (RT, Elements, Count, Lisp.Store.Nil_Ref, Ref, Error);
               Next_Pos := Cursor;
               return;
            when Lisp.Lexer.Tok_Dot =>
               if Count = 0 then
                  Ref := Lisp.Types.No_Ref;
                  Next_Pos := Cursor;
                  Error := Lisp.Types.Error_Syntax;
                  return;
               end if;
               Parse_Dotted_Tail (Source, Cursor, RT, Elements, Count, Ref, Next_Pos, Error);
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
               Parse_List_Element (Source, Tok, RT, Cursor, Elements, Count, Error);
               if Error /= Lisp.Types.Error_None then
                  Ref := Lisp.Types.No_Ref;
                  Next_Pos := Cursor;
                  return;
               end if;
         end case;
      end loop;
   end Parse_List;

   procedure Parse_Token_Expr
     (Source : in String;
      Tok    : in Lisp.Lexer.Token;
      Cursor : in out Positive;
      RT     : in out Lisp.Runtime.State;
      Ref    : out Lisp.Types.Cell_Ref;
      Error  : out Lisp.Types.Error_Code) is
   begin
      pragma Assert (Lisp.Symbols.Valid (RT.Symbols));
      pragma Assert (Lisp.Store.Valid (RT.Store));
      case Tok.Kind is
         when Lisp.Lexer.Tok_Integer
            | Lisp.Lexer.Tok_Nil
            | Lisp.Lexer.Tok_True
            | Lisp.Lexer.Tok_Symbol =>
            Parse_Atom (Source, Tok, RT, Ref, Error);
         when Lisp.Lexer.Tok_Quote =>
            if Cursor > Source'Last then
               Ref := Lisp.Types.No_Ref;
               Error := Lisp.Types.Error_Syntax;
            else
               Parse_Quoted (Source, Cursor, RT, Ref, Cursor, Error);
            end if;
         when Lisp.Lexer.Tok_LParen =>
            if Cursor > Source'Last then
               Ref := Lisp.Types.No_Ref;
               Error := Lisp.Types.Error_Syntax;
            else
               Parse_List (Source, Cursor, RT, Ref, Cursor, Error);
            end if;
         when others =>
            Ref := Lisp.Types.No_Ref;
            Error := Lisp.Types.Error_Syntax;
      end case;
   end Parse_Token_Expr;

   procedure Parse_Expr
     (Source   : in String;
      Pos      : in Positive;
      RT       : in out Lisp.Runtime.State;
      Ref      : out Lisp.Types.Cell_Ref;
      Next_Pos : out Positive;
      Error    : out Lisp.Types.Error_Code) is
      Tok       : Lisp.Lexer.Token;
      Cursor    : Positive := Pos;
   begin
      pragma Assert (Lisp.Env.Valid (RT.Env));
      Scan_Token (Source, Pos, Tok, Cursor);
      Parse_Token_Expr (Source, Tok, Cursor, RT, Ref, Error);
      Next_Pos := Cursor;
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
      pragma Assert (Lisp.Env.Valid (RT.Env));
      Parse_Expr (Source, Pos, RT, Ref, Cursor, Error);
      pragma Assert (Lisp.Env.Valid (RT.Env));
      Next_Pos := Natural (Cursor);
   end Parse_One;
end Lisp.Parser;
