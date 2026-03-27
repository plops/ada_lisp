with Lisp.Config;
with Lisp.Env;
with Lisp.Eval;
with Lisp.Model;
with Lisp.Parser;
with Lisp.Runtime;
with Lisp.Store;
with Lisp.Types;

procedure Proof.Refinement with SPARK_Mode is
   use type Lisp.Types.Error_Code;
   use type Lisp.Types.Cell_Kind;

   procedure Prove_Immediate_Form_Refines
     (Initial_RT : Lisp.Runtime.State;
      Expr       : Lisp.Types.Cell_Ref)
   with
     Ghost,
     Pre =>
       Lisp.Runtime.Valid (Initial_RT)
       and then Lisp.Env.Frame_Valid (Initial_RT.Env, Lisp.Env.Global_Frame)
       and then Lisp.Store.Is_Valid_Ref (Initial_RT.Store, Expr)
       and then Lisp.Model.Pure_Subset_Expr (Initial_RT, Expr)
       and then Lisp.Runtime.Immediate_Result_Form (Initial_RT, Expr)
   is
      Model_RT     : Lisp.Runtime.State := Initial_RT;
      Exec_RT      : Lisp.Runtime.State := Initial_RT;
      Model_Result : Lisp.Types.Cell_Ref;
      Exec_Result  : Lisp.Types.Cell_Ref;
      Model_Error  : Lisp.Types.Error_Code;
      Exec_Error   : Lisp.Types.Error_Code;
   begin
      Lisp.Model.Eval_Pure_Closed
        (Model_RT,
         Lisp.Env.Global_Frame,
         Expr,
         Lisp.Config.Max_Fuel,
         Model_Result,
         Model_Error);
      Lisp.Eval.Eval
        (Exec_RT,
         Lisp.Env.Global_Frame,
         Expr,
         Lisp.Config.Max_Fuel,
         Exec_Result,
         Exec_Error);

      pragma Assert (Model_Error = Lisp.Types.Error_None);
      pragma Assert (Exec_Error = Lisp.Types.Error_None);

      case Lisp.Store.Kind_Of (Initial_RT.Store, Expr) is
         when Lisp.Types.Nil_Cell
            | Lisp.Types.True_Cell
            | Lisp.Types.Integer_Cell =>
            pragma Assert (Model_Result = Expr);
            pragma Assert (Exec_Result = Expr);
         when others =>
            pragma Assert (Lisp.Runtime.Quote_Form (Initial_RT, Expr));
            Lisp.Model.Prove_Pure_Subset_Quote_Result (Initial_RT, Expr);
            pragma Assert (Model_Result = Lisp.Runtime.Quote_Form_Result (Initial_RT, Expr));
            pragma Assert (Exec_Result = Lisp.Runtime.Quote_Form_Result (Initial_RT, Expr));
      end case;

      pragma Assert (Model_Result = Exec_Result);
   end Prove_Immediate_Form_Refines;

   procedure Readable_Result_Refines_Model
     (Source : String)
   with
     Ghost
   is
      Model_RT         : Lisp.Runtime.State;
      Initial_RT       : Lisp.Runtime.State;
      Exec_RT          : Lisp.Runtime.State;
      Model_Expr       : Lisp.Types.Cell_Ref;
      Initial_Expr     : Lisp.Types.Cell_Ref;
      Exec_Expr        : Lisp.Types.Cell_Ref;
      Next_Pos         : Natural;
      Model_Result     : Lisp.Types.Cell_Ref;
      Exec_Result      : Lisp.Types.Cell_Ref;
      Model_Error      : Lisp.Types.Error_Code;
      Exec_Error       : Lisp.Types.Error_Code;
      Quoted_Result_Ref : Lisp.Types.Cell_Ref;
   begin
      if Source'Length = 0
        or else Source'First /= 1
        or else Source'Last >= Natural'Last
      then
         return;
      end if;

      Lisp.Runtime.Initialize (Model_RT, Model_Error);
      if Model_Error /= Lisp.Types.Error_None then
         return;
      end if;

      Lisp.Parser.Parse_One (Source, 1, Model_RT, Model_Expr, Next_Pos, Model_Error);
      if Model_Error /= Lisp.Types.Error_None then
         return;
      end if;

      Initial_RT := Model_RT;
      Initial_Expr := Model_Expr;
      Exec_RT := Model_RT;
      Exec_Expr := Model_Expr;
      Exec_Error := Lisp.Types.Error_None;

      if not Lisp.Runtime.Valid (Model_RT)
        or else not Lisp.Runtime.Valid (Exec_RT)
        or else not Lisp.Model.Pure_Subset_Expr (Model_RT, Model_Expr)
      then
         return;
      end if;
      if not Lisp.Env.Frame_Valid (Model_RT.Env, Lisp.Env.Global_Frame)
        or else not Lisp.Env.Frame_Valid (Exec_RT.Env, Lisp.Env.Global_Frame)
        or else not Lisp.Store.Is_Valid_Ref (Model_RT.Store, Model_Expr)
        or else not Lisp.Store.Is_Valid_Ref (Exec_RT.Store, Exec_Expr)
      then
         return;
      end if;

      Lisp.Model.Eval_Pure_Closed
        (Model_RT,
         Lisp.Env.Global_Frame,
         Model_Expr,
         Lisp.Config.Max_Fuel,
         Model_Result,
         Model_Error);
      Lisp.Eval.Eval
        (Exec_RT,
         Lisp.Env.Global_Frame,
         Exec_Expr,
         Lisp.Config.Max_Fuel,
         Exec_Result,
         Exec_Error);

      if Model_Error = Lisp.Types.Error_None then
         pragma Assert (Lisp.Store.Is_Valid_Ref (Model_RT.Store, Model_Result));
         pragma Assert (Lisp.Model.Pure_Data (Model_RT.Store, Model_Result));
         Lisp.Model.Prove_Pure_Data_Readable (Model_RT, Model_Result);
         pragma Assert (Lisp.Model.Readable_Result (Model_RT, Model_Result));
      end if;

      if Exec_Error = Lisp.Types.Error_None then
         pragma Assert (Lisp.Store.Is_Valid_Ref (Exec_RT.Store, Exec_Result));
      end if;

      if Model_Error = Lisp.Types.Error_None
        and then Exec_Error = Lisp.Types.Error_None
      then
         if Lisp.Runtime.Immediate_Result_Form (Initial_RT, Initial_Expr) then
            Prove_Immediate_Form_Refines (Initial_RT, Initial_Expr);
         end if;

         if Lisp.Runtime.Quote_Form (Initial_RT, Initial_Expr) then
            Lisp.Model.Prove_Pure_Subset_Quote_Result (Initial_RT, Initial_Expr);
            Quoted_Result_Ref := Lisp.Runtime.Quote_Form_Result (Initial_RT, Initial_Expr);
            pragma Assert (Model_Result = Quoted_Result_Ref);
            pragma Assert (Exec_Result = Quoted_Result_Ref);
            pragma Assert (Model_Result = Exec_Result);
         else
            case Lisp.Store.Kind_Of (Model_RT.Store, Model_Expr) is
               when Lisp.Types.Nil_Cell
                  | Lisp.Types.True_Cell
                  | Lisp.Types.Integer_Cell =>
                  pragma Assert (Model_Result = Model_Expr);
                  pragma Assert (Exec_Result = Exec_Expr);
                  pragma Assert (Model_Expr = Exec_Expr);
                  pragma Assert (Model_Result = Exec_Result);
               when others =>
                  null;
            end case;
         end if;
      end if;

   end Readable_Result_Refines_Model;
begin
   null;
end Proof.Refinement;
