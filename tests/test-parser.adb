with Lisp.Parser;
with Lisp.Runtime;
with Lisp.Store;
with Lisp.Types;

procedure Test.Parser with SPARK_Mode => Off is
   use type Lisp.Types.Error_Code;
   use type Lisp.Types.Cell_Kind;
   RT       : Lisp.Runtime.State;
   Ref      : Lisp.Types.Cell_Ref;
   Next_Pos : Natural;
   Error    : Lisp.Types.Error_Code;
begin
   Lisp.Runtime.Initialize (RT, Error);
   pragma Assert (Error = Lisp.Types.Error_None);
   Lisp.Parser.Parse_One ("'(a b)", 1, RT, Ref, Next_Pos, Error);
   pragma Assert (Error = Lisp.Types.Error_None);
   pragma Assert (Lisp.Store.Kind_Of (RT.Store, Ref) = Lisp.Types.Cons_Cell);
end Test.Parser;
