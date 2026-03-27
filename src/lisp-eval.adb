with Lisp.Config;
with Lisp.Env;
with Lisp.Primitives;
with Lisp.Store;

package body Lisp.Eval with SPARK_Mode is
   use type Lisp.Types.Error_Code;
   use type Lisp.Types.Cell_Kind;
   use type Lisp.Runtime.State;

   function Is_Truth (Ref : Lisp.Types.Cell_Ref) return Boolean is
     (Ref /= Lisp.Store.Nil_Ref);

   procedure Proper_List_To_Array
     (RT          : in Lisp.Runtime.State;
      List_Ref    : in Lisp.Types.Cell_Ref;
      Elements    : out Lisp.Types.Cell_Ref_Array;
      Count       : out Natural;
      Error       : out Lisp.Types.Error_Code)
   with
     Pre => Lisp.Runtime.Valid (RT)
       and then Elements'First = 1
       and then (List_Ref = Lisp.Store.Nil_Ref or else Lisp.Store.Is_Valid_Ref (RT.Store, List_Ref)),
     Post => Lisp.Runtime.Valid (RT)
       and then Count <= Elements'Length
       and then
       (if Lisp.Types."=" (Error, Lisp.Types.Error_None) then
           (for all I in Elements'Range =>
              (if I <= Count then Lisp.Store.Is_Valid_Ref (RT.Store, Elements (I)))));

   procedure Params_To_Array
     (RT       : in Lisp.Runtime.State;
      List_Ref : in Lisp.Types.Cell_Ref;
      Names    : out Lisp.Types.Symbol_Id_Array;
      Count    : out Natural;
      Error    : out Lisp.Types.Error_Code)
   with
     Pre => Lisp.Runtime.Valid (RT)
       and then Names'First = 1
       and then (List_Ref = Lisp.Store.Nil_Ref or else Lisp.Store.Is_Valid_Ref (RT.Store, List_Ref)),
     Post => Lisp.Runtime.Valid (RT)
       and then Count <= Names'Length;

   procedure Eval_List
     (RT            : in out Lisp.Runtime.State;
      Current_Frame : in Lisp.Types.Frame_Id;
      List_Ref      : in Lisp.Types.Cell_Ref;
      Fuel          : in Lisp.Types.Fuel_Count;
      Values        : out Lisp.Types.Cell_Ref_Array;
      Count         : out Natural;
      Error         : out Lisp.Types.Error_Code)
   with
     Pre => Lisp.Runtime.Valid (RT)
       and then Lisp.Env.Frame_Valid (RT.Env, Current_Frame)
       and then Values'First = 1
       and then (List_Ref = Lisp.Store.Nil_Ref or else Lisp.Store.Is_Valid_Ref (RT.Store, List_Ref)),
     Post => Lisp.Runtime.Valid (RT)
       and then Count <= Values'Length
       and then Lisp.Store.Cell_Count (RT.Store) >= Lisp.Store.Cell_Count (RT.Store'Old)
       and then Lisp.Env.Frames_Preserved (RT.Env'Old, RT.Env)
       and then
       (if Lisp.Types."=" (Error, Lisp.Types.Error_None) then
           (for all I in Values'Range =>
              (if I <= Count then Lisp.Store.Is_Valid_Ref (RT.Store, Values (I))))),
     Subprogram_Variant => (Decreases => Fuel, Decreases => 0);

   procedure Eval_Begin
     (RT            : in out Lisp.Runtime.State;
      Current_Frame : in Lisp.Types.Frame_Id;
      Forms         : in Lisp.Types.Cell_Ref;
      Fuel          : in Lisp.Types.Fuel_Count;
      Result_Ref    : out Lisp.Types.Cell_Ref;
      Error         : out Lisp.Types.Error_Code)
   with
     Pre => Lisp.Runtime.Valid (RT)
       and then Lisp.Env.Frame_Valid (RT.Env, Current_Frame)
       and then (Forms = Lisp.Store.Nil_Ref or else Lisp.Store.Is_Valid_Ref (RT.Store, Forms)),
     Post => Lisp.Runtime.Valid (RT)
       and then Lisp.Store.Cell_Count (RT.Store) >= Lisp.Store.Cell_Count (RT.Store'Old)
       and then Lisp.Env.Frames_Preserved (RT.Env'Old, RT.Env)
       and then
       (if Lisp.Types."=" (Error, Lisp.Types.Error_None) then
           Lisp.Store.Is_Valid_Ref (RT.Store, Result_Ref)
        else
           Result_Ref = Lisp.Types.No_Ref),
     Subprogram_Variant => (Decreases => Fuel, Decreases => 0);

   procedure Proper_List_To_Array
     (RT          : in Lisp.Runtime.State;
      List_Ref    : in Lisp.Types.Cell_Ref;
      Elements    : out Lisp.Types.Cell_Ref_Array;
      Count       : out Natural;
      Error       : out Lisp.Types.Error_Code) is
      Cursor      : Lisp.Types.Cell_Ref := List_Ref;
      Element_Ref : Lisp.Types.Cell_Ref;
      Next_Ref    : Lisp.Types.Cell_Ref;
   begin
      Elements := (others => Lisp.Types.No_Ref);
      Count := 0;
      while Cursor /= Lisp.Store.Nil_Ref loop
         pragma Loop_Invariant (Lisp.Runtime.Valid (RT));
         pragma Loop_Invariant
           (Cursor = Lisp.Store.Nil_Ref
            or else Lisp.Store.Is_Valid_Ref (RT.Store, Cursor));
         pragma Loop_Invariant (Count <= Elements'Length);
         pragma Loop_Invariant
           (for all I in Elements'Range =>
              (if I <= Count then Lisp.Store.Is_Valid_Ref (RT.Store, Elements (I))));
         if Lisp.Store.Kind_Of (RT.Store, Cursor) /= Lisp.Types.Cons_Cell then
            Error := Lisp.Types.Error_Syntax;
            return;
         end if;
         if Count = Elements'Length then
            Error := Lisp.Types.Error_Arena_Full;
            return;
         end if;
         Element_Ref := Lisp.Store.Car (RT.Store, Cursor);
         if Element_Ref = Lisp.Types.No_Ref then
            Error := Lisp.Types.Error_Syntax;
            return;
         end if;
         Next_Ref := Lisp.Store.Cdr (RT.Store, Cursor);
         if Next_Ref = Lisp.Types.No_Ref then
            Error := Lisp.Types.Error_Syntax;
            return;
         end if;
         pragma Assert (Count + 1 in Elements'Range);
         Count := Count + 1;
         Elements (Count) := Element_Ref;
         Cursor := Next_Ref;
      end loop;
      Error := Lisp.Types.Error_None;
   end Proper_List_To_Array;

   procedure Params_To_Array
     (RT       : in Lisp.Runtime.State;
      List_Ref : in Lisp.Types.Cell_Ref;
      Names    : out Lisp.Types.Symbol_Id_Array;
      Count    : out Natural;
      Error    : out Lisp.Types.Error_Code) is
      Values : Lisp.Types.Cell_Ref_Array (Names'Range);
   begin
      Names := (others => 0);
      Proper_List_To_Array (RT, List_Ref, Values, Count, Error);
      if Error /= Lisp.Types.Error_None then
         return;
      end if;

      for I in 1 .. Count loop
         pragma Loop_Invariant (Lisp.Runtime.Valid (RT));
         pragma Loop_Invariant (Count <= Names'Length);
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
      Old_Cell_Count : constant Natural := Lisp.Store.Cell_Count (RT.Store);
      Old_Env        : constant Lisp.Env.State := RT.Env;
      Exprs          : Lisp.Types.Cell_Ref_Array (Values'Range);
   begin
      Values := (others => Lisp.Types.No_Ref);
      Proper_List_To_Array (RT, List_Ref, Exprs, Count, Error);
      if Error /= Lisp.Types.Error_None then
         return;
      end if;
      if Count > 0 and then Fuel = 0 then
         Error := Lisp.Types.Error_Out_Of_Fuel;
         return;
      end if;
      for I in 1 .. Count loop
         pragma Loop_Invariant (Lisp.Runtime.Valid (RT));
         pragma Loop_Invariant (Lisp.Env.Frame_Valid (RT.Env, Current_Frame));
         pragma Loop_Invariant (Count <= Values'Length);
         pragma Loop_Invariant (Lisp.Store.Cell_Count (RT.Store) >= Old_Cell_Count);
         pragma Loop_Invariant (Lisp.Env.Frames_Preserved (Old_Env, RT.Env));
         pragma Loop_Invariant
           (for all J in Exprs'Range =>
              (if J <= Count then Exprs (J) in 1 .. Old_Cell_Count));
         pragma Loop_Invariant
           (for all J in Exprs'Range =>
              (if J <= Count then Lisp.Store.Is_Valid_Ref (RT.Store, Exprs (J))));
         pragma Loop_Invariant
           (for all J in 1 .. I - 1 => Lisp.Store.Is_Valid_Ref (RT.Store, Values (J)));
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
      Old_Cell_Count : constant Natural := Lisp.Store.Cell_Count (RT.Store);
      Old_Env        : constant Lisp.Env.State := RT.Env;
      Cursor         : Lisp.Types.Cell_Ref := Forms;
      Form_Ref       : Lisp.Types.Cell_Ref;
      Next_Ref       : Lisp.Types.Cell_Ref;
   begin
      Result_Ref := Lisp.Types.No_Ref;
      if Cursor = Lisp.Store.Nil_Ref then
         Result_Ref := Lisp.Store.Nil_Ref;
         Error := Lisp.Types.Error_None;
         return;
      end if;
      if Fuel = 0 then
         Error := Lisp.Types.Error_Out_Of_Fuel;
         return;
      end if;

      while Cursor /= Lisp.Store.Nil_Ref loop
         pragma Loop_Invariant (Lisp.Runtime.Valid (RT));
         pragma Loop_Invariant (Lisp.Env.Frame_Valid (RT.Env, Current_Frame));
         pragma Loop_Invariant (Lisp.Store.Cell_Count (RT.Store) >= Old_Cell_Count);
         pragma Loop_Invariant (Lisp.Env.Frames_Preserved (Old_Env, RT.Env));
         pragma Loop_Invariant
           (Cursor = Lisp.Store.Nil_Ref
            or else Lisp.Store.Is_Valid_Ref (RT.Store, Cursor));
         if Lisp.Store.Kind_Of (RT.Store, Cursor) /= Lisp.Types.Cons_Cell then
            Result_Ref := Lisp.Types.No_Ref;
            Error := Lisp.Types.Error_Syntax;
            return;
         end if;
         Form_Ref := Lisp.Store.Car (RT.Store, Cursor);
         if Form_Ref = Lisp.Types.No_Ref then
            Result_Ref := Lisp.Types.No_Ref;
            Error := Lisp.Types.Error_Syntax;
            return;
         end if;
         Next_Ref := Lisp.Store.Cdr (RT.Store, Cursor);
         if Next_Ref = Lisp.Types.No_Ref then
            Result_Ref := Lisp.Types.No_Ref;
            Error := Lisp.Types.Error_Syntax;
            return;
         end if;
         Eval (RT, Current_Frame, Form_Ref, Fuel - 1, Result_Ref, Error);
         if Error /= Lisp.Types.Error_None then
            return;
         end if;
         Cursor := Next_Ref;
      end loop;

      Error := Lisp.Types.Error_None;
   end Eval_Begin;

   procedure Eval_If_Special
     (RT            : in out Lisp.Runtime.State;
      Current_Frame : in Lisp.Types.Frame_Id;
      Expr          : in Lisp.Types.Cell_Ref;
      Fuel          : in Lisp.Types.Fuel_Count;
      Result_Ref    : out Lisp.Types.Cell_Ref;
      Error         : out Lisp.Types.Error_Code)
   with
     Pre => Lisp.Runtime.Valid (RT)
       and then Lisp.Env.Frame_Valid (RT.Env, Current_Frame)
       and then Lisp.Store.Is_Valid_Ref (RT.Store, Expr)
       and then Fuel > 0
       and then Lisp.Store.Kind_Of (RT.Store, Expr) = Lisp.Types.Cons_Cell
       and then Lisp.Store.Car (RT.Store, Expr) /= Lisp.Types.No_Ref
       and then
         Lisp.Store.Kind_Of (RT.Store, Lisp.Store.Car (RT.Store, Expr)) =
           Lisp.Types.Symbol_Cell
       and then
         Lisp.Store.Symbol_Value (RT.Store, Lisp.Store.Car (RT.Store, Expr)) =
           RT.Known.If_Id,
     Post => Lisp.Runtime.Valid (RT)
       and then Lisp.Store.Cell_Count (RT.Store) >= Lisp.Store.Cell_Count (RT.Store'Old)
       and then Lisp.Env.Frames_Preserved (RT.Env'Old, RT.Env)
       and then
       (if Lisp.Types."=" (Error, Lisp.Types.Error_None) then
           Lisp.Store.Is_Valid_Ref (RT.Store, Result_Ref)
        else
           Result_Ref = Lisp.Types.No_Ref)
       and then
       (if Fuel > 1
         and then RT'Old.Known.If_Id /= RT'Old.Known.Quote_Id
         and then Lisp.Runtime.If_Immediate_Result_Form (RT'Old, Expr)
        then
           Lisp.Types."=" (Error, Lisp.Types.Error_None)
           and then Result_Ref = Lisp.Runtime.If_Immediate_Result (RT'Old, Expr)
           and then RT = RT'Old
        else
           True),
     Subprogram_Variant => (Decreases => Fuel, Decreases => 0);

   procedure Eval_If_Special
     (RT            : in out Lisp.Runtime.State;
      Current_Frame : in Lisp.Types.Frame_Id;
      Expr          : in Lisp.Types.Cell_Ref;
      Fuel          : in Lisp.Types.Fuel_Count;
      Result_Ref    : out Lisp.Types.Cell_Ref;
      Error         : out Lisp.Types.Error_Code) is
      Args_List : Lisp.Types.Cell_Ref := Lisp.Store.Cdr (RT.Store, Expr);
      Operator  : Lisp.Types.Cell_Ref;
      Form1     : Lisp.Types.Cell_Ref;
      Form2     : Lisp.Types.Cell_Ref;
      Form3     : Lisp.Types.Cell_Ref;
      Tail      : Lisp.Types.Cell_Ref;
      Old_RT    : constant Lisp.Runtime.State := RT;
      Old_Env   : constant Lisp.Env.State := RT.Env;

      procedure Assert_Frames_Preserved with Ghost is
      begin
         pragma Assert (Lisp.Env.Frames_Preserved (Old_Env, RT.Env));
      end Assert_Frames_Preserved;

      procedure Assert_Unchanged with Ghost is
      begin
         pragma Assert (RT = Old_RT);
      end Assert_Unchanged;
   begin
      if Args_List = Lisp.Types.No_Ref then
         Result_Ref := Lisp.Types.No_Ref;
         Error := Lisp.Types.Error_Syntax;
         pragma Assert
           (Fuel <= 1
            or else Old_RT.Known.If_Id = Old_RT.Known.Quote_Id
            or else not Lisp.Runtime.If_Immediate_Result_Form (Old_RT, Expr));
         Assert_Frames_Preserved;
         return;
      end if;
      if Lisp.Store.Kind_Of (RT.Store, Args_List) /= Lisp.Types.Cons_Cell then
         Result_Ref := Lisp.Types.No_Ref;
         Error := Lisp.Types.Error_Arity;
         pragma Assert
           (Fuel <= 1
            or else Old_RT.Known.If_Id = Old_RT.Known.Quote_Id
            or else not Lisp.Runtime.If_Immediate_Result_Form (Old_RT, Expr));
         Assert_Frames_Preserved;
         return;
      end if;

      Form1 := Lisp.Store.Car (RT.Store, Args_List);
      if Form1 = Lisp.Types.No_Ref then
         Result_Ref := Lisp.Types.No_Ref;
         Error := Lisp.Types.Error_Syntax;
         pragma Assert
           (Fuel <= 1
            or else Old_RT.Known.If_Id = Old_RT.Known.Quote_Id
            or else not Lisp.Runtime.If_Immediate_Result_Form (Old_RT, Expr));
         Assert_Frames_Preserved;
         return;
      end if;

      Tail := Lisp.Store.Cdr (RT.Store, Args_List);
      if Tail = Lisp.Types.No_Ref then
         Result_Ref := Lisp.Types.No_Ref;
         Error := Lisp.Types.Error_Syntax;
         pragma Assert
           (Fuel <= 1
            or else Old_RT.Known.If_Id = Old_RT.Known.Quote_Id
            or else not Lisp.Runtime.If_Immediate_Result_Form (Old_RT, Expr));
         Assert_Frames_Preserved;
         return;
      end if;
      if Lisp.Store.Kind_Of (RT.Store, Tail) /= Lisp.Types.Cons_Cell then
         Result_Ref := Lisp.Types.No_Ref;
         Error := Lisp.Types.Error_Arity;
         pragma Assert
           (Fuel <= 1
            or else Old_RT.Known.If_Id = Old_RT.Known.Quote_Id
            or else not Lisp.Runtime.If_Immediate_Result_Form (Old_RT, Expr));
         Assert_Frames_Preserved;
         return;
      end if;

      Form2 := Lisp.Store.Car (RT.Store, Tail);
      if Form2 = Lisp.Types.No_Ref then
         Result_Ref := Lisp.Types.No_Ref;
         Error := Lisp.Types.Error_Syntax;
         pragma Assert
           (Fuel <= 1
            or else Old_RT.Known.If_Id = Old_RT.Known.Quote_Id
            or else not Lisp.Runtime.If_Immediate_Result_Form (Old_RT, Expr));
         Assert_Frames_Preserved;
         return;
      end if;

      Tail := Lisp.Store.Cdr (RT.Store, Tail);
      if Tail = Lisp.Types.No_Ref then
         Result_Ref := Lisp.Types.No_Ref;
         Error := Lisp.Types.Error_Syntax;
         pragma Assert
           (Fuel <= 1
            or else Old_RT.Known.If_Id = Old_RT.Known.Quote_Id
            or else not Lisp.Runtime.If_Immediate_Result_Form (Old_RT, Expr));
         Assert_Frames_Preserved;
         return;
      end if;
      if Lisp.Store.Kind_Of (RT.Store, Tail) /= Lisp.Types.Cons_Cell then
         Result_Ref := Lisp.Types.No_Ref;
         Error := Lisp.Types.Error_Arity;
         pragma Assert
           (Fuel <= 1
            or else Old_RT.Known.If_Id = Old_RT.Known.Quote_Id
            or else not Lisp.Runtime.If_Immediate_Result_Form (Old_RT, Expr));
         Assert_Frames_Preserved;
         return;
      end if;

      Form3 := Lisp.Store.Car (RT.Store, Tail);
      if Form3 = Lisp.Types.No_Ref then
         Result_Ref := Lisp.Types.No_Ref;
         Error := Lisp.Types.Error_Syntax;
         pragma Assert
           (Fuel <= 1
            or else Old_RT.Known.If_Id = Old_RT.Known.Quote_Id
            or else not Lisp.Runtime.If_Immediate_Result_Form (Old_RT, Expr));
         Assert_Frames_Preserved;
         return;
      end if;

      Args_List := Lisp.Store.Cdr (RT.Store, Tail);
      if Args_List = Lisp.Types.No_Ref then
         Result_Ref := Lisp.Types.No_Ref;
         Error := Lisp.Types.Error_Syntax;
         pragma Assert
           (Fuel <= 1
            or else Old_RT.Known.If_Id = Old_RT.Known.Quote_Id
            or else not Lisp.Runtime.If_Immediate_Result_Form (Old_RT, Expr));
         Assert_Frames_Preserved;
         return;
      end if;
      if Args_List /= Lisp.Store.Nil_Ref then
         Result_Ref := Lisp.Types.No_Ref;
         Error := Lisp.Types.Error_Arity;
         pragma Assert
           (Fuel <= 1
            or else Old_RT.Known.If_Id = Old_RT.Known.Quote_Id
            or else not Lisp.Runtime.If_Immediate_Result_Form (Old_RT, Expr));
         Assert_Frames_Preserved;
         return;
      end if;

      if Fuel > 1
        and then Old_RT.Known.If_Id /= Old_RT.Known.Quote_Id
        and then Lisp.Runtime.If_Immediate_Result_Form (Old_RT, Expr)
      then
         pragma Assert (Old_RT = RT);
         pragma Assert (Lisp.Runtime.If_Form (Old_RT, Expr));
         pragma Assert (Form1 = Lisp.Runtime.If_Form_Cond (Old_RT, Expr));
         pragma Assert (Form2 = Lisp.Runtime.If_Form_Then (Old_RT, Expr));
         pragma Assert (Form3 = Lisp.Runtime.If_Form_Else (Old_RT, Expr));
         pragma Assert (Lisp.Runtime.Immediate_Result_Form (Old_RT, Form1));
         pragma Assert (Lisp.Runtime.Immediate_Result_Form (Old_RT, Form2));
         pragma Assert (Lisp.Runtime.Immediate_Result_Form (Old_RT, Form3));
      end if;

      Eval (RT, Current_Frame, Form1, Fuel - 1, Operator, Error);
      if Fuel > 1
        and then Old_RT.Known.If_Id /= Old_RT.Known.Quote_Id
        and then Lisp.Runtime.If_Immediate_Result_Form (Old_RT, Expr)
      then
         Assert_Unchanged;
         pragma Assert (Error = Lisp.Types.Error_None);
         pragma Assert (Operator = Lisp.Runtime.Immediate_Result (Old_RT, Form1));
      end if;
      Assert_Frames_Preserved;
      if Error /= Lisp.Types.Error_None then
         Result_Ref := Lisp.Types.No_Ref;
         pragma Assert
           (Fuel <= 1
            or else Old_RT.Known.If_Id = Old_RT.Known.Quote_Id
            or else not Lisp.Runtime.If_Immediate_Result_Form (Old_RT, Expr));
         Assert_Frames_Preserved;
         return;
      end if;

      if Is_Truth (Operator) then
         if Fuel > 1
           and then Old_RT.Known.If_Id /= Old_RT.Known.Quote_Id
           and then Lisp.Runtime.If_Immediate_Result_Form (Old_RT, Expr)
         then
            Assert_Unchanged;
            Result_Ref := Lisp.Runtime.Immediate_Result (Old_RT, Form2);
            Error := Lisp.Types.Error_None;
            pragma Assert (Operator /= Lisp.Store.Nil_Ref);
            pragma Assert (Result_Ref = Lisp.Runtime.Immediate_Result (Old_RT, Form2));
            pragma Assert (Result_Ref = Lisp.Runtime.If_Immediate_Result (Old_RT, Expr));
         else
            Eval (RT, Current_Frame, Form2, Fuel - 1, Result_Ref, Error);
         end if;
         Assert_Frames_Preserved;
      else
         if Fuel > 1
           and then Old_RT.Known.If_Id /= Old_RT.Known.Quote_Id
           and then Lisp.Runtime.If_Immediate_Result_Form (Old_RT, Expr)
         then
            Assert_Unchanged;
            Result_Ref := Lisp.Runtime.Immediate_Result (Old_RT, Form3);
            Error := Lisp.Types.Error_None;
            pragma Assert (Operator = Lisp.Store.Nil_Ref);
            pragma Assert (Result_Ref = Lisp.Runtime.Immediate_Result (Old_RT, Form3));
            pragma Assert (Result_Ref = Lisp.Runtime.If_Immediate_Result (Old_RT, Expr));
         else
            Eval (RT, Current_Frame, Form3, Fuel - 1, Result_Ref, Error);
         end if;
         Assert_Frames_Preserved;
      end if;

      pragma Assert
        ((if Error = Lisp.Types.Error_None then
             Lisp.Store.Is_Valid_Ref (RT.Store, Result_Ref)
          else
             Result_Ref = Lisp.Types.No_Ref));
      pragma Assert
        ((if Fuel > 1
           and then Old_RT.Known.If_Id /= Old_RT.Known.Quote_Id
           and then Lisp.Runtime.If_Immediate_Result_Form (Old_RT, Expr)
          then
             Error = Lisp.Types.Error_None
             and then Result_Ref = Lisp.Runtime.If_Immediate_Result (Old_RT, Expr)
             and then RT = Old_RT
          else
             True));
      Assert_Frames_Preserved;
   end Eval_If_Special;

   procedure Eval
     (RT            : in out Lisp.Runtime.State;
      Current_Frame : in Lisp.Types.Frame_Id;
      Expr          : in Lisp.Types.Cell_Ref;
      Fuel          : in Lisp.Types.Fuel_Count;
      Result_Ref    : out Lisp.Types.Cell_Ref;
      Error         : out Lisp.Types.Error_Code) is
      Head         : Lisp.Types.Cell_Ref;
      Args_List    : Lisp.Types.Cell_Ref;
      Operator     : Lisp.Types.Cell_Ref;
      Arg_Values   : Lisp.Types.Cell_Ref_Array (1 .. Lisp.Config.Max_List_Elements);
      Name_Array   : Lisp.Types.Symbol_Id_Array (1 .. Lisp.Config.Max_Frame_Bindings);
      Arg_Count    : Natural;
      Found        : Boolean;
      New_Frame    : Lisp.Types.Frame_Id;
      Closure_Frame_Id : Lisp.Types.Frame_Id;
      Params       : Lisp.Types.Cell_Ref;
      Body_Expr    : Lisp.Types.Cell_Ref;
      Name_Id      : Lisp.Types.Symbol_Id;
      Form1        : Lisp.Types.Cell_Ref;
      Form2        : Lisp.Types.Cell_Ref;
      Form3        : Lisp.Types.Cell_Ref;
      Tail         : Lisp.Types.Cell_Ref;
      Old_RT       : constant Lisp.Runtime.State := RT;
      Old_Env      : constant Lisp.Env.State := RT.Env;

      procedure Assert_Frames_Preserved with Ghost is
      begin
         pragma Assert (Lisp.Env.Frames_Preserved (Old_Env, RT.Env));
      end Assert_Frames_Preserved;
   begin
      if Fuel = 0 then
         Result_Ref := Lisp.Types.No_Ref;
         Error := Lisp.Types.Error_Out_Of_Fuel;
         Assert_Frames_Preserved;
         return;
      end if;

      case Lisp.Store.Kind_Of (RT.Store, Expr) is
         when Lisp.Types.Nil_Cell | Lisp.Types.True_Cell | Lisp.Types.Integer_Cell
           | Lisp.Types.Primitive_Cell | Lisp.Types.Closure_Cell =>
            Result_Ref := Expr;
            Error := Lisp.Types.Error_None;
            pragma Assert (Lisp.Store.Is_Valid_Ref (RT.Store, Result_Ref));
            pragma Assert
              ((if Lisp.Runtime.Immediate_Result_Form (Old_RT, Expr) then
                   Result_Ref = Lisp.Runtime.Immediate_Result (Old_RT, Expr)
                   and then RT = Old_RT
                else
                   True));
            pragma Assert (not Lisp.Runtime.If_Immediate_Result_Form (Old_RT, Expr));
         when Lisp.Types.Symbol_Cell =>
            Name_Id := Lisp.Store.Symbol_Value (RT.Store, Expr);
            Lisp.Env.Lookup (RT.Env, Current_Frame, Name_Id, Result_Ref, Found);
            if Found and then Lisp.Store.Is_Valid_Ref (RT.Store, Result_Ref) then
               Error := Lisp.Types.Error_None;
            else
               Result_Ref := Lisp.Types.No_Ref;
               Error := Lisp.Types.Error_Unbound_Symbol;
            end if;
            pragma Assert (not Lisp.Runtime.If_Immediate_Result_Form (Old_RT, Expr));
         when Lisp.Types.Cons_Cell =>
            Head := Lisp.Store.Car (RT.Store, Expr);
            Args_List := Lisp.Store.Cdr (RT.Store, Expr);
            if Head = Lisp.Types.No_Ref or else Args_List = Lisp.Types.No_Ref then
               Result_Ref := Lisp.Types.No_Ref;
               Error := Lisp.Types.Error_Syntax;
               Assert_Frames_Preserved;
               return;
            end if;
            if Lisp.Store.Kind_Of (RT.Store, Head) = Lisp.Types.Symbol_Cell then
               Name_Id := Lisp.Store.Symbol_Value (RT.Store, Head);
               if Name_Id = RT.Known.Quote_Id then
                  if Lisp.Store.Kind_Of (RT.Store, Args_List) /= Lisp.Types.Cons_Cell
                  then
                     Result_Ref := Lisp.Types.No_Ref;
                     Error := Lisp.Types.Error_Arity;
                  else
                     Tail := Lisp.Store.Cdr (RT.Store, Args_List);
                     if Tail = Lisp.Types.No_Ref then
                        Result_Ref := Lisp.Types.No_Ref;
                        Error := Lisp.Types.Error_Syntax;
                     elsif Tail /= Lisp.Store.Nil_Ref then
                        Result_Ref := Lisp.Types.No_Ref;
                        Error := Lisp.Types.Error_Arity;
                     else
                        Result_Ref := Lisp.Store.Car (RT.Store, Args_List);
                        if Result_Ref = Lisp.Types.No_Ref then
                           Error := Lisp.Types.Error_Syntax;
                        else
                           pragma Assert (Lisp.Runtime.Quote_Form (RT, Expr));
                           pragma Assert (Result_Ref = Lisp.Runtime.Quote_Form_Result (RT, Expr));
                           pragma Assert (Lisp.Store.Is_Valid_Ref (RT.Store, Result_Ref));
                           Error := Lisp.Types.Error_None;
                        end if;
                     end if;
                  end if;
                  pragma Assert
                    ((if Lisp.Runtime.Quote_Form (RT, Expr) then
                         Error = Lisp.Types.Error_None
                         and then Result_Ref = Lisp.Runtime.Quote_Form_Result (RT, Expr)
                      else
                         True));
                  pragma Assert
                    ((if Error = Lisp.Types.Error_None then
                         Lisp.Store.Is_Valid_Ref (RT.Store, Result_Ref)
                     else
                         Result_Ref = Lisp.Types.No_Ref));
                  pragma Assert
                    ((if Lisp.Runtime.Immediate_Result_Form (Old_RT, Expr) then
                         Error = Lisp.Types.Error_None
                         and then Result_Ref = Lisp.Runtime.Immediate_Result (Old_RT, Expr)
                         and then RT = Old_RT
                      else
                         True));
                  pragma Assert
                    (Old_RT.Known.If_Id = Old_RT.Known.Quote_Id
                     or else not Lisp.Runtime.If_Immediate_Result_Form (Old_RT, Expr));
                  Assert_Frames_Preserved;
                  return;
               elsif Name_Id = RT.Known.If_Id then
                  Eval_If_Special
                    (RT, Current_Frame, Expr, Fuel, Result_Ref, Error);
                  Assert_Frames_Preserved;
                  return;
               elsif Name_Id = RT.Known.Begin_Id then
                  pragma Assert (not Lisp.Runtime.If_Immediate_Result_Form (Old_RT, Expr));
                  Eval_Begin (RT, Current_Frame, Args_List, Fuel - 1, Result_Ref, Error);
                  pragma Assert
                    ((if Error = Lisp.Types.Error_None then
                         Lisp.Store.Is_Valid_Ref (RT.Store, Result_Ref)
                      else
                         Result_Ref = Lisp.Types.No_Ref));
                  Assert_Frames_Preserved;
                  return;
               elsif Name_Id = RT.Known.Lambda_Id then
                  if Lisp.Store.Kind_Of (RT.Store, Args_List) /= Lisp.Types.Cons_Cell then
                     Result_Ref := Lisp.Types.No_Ref;
                     Error := Lisp.Types.Error_Arity;
                     Assert_Frames_Preserved;
                     return;
                  end if;
                  Params := Lisp.Store.Car (RT.Store, Args_List);
                  if Params = Lisp.Types.No_Ref then
                     Result_Ref := Lisp.Types.No_Ref;
                     Error := Lisp.Types.Error_Syntax;
                     Assert_Frames_Preserved;
                     return;
                  end if;
                  Tail := Lisp.Store.Cdr (RT.Store, Args_List);
                  if Tail = Lisp.Types.No_Ref then
                     Result_Ref := Lisp.Types.No_Ref;
                     Error := Lisp.Types.Error_Syntax;
                     Assert_Frames_Preserved;
                     return;
                  end if;
                  if Lisp.Store.Kind_Of (RT.Store, Tail) /= Lisp.Types.Cons_Cell then
                     Result_Ref := Lisp.Types.No_Ref;
                     Error := Lisp.Types.Error_Arity;
                     Assert_Frames_Preserved;
                     return;
                  end if;
                  Body_Expr := Lisp.Store.Car (RT.Store, Tail);
                  if Body_Expr = Lisp.Types.No_Ref then
                     Result_Ref := Lisp.Types.No_Ref;
                     Error := Lisp.Types.Error_Syntax;
                     Assert_Frames_Preserved;
                     return;
                  end if;
                  Form1 := Lisp.Store.Cdr (RT.Store, Tail);
                  if Form1 = Lisp.Types.No_Ref then
                     Result_Ref := Lisp.Types.No_Ref;
                     Error := Lisp.Types.Error_Syntax;
                     Assert_Frames_Preserved;
                     return;
                  end if;
                  if Form1 /= Lisp.Store.Nil_Ref then
                     Result_Ref := Lisp.Types.No_Ref;
                     Error := Lisp.Types.Error_Arity;
                     Assert_Frames_Preserved;
                     return;
                  end if;
                  Params_To_Array (RT, Params, Name_Array, Arg_Count, Error);
                  if Error /= Lisp.Types.Error_None then
                     Result_Ref := Lisp.Types.No_Ref;
                     Assert_Frames_Preserved;
                     return;
                  end if;
                  pragma Assert (Arg_Count <= Name_Array'Length);
                  pragma Assert
                    (Name_Array (Name_Array'First) = Name_Array (Name_Array'First));
                  Lisp.Store.Make_Closure (RT.Store, Params, Body_Expr, Current_Frame, Result_Ref, Error);
                  pragma Assert
                    ((if Error = Lisp.Types.Error_None then
                         Lisp.Store.Is_Valid_Ref (RT.Store, Result_Ref)
                      else
                         Result_Ref = Lisp.Types.No_Ref));
                  Assert_Frames_Preserved;
                  return;
               elsif Name_Id = RT.Known.Define_Id then
                  pragma Assert (not Lisp.Runtime.If_Immediate_Result_Form (Old_RT, Expr));
                  if Current_Frame /= Lisp.Env.Global_Frame then
                     Result_Ref := Lisp.Types.No_Ref;
                     Error := Lisp.Types.Error_Invalid_Define;
                     Assert_Frames_Preserved;
                     return;
                  end if;
                  if Lisp.Store.Kind_Of (RT.Store, Args_List) /= Lisp.Types.Cons_Cell then
                     Result_Ref := Lisp.Types.No_Ref;
                     Error := Lisp.Types.Error_Arity;
                     Assert_Frames_Preserved;
                     return;
                  end if;
                  Form1 := Lisp.Store.Car (RT.Store, Args_List);
                  if Form1 = Lisp.Types.No_Ref then
                     Result_Ref := Lisp.Types.No_Ref;
                     Error := Lisp.Types.Error_Syntax;
                     Assert_Frames_Preserved;
                     return;
                  end if;
                  if Lisp.Store.Kind_Of (RT.Store, Form1) /= Lisp.Types.Symbol_Cell then
                     Result_Ref := Lisp.Types.No_Ref;
                     Error := Lisp.Types.Error_Invalid_Define;
                     Assert_Frames_Preserved;
                     return;
                  end if;
                  Name_Id := Lisp.Store.Symbol_Value (RT.Store, Form1);
                  if Lisp.Runtime.Is_Reserved (RT, Name_Id) then
                     Result_Ref := Lisp.Types.No_Ref;
                     Error := Lisp.Types.Error_Reserved_Name;
                     Assert_Frames_Preserved;
                     return;
                  end if;
                  Tail := Lisp.Store.Cdr (RT.Store, Args_List);
                  if Tail = Lisp.Types.No_Ref then
                     Result_Ref := Lisp.Types.No_Ref;
                     Error := Lisp.Types.Error_Syntax;
                     Assert_Frames_Preserved;
                     return;
                  end if;
                  if Lisp.Store.Kind_Of (RT.Store, Tail) /= Lisp.Types.Cons_Cell then
                     Result_Ref := Lisp.Types.No_Ref;
                     Error := Lisp.Types.Error_Arity;
                     Assert_Frames_Preserved;
                     return;
                  end if;
                  Form2 := Lisp.Store.Car (RT.Store, Tail);
                  if Form2 = Lisp.Types.No_Ref then
                     Result_Ref := Lisp.Types.No_Ref;
                     Error := Lisp.Types.Error_Syntax;
                     Assert_Frames_Preserved;
                     return;
                  end if;
                  Form3 := Lisp.Store.Cdr (RT.Store, Tail);
                  if Form3 = Lisp.Types.No_Ref then
                     Result_Ref := Lisp.Types.No_Ref;
                     Error := Lisp.Types.Error_Syntax;
                     Assert_Frames_Preserved;
                     return;
                  end if;
                  if Form3 /= Lisp.Store.Nil_Ref then
                     Result_Ref := Lisp.Types.No_Ref;
                     Error := Lisp.Types.Error_Arity;
                     Assert_Frames_Preserved;
                     return;
                  end if;
                  Eval (RT, Current_Frame, Form2, Fuel - 1, Operator, Error);
                  Assert_Frames_Preserved;
                  if Error /= Lisp.Types.Error_None then
                     Result_Ref := Lisp.Types.No_Ref;
                     Assert_Frames_Preserved;
                     return;
                  end if;
                  Lisp.Env.Define_Global (RT.Env, Name_Id, Operator, Error);
                  Assert_Frames_Preserved;
                  if Error = Lisp.Types.Error_None then
                     Result_Ref := Form1;
                  else
                     Result_Ref := Lisp.Types.No_Ref;
                  end if;
                  pragma Assert
                    ((if Error = Lisp.Types.Error_None then
                         Lisp.Store.Is_Valid_Ref (RT.Store, Result_Ref)
                      else
                         Result_Ref = Lisp.Types.No_Ref));
                  Assert_Frames_Preserved;
                  return;
               end if;
            end if;

            pragma Assert (not Lisp.Runtime.If_Immediate_Result_Form (Old_RT, Expr));
            Eval (RT, Current_Frame, Head, Fuel - 1, Operator, Error);
            Assert_Frames_Preserved;
            if Error /= Lisp.Types.Error_None then
               Result_Ref := Lisp.Types.No_Ref;
               Assert_Frames_Preserved;
               return;
            end if;
            Eval_List (RT, Current_Frame, Args_List, Fuel - 1, Arg_Values, Arg_Count, Error);
            Assert_Frames_Preserved;
            if Error /= Lisp.Types.Error_None then
               Result_Ref := Lisp.Types.No_Ref;
               Assert_Frames_Preserved;
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
                  Closure_Frame_Id := Lisp.Store.Closure_Frame (RT.Store, Operator);
                  if Params = Lisp.Types.No_Ref
                    or else Body_Expr = Lisp.Types.No_Ref
                    or else not Lisp.Env.Frame_Valid (RT.Env, Closure_Frame_Id)
                  then
                     Result_Ref := Lisp.Types.No_Ref;
                     Error := Lisp.Types.Error_Syntax;
                     Assert_Frames_Preserved;
                     return;
                  end if;
                  declare
                     Param_Count : Natural;
                  begin
                     Params_To_Array (RT, Params, Name_Array, Param_Count, Error);
                     if Error /= Lisp.Types.Error_None then
                        Result_Ref := Lisp.Types.No_Ref;
                        Assert_Frames_Preserved;
                        return;
                     end if;
                     if Param_Count /= Arg_Count then
                        Result_Ref := Lisp.Types.No_Ref;
                        Error := Lisp.Types.Error_Arity;
                        Assert_Frames_Preserved;
                        return;
                     end if;
                     Lisp.Env.Push_Frame
                       (RT.Env,
                        Closure_Frame_Id,
                        Name_Array (1 .. Param_Count),
                        Arg_Values (1 .. Arg_Count),
                        New_Frame,
                        Error);
                     Assert_Frames_Preserved;
                     if Error /= Lisp.Types.Error_None then
                        Result_Ref := Lisp.Types.No_Ref;
                        Assert_Frames_Preserved;
                        return;
                     end if;
                     Eval (RT, New_Frame, Body_Expr, Fuel - 1, Result_Ref, Error);
                     Assert_Frames_Preserved;
                  end;
               when others =>
                  Result_Ref := Lisp.Types.No_Ref;
                  Error := Lisp.Types.Error_Not_Callable;
            end case;
            Assert_Frames_Preserved;
      end case;
      pragma Assert
        ((if Error = Lisp.Types.Error_None then
             Lisp.Store.Is_Valid_Ref (RT.Store, Result_Ref)
          else
             Result_Ref = Lisp.Types.No_Ref));
      Assert_Frames_Preserved;
   end Eval;

   procedure Prove_If_Immediate_Eval
     (RT            : in Lisp.Runtime.State;
      Current_Frame : in Lisp.Types.Frame_Id;
      Expr          : in Lisp.Types.Cell_Ref;
      Fuel          : in Lisp.Types.Fuel_Count;
      Result_Ref    : out Lisp.Types.Cell_Ref;
      Error         : out Lisp.Types.Error_Code) is
      Exec_RT : Lisp.Runtime.State := RT;
      Form1   : constant Lisp.Types.Cell_Ref := Lisp.Runtime.If_Form_Cond (RT, Expr);
      Form2   : constant Lisp.Types.Cell_Ref := Lisp.Runtime.If_Form_Then (RT, Expr);
      Form3   : constant Lisp.Types.Cell_Ref := Lisp.Runtime.If_Form_Else (RT, Expr);
   begin
      pragma Assert (Lisp.Runtime.Immediate_Result_Form (RT, Form1));
      pragma Assert (Lisp.Runtime.Immediate_Result_Form (RT, Form2));
      pragma Assert (Lisp.Runtime.Immediate_Result_Form (RT, Form3));

      Eval_If_Special (Exec_RT, Current_Frame, Expr, Fuel, Result_Ref, Error);

      pragma Assert (Exec_RT = RT);
      pragma Assert (Error = Lisp.Types.Error_None);
      if Lisp.Runtime.Immediate_Result (RT, Form1) /= Lisp.Store.Nil_Ref then
         pragma Assert (Result_Ref = Lisp.Runtime.Immediate_Result (RT, Form2));
      else
         pragma Assert (Result_Ref = Lisp.Runtime.Immediate_Result (RT, Form3));
      end if;
      pragma Assert (Result_Ref = Lisp.Runtime.If_Immediate_Result (RT, Expr));
   end Prove_If_Immediate_Eval;
end Lisp.Eval;
