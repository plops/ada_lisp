package body Lisp.Runtime with SPARK_Mode is
   use type Lisp.Types.Error_Code;

   procedure Intern_Known
     (RT      : in out State;
      Name    : in String;
      First   : in Positive;
      Last    : in Natural;
      Name_Id : out Lisp.Types.Symbol_Id;
      Error   : out Lisp.Types.Error_Code)
   with
     Pre  => Valid (RT)
       and then Name'First = 1
       and then First in Name'Range
       and then Last in First .. Name'Last,
     Post => Valid (RT)
       and then Lisp.Symbols.Entries_Preserved (RT'Old.Symbols, RT.Symbols)
       and then
       (if Lisp.Types."=" (Error, Lisp.Types.Error_None) then
           Lisp.Symbols.Interned (RT.Symbols, Name_Id)
           and then Lisp.Symbols.Equal_Slice (RT.Symbols, Name_Id, Name, First, Last)
        else
           Name_Id = 0);

   procedure Bind_Primitive
     (RT      : in out State;
      Name_Id : in Lisp.Types.Symbol_Id;
      Prim    : in Lisp.Types.Primitive_Kind;
      Error   : out Lisp.Types.Error_Code)
   with
     Pre  => Valid (RT),
     Post => Valid (RT) is
      Ref : Lisp.Types.Cell_Ref;
   begin
      Lisp.Store.Make_Primitive (RT.Store, Prim, Ref, Error);
      if Error /= Lisp.Types.Error_None then
         return;
      end if;

      Lisp.Env.Define_Global (RT.Env, Name_Id, Ref, Error);
   end Bind_Primitive;

   procedure Intern_Known
     (RT      : in out State;
      Name    : in String;
      First   : in Positive;
      Last    : in Natural;
      Name_Id : out Lisp.Types.Symbol_Id;
      Error   : out Lisp.Types.Error_Code) is
   begin
      Lisp.Symbols.Intern (RT.Symbols, Name, First, Last, Name_Id, Error);
   end Intern_Known;

   procedure Prove_Quote_If_Known_Distinct (RT : in State) is
   begin
      pragma Assert
        (Lisp.Symbols.Length_Of (RT.Symbols, RT.Known.Quote_Id) =
         Quote_Name'Length);
      pragma Assert
        (Lisp.Symbols.Length_Of (RT.Symbols, RT.Known.If_Id) =
         If_Name'Length);
      Lisp.Symbols.Prove_Different_Length_Ids_Distinct
        (RT.Symbols,
         RT.Known.Quote_Id,
         Quote_Name'Length,
         RT.Known.If_Id,
         If_Name'Length);
   end Prove_Quote_If_Known_Distinct;

   procedure Initialize (RT : in out State; Error : out Lisp.Types.Error_Code) is
      Name_Id     : Lisp.Types.Symbol_Id;
      Quote_Id    : Lisp.Types.Symbol_Id;
      If_Id       : Lisp.Types.Symbol_Id;
      Quote_Table : Lisp.Symbols.Table;
   begin
      Lisp.Symbols.Initialize (RT.Symbols);
      Lisp.Store.Initialize (RT.Store);
      Lisp.Env.Initialize (RT.Env);
      RT.Known := (others => 0);
      pragma Assert (Lisp.Symbols.Valid (RT.Symbols));
      pragma Assert (Lisp.Store.Valid (RT.Store));
      pragma Assert (Lisp.Env.Valid (RT.Env));

      Intern_Known (RT, Quote_Name, Quote_Name'First, Quote_Name'Last, Name_Id, Error);
      if Error /= Lisp.Types.Error_None then return; end if;
      RT.Known.Quote_Id := Name_Id;
      Intern_Known (RT, If_Name, If_Name'First, If_Name'Last, Name_Id, Error);
      if Error /= Lisp.Types.Error_None then return; end if;
      RT.Known.If_Id := Name_Id;
      Intern_Known (RT, "lambda", 1, 6, Name_Id, Error);
      if Error /= Lisp.Types.Error_None then return; end if;
      RT.Known.Lambda_Id := Name_Id;
      Intern_Known (RT, "define", 1, 6, Name_Id, Error);
      if Error /= Lisp.Types.Error_None then return; end if;
      RT.Known.Define_Id := Name_Id;
      Intern_Known (RT, "begin", 1, 5, Name_Id, Error);
      if Error /= Lisp.Types.Error_None then return; end if;
      RT.Known.Begin_Id := Name_Id;
      Intern_Known (RT, "atom", 1, 4, Name_Id, Error);
      if Error /= Lisp.Types.Error_None then return; end if;
      RT.Known.Atom_Id := Name_Id;
      Intern_Known (RT, "eq", 1, 2, Name_Id, Error);
      if Error /= Lisp.Types.Error_None then return; end if;
      RT.Known.Eq_Id := Name_Id;
      Intern_Known (RT, "cons", 1, 4, Name_Id, Error);
      if Error /= Lisp.Types.Error_None then return; end if;
      RT.Known.Cons_Id := Name_Id;
      Intern_Known (RT, "car", 1, 3, Name_Id, Error);
      if Error /= Lisp.Types.Error_None then return; end if;
      RT.Known.Car_Id := Name_Id;
      Intern_Known (RT, "cdr", 1, 3, Name_Id, Error);
      if Error /= Lisp.Types.Error_None then return; end if;
      RT.Known.Cdr_Id := Name_Id;
      Intern_Known (RT, "null", 1, 4, Name_Id, Error);
      if Error /= Lisp.Types.Error_None then return; end if;
      RT.Known.Null_Id := Name_Id;
      Intern_Known (RT, "+", 1, 1, Name_Id, Error);
      if Error /= Lisp.Types.Error_None then return; end if;
      RT.Known.Add_Id := Name_Id;
      Intern_Known (RT, "-", 1, 1, Name_Id, Error);
      if Error /= Lisp.Types.Error_None then return; end if;
      RT.Known.Sub_Id := Name_Id;
      Intern_Known (RT, "*", 1, 1, Name_Id, Error);
      if Error /= Lisp.Types.Error_None then return; end if;
      RT.Known.Mul_Id := Name_Id;
      Intern_Known (RT, "<", 1, 1, Name_Id, Error);
      if Error /= Lisp.Types.Error_None then return; end if;
      RT.Known.Lt_Id := Name_Id;
      Intern_Known (RT, "<=", 1, 2, Name_Id, Error);
      if Error /= Lisp.Types.Error_None then return; end if;
      RT.Known.Le_Id := Name_Id;

      Bind_Primitive (RT, RT.Known.Atom_Id, Lisp.Types.Prim_Atom, Error);
      if Error /= Lisp.Types.Error_None then return; end if;
      Bind_Primitive (RT, RT.Known.Eq_Id, Lisp.Types.Prim_Eq, Error);
      if Error /= Lisp.Types.Error_None then return; end if;
      Bind_Primitive (RT, RT.Known.Cons_Id, Lisp.Types.Prim_Cons, Error);
      if Error /= Lisp.Types.Error_None then return; end if;
      Bind_Primitive (RT, RT.Known.Car_Id, Lisp.Types.Prim_Car, Error);
      if Error /= Lisp.Types.Error_None then return; end if;
      Bind_Primitive (RT, RT.Known.Cdr_Id, Lisp.Types.Prim_Cdr, Error);
      if Error /= Lisp.Types.Error_None then return; end if;
      Bind_Primitive (RT, RT.Known.Null_Id, Lisp.Types.Prim_Null, Error);
      if Error /= Lisp.Types.Error_None then return; end if;
      Bind_Primitive (RT, RT.Known.Add_Id, Lisp.Types.Prim_Add, Error);
      if Error /= Lisp.Types.Error_None then return; end if;
      Bind_Primitive (RT, RT.Known.Sub_Id, Lisp.Types.Prim_Sub, Error);
      if Error /= Lisp.Types.Error_None then return; end if;
      Bind_Primitive (RT, RT.Known.Mul_Id, Lisp.Types.Prim_Mul, Error);
      if Error /= Lisp.Types.Error_None then return; end if;
      Bind_Primitive (RT, RT.Known.Lt_Id, Lisp.Types.Prim_Lt, Error);
      if Error /= Lisp.Types.Error_None then return; end if;
      Bind_Primitive (RT, RT.Known.Le_Id, Lisp.Types.Prim_Le, Error);
      if Error /= Lisp.Types.Error_None then return; end if;

      declare
         Symbols : Lisp.Symbols.Table renames RT.Symbols;
      begin
         Lisp.Symbols.Intern
           (Symbols, Quote_Name, Quote_Name'First, Quote_Name'Last, Quote_Id, Error);
         if Error /= Lisp.Types.Error_None then return; end if;
         pragma Assert
           (Lisp.Symbols.Equal_Slice
              (Symbols, Quote_Id, Quote_Name, Quote_Name'First, Quote_Name'Last));
         Quote_Table := Symbols;
         pragma Assert
           (Lisp.Symbols.Equal_Slice
              (Quote_Table, Quote_Id, Quote_Name, Quote_Name'First, Quote_Name'Last));
         Lisp.Symbols.Intern
           (Symbols, If_Name, If_Name'First, If_Name'Last, If_Id, Error);
         if Error /= Lisp.Types.Error_None then return; end if;
         pragma Assert
           (Lisp.Symbols.Equal_Slice
              (Symbols, If_Id, If_Name, If_Name'First, If_Name'Last));
         pragma Assert
           (Lisp.Symbols.Entries_Preserved (Quote_Table, Symbols));
         Lisp.Symbols.Prove_Equal_Slice_Preserved
           (Quote_Table,
            Symbols,
            Quote_Id,
            Quote_Name,
            Quote_Name'First,
            Quote_Name'Last);
         pragma Assert
           (Lisp.Symbols.Equal_Slice
              (Symbols, Quote_Id, Quote_Name, Quote_Name'First, Quote_Name'Last));
         Lisp.Symbols.Prove_Different_Length_Ids_Distinct
           (Symbols, Quote_Id, Quote_Name'Length, If_Id, If_Name'Length);
         pragma Assert (Quote_Id /= If_Id);
      end;
      RT.Known.Quote_Id := Quote_Id;
      RT.Known.If_Id := If_Id;
      pragma Assert (Quote_If_Known (RT));
      pragma Assert (RT.Known.Quote_Id /= RT.Known.If_Id);

      pragma Assert (Lisp.Symbols.Valid (RT.Symbols));
      pragma Assert (Lisp.Store.Valid (RT.Store));
      pragma Assert (Lisp.Env.Valid (RT.Env));
      Error := Lisp.Types.Error_None;
   end Initialize;

   function If_Form
     (RT   : State;
      Expr : Lisp.Types.Cell_Ref) return Boolean is
      Head_Expr : Lisp.Types.Cell_Ref;
      Args_Expr : Lisp.Types.Cell_Ref;
      Tail_1    : Lisp.Types.Cell_Ref;
      Tail_2    : Lisp.Types.Cell_Ref;
   begin
      if Lisp.Store.Kind_Of (RT.Store, Expr) /= Lisp.Types.Cons_Cell then
         return False;
      end if;

      Head_Expr := Lisp.Store.Car (RT.Store, Expr);
      Args_Expr := Lisp.Store.Cdr (RT.Store, Expr);
      if Head_Expr = Lisp.Types.No_Ref
        or else Args_Expr = Lisp.Types.No_Ref
        or else Lisp.Store.Kind_Of (RT.Store, Head_Expr) /= Lisp.Types.Symbol_Cell
        or else Lisp.Store.Symbol_Value (RT.Store, Head_Expr) /= RT.Known.If_Id
        or else Lisp.Store.Kind_Of (RT.Store, Args_Expr) /= Lisp.Types.Cons_Cell
      then
         return False;
      end if;

      if Lisp.Store.Car (RT.Store, Args_Expr) = Lisp.Types.No_Ref then
         return False;
      end if;

      Tail_1 := Lisp.Store.Cdr (RT.Store, Args_Expr);
      if Tail_1 = Lisp.Types.No_Ref
        or else Lisp.Store.Kind_Of (RT.Store, Tail_1) /= Lisp.Types.Cons_Cell
        or else Lisp.Store.Car (RT.Store, Tail_1) = Lisp.Types.No_Ref
      then
         return False;
      end if;

      Tail_2 := Lisp.Store.Cdr (RT.Store, Tail_1);
      return Tail_2 /= Lisp.Types.No_Ref
        and then Lisp.Store.Kind_Of (RT.Store, Tail_2) = Lisp.Types.Cons_Cell
        and then Lisp.Store.Car (RT.Store, Tail_2) /= Lisp.Types.No_Ref
        and then Lisp.Store.Cdr (RT.Store, Tail_2) = Lisp.Store.Nil_Ref;
   end If_Form;

   function If_Form_Cond
     (RT   : State;
      Expr : Lisp.Types.Cell_Ref) return Lisp.Types.Cell_Ref is
      Args_Expr : constant Lisp.Types.Cell_Ref := Lisp.Store.Cdr (RT.Store, Expr);
   begin
      return Lisp.Store.Car (RT.Store, Args_Expr);
   end If_Form_Cond;

   function If_Form_Then
     (RT   : State;
      Expr : Lisp.Types.Cell_Ref) return Lisp.Types.Cell_Ref is
      Args_Expr : constant Lisp.Types.Cell_Ref := Lisp.Store.Cdr (RT.Store, Expr);
      Tail_1    : constant Lisp.Types.Cell_Ref := Lisp.Store.Cdr (RT.Store, Args_Expr);
   begin
      return Lisp.Store.Car (RT.Store, Tail_1);
   end If_Form_Then;

   function If_Form_Else
     (RT   : State;
      Expr : Lisp.Types.Cell_Ref) return Lisp.Types.Cell_Ref is
      Args_Expr : constant Lisp.Types.Cell_Ref := Lisp.Store.Cdr (RT.Store, Expr);
      Tail_1    : constant Lisp.Types.Cell_Ref := Lisp.Store.Cdr (RT.Store, Args_Expr);
      Tail_2    : constant Lisp.Types.Cell_Ref := Lisp.Store.Cdr (RT.Store, Tail_1);
   begin
      return Lisp.Store.Car (RT.Store, Tail_2);
   end If_Form_Else;

   function Immediate_Result_Form
     (RT   : State;
      Expr : Lisp.Types.Cell_Ref) return Boolean is
      Kind : constant Lisp.Types.Cell_Kind := Lisp.Store.Kind_Of (RT.Store, Expr);
   begin
      return Kind = Lisp.Types.Nil_Cell
        or else Kind = Lisp.Types.True_Cell
        or else Kind = Lisp.Types.Integer_Cell
        or else Quote_Form (RT, Expr);
   end Immediate_Result_Form;

   function Immediate_Result
     (RT   : State;
      Expr : Lisp.Types.Cell_Ref) return Lisp.Types.Cell_Ref is
      Kind : constant Lisp.Types.Cell_Kind := Lisp.Store.Kind_Of (RT.Store, Expr);
   begin
      if Kind = Lisp.Types.Nil_Cell
        or else Kind = Lisp.Types.True_Cell
        or else Kind = Lisp.Types.Integer_Cell
      then
         return Expr;
      else
         pragma Assert (Quote_Form (RT, Expr));
         return Quote_Form_Result (RT, Expr);
      end if;
   end Immediate_Result;

   function If_Immediate_Result_Form
     (RT   : State;
      Expr : Lisp.Types.Cell_Ref) return Boolean is
   begin
      return If_Form (RT, Expr)
        and then Immediate_Result_Form (RT, If_Form_Cond (RT, Expr))
        and then Immediate_Result_Form (RT, If_Form_Then (RT, Expr))
        and then Immediate_Result_Form (RT, If_Form_Else (RT, Expr));
   end If_Immediate_Result_Form;

   function If_Immediate_Result
     (RT   : State;
      Expr : Lisp.Types.Cell_Ref) return Lisp.Types.Cell_Ref is
   begin
      if Immediate_Result (RT, If_Form_Cond (RT, Expr)) /= Lisp.Store.Nil_Ref then
         return Immediate_Result (RT, If_Form_Then (RT, Expr));
      else
         return Immediate_Result (RT, If_Form_Else (RT, Expr));
      end if;
   end If_Immediate_Result;

   function Begin_Single_Immediate_Result_Form
     (RT   : State;
      Expr : Lisp.Types.Cell_Ref) return Boolean is
      Head_Expr : Lisp.Types.Cell_Ref;
      Args_Expr : Lisp.Types.Cell_Ref;
   begin
      if Lisp.Store.Kind_Of (RT.Store, Expr) /= Lisp.Types.Cons_Cell then
         return False;
      end if;

      Head_Expr := Lisp.Store.Car (RT.Store, Expr);
      Args_Expr := Lisp.Store.Cdr (RT.Store, Expr);
      return Head_Expr /= Lisp.Types.No_Ref
        and then Args_Expr /= Lisp.Types.No_Ref
        and then Lisp.Store.Kind_Of (RT.Store, Head_Expr) = Lisp.Types.Symbol_Cell
        and then Lisp.Store.Symbol_Value (RT.Store, Head_Expr) = RT.Known.Begin_Id
        and then Single_Argument_List (RT.Store, Args_Expr)
        and then Immediate_Result_Form (RT, Lisp.Store.Car (RT.Store, Args_Expr));
   end Begin_Single_Immediate_Result_Form;

   function Begin_Single_Immediate_Result
     (RT   : State;
      Expr : Lisp.Types.Cell_Ref) return Lisp.Types.Cell_Ref is
      Args_Expr : constant Lisp.Types.Cell_Ref := Lisp.Store.Cdr (RT.Store, Expr);
   begin
      return Immediate_Result (RT, Lisp.Store.Car (RT.Store, Args_Expr));
   end Begin_Single_Immediate_Result;

   function Is_Reserved (RT : State; Name : Lisp.Types.Symbol_Id) return Boolean is
     (Name = RT.Known.Quote_Id
      or else Name = RT.Known.If_Id
      or else Name = RT.Known.Lambda_Id
      or else Name = RT.Known.Define_Id
      or else Name = RT.Known.Begin_Id
      or else Name = RT.Known.Atom_Id
      or else Name = RT.Known.Eq_Id
      or else Name = RT.Known.Cons_Id
      or else Name = RT.Known.Car_Id
      or else Name = RT.Known.Cdr_Id
      or else Name = RT.Known.Null_Id
      or else Name = RT.Known.Add_Id
      or else Name = RT.Known.Sub_Id
      or else Name = RT.Known.Mul_Id
      or else Name = RT.Known.Lt_Id
      or else Name = RT.Known.Le_Id
      or else Name = 0
      or else Name = 1
      or else Name = 2);
end Lisp.Runtime;
