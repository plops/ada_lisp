with Lisp.Config;
with Lisp.Env;
with Lisp.Primitives;
with Lisp.Store;

package body Lisp.Eval with SPARK_Mode is
   use type Lisp.Types.Error_Code;
   use type Lisp.Types.Cell_Kind;

   function Is_Truth (Ref : Lisp.Types.Cell_Ref) return Boolean is
     (Ref /= Lisp.Store.Nil_Ref);

   procedure Proper_List_To_Array
     (RT          : in Lisp.Runtime.State;
      List_Ref    : in Lisp.Types.Cell_Ref;
      Elements    : out Lisp.Types.Cell_Ref_Array;
      Count       : out Natural;
      Error       : out Lisp.Types.Error_Code) is
      Cursor : Lisp.Types.Cell_Ref := List_Ref;
   begin
      Count := 0;
      while Cursor /= Lisp.Store.Nil_Ref loop
         if Lisp.Store.Kind_Of (RT.Store, Cursor) /= Lisp.Types.Cons_Cell then
            Error := Lisp.Types.Error_Syntax;
            return;
         end if;
         if Count = Elements'Length then
            Error := Lisp.Types.Error_Arena_Full;
            return;
         end if;
         Count := Count + 1;
         Elements (Count) := Lisp.Store.Car (RT.Store, Cursor);
         Cursor := Lisp.Store.Cdr (RT.Store, Cursor);
      end loop;
      Error := Lisp.Types.Error_None;
   end Proper_List_To_Array;

   procedure Params_To_Array
     (RT       : in Lisp.Runtime.State;
      List_Ref : in Lisp.Types.Cell_Ref;
      Names    : out Lisp.Types.Symbol_Id_Array;
      Count    : out Natural;
      Error    : out Lisp.Types.Error_Code) is
      Values : Lisp.Types.Cell_Ref_Array (Names'Range) := (others => Lisp.Types.No_Ref);
   begin
      Proper_List_To_Array (RT, List_Ref, Values, Count, Error);
      if Error /= Lisp.Types.Error_None then
         return;
      end if;

      for I in 1 .. Count loop
         if Lisp.Store.Kind_Of (RT.Store, Values (I)) /= Lisp.Types.Symbol_Cell then
            Error := Lisp.Types.Error_Invalid_Parameter_List;
            return;
         end if;
         Names (I) := Lisp.Store.Symbol_Value (RT.Store, Values (I));
         if Lisp.Runtime.Is_Reserved (RT, Names (I)) then
            Error := Lisp.Types.Error_Reserved_Name;
            return;
         end if;
         for J in 1 .. I - 1 loop
            if Names (J) = Names (I) then
               Error := Lisp.Types.Error_Invalid_Parameter_List;
               return;
            end if;
         end loop;
      end loop;
      Error := Lisp.Types.Error_None;
   end Params_To_Array;

   procedure Eval_List
     (RT            : in out Lisp.Runtime.State;
      Current_Frame : in Lisp.Types.Frame_Id;
      List_Ref      : in Lisp.Types.Cell_Ref;
      Fuel          : in Lisp.Types.Fuel_Count;
      Values        : out Lisp.Types.Cell_Ref_Array;
      Count         : out Natural;
      Error         : out Lisp.Types.Error_Code) is
      Exprs : Lisp.Types.Cell_Ref_Array (Values'Range) := (others => Lisp.Types.No_Ref);
   begin
      Proper_List_To_Array (RT, List_Ref, Exprs, Count, Error);
      if Error /= Lisp.Types.Error_None then
         return;
      end if;
      for I in 1 .. Count loop
         Eval (RT, Current_Frame, Exprs (I), Fuel - 1, Values (I), Error);
         if Error /= Lisp.Types.Error_None then
            return;
         end if;
      end loop;
      Error := Lisp.Types.Error_None;
   end Eval_List;

   procedure Eval_Begin
     (RT            : in out Lisp.Runtime.State;
      Current_Frame : in Lisp.Types.Frame_Id;
      Forms         : in Lisp.Types.Cell_Ref;
      Fuel          : in Lisp.Types.Fuel_Count;
      Result_Ref    : out Lisp.Types.Cell_Ref;
      Error         : out Lisp.Types.Error_Code) is
      Cursor : Lisp.Types.Cell_Ref := Forms;
   begin
      if Cursor = Lisp.Store.Nil_Ref then
         Result_Ref := Lisp.Store.Nil_Ref;
         Error := Lisp.Types.Error_None;
         return;
      end if;

      while Cursor /= Lisp.Store.Nil_Ref loop
         if Lisp.Store.Kind_Of (RT.Store, Cursor) /= Lisp.Types.Cons_Cell then
            Result_Ref := Lisp.Types.No_Ref;
            Error := Lisp.Types.Error_Syntax;
            return;
         end if;
         Eval (RT, Current_Frame, Lisp.Store.Car (RT.Store, Cursor), Fuel - 1, Result_Ref, Error);
         if Error /= Lisp.Types.Error_None then
            return;
         end if;
         Cursor := Lisp.Store.Cdr (RT.Store, Cursor);
      end loop;

      Error := Lisp.Types.Error_None;
   end Eval_Begin;

   procedure Eval
     (RT            : in out Lisp.Runtime.State;
      Current_Frame : in Lisp.Types.Frame_Id;
      Expr          : in Lisp.Types.Cell_Ref;
      Fuel          : in Lisp.Types.Fuel_Count;
      Result_Ref    : out Lisp.Types.Cell_Ref;
      Error         : out Lisp.Types.Error_Code) is
      Head         : Lisp.Types.Cell_Ref := Lisp.Types.No_Ref;
      Args_List    : Lisp.Types.Cell_Ref := Lisp.Types.No_Ref;
      Operator     : Lisp.Types.Cell_Ref := Lisp.Types.No_Ref;
      Arg_Values   : Lisp.Types.Cell_Ref_Array (1 .. Lisp.Config.Max_List_Elements) := (others => Lisp.Types.No_Ref);
      Name_Array   : Lisp.Types.Symbol_Id_Array (1 .. Lisp.Config.Max_Frame_Bindings) := (others => 0);
      Arg_Count    : Natural := 0;
      Found        : Boolean := False;
      New_Frame    : Lisp.Types.Frame_Id := Lisp.Types.No_Frame;
      Params       : Lisp.Types.Cell_Ref := Lisp.Types.No_Ref;
      Body_Expr    : Lisp.Types.Cell_Ref := Lisp.Types.No_Ref;
      Name_Id      : Lisp.Types.Symbol_Id := 0;
      Form1        : Lisp.Types.Cell_Ref := Lisp.Types.No_Ref;
      Form2        : Lisp.Types.Cell_Ref := Lisp.Types.No_Ref;
      Form3        : Lisp.Types.Cell_Ref := Lisp.Types.No_Ref;
      Tail         : Lisp.Types.Cell_Ref := Lisp.Types.No_Ref;
   begin
      if Fuel = 0 then
         Result_Ref := Lisp.Types.No_Ref;
         Error := Lisp.Types.Error_Out_Of_Fuel;
         return;
      end if;

      case Lisp.Store.Kind_Of (RT.Store, Expr) is
         when Lisp.Types.Nil_Cell | Lisp.Types.True_Cell | Lisp.Types.Integer_Cell
           | Lisp.Types.Primitive_Cell | Lisp.Types.Closure_Cell =>
            Result_Ref := Expr;
            Error := Lisp.Types.Error_None;
         when Lisp.Types.Symbol_Cell =>
            Name_Id := Lisp.Store.Symbol_Value (RT.Store, Expr);
            Lisp.Env.Lookup (RT.Env, Current_Frame, Name_Id, Result_Ref, Found);
            if Found then
               Error := Lisp.Types.Error_None;
            else
               Result_Ref := Lisp.Types.No_Ref;
               Error := Lisp.Types.Error_Unbound_Symbol;
            end if;
         when Lisp.Types.Cons_Cell =>
            Head := Lisp.Store.Car (RT.Store, Expr);
            Args_List := Lisp.Store.Cdr (RT.Store, Expr);
            if Lisp.Store.Kind_Of (RT.Store, Head) = Lisp.Types.Symbol_Cell then
               Name_Id := Lisp.Store.Symbol_Value (RT.Store, Head);
               if Name_Id = RT.Known.Quote_Id then
                  if Lisp.Store.Kind_Of (RT.Store, Args_List) /= Lisp.Types.Cons_Cell
                    or else Lisp.Store.Cdr (RT.Store, Args_List) /= Lisp.Store.Nil_Ref
                  then
                     Result_Ref := Lisp.Types.No_Ref;
                     Error := Lisp.Types.Error_Arity;
                  else
                     Result_Ref := Lisp.Store.Car (RT.Store, Args_List);
                     Error := Lisp.Types.Error_None;
                  end if;
                  return;
               elsif Name_Id = RT.Known.If_Id then
                  if Lisp.Store.Kind_Of (RT.Store, Args_List) /= Lisp.Types.Cons_Cell then
                     Result_Ref := Lisp.Types.No_Ref;
                     Error := Lisp.Types.Error_Arity;
                     return;
                  end if;
                  Form1 := Lisp.Store.Car (RT.Store, Args_List);
                  Tail := Lisp.Store.Cdr (RT.Store, Args_List);
                  if Lisp.Store.Kind_Of (RT.Store, Tail) /= Lisp.Types.Cons_Cell then
                     Result_Ref := Lisp.Types.No_Ref;
                     Error := Lisp.Types.Error_Arity;
                     return;
                  end if;
                  Form2 := Lisp.Store.Car (RT.Store, Tail);
                  Tail := Lisp.Store.Cdr (RT.Store, Tail);
                  if Lisp.Store.Kind_Of (RT.Store, Tail) /= Lisp.Types.Cons_Cell
                    or else Lisp.Store.Cdr (RT.Store, Tail) /= Lisp.Store.Nil_Ref
                  then
                     Result_Ref := Lisp.Types.No_Ref;
                     Error := Lisp.Types.Error_Arity;
                     return;
                  end if;
                  Form3 := Lisp.Store.Car (RT.Store, Tail);
                  Eval (RT, Current_Frame, Form1, Fuel - 1, Operator, Error);
                  if Error /= Lisp.Types.Error_None then
                     Result_Ref := Lisp.Types.No_Ref;
                     return;
                  end if;
                  if Is_Truth (Operator) then
                     Eval (RT, Current_Frame, Form2, Fuel - 1, Result_Ref, Error);
                  else
                     Eval (RT, Current_Frame, Form3, Fuel - 1, Result_Ref, Error);
                  end if;
                  return;
               elsif Name_Id = RT.Known.Begin_Id then
                  Eval_Begin (RT, Current_Frame, Args_List, Fuel, Result_Ref, Error);
                  return;
               elsif Name_Id = RT.Known.Lambda_Id then
                  if Lisp.Store.Kind_Of (RT.Store, Args_List) /= Lisp.Types.Cons_Cell then
                     Result_Ref := Lisp.Types.No_Ref;
                     Error := Lisp.Types.Error_Arity;
                     return;
                  end if;
                  Params := Lisp.Store.Car (RT.Store, Args_List);
                  Tail := Lisp.Store.Cdr (RT.Store, Args_List);
                  if Lisp.Store.Kind_Of (RT.Store, Tail) /= Lisp.Types.Cons_Cell
                    or else Lisp.Store.Cdr (RT.Store, Tail) /= Lisp.Store.Nil_Ref
                  then
                     Result_Ref := Lisp.Types.No_Ref;
                     Error := Lisp.Types.Error_Arity;
                     return;
                  end if;
                  Body_Expr := Lisp.Store.Car (RT.Store, Tail);
                  Params_To_Array (RT, Params, Name_Array, Arg_Count, Error);
                  if Error /= Lisp.Types.Error_None then
                     Result_Ref := Lisp.Types.No_Ref;
                     return;
                  end if;
                  Lisp.Store.Make_Closure (RT.Store, Params, Body_Expr, Current_Frame, Result_Ref, Error);
                  return;
               elsif Name_Id = RT.Known.Define_Id then
                  if Current_Frame /= Lisp.Env.Global_Frame then
                     Result_Ref := Lisp.Types.No_Ref;
                     Error := Lisp.Types.Error_Invalid_Define;
                     return;
                  end if;
                  if Lisp.Store.Kind_Of (RT.Store, Args_List) /= Lisp.Types.Cons_Cell then
                     Result_Ref := Lisp.Types.No_Ref;
                     Error := Lisp.Types.Error_Arity;
                     return;
                  end if;
                  Form1 := Lisp.Store.Car (RT.Store, Args_List);
                  if Lisp.Store.Kind_Of (RT.Store, Form1) /= Lisp.Types.Symbol_Cell then
                     Result_Ref := Lisp.Types.No_Ref;
                     Error := Lisp.Types.Error_Invalid_Define;
                     return;
                  end if;
                  Name_Id := Lisp.Store.Symbol_Value (RT.Store, Form1);
                  if Lisp.Runtime.Is_Reserved (RT, Name_Id) then
                     Result_Ref := Lisp.Types.No_Ref;
                     Error := Lisp.Types.Error_Reserved_Name;
                     return;
                  end if;
                  Tail := Lisp.Store.Cdr (RT.Store, Args_List);
                  if Lisp.Store.Kind_Of (RT.Store, Tail) /= Lisp.Types.Cons_Cell
                    or else Lisp.Store.Cdr (RT.Store, Tail) /= Lisp.Store.Nil_Ref
                  then
                     Result_Ref := Lisp.Types.No_Ref;
                     Error := Lisp.Types.Error_Arity;
                     return;
                  end if;
                  Eval (RT, Current_Frame, Lisp.Store.Car (RT.Store, Tail), Fuel - 1, Operator, Error);
                  if Error /= Lisp.Types.Error_None then
                     Result_Ref := Lisp.Types.No_Ref;
                     return;
                  end if;
                  Lisp.Env.Define_Global (RT.Env, Name_Id, Operator, Error);
                  if Error = Lisp.Types.Error_None then
                     Result_Ref := Form1;
                  else
                     Result_Ref := Lisp.Types.No_Ref;
                  end if;
                  return;
               end if;
            end if;

            Eval (RT, Current_Frame, Head, Fuel - 1, Operator, Error);
            if Error /= Lisp.Types.Error_None then
               Result_Ref := Lisp.Types.No_Ref;
               return;
            end if;
            Eval_List (RT, Current_Frame, Args_List, Fuel, Arg_Values, Arg_Count, Error);
            if Error /= Lisp.Types.Error_None then
               Result_Ref := Lisp.Types.No_Ref;
               return;
            end if;

            case Lisp.Store.Kind_Of (RT.Store, Operator) is
               when Lisp.Types.Primitive_Cell =>
                  Lisp.Primitives.Apply
                    (RT,
                     Lisp.Store.Primitive_Value (RT.Store, Operator),
                     Arg_Values (1 .. Arg_Count),
                     Arg_Count,
                     Result_Ref,
                     Error);
               when Lisp.Types.Closure_Cell =>
                  Params := Lisp.Store.Closure_Params (RT.Store, Operator);
                  Body_Expr := Lisp.Store.Closure_Body (RT.Store, Operator);
                  Params_To_Array (RT, Params, Name_Array, Arg_Count, Error);
                  if Error /= Lisp.Types.Error_None then
                     Result_Ref := Lisp.Types.No_Ref;
                     return;
                  end if;
                  if Arg_Count /= Arg_Count then
                     null;
                  end if;
                  declare
                     Param_Count : Natural := 0;
                  begin
                     Params_To_Array (RT, Params, Name_Array, Param_Count, Error);
                     if Error /= Lisp.Types.Error_None then
                        Result_Ref := Lisp.Types.No_Ref;
                        return;
                     end if;
                     if Param_Count /= Arg_Count then
                        Result_Ref := Lisp.Types.No_Ref;
                        Error := Lisp.Types.Error_Arity;
                        return;
                     end if;
                     Lisp.Env.Push_Frame
                       (RT.Env,
                        Lisp.Store.Closure_Frame (RT.Store, Operator),
                        Name_Array (1 .. Param_Count),
                        Arg_Values (1 .. Arg_Count),
                        New_Frame,
                        Error);
                     if Error /= Lisp.Types.Error_None then
                        Result_Ref := Lisp.Types.No_Ref;
                        return;
                     end if;
                     Eval (RT, New_Frame, Body_Expr, Fuel - 1, Result_Ref, Error);
                  end;
               when others =>
                  Result_Ref := Lisp.Types.No_Ref;
                  Error := Lisp.Types.Error_Not_Callable;
            end case;
      end case;
   end Eval;
end Lisp.Eval;
