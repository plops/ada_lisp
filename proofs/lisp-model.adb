package body Lisp.Model
with
  SPARK_Mode
is
   use type Lisp.Types.Cell_Kind;
   use type Lisp.Types.Error_Code;
   use type Lisp.Types.Symbol_Id;

   function Is_Truth (Ref : Lisp.Types.Cell_Ref) return Boolean is
     (Ref /= Lisp.Store.Nil_Ref);

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

   function Pure_Subset_Forms
     (RT    : Lisp.Runtime.State;
      Forms : Lisp.Types.Cell_Ref) return Boolean
   with
     Pre => Lisp.Runtime.Valid (RT)
       and then (Forms = Lisp.Types.No_Ref or else Lisp.Store.Is_Valid_Ref (RT.Store, Forms)),
     Subprogram_Variant => (Decreases => Forms);

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

   procedure Prove_Pure_Data_Readable
     (RT   : Lisp.Runtime.State;
      Expr : Lisp.Types.Cell_Ref) is
   begin
      case Lisp.Store.Kind_Of (RT.Store, Expr) is
         when Lisp.Types.Nil_Cell
            | Lisp.Types.True_Cell
            | Lisp.Types.Integer_Cell
            | Lisp.Types.Symbol_Cell =>
            pragma Assert (Readable_Result (RT, Expr));
         when Lisp.Types.Cons_Cell =>
            declare
               Left_Expr  : constant Lisp.Types.Cell_Ref := Lisp.Store.Car (RT.Store, Expr);
               Right_Expr : constant Lisp.Types.Cell_Ref := Lisp.Store.Cdr (RT.Store, Expr);
            begin
               pragma Assert (Left_Expr < Expr);
               pragma Assert (Right_Expr < Expr);
               pragma Assert (Lisp.Store.Is_Valid_Ref (RT.Store, Left_Expr));
               pragma Assert (Lisp.Store.Is_Valid_Ref (RT.Store, Right_Expr));
               pragma Assert (Pure_Data (RT.Store, Left_Expr));
               pragma Assert (Pure_Data (RT.Store, Right_Expr));
               Prove_Pure_Data_Readable (RT, Left_Expr);
               Prove_Pure_Data_Readable (RT, Right_Expr);
               pragma Assert (Readable_Result (RT, Left_Expr));
               pragma Assert (Readable_Result (RT, Right_Expr));
               pragma Assert (Readable_Result (RT, Expr));
            end;
         when Lisp.Types.Primitive_Cell
            | Lisp.Types.Closure_Cell =>
            null;
      end case;
   end Prove_Pure_Data_Readable;

   procedure Prove_Pure_Subset_Quote_Result
     (RT   : Lisp.Runtime.State;
      Expr : Lisp.Types.Cell_Ref) is
   begin
      pragma Assert (Pure_Subset_Expr (RT, Expr));
      pragma Assert (Pure_Data (RT.Store, Lisp.Runtime.Quote_Form_Result (RT, Expr)));
   end Prove_Pure_Subset_Quote_Result;

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
               if Head_Expr = Lisp.Types.No_Ref
                 or else Args_Expr = Lisp.Types.No_Ref
                 or else Lisp.Store.Kind_Of (RT.Store, Head_Expr) /= Lisp.Types.Symbol_Cell
               then
                  return False;
               end if;

               declare
                  Name_Id : constant Lisp.Types.Symbol_Id :=
                    Lisp.Store.Symbol_Value (RT.Store, Head_Expr);
               begin
                  if Name_Id = RT.Known.Quote_Id then
                     if Quote_Args (RT.Store, Args_Expr) then
                        pragma Assert (Lisp.Runtime.Quote_Form (RT, Expr));
                        pragma Assert
                          (Lisp.Runtime.Quote_Form_Result (RT, Expr) =
                             Lisp.Store.Car (RT.Store, Args_Expr));
                        pragma Assert
                          (Pure_Data (RT.Store, Lisp.Runtime.Quote_Form_Result (RT, Expr)));
                     end if;
                     return Quote_Args (RT.Store, Args_Expr);
                  elsif Name_Id = RT.Known.If_Id then
                     if Lisp.Store.Kind_Of (RT.Store, Args_Expr) /= Lisp.Types.Cons_Cell then
                        return False;
                     end if;

                     declare
                        Cond_Expr : constant Lisp.Types.Cell_Ref := Lisp.Store.Car (RT.Store, Args_Expr);
                        Tail_1    : constant Lisp.Types.Cell_Ref := Lisp.Store.Cdr (RT.Store, Args_Expr);
                     begin
                        pragma Assert (Cond_Expr < Args_Expr);
                        pragma Assert (Tail_1 < Args_Expr);
                        if Cond_Expr = Lisp.Types.No_Ref
                          or else Tail_1 = Lisp.Types.No_Ref
                          or else Lisp.Store.Kind_Of (RT.Store, Tail_1) /= Lisp.Types.Cons_Cell
                        then
                           return False;
                        end if;

                        declare
                           Then_Expr : constant Lisp.Types.Cell_Ref := Lisp.Store.Car (RT.Store, Tail_1);
                           Tail_2    : constant Lisp.Types.Cell_Ref := Lisp.Store.Cdr (RT.Store, Tail_1);
                        begin
                           pragma Assert (Then_Expr < Tail_1);
                           pragma Assert (Tail_2 < Tail_1);
                           if Then_Expr = Lisp.Types.No_Ref
                             or else Tail_2 = Lisp.Types.No_Ref
                             or else Lisp.Store.Kind_Of (RT.Store, Tail_2) /= Lisp.Types.Cons_Cell
                           then
                              return False;
                           end if;

                           declare
                              Else_Expr  : constant Lisp.Types.Cell_Ref := Lisp.Store.Car (RT.Store, Tail_2);
                              Final_Tail : constant Lisp.Types.Cell_Ref := Lisp.Store.Cdr (RT.Store, Tail_2);
                              Result     : constant Boolean :=
                                Else_Expr /= Lisp.Types.No_Ref
                                and then Final_Tail /= Lisp.Types.No_Ref
                                and then Final_Tail = Lisp.Store.Nil_Ref
                                and then Pure_Subset_Expr (RT, Cond_Expr)
                                and then Pure_Subset_Expr (RT, Then_Expr)
                                and then Pure_Subset_Expr (RT, Else_Expr);
                           begin
                              pragma Assert (Else_Expr < Tail_2);
                              pragma Assert (Final_Tail < Tail_2);
                              return Result;
                           end;
                        end;
                     end;
                  elsif Name_Id = RT.Known.Begin_Id then
                     return Pure_Subset_Forms (RT, Args_Expr);
                  else
                     return False;
                  end if;
               end;
            end;
      end case;
   end Pure_Subset_Expr;

   function Pure_Subset_Forms
     (RT    : Lisp.Runtime.State;
      Forms : Lisp.Types.Cell_Ref) return Boolean is
   begin
      if Forms = Lisp.Store.Nil_Ref then
         return True;
      end if;

      if Forms = Lisp.Types.No_Ref
        or else not Lisp.Store.Is_Valid_Ref (RT.Store, Forms)
        or else Lisp.Store.Kind_Of (RT.Store, Forms) /= Lisp.Types.Cons_Cell
      then
         return False;
      end if;

      declare
         Form_Ref : constant Lisp.Types.Cell_Ref := Lisp.Store.Car (RT.Store, Forms);
         Tail_Ref : constant Lisp.Types.Cell_Ref := Lisp.Store.Cdr (RT.Store, Forms);
      begin
         pragma Assert (Form_Ref < Forms);
         pragma Assert (Tail_Ref < Forms);
         return Form_Ref /= Lisp.Types.No_Ref
           and then Tail_Ref /= Lisp.Types.No_Ref
           and then Pure_Subset_Expr (RT, Form_Ref)
           and then Pure_Subset_Forms (RT, Tail_Ref);
      end;
   end Pure_Subset_Forms;

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
      Head_Expr        : Lisp.Types.Cell_Ref;
      Args_Expr        : Lisp.Types.Cell_Ref;
      Cond_Expr        : Lisp.Types.Cell_Ref;
      Then_Expr        : Lisp.Types.Cell_Ref;
      Else_Expr        : Lisp.Types.Cell_Ref;
      Tail_Expr        : Lisp.Types.Cell_Ref;
      Form_Expr        : Lisp.Types.Cell_Ref;
      Condition_Result : Lisp.Types.Cell_Ref;
      Condition_Error  : Lisp.Types.Error_Code;
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
            pragma Assert (not Lisp.Runtime.If_Immediate_Result_Form (RT, Expr));
            pragma Assert (Pure_Data (RT.Store, Result_Ref));
         when Lisp.Types.Cons_Cell =>
            Head_Expr := Lisp.Store.Car (RT.Store, Expr);
            Args_Expr := Lisp.Store.Cdr (RT.Store, Expr);
            if Head_Expr = Lisp.Types.No_Ref
              or else Args_Expr = Lisp.Types.No_Ref
              or else Lisp.Store.Kind_Of (RT.Store, Head_Expr) /= Lisp.Types.Symbol_Cell
            then
               Result_Ref := Lisp.Types.No_Ref;
               Error := Lisp.Types.Error_Type;
               pragma Assert (not Lisp.Runtime.If_Immediate_Result_Form (RT, Expr));
            elsif Lisp.Store.Symbol_Value (RT.Store, Head_Expr) = RT.Known.Quote_Id then
               pragma Assert
                 (RT.Known.If_Id = RT.Known.Quote_Id
                  or else not Lisp.Runtime.If_Immediate_Result_Form (RT, Expr));
               if not Quote_Args (RT.Store, Args_Expr) then
                  Result_Ref := Lisp.Types.No_Ref;
                  Error := Lisp.Types.Error_Type;
               else
                  Result_Ref := Lisp.Store.Car (RT.Store, Args_Expr);
                  pragma Assert (Lisp.Runtime.Quote_Form (RT, Expr));
                  pragma Assert (Result_Ref = Lisp.Runtime.Quote_Form_Result (RT, Expr));
                  Error := Lisp.Types.Error_None;
                  pragma Assert (Pure_Data (RT.Store, Result_Ref));
               end if;
               pragma Assert
                 ((if Lisp.Runtime.Quote_Form (RT, Expr)
                      and then Pure_Data (RT.Store, Lisp.Runtime.Quote_Form_Result (RT, Expr))
                   then
                      Error = Lisp.Types.Error_None
                      and then Result_Ref = Lisp.Runtime.Quote_Form_Result (RT, Expr)
                   else
                      True));
            elsif Lisp.Store.Symbol_Value (RT.Store, Head_Expr) = RT.Known.If_Id then
               if Lisp.Store.Kind_Of (RT.Store, Args_Expr) /= Lisp.Types.Cons_Cell then
                  Result_Ref := Lisp.Types.No_Ref;
                  Error := Lisp.Types.Error_Type;
                  pragma Assert
                    (Fuel <= 1 or else not Lisp.Runtime.If_Immediate_Result_Form (RT, Expr));
                  return;
               end if;

               Cond_Expr := Lisp.Store.Car (RT.Store, Args_Expr);
               Tail_Expr := Lisp.Store.Cdr (RT.Store, Args_Expr);
               if Cond_Expr = Lisp.Types.No_Ref
                 or else Tail_Expr = Lisp.Types.No_Ref
                 or else Lisp.Store.Kind_Of (RT.Store, Tail_Expr) /= Lisp.Types.Cons_Cell
               then
                  Result_Ref := Lisp.Types.No_Ref;
                  Error := Lisp.Types.Error_Type;
                  pragma Assert
                    (Fuel <= 1 or else not Lisp.Runtime.If_Immediate_Result_Form (RT, Expr));
                  return;
               end if;

               Then_Expr := Lisp.Store.Car (RT.Store, Tail_Expr);
               Tail_Expr := Lisp.Store.Cdr (RT.Store, Tail_Expr);
               if Then_Expr = Lisp.Types.No_Ref
                 or else Tail_Expr = Lisp.Types.No_Ref
                 or else Lisp.Store.Kind_Of (RT.Store, Tail_Expr) /= Lisp.Types.Cons_Cell
               then
                  Result_Ref := Lisp.Types.No_Ref;
                  Error := Lisp.Types.Error_Type;
                  pragma Assert
                    (Fuel <= 1 or else not Lisp.Runtime.If_Immediate_Result_Form (RT, Expr));
                  return;
               end if;

               Else_Expr := Lisp.Store.Car (RT.Store, Tail_Expr);
               Tail_Expr := Lisp.Store.Cdr (RT.Store, Tail_Expr);
               if Else_Expr = Lisp.Types.No_Ref
                 or else Tail_Expr = Lisp.Types.No_Ref
                 or else Tail_Expr /= Lisp.Store.Nil_Ref
               then
                  Result_Ref := Lisp.Types.No_Ref;
                  Error := Lisp.Types.Error_Type;
                  pragma Assert
                    (Fuel <= 1 or else not Lisp.Runtime.If_Immediate_Result_Form (RT, Expr));
                  return;
               end if;

               if not Pure_Subset_Expr (RT, Cond_Expr)
                 or else not Pure_Subset_Expr (RT, Then_Expr)
                 or else not Pure_Subset_Expr (RT, Else_Expr)
               then
                  Result_Ref := Lisp.Types.No_Ref;
                  Error := Lisp.Types.Error_Type;
                  pragma Assert
                    (Fuel <= 1 or else not Lisp.Runtime.If_Immediate_Result_Form (RT, Expr));
                  return;
               end if;
               if Lisp.Runtime.If_Immediate_Result_Form (RT, Expr) then
                  pragma Assert (Lisp.Runtime.If_Form (RT, Expr));
                  pragma Assert (Cond_Expr = Lisp.Runtime.If_Form_Cond (RT, Expr));
                  pragma Assert (Then_Expr = Lisp.Runtime.If_Form_Then (RT, Expr));
                  pragma Assert (Else_Expr = Lisp.Runtime.If_Form_Else (RT, Expr));
                  pragma Assert (Pure_Subset_Expr (RT, Cond_Expr));
                  pragma Assert (Pure_Subset_Expr (RT, Then_Expr));
                  pragma Assert (Pure_Subset_Expr (RT, Else_Expr));
                  pragma Assert (Lisp.Runtime.Immediate_Result_Form (RT, Cond_Expr));
                  pragma Assert (Lisp.Runtime.Immediate_Result_Form (RT, Then_Expr));
                  pragma Assert (Lisp.Runtime.Immediate_Result_Form (RT, Else_Expr));
               end if;
               Eval_Pure_Closed
                 (RT,
                  Current_Frame,
                  Cond_Expr,
                  Fuel - 1,
                  Condition_Result,
                  Condition_Error);
               if Fuel > 1
                 and then Lisp.Runtime.Quote_If_Known (RT)
                 and then Lisp.Runtime.If_Immediate_Result_Form (RT, Expr)
               then
                  pragma Assert (Condition_Error = Lisp.Types.Error_None);
                  if Lisp.Store.Kind_Of (RT.Store, Cond_Expr) = Lisp.Types.Nil_Cell
                    or else Lisp.Store.Kind_Of (RT.Store, Cond_Expr) = Lisp.Types.True_Cell
                    or else Lisp.Store.Kind_Of (RT.Store, Cond_Expr) = Lisp.Types.Integer_Cell
                  then
                     pragma Assert (Condition_Result = Cond_Expr);
                  else
                     pragma Assert (Lisp.Runtime.Quote_Form (RT, Cond_Expr));
                     pragma Assert
                       (Condition_Result = Lisp.Runtime.Quote_Form_Result (RT, Cond_Expr));
                  end if;
                  pragma Assert
                    (Condition_Result = Lisp.Runtime.Immediate_Result (RT, Cond_Expr));
               end if;
               if Condition_Error /= Lisp.Types.Error_None then
                  Result_Ref := Lisp.Types.No_Ref;
                  Error := Condition_Error;
                  pragma Assert
                    (Fuel <= 1
                     or else not Lisp.Runtime.Quote_If_Known (RT)
                     or else not Lisp.Runtime.If_Immediate_Result_Form (RT, Expr));
                  return;
               end if;
               if Is_Truth (Condition_Result) then
                  Eval_Pure_Closed
                    (RT,
                     Current_Frame,
                     Then_Expr,
                     Fuel - 1,
                     Result_Ref,
                     Error);
                  if Fuel > 1
                    and then Lisp.Runtime.Quote_If_Known (RT)
                    and then Lisp.Runtime.If_Immediate_Result_Form (RT, Expr)
                  then
                     pragma Assert
                       (Condition_Result = Lisp.Runtime.Immediate_Result (RT, Cond_Expr));
                     pragma Assert (Condition_Result /= Lisp.Store.Nil_Ref);
                     pragma Assert (Error = Lisp.Types.Error_None);
                     if Lisp.Store.Kind_Of (RT.Store, Then_Expr) = Lisp.Types.Nil_Cell
                       or else Lisp.Store.Kind_Of (RT.Store, Then_Expr) = Lisp.Types.True_Cell
                       or else Lisp.Store.Kind_Of (RT.Store, Then_Expr) = Lisp.Types.Integer_Cell
                     then
                        pragma Assert (Result_Ref = Then_Expr);
                     else
                        pragma Assert (Lisp.Runtime.Quote_Form (RT, Then_Expr));
                        pragma Assert
                          (Result_Ref = Lisp.Runtime.Quote_Form_Result (RT, Then_Expr));
                     end if;
                     pragma Assert
                       (Result_Ref = Lisp.Runtime.Immediate_Result (RT, Then_Expr));
                     pragma Assert
                       (Result_Ref = Lisp.Runtime.If_Immediate_Result (RT, Expr));
                  end if;
               else
                  Eval_Pure_Closed
                    (RT,
                     Current_Frame,
                     Else_Expr,
                     Fuel - 1,
                     Result_Ref,
                     Error);
                  if Fuel > 1
                    and then Lisp.Runtime.Quote_If_Known (RT)
                    and then Lisp.Runtime.If_Immediate_Result_Form (RT, Expr)
                  then
                     pragma Assert
                       (Condition_Result = Lisp.Runtime.Immediate_Result (RT, Cond_Expr));
                     pragma Assert (Condition_Result = Lisp.Store.Nil_Ref);
                     pragma Assert (Error = Lisp.Types.Error_None);
                     if Lisp.Store.Kind_Of (RT.Store, Else_Expr) = Lisp.Types.Nil_Cell
                       or else Lisp.Store.Kind_Of (RT.Store, Else_Expr) = Lisp.Types.True_Cell
                       or else Lisp.Store.Kind_Of (RT.Store, Else_Expr) = Lisp.Types.Integer_Cell
                     then
                        pragma Assert (Result_Ref = Else_Expr);
                     else
                        pragma Assert (Lisp.Runtime.Quote_Form (RT, Else_Expr));
                        pragma Assert
                          (Result_Ref = Lisp.Runtime.Quote_Form_Result (RT, Else_Expr));
                     end if;
                     pragma Assert
                       (Result_Ref = Lisp.Runtime.Immediate_Result (RT, Else_Expr));
                     pragma Assert
                       (Result_Ref = Lisp.Runtime.If_Immediate_Result (RT, Expr));
                  end if;
               end if;
               if Fuel > 1
                 and then Lisp.Runtime.Quote_If_Known (RT)
                 and then Lisp.Runtime.If_Immediate_Result_Form (RT, Expr)
               then
                  pragma Assert (Error = Lisp.Types.Error_None);
                  pragma Assert (Result_Ref = Lisp.Runtime.If_Immediate_Result (RT, Expr));
               end if;
            elsif Lisp.Store.Symbol_Value (RT.Store, Head_Expr) = RT.Known.Begin_Id then
               pragma Assert (not Lisp.Runtime.If_Immediate_Result_Form (RT, Expr));
               if not Pure_Subset_Forms (RT, Args_Expr) then
                  Result_Ref := Lisp.Types.No_Ref;
                  Error := Lisp.Types.Error_Type;
                  return;
               end if;

               if Args_Expr = Lisp.Store.Nil_Ref then
                  Result_Ref := Lisp.Store.Nil_Ref;
                  Error := Lisp.Types.Error_None;
                  pragma Assert (Pure_Data (RT.Store, Result_Ref));
                  return;
               end if;

               if Fuel = 1 then
                  Result_Ref := Lisp.Types.No_Ref;
                  Error := Lisp.Types.Error_Out_Of_Fuel;
                  return;
               end if;

               Result_Ref := Lisp.Store.Nil_Ref;
               Error := Lisp.Types.Error_None;
               Tail_Expr := Args_Expr;
               while Tail_Expr /= Lisp.Store.Nil_Ref loop
                  pragma Loop_Invariant (Lisp.Runtime.Valid (RT));
                  pragma Loop_Invariant (Lisp.Env.Frame_Valid (RT.Env, Current_Frame));
                  pragma Loop_Invariant (Lisp.Store.Is_Valid_Ref (RT.Store, Tail_Expr));
                  pragma Loop_Invariant (Pure_Data (RT.Store, Result_Ref));
                  pragma Loop_Invariant (Error = Lisp.Types.Error_None);
                  pragma Loop_Invariant (Fuel > 1);

                  if Lisp.Store.Kind_Of (RT.Store, Tail_Expr) /= Lisp.Types.Cons_Cell then
                     Result_Ref := Lisp.Types.No_Ref;
                     Error := Lisp.Types.Error_Type;
                     return;
                  end if;
                  Form_Expr := Lisp.Store.Car (RT.Store, Tail_Expr);
                  Tail_Expr := Lisp.Store.Cdr (RT.Store, Tail_Expr);
                  if Form_Expr = Lisp.Types.No_Ref
                    or else Tail_Expr = Lisp.Types.No_Ref
                    or else not Pure_Subset_Expr (RT, Form_Expr)
                  then
                     Result_Ref := Lisp.Types.No_Ref;
                     Error := Lisp.Types.Error_Type;
                     return;
                  end if;

                  Eval_Pure_Closed
                    (RT,
                     Current_Frame,
                     Form_Expr,
                     Fuel - 2,
                     Result_Ref,
                     Error);
                  if Error /= Lisp.Types.Error_None then
                     Result_Ref := Lisp.Types.No_Ref;
                     return;
                  end if;
               end loop;
            else
               Result_Ref := Lisp.Types.No_Ref;
               Error := Lisp.Types.Error_Type;
               pragma Assert (not Lisp.Runtime.If_Immediate_Result_Form (RT, Expr));
            end if;
         when Lisp.Types.Symbol_Cell
            | Lisp.Types.Primitive_Cell
            | Lisp.Types.Closure_Cell =>
            Result_Ref := Lisp.Types.No_Ref;
            Error := Lisp.Types.Error_Type;
            pragma Assert (not Lisp.Runtime.If_Immediate_Result_Form (RT, Expr));
      end case;
   end Eval_Pure_Closed;
end Lisp.Model;
