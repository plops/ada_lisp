with Lisp.Symbols;
with Lisp.Text_Buffers;
with Lisp.Types;

procedure Test.Symbols is
   use type Lisp.Types.Error_Code;
   Table  : Lisp.Symbols.Table;
   Id1    : Lisp.Types.Symbol_Id;
   Id2    : Lisp.Types.Symbol_Id;
   Error  : Lisp.Types.Error_Code;
   Buffer : Lisp.Text_Buffers.Buffer;
begin
   Lisp.Symbols.Initialize (Table);
   Lisp.Symbols.Intern (Table, "foo", 1, 3, Id1, Error);
   pragma Assert (Error = Lisp.Types.Error_None);
   Lisp.Symbols.Intern (Table, "foo", 1, 3, Id2, Error);
   pragma Assert (Error = Lisp.Types.Error_None);
   pragma Assert (Id1 = Id2);

   Lisp.Text_Buffers.Clear (Buffer);
   Lisp.Symbols.Lookup_Image (Table, Id1, Buffer, Error);
   pragma Assert (Error = Lisp.Types.Error_None);
   pragma Assert (Lisp.Text_Buffers.Image (Buffer) = "foo");
end Test.Symbols;
