with Lisp.Eval;

package body Lisp.Model
with
  SPARK_Mode
is
   use type Lisp.Types.Cell_Kind;

   function Pure_Subset_Expr
     (RT   : Lisp.Runtime.State;
      Expr : Lisp.Types.Cell_Ref) return Boolean is
   begin
      if not Lisp.Store.Is_Valid_Ref (RT.Store, Expr) then
         return False;
      end if;

      case Lisp.Store.Kind_Of (RT.Store, Expr) is
         when Lisp.Types.Nil_Cell
            | Lisp.Types.True_Cell
            | Lisp.Types.Integer_Cell
            | Lisp.Types.Symbol_Cell =>
            return True;
         when Lisp.Types.Primitive_Cell
            | Lisp.Types.Closure_Cell =>
            return False;
         when Lisp.Types.Cons_Cell =>
            return Pure_Subset_Expr (RT, Lisp.Store.Car (RT.Store, Expr))
              and then Pure_Subset_Expr (RT, Lisp.Store.Cdr (RT.Store, Expr));
      end case;
   end Pure_Subset_Expr;

   function Same_Readable_Value
     (Left_RT    : Lisp.Runtime.State;
      Left_Value : Lisp.Types.Cell_Ref;
      Right_RT   : Lisp.Runtime.State;
      Right_Value : Lisp.Types.Cell_Ref) return Boolean is
   begin
      if not Readable_Result (Left_RT, Left_Value)
        or else not Readable_Result (Right_RT, Right_Value)
      then
         return False;
      end if;

      if Lisp.Store.Kind_Of (Left_RT.Store, Left_Value) /=
         Lisp.Store.Kind_Of (Right_RT.Store, Right_Value)
      then
         return False;
      end if;

      case Lisp.Store.Kind_Of (Left_RT.Store, Left_Value) is
         when Lisp.Types.Nil_Cell | Lisp.Types.True_Cell =>
            return True;
         when Lisp.Types.Integer_Cell =>
            return Lisp.Store.Integer_Value (Left_RT.Store, Left_Value) =
              Lisp.Store.Integer_Value (Right_RT.Store, Right_Value);
         when Lisp.Types.Symbol_Cell =>
            return Lisp.Store.Symbol_Value (Left_RT.Store, Left_Value) =
              Lisp.Store.Symbol_Value (Right_RT.Store, Right_Value);
         when Lisp.Types.Cons_Cell =>
            return Same_Readable_Value
                (Left_RT,
                 Lisp.Store.Car (Left_RT.Store, Left_Value),
                 Right_RT,
                 Lisp.Store.Car (Right_RT.Store, Right_Value))
              and then Same_Readable_Value
                (Left_RT,
                 Lisp.Store.Cdr (Left_RT.Store, Left_Value),
                 Right_RT,
                 Lisp.Store.Cdr (Right_RT.Store, Right_Value));
         when Lisp.Types.Primitive_Cell | Lisp.Types.Closure_Cell =>
            return False;
      end case;
   end Same_Readable_Value;

   procedure Eval_Pure_Closed
     (RT            : in Lisp.Runtime.State;
      Current_Frame : in Lisp.Types.Frame_Id;
      Expr          : in Lisp.Types.Cell_Ref;
      Fuel          : in Lisp.Types.Fuel_Count;
      Result_Ref    : out Lisp.Types.Cell_Ref;
      Error         : out Lisp.Types.Error_Code) is
      Model_RT : Lisp.Runtime.State := RT;
   begin
      Lisp.Eval.Eval (Model_RT, Current_Frame, Expr, Fuel, Result_Ref, Error);
   end Eval_Pure_Closed;
end Lisp.Model;
