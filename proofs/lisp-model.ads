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

   function Pure_Subset_Expr
     (RT   : Lisp.Runtime.State;
      Expr : Lisp.Types.Cell_Ref) return Boolean
   with
     Pre => Lisp.Runtime.Valid (RT)
       and then (Expr = Lisp.Types.No_Ref or else Lisp.Store.Is_Valid_Ref (RT.Store, Expr)),
     Subprogram_Variant => (Decreases => Expr);

   function Readable_Result
     (RT    : Lisp.Runtime.State;
     Value : Lisp.Types.Cell_Ref) return Boolean
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
               Lisp.Store.Readable_Value (RT.Store, Lisp.Store.Car (RT.Store, Value))
               and then Lisp.Store.Readable_Value (RT.Store, Lisp.Store.Cdr (RT.Store, Value))
            else
               True)
        else
           True);

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
     (RT            : in out Lisp.Runtime.State;
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
        else
           Result_Ref = Lisp.Types.No_Ref);
end Lisp.Model;
