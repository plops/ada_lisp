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
      Old_Cell_Count : constant Natural := Lisp.Store.Cell_Count (RT.Store);
      Old_Env        : constant Lisp.Env.State := RT.Env;
      Arg1      : Lisp.Types.Cell_Ref := Lisp.Types.No_Ref;
      Arg2      : Lisp.Types.Cell_Ref := Lisp.Types.No_Ref;
      Left_Int  : Lisp.Types.Lisp_Int := 0;
      Right_Int : Lisp.Types.Lisp_Int := 0;
      Value     : Lisp.Types.Lisp_Int := 0;

      procedure Assert_Preserved with Ghost is
      begin
         pragma Assert (Lisp.Store.Cell_Count (RT.Store) >= Old_Cell_Count);
         pragma Assert (Lisp.Env.Frames_Preserved (Old_Env, RT.Env));
      end Assert_Preserved;
   begin
      case Prim is
         when Lisp.Types.Prim_Atom =>
            Expect_Arity (1, Arg_Count, Result_Ref, Error);
            if Error /= Lisp.Types.Error_None then
               Assert_Preserved;
               return;
            end if;
            Arg1 := Args (Args'First);
            Result_Ref := Truth (Lisp.Store.Kind_Of (RT.Store, Arg1) /= Lisp.Types.Cons_Cell);
            Error := Lisp.Types.Error_None;
         when Lisp.Types.Prim_Eq =>
            Expect_Arity (2, Arg_Count, Result_Ref, Error);
            if Error /= Lisp.Types.Error_None then
               Assert_Preserved;
               return;
            end if;
            Arg1 := Args (Args'First);
            Arg2 := Args (Args'First + 1);
            if Arg1 = Arg2 then
               Result_Ref := Lisp.Store.True_Ref;
            elsif Lisp.Store.Kind_Of (RT.Store, Arg1) = Lisp.Types.Integer_Cell
              and then Lisp.Store.Kind_Of (RT.Store, Arg2) = Lisp.Types.Integer_Cell
            then
               Result_Ref := Truth
                 (Lisp.Store.Integer_Value (RT.Store, Arg1) =
                  Lisp.Store.Integer_Value (RT.Store, Arg2));
            elsif Lisp.Store.Kind_Of (RT.Store, Arg1) = Lisp.Types.Symbol_Cell
              and then Lisp.Store.Kind_Of (RT.Store, Arg2) = Lisp.Types.Symbol_Cell
            then
               Result_Ref := Truth
                 (Lisp.Store.Symbol_Value (RT.Store, Arg1) =
                  Lisp.Store.Symbol_Value (RT.Store, Arg2));
            else
               Result_Ref := Lisp.Store.Nil_Ref;
            end if;
            Error := Lisp.Types.Error_None;
         when Lisp.Types.Prim_Cons =>
            Expect_Arity (2, Arg_Count, Result_Ref, Error);
            if Error /= Lisp.Types.Error_None then
               Assert_Preserved;
               return;
            end if;
            Arg1 := Args (Args'First);
            Arg2 := Args (Args'First + 1);
            pragma Assert (Lisp.Store.Valid (RT.Store));
            Lisp.Store.Make_Cons (RT.Store, Arg1, Arg2, Result_Ref, Error);
         when Lisp.Types.Prim_Car =>
            Expect_Arity (1, Arg_Count, Result_Ref, Error);
            if Error /= Lisp.Types.Error_None then
               Assert_Preserved;
               return;
            end if;
            Arg1 := Args (Args'First);
            if Arg1 = Lisp.Store.Nil_Ref then
               Result_Ref := Lisp.Store.Nil_Ref;
               Error := Lisp.Types.Error_None;
            elsif Lisp.Store.Kind_Of (RT.Store, Arg1) /= Lisp.Types.Cons_Cell then
               Result_Ref := Lisp.Types.No_Ref;
               Error := Lisp.Types.Error_Type;
            else
               Result_Ref := Lisp.Store.Car (RT.Store, Arg1);
               if Result_Ref = Lisp.Types.No_Ref then
                  Error := Lisp.Types.Error_Type;
               else
                  Error := Lisp.Types.Error_None;
               end if;
            end if;
         when Lisp.Types.Prim_Cdr =>
            Expect_Arity (1, Arg_Count, Result_Ref, Error);
            if Error /= Lisp.Types.Error_None then
               Assert_Preserved;
               return;
            end if;
            Arg1 := Args (Args'First);
            if Arg1 = Lisp.Store.Nil_Ref then
               Result_Ref := Lisp.Store.Nil_Ref;
               Error := Lisp.Types.Error_None;
            elsif Lisp.Store.Kind_Of (RT.Store, Arg1) /= Lisp.Types.Cons_Cell then
               Result_Ref := Lisp.Types.No_Ref;
               Error := Lisp.Types.Error_Type;
            else
               Result_Ref := Lisp.Store.Cdr (RT.Store, Arg1);
               if Result_Ref = Lisp.Types.No_Ref then
                  Error := Lisp.Types.Error_Type;
               else
                  Error := Lisp.Types.Error_None;
               end if;
            end if;
         when Lisp.Types.Prim_Null =>
            Expect_Arity (1, Arg_Count, Result_Ref, Error);
            if Error /= Lisp.Types.Error_None then
               Assert_Preserved;
               return;
            end if;
            Arg1 := Args (Args'First);
            Result_Ref := Truth (Arg1 = Lisp.Store.Nil_Ref);
            Error := Lisp.Types.Error_None;
         when Lisp.Types.Prim_Add | Lisp.Types.Prim_Sub | Lisp.Types.Prim_Mul | Lisp.Types.Prim_Lt | Lisp.Types.Prim_Le =>
            Expect_Arity (2, Arg_Count, Result_Ref, Error);
            if Error /= Lisp.Types.Error_None then
               Assert_Preserved;
               return;
            end if;
            Arg1 := Args (Args'First);
            Arg2 := Args (Args'First + 1);
            if Lisp.Store.Kind_Of (RT.Store, Arg1) /= Lisp.Types.Integer_Cell
              or else
               Lisp.Store.Kind_Of (RT.Store, Arg2) /= Lisp.Types.Integer_Cell
            then
               Result_Ref := Lisp.Types.No_Ref;
               Error := Lisp.Types.Error_Type;
               Assert_Preserved;
               return;
            end if;
            Left_Int := Lisp.Store.Integer_Value (RT.Store, Arg1);
            Right_Int := Lisp.Store.Integer_Value (RT.Store, Arg2);
            case Prim is
               when Lisp.Types.Prim_Add =>
                  Lisp.Arith.Try_Add (Left_Int, Right_Int, Value, Error);
                  if Error = Lisp.Types.Error_None then
                     pragma Assert (Lisp.Store.Valid (RT.Store));
                     Lisp.Store.Make_Integer (RT.Store, Value, Result_Ref, Error);
                  else
                     Result_Ref := Lisp.Types.No_Ref;
                  end if;
               when Lisp.Types.Prim_Sub =>
                  Lisp.Arith.Try_Sub (Left_Int, Right_Int, Value, Error);
                  if Error = Lisp.Types.Error_None then
                     pragma Assert (Lisp.Store.Valid (RT.Store));
                     Lisp.Store.Make_Integer (RT.Store, Value, Result_Ref, Error);
                  else
                     Result_Ref := Lisp.Types.No_Ref;
                  end if;
               when Lisp.Types.Prim_Mul =>
                  Lisp.Arith.Try_Mul (Left_Int, Right_Int, Value, Error);
                  if Error = Lisp.Types.Error_None then
                     pragma Assert (Lisp.Store.Valid (RT.Store));
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
      Assert_Preserved;
   end Apply;
end Lisp.Primitives;
