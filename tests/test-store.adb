with Lisp.Store;
with Lisp.Types;

procedure Test.Store is
   use type Lisp.Types.Error_Code;
   use type Lisp.Types.Cell_Kind;
   Arena : Lisp.Store.Arena;
   A     : Lisp.Types.Cell_Ref;
   B     : Lisp.Types.Cell_Ref;
   Error : Lisp.Types.Error_Code;
begin
   Lisp.Store.Initialize (Arena);
   Lisp.Store.Make_Integer (Arena, 1, A, Error);
   pragma Assert (Error = Lisp.Types.Error_None);
   Lisp.Store.Make_Cons (Arena, A, Lisp.Store.Nil_Ref, B, Error);
   pragma Assert (Error = Lisp.Types.Error_None);
   pragma Assert (Lisp.Store.Kind_Of (Arena, B) = Lisp.Types.Cons_Cell);
end Test.Store;
