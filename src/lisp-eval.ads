with Lisp.Runtime;
with Lisp.Types;

package Lisp.Eval with SPARK_Mode is
   procedure Eval
     (RT            : in out Lisp.Runtime.State;
      Current_Frame : in Lisp.Types.Frame_Id;
      Expr          : in Lisp.Types.Cell_Ref;
      Fuel          : in Lisp.Types.Fuel_Count;
      Result_Ref    : out Lisp.Types.Cell_Ref;
      Error         : out Lisp.Types.Error_Code)
   with
     Pre => Lisp.Runtime.Valid (RT),
     Post => Lisp.Runtime.Valid (RT),
     Subprogram_Variant => (Decreases => Fuel);
end Lisp.Eval;
