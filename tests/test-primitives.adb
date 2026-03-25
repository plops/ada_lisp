with Lisp.Primitives;
with Lisp.Runtime;
with Lisp.Store;
with Lisp.Types;

procedure Test.Primitives is
   use type Lisp.Types.Error_Code;
   RT     : Lisp.Runtime.State;
   A      : Lisp.Types.Cell_Ref;
   B      : Lisp.Types.Cell_Ref;
   Args   : Lisp.Types.Cell_Ref_Array (1 .. 2);
   Result : Lisp.Types.Cell_Ref;
   Error  : Lisp.Types.Error_Code;
begin
   Lisp.Runtime.Initialize (RT, Error);
   pragma Assert (Error = Lisp.Types.Error_None);
   Lisp.Store.Make_Integer (RT.Store, 1, A, Error);
   Lisp.Store.Make_Integer (RT.Store, 2, B, Error);
   Args := (1 => A, 2 => B);
   Lisp.Primitives.Apply (RT, Lisp.Types.Prim_Add, Args, 2, Result, Error);
   pragma Assert (Error = Lisp.Types.Error_None);
   pragma Assert (Lisp.Store.Integer_Value (RT.Store, Result) = 3);
end Test.Primitives;
