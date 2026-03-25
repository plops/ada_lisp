with Lisp.Eval;
with Lisp.Parser;
with Lisp.Runtime;
with Lisp.Types;

procedure Test.Eval_Core with SPARK_Mode => Off is
   use type Lisp.Types.Error_Code;
   RT       : Lisp.Runtime.State;
   Expr     : Lisp.Types.Cell_Ref;
   Result   : Lisp.Types.Cell_Ref;
   Next_Pos : Natural;
   Error    : Lisp.Types.Error_Code;
begin
   Lisp.Runtime.Initialize (RT, Error);
   pragma Assert (Error = Lisp.Types.Error_None);
   Lisp.Parser.Parse_One ("(+ 1 2)", 1, RT, Expr, Next_Pos, Error);
   pragma Assert (Error = Lisp.Types.Error_None);
   Lisp.Eval.Eval (RT, 1, Expr, 100, Result, Error);
   pragma Assert (Error = Lisp.Types.Error_None);
end Test.Eval_Core;
