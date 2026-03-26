with Lisp.Eval;

package body Lisp.Model
with
  SPARK_Mode
is
   use type Lisp.Types.Cell_Kind;

   function Readable_Result
     (RT    : Lisp.Runtime.State;
      Value : Lisp.Types.Cell_Ref) return Boolean is
   begin
      return Lisp.Store.Readable_Value (RT.Store, Value);
   end Readable_Result;

   function Pure_Subset_Expr
     (RT   : Lisp.Runtime.State;
      Expr : Lisp.Types.Cell_Ref) return Boolean is
   begin
      if Expr = Lisp.Types.No_Ref then
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
            declare
               Left_Expr  : constant Lisp.Types.Cell_Ref := Lisp.Store.Car (RT.Store, Expr);
               Right_Expr : constant Lisp.Types.Cell_Ref := Lisp.Store.Cdr (RT.Store, Expr);
            begin
               pragma Assert (Left_Expr < Expr);
               pragma Assert (Right_Expr < Expr);
               return Pure_Subset_Expr (RT, Left_Expr)
                 and then Pure_Subset_Expr (RT, Right_Expr);
            end;
      end case;
   end Pure_Subset_Expr;

   function Same_Readable_Value
     (Left_RT    : Lisp.Runtime.State;
      Left_Value : Lisp.Types.Cell_Ref;
      Right_RT   : Lisp.Runtime.State;
      Right_Value : Lisp.Types.Cell_Ref) return Boolean is
   begin
      if not Lisp.Store.Readable_Value (Left_RT.Store, Left_Value)
        or else not Lisp.Store.Readable_Value (Right_RT.Store, Right_Value)
      then
         return False;
      end if;

      pragma Assert (Lisp.Store.Is_Valid_Ref (Left_RT.Store, Left_Value));
      pragma Assert (Lisp.Store.Is_Valid_Ref (Right_RT.Store, Right_Value));

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
            declare
               Left_Car   : constant Lisp.Types.Cell_Ref := Lisp.Store.Car (Left_RT.Store, Left_Value);
               Right_Car  : constant Lisp.Types.Cell_Ref := Lisp.Store.Car (Right_RT.Store, Right_Value);
               Left_Cdr   : constant Lisp.Types.Cell_Ref := Lisp.Store.Cdr (Left_RT.Store, Left_Value);
               Right_Cdr  : constant Lisp.Types.Cell_Ref := Lisp.Store.Cdr (Right_RT.Store, Right_Value);
            begin
               pragma Assert (Left_Car < Left_Value);
               pragma Assert (Right_Car < Right_Value);
               pragma Assert (Left_Cdr < Left_Value);
               pragma Assert (Right_Cdr < Right_Value);
               pragma Assert (Lisp.Store.Readable_Value (Left_RT.Store, Left_Car));
               pragma Assert (Lisp.Store.Readable_Value (Right_RT.Store, Right_Car));
               pragma Assert (Lisp.Store.Readable_Value (Left_RT.Store, Left_Cdr));
               pragma Assert (Lisp.Store.Readable_Value (Right_RT.Store, Right_Cdr));
               return Same_Readable_Value (Left_RT, Left_Car, Right_RT, Right_Car)
                 and then Same_Readable_Value (Left_RT, Left_Cdr, Right_RT, Right_Cdr);
            end;
         when Lisp.Types.Primitive_Cell | Lisp.Types.Closure_Cell =>
            return False;
      end case;
   end Same_Readable_Value;

   procedure Eval_Pure_Closed
     (RT            : in out Lisp.Runtime.State;
      Current_Frame : in Lisp.Types.Frame_Id;
      Expr          : in Lisp.Types.Cell_Ref;
      Fuel          : in Lisp.Types.Fuel_Count;
      Result_Ref    : out Lisp.Types.Cell_Ref;
      Error         : out Lisp.Types.Error_Code) is
   begin
      Lisp.Eval.Eval (RT, Current_Frame, Expr, Fuel, Result_Ref, Error);
   end Eval_Pure_Closed;
end Lisp.Model;
