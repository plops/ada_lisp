with Lisp.Env;
with Lisp.Eval;
with Lisp.Model;
with Lisp.Parser;
with Lisp.Runtime;
with Lisp.Types;

procedure Proof.Refinement with SPARK_Mode is
   use type Lisp.Types.Error_Code;

   procedure Readable_Result_Refines_Model
     (Source : String)
   with
     Ghost
   is
      Model_RT     : Lisp.Runtime.State;
      Exec_RT      : Lisp.Runtime.State;
      Expr         : Lisp.Types.Cell_Ref;
      Next_Pos     : Natural;
      Model_Result : Lisp.Types.Cell_Ref;
      Exec_Result  : Lisp.Types.Cell_Ref;
      Model_Error  : Lisp.Types.Error_Code;
      Exec_Error   : Lisp.Types.Error_Code;
   begin
      Lisp.Runtime.Initialize (Model_RT, Model_Error);
      Lisp.Runtime.Initialize (Exec_RT, Exec_Error);
      if Model_Error /= Lisp.Types.Error_None
        or else Exec_Error /= Lisp.Types.Error_None
      then
         return;
      end if;

      Lisp.Parser.Parse_One (Source, Source'First, Model_RT, Expr, Next_Pos, Model_Error);
      Lisp.Parser.Parse_One (Source, Source'First, Exec_RT, Expr, Next_Pos, Exec_Error);
      if Model_Error /= Lisp.Types.Error_None
        or else Exec_Error /= Lisp.Types.Error_None
      then
         return;
      end if;

      if not Lisp.Model.Pure_Subset_Expr (Model_RT, Expr) then
         return;
      end if;

      Lisp.Model.Eval_Pure_Closed
        (Model_RT, Lisp.Env.Global_Frame, Expr, 64, Model_Result, Model_Error);
      Lisp.Eval.Eval
        (Exec_RT, Lisp.Env.Global_Frame, Expr, 64, Exec_Result, Exec_Error);

      pragma Assert (Model_Error = Exec_Error);
      if Exec_Error = Lisp.Types.Error_None
        and then Lisp.Model.Readable_Result (Model_RT, Model_Result)
        and then Lisp.Model.Readable_Result (Exec_RT, Exec_Result)
      then
         pragma Assert
           (Lisp.Model.Same_Readable_Value
              (Model_RT, Model_Result, Exec_RT, Exec_Result));
      end if;
   end Readable_Result_Refines_Model;
begin
   null;
end Proof.Refinement;
