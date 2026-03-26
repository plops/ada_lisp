with Lisp.Runtime;
with Lisp.Store;
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
     Pre => Lisp.Runtime.Valid (RT)
       and then Lisp.Store.Is_Valid_Ref (RT.Store, Expr),
     Post => Lisp.Runtime.Valid (RT)
       and then
       (if Lisp.Types."=" (Error, Lisp.Types.Error_None) then
           Lisp.Store.Is_Valid_Ref (RT.Store, Result_Ref)
        else
           Result_Ref = Lisp.Types.No_Ref),
     Subprogram_Variant => (Decreases => Fuel);
end Lisp.Eval;
