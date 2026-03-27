with Lisp.Runtime;
with Lisp.Env;
with Lisp.Store;
with Lisp.Types;

package Lisp.Model
with
  SPARK_Mode,
  Ghost
is
   pragma Elaborate_Body;
   use type Lisp.Types.Cell_Kind;
   use type Lisp.Types.Symbol_Id;

   function Pure_Data
     (S    : Lisp.Store.Arena;
      Expr : Lisp.Types.Cell_Ref) return Boolean
   with
     Pre => Lisp.Store.Valid (S)
       and then (Expr = Lisp.Types.No_Ref or else Lisp.Store.Is_Valid_Ref (S, Expr)),
     Post =>
       (if Pure_Data'Result then
           Expr /= Lisp.Types.No_Ref
           and then Lisp.Store.Is_Valid_Ref (S, Expr)
           and then Lisp.Store.Kind_Of (S, Expr) /= Lisp.Types.Primitive_Cell
           and then Lisp.Store.Kind_Of (S, Expr) /= Lisp.Types.Closure_Cell
        else
           True)
       and then
       (if Expr /= Lisp.Types.No_Ref
         and then Lisp.Store.Is_Valid_Ref (S, Expr)
         and then
         (Lisp.Store.Kind_Of (S, Expr) = Lisp.Types.Nil_Cell
          or else Lisp.Store.Kind_Of (S, Expr) = Lisp.Types.True_Cell
          or else Lisp.Store.Kind_Of (S, Expr) = Lisp.Types.Integer_Cell
          or else Lisp.Store.Kind_Of (S, Expr) = Lisp.Types.Symbol_Cell)
        then
           Pure_Data'Result)
       and then
       (if Pure_Data'Result
         and then Expr /= Lisp.Types.No_Ref
         and then Lisp.Store.Is_Valid_Ref (S, Expr)
         and then Lisp.Store.Kind_Of (S, Expr) = Lisp.Types.Cons_Cell
        then
           Lisp.Store.Car (S, Expr) /= Lisp.Types.No_Ref
           and then Lisp.Store.Cdr (S, Expr) /= Lisp.Types.No_Ref
           and then Pure_Data (S, Lisp.Store.Car (S, Expr))
           and then Pure_Data (S, Lisp.Store.Cdr (S, Expr))
        else
           True),
     Subprogram_Variant => (Decreases => Expr);

   procedure Prove_Pure_Data_Readable
     (RT   : Lisp.Runtime.State;
      Expr : Lisp.Types.Cell_Ref)
   with
     Ghost,
     Pre =>
       Lisp.Runtime.Valid (RT)
       and then Lisp.Store.Is_Valid_Ref (RT.Store, Expr)
       and then Pure_Data (RT.Store, Expr),
     Post => Readable_Result (RT, Expr);

   procedure Prove_Pure_Subset_Quote_Result
     (RT   : Lisp.Runtime.State;
      Expr : Lisp.Types.Cell_Ref)
   with
     Ghost,
     Pre =>
       Lisp.Runtime.Valid (RT)
       and then Lisp.Store.Is_Valid_Ref (RT.Store, Expr)
       and then Pure_Subset_Expr (RT, Expr)
       and then Lisp.Runtime.Quote_Form (RT, Expr),
     Post =>
       Pure_Data (RT.Store, Lisp.Runtime.Quote_Form_Result (RT, Expr));

   function Pure_Subset_Expr
     (RT   : Lisp.Runtime.State;
      Expr : Lisp.Types.Cell_Ref) return Boolean
   with
     Pre => Lisp.Runtime.Valid (RT)
       and then (Expr = Lisp.Types.No_Ref or else Lisp.Store.Is_Valid_Ref (RT.Store, Expr)),
     Post =>
       (if Pure_Subset_Expr'Result
         and then Expr /= Lisp.Types.No_Ref
         and then Lisp.Store.Is_Valid_Ref (RT.Store, Expr)
         and then Lisp.Runtime.Quote_Form (RT, Expr)
        then
           Pure_Data (RT.Store, Lisp.Runtime.Quote_Form_Result (RT, Expr))
        else
           True),
     Subprogram_Variant => (Decreases => Expr);

   function Readable_Result
     (RT    : Lisp.Runtime.State;
      Value : Lisp.Types.Cell_Ref) return Boolean is
     (Value /= Lisp.Types.No_Ref
      and then Lisp.Store.Is_Valid_Ref (RT.Store, Value)
      and then
      (case Lisp.Store.Kind_Of (RT.Store, Value) is
          when Lisp.Types.Nil_Cell
             | Lisp.Types.True_Cell
             | Lisp.Types.Integer_Cell
             | Lisp.Types.Symbol_Cell =>
             True,
          when Lisp.Types.Primitive_Cell
             | Lisp.Types.Closure_Cell =>
             False,
          when Lisp.Types.Cons_Cell =>
             Lisp.Store.Car (RT.Store, Value) /= Lisp.Types.No_Ref
             and then Lisp.Store.Cdr (RT.Store, Value) /= Lisp.Types.No_Ref
             and then Readable_Result (RT, Lisp.Store.Car (RT.Store, Value))
             and then Readable_Result (RT, Lisp.Store.Cdr (RT.Store, Value))))
   with
     Pre => Lisp.Runtime.Valid (RT)
       and then (Value = Lisp.Types.No_Ref or else Lisp.Store.Is_Valid_Ref (RT.Store, Value)),
     Post =>
       (if Readable_Result'Result then
           Lisp.Store.Is_Valid_Ref (RT.Store, Value)
           and then Lisp.Store.Kind_Of (RT.Store, Value) /= Lisp.Types.Primitive_Cell
           and then Lisp.Store.Kind_Of (RT.Store, Value) /= Lisp.Types.Closure_Cell
           and then
           (if Lisp.Store.Kind_Of (RT.Store, Value) = Lisp.Types.Cons_Cell then
               Readable_Result (RT, Lisp.Store.Car (RT.Store, Value))
               and then Readable_Result (RT, Lisp.Store.Cdr (RT.Store, Value))
            else
               True)
        else
           True),
     Subprogram_Variant => (Decreases => Value);

   function Same_Readable_Value
     (Left_RT    : Lisp.Runtime.State;
      Left_Value : Lisp.Types.Cell_Ref;
      Right_RT   : Lisp.Runtime.State;
     Right_Value : Lisp.Types.Cell_Ref) return Boolean
   with
     Pre =>
       Lisp.Runtime.Valid (Left_RT)
       and then Lisp.Runtime.Valid (Right_RT)
       and then
       (Left_Value = Lisp.Types.No_Ref
        or else Lisp.Store.Is_Valid_Ref (Left_RT.Store, Left_Value))
       and then
       (Right_Value = Lisp.Types.No_Ref
        or else Lisp.Store.Is_Valid_Ref (Right_RT.Store, Right_Value))
       and then Lisp.Store.Readable_Value (Left_RT.Store, Left_Value)
       and then Lisp.Store.Readable_Value (Right_RT.Store, Right_Value),
     Subprogram_Variant => (Decreases => Left_Value);

   procedure Eval_Pure_Closed
     (RT            : in Lisp.Runtime.State;
      Current_Frame : in Lisp.Types.Frame_Id;
      Expr          : in Lisp.Types.Cell_Ref;
      Fuel          : in Lisp.Types.Fuel_Count;
      Result_Ref    : out Lisp.Types.Cell_Ref;
      Error         : out Lisp.Types.Error_Code)
   with
     Pre =>
       Lisp.Runtime.Valid (RT)
       and then Lisp.Env.Frame_Valid (RT.Env, Current_Frame)
       and then Lisp.Store.Is_Valid_Ref (RT.Store, Expr)
       and then Pure_Subset_Expr (RT, Expr),
     Post =>
       Lisp.Runtime.Valid (RT)
       and then
       (if Lisp.Types."=" (Error, Lisp.Types.Error_None) then
           Lisp.Store.Is_Valid_Ref (RT.Store, Result_Ref)
           and then Pure_Data (RT.Store, Result_Ref)
        else
           Result_Ref = Lisp.Types.No_Ref)
       and then
       (if Fuel > 0
         and then
         (Lisp.Store.Kind_Of (RT.Store, Expr) = Lisp.Types.Nil_Cell
          or else Lisp.Store.Kind_Of (RT.Store, Expr) = Lisp.Types.True_Cell
          or else Lisp.Store.Kind_Of (RT.Store, Expr) = Lisp.Types.Integer_Cell)
        then
           Lisp.Types."=" (Error, Lisp.Types.Error_None)
           and then Result_Ref = Expr
       else
           True)
       and then
       (if Fuel > 0
         and then Lisp.Runtime.Quote_Form (RT, Expr)
         and then Pure_Data (RT.Store, Lisp.Runtime.Quote_Form_Result (RT, Expr))
        then
           Lisp.Types."=" (Error, Lisp.Types.Error_None)
           and then Result_Ref = Lisp.Runtime.Quote_Form_Result (RT, Expr)
        else
           True);
end Lisp.Model;
