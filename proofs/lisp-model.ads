with Lisp.Runtime;
with Lisp.Store;
with Lisp.Types;

package Lisp.Model
with
  SPARK_Mode,
  Ghost
is
   pragma Elaborate_Body;

   function Pure_Subset_Expr
     (RT   : Lisp.Runtime.State;
      Expr : Lisp.Types.Cell_Ref) return Boolean
   with
     Subprogram_Variant => (Decreases => Expr);

   function Readable_Result
     (RT    : Lisp.Runtime.State;
      Value : Lisp.Types.Cell_Ref) return Boolean is
     (Lisp.Store.Readable_Value (RT.Store, Value));

   function Same_Readable_Value
     (Left_RT    : Lisp.Runtime.State;
      Left_Value : Lisp.Types.Cell_Ref;
      Right_RT   : Lisp.Runtime.State;
      Right_Value : Lisp.Types.Cell_Ref) return Boolean
   with
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
       and then Pure_Subset_Expr (RT, Expr);
end Lisp.Model;
