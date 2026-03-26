with Lisp.Config;
with Lisp.Env;
with Lisp.Lexer;
with Lisp.Store;
with Lisp.Symbols;

package body Lisp.Parser with SPARK_Mode is
   use type Lisp.Types.Error_Code;
   use type Lisp.Lexer.Token_Kind;

   function End_Pos (Source : String) return Natural;

   procedure Parse_Expr
     (Source   : in String;
      Pos      : in Positive;
      RT       : in out Lisp.Runtime.State;
      Ref      : out Lisp.Types.Cell_Ref;
      Next_Pos : out Positive;
      Error    : out Lisp.Types.Error_Code)
   with
     Pre => Lisp.Runtime.Valid (RT)
       and then Source'First = 1
       and then Pos in Source'Range
       and then Source'Last < Natural'Last,
     Post => Next_Pos in Pos .. End_Pos (Source)
       and then Lisp.Runtime.Valid (RT)
       and then
       (if Lisp.Types."=" (Error, Lisp.Types.Error_None) then
           Lisp.Store.Is_Valid_Ref (RT.Store, Ref)
        else
           Ref = Lisp.Types.No_Ref);

   function End_Pos (Source : String) return Natural is
     (if Source'Last < Natural'Last then Source'Last + 1 else Natural'Last);

   function Element_Prefix_Valid
     (RT       : Lisp.Runtime.State;
      Elements : Lisp.Types.Cell_Ref_Array;
      Count    : Natural) return Boolean is
     (Elements'First = 1
      and then Count <= Elements'Length
      and then (for all I in 1 .. Count => Lisp.Store.Is_Valid_Ref (RT.Store, Elements (I))));

   procedure Make_Cons_Cell
     (RT    : in out Lisp.Runtime.State;
      Left  : in Lisp.Types.Cell_Ref;
      Right : in Lisp.Types.Cell_Ref;
      Ref   : out Lisp.Types.Cell_Ref;
      Error : out Lisp.Types.Error_Code)
   with
     Pre => Lisp.Runtime.Valid (RT),
     Post => Lisp.Runtime.Valid (RT)
       and then
       (if Lisp.Types."=" (Error, Lisp.Types.Error_None) then
           Lisp.Store.Is_Valid_Ref (RT.Store, Ref)
        else
           Ref = Lisp.Types.No_Ref);

   procedure Make_List
     (RT         : in out Lisp.Runtime.State;
      Elements   : in Lisp.Types.Cell_Ref_Array;
      Elem_Count : in Natural;
      Tail       : in Lisp.Types.Cell_Ref;
      Ref        : out Lisp.Types.Cell_Ref;
      Error      : out Lisp.Types.Error_Code)
   with
     Pre  => Lisp.Runtime.Valid (RT)
       and then Elements'First = 1
       and then Elem_Count <= Elements'Length
       and then Element_Prefix_Valid (RT, Elements, Elem_Count)
       and then (Tail = Lisp.Store.Nil_Ref or else Lisp.Store.Is_Valid_Ref (RT.Store, Tail)),
     Post => Lisp.Runtime.Valid (RT)
       and then
       (if Lisp.Types."=" (Error, Lisp.Types.Error_None) then
           Lisp.Store.Is_Valid_Ref (RT.Store, Ref)
        else
           Ref = Lisp.Types.No_Ref) is
      Result : Lisp.Types.Cell_Ref := Tail;
   begin
      pragma Assert (Lisp.Runtime.Valid (RT));
      pragma Assert (Elements'First = 1);
      pragma Assert (Element_Prefix_Valid (RT, Elements, Elem_Count));
      for I in reverse 1 .. Elem_Count loop
         pragma Loop_Invariant (Lisp.Store.Valid (RT.Store));
         pragma Loop_Invariant (Elem_Count <= Elements'Length);
         pragma Loop_Invariant (Elements'First = 1);
         pragma Loop_Invariant (Element_Prefix_Valid (RT, Elements, Elem_Count));
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
      Next_Pos : out Positive)
   with
     Pre => Source'First = 1
       and then Pos in Source'Range
       and then Source'Last < Natural'Last,
     Post => Next_Pos in Pos .. End_Pos (Source)
       and then Item.First > 0
       and then Item.Last in Item.First .. End_Pos (Source)
       and then (if Item.Kind /= Lisp.Lexer.Tok_EOF then Item.First in Source'Range) is
   begin
      Lisp.Lexer.Next_Token (Source, Pos, Item, Next_Pos);
   end Scan_Token;

   procedure Intern_Symbol
     (RT      : in out Lisp.Runtime.State;
      Source  : in String;
      First   : in Positive;
      Last    : in Natural;
      Sym_Id  : out Lisp.Types.Symbol_Id;
      Error   : out Lisp.Types.Error_Code)
   with
     Pre => Lisp.Runtime.Valid (RT)
       and then Source'First = 1
       and then First in Source'Range
       and then Last in First .. Source'Last,
     Post => Lisp.Runtime.Valid (RT) is
   begin
      Lisp.Symbols.Intern (RT.Symbols, Source, First, Last, Sym_Id, Error);
   end Intern_Symbol;

   procedure Make_Integer_Cell
     (RT    : in out Lisp.Runtime.State;
      Value : in Lisp.Types.Lisp_Int;
      Ref   : out Lisp.Types.Cell_Ref;
      Error : out Lisp.Types.Error_Code)
   with
     Pre => Lisp.Runtime.Valid (RT),
     Post => Lisp.Runtime.Valid (RT)
       and then
       (if Lisp.Types."=" (Error, Lisp.Types.Error_None) then
           Lisp.Store.Is_Valid_Ref (RT.Store, Ref)
        else
           Ref = Lisp.Types.No_Ref) is
   begin
      Lisp.Store.Make_Integer (RT.Store, Value, Ref, Error);
   end Make_Integer_Cell;

   procedure Make_Symbol_Cell
     (RT    : in out Lisp.Runtime.State;
      Value : in Lisp.Types.Symbol_Id;
      Ref   : out Lisp.Types.Cell_Ref;
      Error : out Lisp.Types.Error_Code)
   with
     Pre => Lisp.Runtime.Valid (RT),
     Post => Lisp.Runtime.Valid (RT)
       and then
       (if Lisp.Types."=" (Error, Lisp.Types.Error_None) then
           Lisp.Store.Is_Valid_Ref (RT.Store, Ref)
        else
           Ref = Lisp.Types.No_Ref) is
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

   procedure Parse_Atom
     (Source : in String;
      Tok    : in Lisp.Lexer.Token;
      RT     : in out Lisp.Runtime.State;
      Ref    : out Lisp.Types.Cell_Ref;
      Error  : out Lisp.Types.Error_Code)
   with
     Pre => Lisp.Runtime.Valid (RT)
       and then Source'First = 1
       and then (Tok.Kind = Lisp.Lexer.Tok_Integer
                 or else Tok.Kind = Lisp.Lexer.Tok_Nil
                 or else Tok.Kind = Lisp.Lexer.Tok_True
                 or else Tok.Kind = Lisp.Lexer.Tok_Symbol)
       and then
       (if Tok.Kind = Lisp.Lexer.Tok_Symbol then
           Tok.First in Source'Range
           and then Tok.Last in Tok.First .. Source'Last),
     Post => Lisp.Runtime.Valid (RT)
       and then
       (if Lisp.Types."=" (Error, Lisp.Types.Error_None) then
           Lisp.Store.Is_Valid_Ref (RT.Store, Ref)
        else
           Ref = Lisp.Types.No_Ref) is
      Sym_Id : Lisp.Types.Symbol_Id;
   begin
      case Tok.Kind is
         when Lisp.Lexer.Tok_Integer =>
            Make_Integer_Cell (RT, Tok.Int_Value, Ref, Error);
         when Lisp.Lexer.Tok_Nil =>
            Ref := Lisp.Store.Nil_Ref;
            Error := Lisp.Types.Error_None;
         when Lisp.Lexer.Tok_True =>
            Ref := Lisp.Store.True_Ref;
            Error := Lisp.Types.Error_None;
         when Lisp.Lexer.Tok_Symbol =>
            Intern_Symbol (RT, Source, Tok.First, Tok.Last, Sym_Id, Error);
            if Error = Lisp.Types.Error_None then
               Make_Symbol_Cell (RT, Sym_Id, Ref, Error);
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
      Elements : in out Lisp.Types.Cell_Ref_Array;
      Count    : in out Natural;
      Next_Pos : out Positive;
      Error    : out Lisp.Types.Error_Code)
   with
     Pre => Lisp.Runtime.Valid (RT)
       and then Source'First = 1
       and then Source'Last < Natural'Last
       and then Elements'First = 1
       and then Tok.First in Source'Range
       and then Count < Elements'Length
       and then Element_Prefix_Valid (RT, Elements, Count),
     Post => Lisp.Runtime.Valid (RT)
       and then Count <= Elements'Length
       and then Element_Prefix_Valid (RT, Elements, Count)
       and then Next_Pos in Tok.First .. End_Pos (Source) is
      Elem_Ref : Lisp.Types.Cell_Ref;
   begin
      Parse_Expr (Source, Tok.First, RT, Elem_Ref, Next_Pos, Error);
      if Error /= Lisp.Types.Error_None then
         return;
      end if;

      Count := Count + 1;
      Elements (Count) := Elem_Ref;
   end Parse_List_Element;

   procedure Parse_Dotted_Tail
     (Source   : in String;
      Cursor   : in Positive;
      RT       : in out Lisp.Runtime.State;
      Elements : in Lisp.Types.Cell_Ref_Array;
      Count    : in Natural;
      Ref      : out Lisp.Types.Cell_Ref;
      Next_Pos : out Positive;
      Error    : out Lisp.Types.Error_Code)
   with
     Pre => Lisp.Runtime.Valid (RT)
       and then Source'First = 1
       and then Source'Last < Natural'Last
       and then Elements'First = 1
       and then Cursor in Source'Range
       and then Count in 1 .. Elements'Length
       and then Element_Prefix_Valid (RT, Elements, Count),
     Post => Next_Pos in Cursor .. End_Pos (Source)
       and then Lisp.Runtime.Valid (RT)
       and then
       (if Lisp.Types."=" (Error, Lisp.Types.Error_None) then
           Lisp.Store.Is_Valid_Ref (RT.Store, Ref)
        else
           Ref = Lisp.Types.No_Ref) is
      Tail      : Lisp.Types.Cell_Ref;
      Close_Tok : Lisp.Lexer.Token;
      Tail_Pos  : Positive;
   begin
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
     Pre => Lisp.Runtime.Valid (RT)
       and then Source'First = 1
       and then Source'Last < Natural'Last
       and then Cursor in Source'Range,
     Post => Next_Pos in Cursor .. End_Pos (Source)
       and then Lisp.Runtime.Valid (RT)
       and then
       (if Lisp.Types."=" (Error, Lisp.Types.Error_None) then
           Lisp.Store.Is_Valid_Ref (RT.Store, Ref)
        else
           Ref = Lisp.Types.No_Ref) is
      Quote_Ref : Lisp.Types.Cell_Ref;
      Tail_Ref  : Lisp.Types.Cell_Ref;
   begin
      Parse_Expr (Source, Cursor, RT, Tail_Ref, Next_Pos, Error);
      if Error /= Lisp.Types.Error_None then
         Ref := Lisp.Types.No_Ref;
         return;
      end if;

      Make_Symbol_Cell (RT, RT.Known.Quote_Id, Quote_Ref, Error);
      if Error /= Lisp.Types.Error_None then
         Ref := Lisp.Types.No_Ref;
         return;
      end if;

      Make_Cons_Cell (RT, Tail_Ref, Lisp.Store.Nil_Ref, Tail_Ref, Error);
      if Error /= Lisp.Types.Error_None then
         Ref := Lisp.Types.No_Ref;
         return;
      end if;

      Make_Cons_Cell (RT, Quote_Ref, Tail_Ref, Ref, Error);
   end Parse_Quoted;

   procedure Parse_List
     (Source   : in String;
      Pos      : in Positive;
      RT       : in out Lisp.Runtime.State;
      Ref      : out Lisp.Types.Cell_Ref;
      Next_Pos : out Positive;
      Error    : out Lisp.Types.Error_Code)
   with
     Pre => Lisp.Runtime.Valid (RT)
       and then Source'First = 1
       and then Pos in Source'Range
       and then Source'Last < Natural'Last,
     Post => Next_Pos in Pos .. End_Pos (Source)
       and then Lisp.Runtime.Valid (RT)
       and then
       (if Lisp.Types."=" (Error, Lisp.Types.Error_None) then
           Lisp.Store.Is_Valid_Ref (RT.Store, Ref)
        else
           Ref = Lisp.Types.No_Ref) is
      Tok       : Lisp.Lexer.Token;
      Cursor    : Positive := Pos;
      Elements  : Lisp.Types.Cell_Ref_Array (1 .. Lisp.Config.Max_List_Elements) := (others => Lisp.Types.No_Ref);
      Count     : Natural := 0;
   begin
      loop
         pragma Loop_Invariant (Lisp.Symbols.Valid (RT.Symbols));
         pragma Loop_Invariant (Lisp.Store.Valid (RT.Store));
         pragma Loop_Invariant (Lisp.Env.Valid (RT.Env));
         pragma Loop_Invariant (Elements'First = 1);
         pragma Loop_Invariant (Element_Prefix_Valid (RT, Elements, Count));
         pragma Loop_Invariant (Count <= Lisp.Config.Max_List_Elements);
         pragma Loop_Invariant (Cursor in Pos .. End_Pos (Source));
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
               Parse_List_Element (Source, Tok, RT, Elements, Count, Cursor, Error);
               if Error /= Lisp.Types.Error_None then
                  Ref := Lisp.Types.No_Ref;
                  Next_Pos := Cursor;
                  return;
               end if;
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
   begin
      Scan_Token (Source, Pos, Tok, Cursor);
      case Tok.Kind is
         when Lisp.Lexer.Tok_Integer
            | Lisp.Lexer.Tok_Nil
            | Lisp.Lexer.Tok_True
            | Lisp.Lexer.Tok_Symbol =>
            Parse_Atom (Source, Tok, RT, Ref, Error);
            Next_Pos := Cursor;
         when Lisp.Lexer.Tok_Quote =>
            if Cursor > Source'Last then
               Ref := Lisp.Types.No_Ref;
               Next_Pos := Cursor;
               Error := Lisp.Types.Error_Syntax;
            else
               Parse_Quoted (Source, Cursor, RT, Ref, Next_Pos, Error);
            end if;
         when Lisp.Lexer.Tok_LParen =>
            if Cursor > Source'Last then
               Ref := Lisp.Types.No_Ref;
               Next_Pos := Cursor;
               Error := Lisp.Types.Error_Syntax;
            else
               Parse_List (Source, Cursor, RT, Ref, Next_Pos, Error);
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
