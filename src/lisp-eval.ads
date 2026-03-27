with Lisp.Runtime;
with Lisp.Env;
with Lisp.Store;
with Lisp.Types;

package Lisp.Eval with SPARK_Mode is
   use type Lisp.Types.Cell_Kind;
   use type Lisp.Runtime.State;

   procedure Eval
     (RT            : in out Lisp.Runtime.State;
      Current_Frame : in Lisp.Types.Frame_Id;
      Expr          : in Lisp.Types.Cell_Ref;
      Fuel          : in Lisp.Types.Fuel_Count;
      Result_Ref    : out Lisp.Types.Cell_Ref;
     Error         : out Lisp.Types.Error_Code)
   with
     Pre => Lisp.Runtime.Valid (RT)
       and then Lisp.Env.Frame_Valid (RT.Env, Current_Frame)
       and then Lisp.Store.Is_Valid_Ref (RT.Store, Expr),
     Post => Lisp.Runtime.Valid (RT)
       and then Lisp.Store.Cell_Count (RT.Store) >= Lisp.Store.Cell_Count (RT.Store'Old)
       and then Lisp.Env.Frames_Preserved (RT.Env'Old, RT.Env)
       and then
       (if Lisp.Types."=" (Error, Lisp.Types.Error_None) then
           Lisp.Store.Is_Valid_Ref (RT.Store, Result_Ref)
        else
           Result_Ref = Lisp.Types.No_Ref)
       and then
       (if Fuel > 0
         and then
         (Lisp.Store.Kind_Of (RT.Store'Old, Expr) = Lisp.Types.Nil_Cell
          or else Lisp.Store.Kind_Of (RT.Store'Old, Expr) = Lisp.Types.True_Cell
          or else Lisp.Store.Kind_Of (RT.Store'Old, Expr) = Lisp.Types.Integer_Cell)
        then
           Lisp.Types."=" (Error, Lisp.Types.Error_None)
           and then Result_Ref = Expr
        else
           True)
       and then
       (if Fuel > 0
         and then Lisp.Runtime.Quote_Form (RT'Old, Expr)
        then
           Lisp.Types."=" (Error, Lisp.Types.Error_None)
           and then Result_Ref = Lisp.Runtime.Quote_Form_Result (RT'Old, Expr)
        else
           True)
       and then
       (if Fuel > 0
         and then Lisp.Runtime.Immediate_Result_Form (RT'Old, Expr)
        then
           Lisp.Types."=" (Error, Lisp.Types.Error_None)
           and then Result_Ref = Lisp.Runtime.Immediate_Result (RT'Old, Expr)
           and then RT = RT'Old
        else
           True)
       ,
     Subprogram_Variant => (Decreases => Fuel, Decreases => 1);

   procedure Prove_If_Immediate_Eval
     (RT            : in Lisp.Runtime.State;
      Current_Frame : in Lisp.Types.Frame_Id;
      Expr          : in Lisp.Types.Cell_Ref;
      Fuel          : in Lisp.Types.Fuel_Count;
      Result_Ref    : out Lisp.Types.Cell_Ref;
      Error         : out Lisp.Types.Error_Code)
   with
     Ghost,
     Pre => Lisp.Runtime.Valid (RT)
       and then Lisp.Env.Frame_Valid (RT.Env, Current_Frame)
       and then Lisp.Store.Is_Valid_Ref (RT.Store, Expr)
       and then Fuel > 1
       and then Lisp.Runtime.Quote_If_Known (RT)
       and then Lisp.Runtime.If_Immediate_Result_Form (RT, Expr),
     Post => Lisp.Types."=" (Error, Lisp.Types.Error_None)
       and then Result_Ref = Lisp.Runtime.If_Immediate_Result (RT, Expr);

   procedure Prove_Begin_Single_Immediate_Eval
     (RT            : in Lisp.Runtime.State;
      Current_Frame : in Lisp.Types.Frame_Id;
      Expr          : in Lisp.Types.Cell_Ref;
      Fuel          : in Lisp.Types.Fuel_Count;
      Result_Ref    : out Lisp.Types.Cell_Ref;
      Error         : out Lisp.Types.Error_Code)
   with
     Ghost,
     Pre => Lisp.Runtime.Valid (RT)
       and then Lisp.Env.Frame_Valid (RT.Env, Current_Frame)
       and then Lisp.Store.Is_Valid_Ref (RT.Store, Expr)
       and then Fuel > 2
       and then Lisp.Runtime.Quote_If_Begin_Known (RT)
       and then Lisp.Runtime.Begin_Single_Immediate_Result_Form (RT, Expr),
     Post => Lisp.Types."=" (Error, Lisp.Types.Error_None)
       and then Result_Ref = Lisp.Runtime.Begin_Single_Immediate_Result (RT, Expr);
end Lisp.Eval;
