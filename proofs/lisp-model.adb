package body Lisp.Model
with
  SPARK_Mode
is
   use type Lisp.Types.Cell_Kind;
   use type Lisp.Types.Error_Code;
   use type Lisp.Types.Symbol_Id;

   function Quote_Args
     (S    : Lisp.Store.Arena;
      Args : Lisp.Types.Cell_Ref) return Boolean is
     (Args /= Lisp.Types.No_Ref
      and then Lisp.Store.Is_Valid_Ref (S, Args)
      and then Lisp.Store.Kind_Of (S, Args) = Lisp.Types.Cons_Cell
      and then Lisp.Store.Car (S, Args) /= Lisp.Types.No_Ref
      and then Lisp.Store.Cdr (S, Args) = Lisp.Store.Nil_Ref
      and then Pure_Data (S, Lisp.Store.Car (S, Args)))
   with
     Pre => Lisp.Store.Valid (S)
       and then (Args = Lisp.Types.No_Ref or else Lisp.Store.Is_Valid_Ref (S, Args));

   function Readable_Result
     (RT    : Lisp.Runtime.State;
      Value : Lisp.Types.Cell_Ref) return Boolean is
   begin
      return Lisp.Store.Readable_Value (RT.Store, Value);
   end Readable_Result;

   function Pure_Data
     (S    : Lisp.Store.Arena;
      Expr : Lisp.Types.Cell_Ref) return Boolean is
   begin
      if Expr = Lisp.Types.No_Ref or else not Lisp.Store.Is_Valid_Ref (S, Expr) then
         return False;
      end if;

      case Lisp.Store.Kind_Of (S, Expr) is
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
               Left_Expr  : constant Lisp.Types.Cell_Ref := Lisp.Store.Car (S, Expr);
               Right_Expr : constant Lisp.Types.Cell_Ref := Lisp.Store.Cdr (S, Expr);
            begin
               pragma Assert (Left_Expr < Expr);
               pragma Assert (Right_Expr < Expr);
               return Pure_Data (S, Left_Expr)
                 and then Pure_Data (S, Right_Expr);
            end;
      end case;
   end Pure_Data;

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
            | Lisp.Types.Integer_Cell =>
            return True;
         when Lisp.Types.Symbol_Cell
            | Lisp.Types.Primitive_Cell
            | Lisp.Types.Closure_Cell =>
            return False;
         when Lisp.Types.Cons_Cell =>
            declare
               Head_Expr : constant Lisp.Types.Cell_Ref := Lisp.Store.Car (RT.Store, Expr);
               Args_Expr : constant Lisp.Types.Cell_Ref := Lisp.Store.Cdr (RT.Store, Expr);
            begin
               pragma Assert (Head_Expr < Expr);
               pragma Assert (Args_Expr < Expr);
               return Head_Expr /= Lisp.Types.No_Ref
                 and then Args_Expr /= Lisp.Types.No_Ref
                 and then Lisp.Store.Kind_Of (RT.Store, Head_Expr) = Lisp.Types.Symbol_Cell
                 and then Lisp.Store.Symbol_Value (RT.Store, Head_Expr) = RT.Known.Quote_Id
                 and then Quote_Args (RT.Store, Args_Expr);
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
     (RT            : in Lisp.Runtime.State;
      Current_Frame : in Lisp.Types.Frame_Id;
      Expr          : in Lisp.Types.Cell_Ref;
      Fuel          : in Lisp.Types.Fuel_Count;
      Result_Ref    : out Lisp.Types.Cell_Ref;
      Error         : out Lisp.Types.Error_Code) is
      pragma Unreferenced (Current_Frame);
      Head_Expr : Lisp.Types.Cell_Ref;
      Args_Expr : Lisp.Types.Cell_Ref;
   begin
      if Fuel = 0 then
         Result_Ref := Lisp.Types.No_Ref;
         Error := Lisp.Types.Error_Out_Of_Fuel;
         return;
      end if;

      case Lisp.Store.Kind_Of (RT.Store, Expr) is
         when Lisp.Types.Nil_Cell
            | Lisp.Types.True_Cell
            | Lisp.Types.Integer_Cell =>
            Result_Ref := Expr;
            Error := Lisp.Types.Error_None;
            pragma Assert (Pure_Data (RT.Store, Result_Ref));
         when Lisp.Types.Cons_Cell =>
            Head_Expr := Lisp.Store.Car (RT.Store, Expr);
            Args_Expr := Lisp.Store.Cdr (RT.Store, Expr);
            if Head_Expr = Lisp.Types.No_Ref
              or else Args_Expr = Lisp.Types.No_Ref
              or else Lisp.Store.Kind_Of (RT.Store, Head_Expr) /= Lisp.Types.Symbol_Cell
              or else Lisp.Store.Symbol_Value (RT.Store, Head_Expr) /= RT.Known.Quote_Id
              or else not Quote_Args (RT.Store, Args_Expr)
            then
               Result_Ref := Lisp.Types.No_Ref;
               Error := Lisp.Types.Error_Type;
            else
               Result_Ref := Lisp.Store.Car (RT.Store, Args_Expr);
               Error := Lisp.Types.Error_None;
               pragma Assert (Pure_Data (RT.Store, Result_Ref));
            end if;
         when Lisp.Types.Symbol_Cell
            | Lisp.Types.Primitive_Cell
            | Lisp.Types.Closure_Cell =>
            Result_Ref := Lisp.Types.No_Ref;
            Error := Lisp.Types.Error_Type;
      end case;
   end Eval_Pure_Closed;
end Lisp.Model;
