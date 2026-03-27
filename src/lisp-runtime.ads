with Lisp.Env;
with Lisp.Store;
with Lisp.Symbols;
with Lisp.Types;

package Lisp.Runtime with SPARK_Mode is
   use type Lisp.Types.Cell_Kind;

   Quote_Name : constant String := "quote";
   If_Name    : constant String := "if";

   type Well_Known_Symbols is record
      Quote_Id  : Lisp.Types.Symbol_Id := 0;
      If_Id     : Lisp.Types.Symbol_Id := 0;
      Lambda_Id : Lisp.Types.Symbol_Id := 0;
      Define_Id : Lisp.Types.Symbol_Id := 0;
      Begin_Id  : Lisp.Types.Symbol_Id := 0;
      Atom_Id   : Lisp.Types.Symbol_Id := 0;
      Eq_Id     : Lisp.Types.Symbol_Id := 0;
      Cons_Id   : Lisp.Types.Symbol_Id := 0;
      Car_Id    : Lisp.Types.Symbol_Id := 0;
      Cdr_Id    : Lisp.Types.Symbol_Id := 0;
      Null_Id   : Lisp.Types.Symbol_Id := 0;
      Add_Id    : Lisp.Types.Symbol_Id := 0;
      Sub_Id    : Lisp.Types.Symbol_Id := 0;
      Mul_Id    : Lisp.Types.Symbol_Id := 0;
      Lt_Id     : Lisp.Types.Symbol_Id := 0;
      Le_Id     : Lisp.Types.Symbol_Id := 0;
   end record;

   type State is record
      Symbols : Lisp.Symbols.Table;
      Store   : Lisp.Store.Arena;
      Env     : Lisp.Env.State;
      Known   : Well_Known_Symbols;
   end record;

   function Valid (RT : State) return Boolean is
     (Lisp.Symbols.Valid (RT.Symbols)
      and then Lisp.Store.Valid (RT.Store)
      and then Lisp.Env.Valid (RT.Env));

   function Quote_If_Known (RT : State) return Boolean is
     (Lisp.Symbols.Equal_Slice
        (RT.Symbols,
         RT.Known.Quote_Id,
         Quote_Name,
         Quote_Name'First,
         Quote_Name'Last)
      and then
      Lisp.Symbols.Equal_Slice
        (RT.Symbols,
         RT.Known.If_Id,
         If_Name,
         If_Name'First,
         If_Name'Last))
   with
     Pre => Valid (RT);

   procedure Prove_Quote_If_Known_Distinct (RT : in State)
   with
     Ghost,
     Pre => Valid (RT)
       and then Quote_If_Known (RT),
     Post => RT.Known.Quote_Id /= RT.Known.If_Id;

   procedure Initialize (RT : in out State; Error : out Lisp.Types.Error_Code)
   with
     Post => Valid (RT)
       and then
       (if Lisp.Types."=" (Error, Lisp.Types.Error_None) then
           Quote_If_Known (RT)
           and then
           RT.Known.Quote_Id /= RT.Known.If_Id
        else
           True);

   function Single_Argument_List
     (S    : Lisp.Store.Arena;
      Args : Lisp.Types.Cell_Ref) return Boolean is
     (Args /= Lisp.Types.No_Ref
      and then Lisp.Store.Is_Valid_Ref (S, Args)
      and then Lisp.Store.Kind_Of (S, Args) = Lisp.Types.Cons_Cell
      and then Lisp.Store.Car (S, Args) /= Lisp.Types.No_Ref
      and then Lisp.Store.Cdr (S, Args) = Lisp.Store.Nil_Ref)
   with
     Pre => Lisp.Store.Valid (S)
       and then (Args = Lisp.Types.No_Ref or else Lisp.Store.Is_Valid_Ref (S, Args)),
     Post =>
       (if Single_Argument_List'Result then
           Args /= Lisp.Types.No_Ref
           and then Lisp.Store.Is_Valid_Ref (S, Args)
           and then Lisp.Store.Kind_Of (S, Args) = Lisp.Types.Cons_Cell
           and then Lisp.Store.Car (S, Args) /= Lisp.Types.No_Ref
           and then Lisp.Store.Cdr (S, Args) = Lisp.Store.Nil_Ref
        else
           True);

   function Quote_Form
     (RT   : State;
      Expr : Lisp.Types.Cell_Ref) return Boolean is
     (Lisp.Store.Kind_Of (RT.Store, Expr) = Lisp.Types.Cons_Cell
      and then Lisp.Store.Car (RT.Store, Expr) /= Lisp.Types.No_Ref
      and then Lisp.Store.Cdr (RT.Store, Expr) /= Lisp.Types.No_Ref
      and then
      Lisp.Store.Kind_Of (RT.Store, Lisp.Store.Car (RT.Store, Expr)) = Lisp.Types.Symbol_Cell
      and then
      Lisp.Store.Symbol_Value (RT.Store, Lisp.Store.Car (RT.Store, Expr)) = RT.Known.Quote_Id
      and then Single_Argument_List (RT.Store, Lisp.Store.Cdr (RT.Store, Expr)))
   with
     Pre => Valid (RT)
       and then Lisp.Store.Is_Valid_Ref (RT.Store, Expr),
     Post =>
       (if Quote_Form'Result then
           Lisp.Store.Kind_Of (RT.Store, Expr) = Lisp.Types.Cons_Cell
           and then Lisp.Store.Car (RT.Store, Expr) /= Lisp.Types.No_Ref
           and then Lisp.Store.Cdr (RT.Store, Expr) /= Lisp.Types.No_Ref
           and then
           Lisp.Store.Kind_Of (RT.Store, Lisp.Store.Car (RT.Store, Expr)) = Lisp.Types.Symbol_Cell
           and then
           Lisp.Store.Symbol_Value (RT.Store, Lisp.Store.Car (RT.Store, Expr)) = RT.Known.Quote_Id
           and then Single_Argument_List (RT.Store, Lisp.Store.Cdr (RT.Store, Expr))
        else
           True);

   function Quote_Form_Result
     (RT   : State;
      Expr : Lisp.Types.Cell_Ref) return Lisp.Types.Cell_Ref is
     (Lisp.Store.Car (RT.Store, Lisp.Store.Cdr (RT.Store, Expr)))
   with
     Pre => Valid (RT)
       and then Lisp.Store.Is_Valid_Ref (RT.Store, Expr)
       and then Quote_Form (RT, Expr),
     Post =>
       Lisp.Store.Is_Valid_Ref (RT.Store, Quote_Form_Result'Result);

   function If_Form
     (RT   : State;
      Expr : Lisp.Types.Cell_Ref) return Boolean
   with
     Pre => Valid (RT)
       and then Lisp.Store.Is_Valid_Ref (RT.Store, Expr),
     Post =>
       (if If_Form'Result then
           Lisp.Store.Kind_Of (RT.Store, Expr) = Lisp.Types.Cons_Cell
           and then Lisp.Store.Car (RT.Store, Expr) /= Lisp.Types.No_Ref
           and then Lisp.Store.Cdr (RT.Store, Expr) /= Lisp.Types.No_Ref
           and then
           Lisp.Store.Kind_Of (RT.Store, Lisp.Store.Car (RT.Store, Expr)) = Lisp.Types.Symbol_Cell
           and then
           Lisp.Store.Symbol_Value (RT.Store, Lisp.Store.Car (RT.Store, Expr)) = RT.Known.If_Id
           and then
           Lisp.Store.Kind_Of (RT.Store, Lisp.Store.Cdr (RT.Store, Expr)) = Lisp.Types.Cons_Cell
           and then Lisp.Store.Car (RT.Store, Lisp.Store.Cdr (RT.Store, Expr)) /= Lisp.Types.No_Ref
           and then Lisp.Store.Cdr (RT.Store, Lisp.Store.Cdr (RT.Store, Expr)) /= Lisp.Types.No_Ref
           and then
           Lisp.Store.Kind_Of
             (RT.Store, Lisp.Store.Cdr (RT.Store, Lisp.Store.Cdr (RT.Store, Expr))) =
             Lisp.Types.Cons_Cell
           and then
           Lisp.Store.Car
             (RT.Store, Lisp.Store.Cdr (RT.Store, Lisp.Store.Cdr (RT.Store, Expr))) /=
             Lisp.Types.No_Ref
           and then
           Lisp.Store.Cdr
             (RT.Store, Lisp.Store.Cdr (RT.Store, Lisp.Store.Cdr (RT.Store, Expr))) /=
             Lisp.Types.No_Ref
           and then
           Lisp.Store.Kind_Of
             (RT.Store,
              Lisp.Store.Cdr
                (RT.Store, Lisp.Store.Cdr (RT.Store, Lisp.Store.Cdr (RT.Store, Expr)))) =
             Lisp.Types.Cons_Cell
           and then
           Lisp.Store.Car
             (RT.Store,
              Lisp.Store.Cdr
                (RT.Store, Lisp.Store.Cdr (RT.Store, Lisp.Store.Cdr (RT.Store, Expr)))) /=
             Lisp.Types.No_Ref
           and then
           Lisp.Store.Cdr
             (RT.Store,
              Lisp.Store.Cdr
                (RT.Store, Lisp.Store.Cdr (RT.Store, Lisp.Store.Cdr (RT.Store, Expr)))) =
             Lisp.Store.Nil_Ref
        else
           True);

   function If_Form_Cond
     (RT   : State;
      Expr : Lisp.Types.Cell_Ref) return Lisp.Types.Cell_Ref
   with
     Pre => Valid (RT)
       and then Lisp.Store.Is_Valid_Ref (RT.Store, Expr)
       and then If_Form (RT, Expr),
     Post =>
       Lisp.Store.Is_Valid_Ref (RT.Store, If_Form_Cond'Result)
       and then If_Form_Cond'Result < Expr
       and then
       If_Form_Cond'Result =
         Lisp.Store.Car (RT.Store, Lisp.Store.Cdr (RT.Store, Expr));

   function If_Form_Then
     (RT   : State;
      Expr : Lisp.Types.Cell_Ref) return Lisp.Types.Cell_Ref
   with
     Pre => Valid (RT)
       and then Lisp.Store.Is_Valid_Ref (RT.Store, Expr)
       and then If_Form (RT, Expr),
     Post =>
       Lisp.Store.Is_Valid_Ref (RT.Store, If_Form_Then'Result)
       and then If_Form_Then'Result < Expr
       and then
       If_Form_Then'Result =
         Lisp.Store.Car
           (RT.Store,
            Lisp.Store.Cdr (RT.Store, Lisp.Store.Cdr (RT.Store, Expr)));

   function If_Form_Else
     (RT   : State;
      Expr : Lisp.Types.Cell_Ref) return Lisp.Types.Cell_Ref
   with
     Pre => Valid (RT)
       and then Lisp.Store.Is_Valid_Ref (RT.Store, Expr)
       and then If_Form (RT, Expr),
     Post =>
       Lisp.Store.Is_Valid_Ref (RT.Store, If_Form_Else'Result)
       and then If_Form_Else'Result < Expr
       and then
       If_Form_Else'Result =
         Lisp.Store.Car
           (RT.Store,
            Lisp.Store.Cdr
              (RT.Store,
               Lisp.Store.Cdr (RT.Store, Lisp.Store.Cdr (RT.Store, Expr))));

   function Immediate_Result_Form
     (RT   : State;
      Expr : Lisp.Types.Cell_Ref) return Boolean
   with
     Pre => Valid (RT)
       and then Lisp.Store.Is_Valid_Ref (RT.Store, Expr),
     Post =>
       (if Immediate_Result_Form'Result
         and then Lisp.Store.Kind_Of (RT.Store, Expr) /= Lisp.Types.Nil_Cell
         and then Lisp.Store.Kind_Of (RT.Store, Expr) /= Lisp.Types.True_Cell
         and then Lisp.Store.Kind_Of (RT.Store, Expr) /= Lisp.Types.Integer_Cell
        then
           Quote_Form (RT, Expr)
        else
           True);

   function Immediate_Result
     (RT   : State;
      Expr : Lisp.Types.Cell_Ref) return Lisp.Types.Cell_Ref
   with
     Pre => Valid (RT)
       and then Lisp.Store.Is_Valid_Ref (RT.Store, Expr)
       and then Immediate_Result_Form (RT, Expr),
     Post =>
       Lisp.Store.Is_Valid_Ref (RT.Store, Immediate_Result'Result)
       and then
       (if Lisp.Store.Kind_Of (RT.Store, Expr) = Lisp.Types.Nil_Cell
          or else Lisp.Store.Kind_Of (RT.Store, Expr) = Lisp.Types.True_Cell
          or else Lisp.Store.Kind_Of (RT.Store, Expr) = Lisp.Types.Integer_Cell
        then
           Immediate_Result'Result = Expr
        else
           Lisp.Runtime.Quote_Form (RT, Expr)
           and then
           Immediate_Result'Result = Lisp.Runtime.Quote_Form_Result (RT, Expr));

   function If_Immediate_Result_Form
     (RT   : State;
      Expr : Lisp.Types.Cell_Ref) return Boolean
   with
     Pre => Valid (RT)
       and then Lisp.Store.Is_Valid_Ref (RT.Store, Expr),
     Post =>
       (if If_Immediate_Result_Form'Result
        then
           If_Form (RT, Expr)
           and then
           Immediate_Result_Form (RT, If_Form_Cond (RT, Expr))
           and then
           Immediate_Result_Form (RT, If_Form_Then (RT, Expr))
           and then
           Immediate_Result_Form (RT, If_Form_Else (RT, Expr))
        else
           True);

   function If_Immediate_Result
     (RT   : State;
      Expr : Lisp.Types.Cell_Ref) return Lisp.Types.Cell_Ref
   with
     Pre => Valid (RT)
       and then Lisp.Store.Is_Valid_Ref (RT.Store, Expr)
       and then If_Immediate_Result_Form (RT, Expr),
     Post =>
       Lisp.Store.Is_Valid_Ref (RT.Store, If_Immediate_Result'Result)
       and then
       (if Immediate_Result (RT, If_Form_Cond (RT, Expr)) /= Lisp.Store.Nil_Ref
        then
           If_Immediate_Result'Result =
             Immediate_Result (RT, If_Form_Then (RT, Expr))
        else
           If_Immediate_Result'Result =
             Immediate_Result (RT, If_Form_Else (RT, Expr)));

   function Is_Reserved (RT : State; Name : Lisp.Types.Symbol_Id) return Boolean;
end Lisp.Runtime;
