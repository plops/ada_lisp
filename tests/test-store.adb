with Lisp.Config;
with Lisp.Store;
with Lisp.Types;

procedure Test.Store with SPARK_Mode => Off is
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

   for I in 1 .. Lisp.Config.Max_Cells - 4 loop
      Lisp.Store.Make_Integer (Arena, Lisp.Types.Lisp_Int (I), A, Error);
      pragma Assert (Error = Lisp.Types.Error_None);
   end loop;

   Lisp.Store.Make_Integer (Arena, 0, A, Error);
   pragma Assert (Error = Lisp.Types.Error_Arena_Full);
end Test.Store;
