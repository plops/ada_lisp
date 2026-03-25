with Lisp.Arith;
with Lisp.Store;

package body Lisp.Primitives with SPARK_Mode is
   use type Lisp.Types.Error_Code;
   use type Lisp.Types.Cell_Kind;

   function Truth (Condition : Boolean) return Lisp.Types.Cell_Ref is
     (if Condition then Lisp.Store.True_Ref else Lisp.Store.Nil_Ref);

   procedure Expect_Arity
     (Expected   : in Natural;
      Arg_Count  : in Natural;
      Result_Ref : out Lisp.Types.Cell_Ref;
      Error      : out Lisp.Types.Error_Code) is
   begin
      if Arg_Count /= Expected then
         Result_Ref := Lisp.Types.No_Ref;
         Error := Lisp.Types.Error_Arity;
      else
         Result_Ref := Lisp.Types.No_Ref;
         Error := Lisp.Types.Error_None;
      end if;
   end Expect_Arity;

   procedure Apply
     (RT         : in out Lisp.Runtime.State;
      Prim       : in Lisp.Types.Primitive_Kind;
      Args       : in Lisp.Types.Cell_Ref_Array;
      Arg_Count  : in Natural;
      Result_Ref : out Lisp.Types.Cell_Ref;
      Error      : out Lisp.Types.Error_Code) is
      Left_Int  : Lisp.Types.Lisp_Int := 0;
      Right_Int : Lisp.Types.Lisp_Int := 0;
      Value     : Lisp.Types.Lisp_Int := 0;
   begin
      case Prim is
         when Lisp.Types.Prim_Atom =>
            Expect_Arity (1, Arg_Count, Result_Ref, Error);
            if Error /= Lisp.Types.Error_None then
               return;
            end if;
            Result_Ref := Truth (Lisp.Store.Kind_Of (RT.Store, Args (Args'First)) /= Lisp.Types.Cons_Cell);
            Error := Lisp.Types.Error_None;
         when Lisp.Types.Prim_Eq =>
            Expect_Arity (2, Arg_Count, Result_Ref, Error);
            if Error /= Lisp.Types.Error_None then
               return;
            end if;
            if Args (Args'First) = Args (Args'First + 1) then
               Result_Ref := Lisp.Store.True_Ref;
            elsif Lisp.Store.Kind_Of (RT.Store, Args (Args'First)) = Lisp.Types.Integer_Cell
              and then Lisp.Store.Kind_Of (RT.Store, Args (Args'First + 1)) = Lisp.Types.Integer_Cell
            then
               Result_Ref := Truth
                 (Lisp.Store.Integer_Value (RT.Store, Args (Args'First)) =
                  Lisp.Store.Integer_Value (RT.Store, Args (Args'First + 1)));
            elsif Lisp.Store.Kind_Of (RT.Store, Args (Args'First)) = Lisp.Types.Symbol_Cell
              and then Lisp.Store.Kind_Of (RT.Store, Args (Args'First + 1)) = Lisp.Types.Symbol_Cell
            then
               Result_Ref := Truth
                 (Lisp.Store.Symbol_Value (RT.Store, Args (Args'First)) =
                  Lisp.Store.Symbol_Value (RT.Store, Args (Args'First + 1)));
            else
               Result_Ref := Lisp.Store.Nil_Ref;
            end if;
            Error := Lisp.Types.Error_None;
         when Lisp.Types.Prim_Cons =>
            Expect_Arity (2, Arg_Count, Result_Ref, Error);
            if Error /= Lisp.Types.Error_None then
               return;
            end if;
            Lisp.Store.Make_Cons (RT.Store, Args (Args'First), Args (Args'First + 1), Result_Ref, Error);
         when Lisp.Types.Prim_Car =>
            Expect_Arity (1, Arg_Count, Result_Ref, Error);
            if Error /= Lisp.Types.Error_None then
               return;
            end if;
            if Args (Args'First) = Lisp.Store.Nil_Ref then
               Result_Ref := Lisp.Store.Nil_Ref;
               Error := Lisp.Types.Error_None;
            elsif Lisp.Store.Kind_Of (RT.Store, Args (Args'First)) /= Lisp.Types.Cons_Cell then
               Result_Ref := Lisp.Types.No_Ref;
               Error := Lisp.Types.Error_Type;
            else
               Result_Ref := Lisp.Store.Car (RT.Store, Args (Args'First));
               Error := Lisp.Types.Error_None;
            end if;
         when Lisp.Types.Prim_Cdr =>
            Expect_Arity (1, Arg_Count, Result_Ref, Error);
            if Error /= Lisp.Types.Error_None then
               return;
            end if;
            if Args (Args'First) = Lisp.Store.Nil_Ref then
               Result_Ref := Lisp.Store.Nil_Ref;
               Error := Lisp.Types.Error_None;
            elsif Lisp.Store.Kind_Of (RT.Store, Args (Args'First)) /= Lisp.Types.Cons_Cell then
               Result_Ref := Lisp.Types.No_Ref;
               Error := Lisp.Types.Error_Type;
            else
               Result_Ref := Lisp.Store.Cdr (RT.Store, Args (Args'First));
               Error := Lisp.Types.Error_None;
            end if;
         when Lisp.Types.Prim_Null =>
            Expect_Arity (1, Arg_Count, Result_Ref, Error);
            if Error /= Lisp.Types.Error_None then
               return;
            end if;
            Result_Ref := Truth (Args (Args'First) = Lisp.Store.Nil_Ref);
            Error := Lisp.Types.Error_None;
         when Lisp.Types.Prim_Add | Lisp.Types.Prim_Sub | Lisp.Types.Prim_Mul | Lisp.Types.Prim_Lt | Lisp.Types.Prim_Le =>
            Expect_Arity (2, Arg_Count, Result_Ref, Error);
            if Error /= Lisp.Types.Error_None then
               return;
            end if;
            if Lisp.Store.Kind_Of (RT.Store, Args (Args'First)) /= Lisp.Types.Integer_Cell
              or else
               Lisp.Store.Kind_Of (RT.Store, Args (Args'First + 1)) /= Lisp.Types.Integer_Cell
            then
               Result_Ref := Lisp.Types.No_Ref;
               Error := Lisp.Types.Error_Type;
               return;
            end if;
            Left_Int := Lisp.Store.Integer_Value (RT.Store, Args (Args'First));
            Right_Int := Lisp.Store.Integer_Value (RT.Store, Args (Args'First + 1));
            case Prim is
               when Lisp.Types.Prim_Add =>
                  Lisp.Arith.Try_Add (Left_Int, Right_Int, Value, Error);
                  if Error = Lisp.Types.Error_None then
                     Lisp.Store.Make_Integer (RT.Store, Value, Result_Ref, Error);
                  else
                     Result_Ref := Lisp.Types.No_Ref;
                  end if;
               when Lisp.Types.Prim_Sub =>
                  Lisp.Arith.Try_Sub (Left_Int, Right_Int, Value, Error);
                  if Error = Lisp.Types.Error_None then
                     Lisp.Store.Make_Integer (RT.Store, Value, Result_Ref, Error);
                  else
                     Result_Ref := Lisp.Types.No_Ref;
                  end if;
               when Lisp.Types.Prim_Mul =>
                  Lisp.Arith.Try_Mul (Left_Int, Right_Int, Value, Error);
                  if Error = Lisp.Types.Error_None then
                     Lisp.Store.Make_Integer (RT.Store, Value, Result_Ref, Error);
                  else
                     Result_Ref := Lisp.Types.No_Ref;
                  end if;
               when Lisp.Types.Prim_Lt =>
                  Result_Ref := Truth (Left_Int < Right_Int);
                  Error := Lisp.Types.Error_None;
               when Lisp.Types.Prim_Le =>
                  Result_Ref := Truth (Left_Int <= Right_Int);
                  Error := Lisp.Types.Error_None;
               when others =>
                  Result_Ref := Lisp.Types.No_Ref;
                  Error := Lisp.Types.Error_Not_Callable;
            end case;
      end case;
   end Apply;
end Lisp.Primitives;
