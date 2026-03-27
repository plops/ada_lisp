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

   procedure Readable_Result_Refines_Model
     (Source : String)
   with
     Ghost
   is
      Model_RT     : Lisp.Runtime.State;
      Exec_RT      : Lisp.Runtime.State;
      Model_Expr   : Lisp.Types.Cell_Ref;
      Exec_Expr    : Lisp.Types.Cell_Ref;
      Next_Pos     : Natural;
      Model_Result : Lisp.Types.Cell_Ref;
      Exec_Result  : Lisp.Types.Cell_Ref;
      Model_Error  : Lisp.Types.Error_Code;
      Exec_Error   : Lisp.Types.Error_Code;
   begin
      if Source'Length = 0
        or else Source'First /= 1
        or else Source'Last >= Natural'Last
      then
         return;
      end if;

      Lisp.Runtime.Initialize (Model_RT, Model_Error);
      Lisp.Runtime.Initialize (Exec_RT, Exec_Error);
      if Model_Error /= Lisp.Types.Error_None
        or else Exec_Error /= Lisp.Types.Error_None
      then
         return;
      end if;

      Lisp.Parser.Parse_One (Source, 1, Model_RT, Model_Expr, Next_Pos, Model_Error);
      Lisp.Parser.Parse_One (Source, 1, Exec_RT, Exec_Expr, Next_Pos, Exec_Error);
      if Model_Error /= Lisp.Types.Error_None
        or else Exec_Error /= Lisp.Types.Error_None
      then
         return;
      end if;

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
      end if;

      if Exec_Error = Lisp.Types.Error_None then
         pragma Assert (Lisp.Store.Is_Valid_Ref (Exec_RT.Store, Exec_Result));
      end if;
   end Readable_Result_Refines_Model;
begin
   null;
end Proof.Refinement;
