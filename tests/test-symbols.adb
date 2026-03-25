with Lisp.Config;
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

   declare
      Long_Symbol : constant String := (1 .. Lisp.Config.Max_Symbol_Length + 1 => 'x');
   begin
      Lisp.Symbols.Intern
        (Table, Long_Symbol, Long_Symbol'First, Long_Symbol'Last, Id1, Error);
      pragma Assert (Error = Lisp.Types.Error_Symbol_Too_Long);
   end;

   Lisp.Symbols.Initialize (Table);
   for I in 1 .. Lisp.Config.Max_Symbols loop
      declare
         Img  : constant String := Natural'Image (I);
         Name : constant String := "s" & Img (Img'First + 1 .. Img'Last);
      begin
         Lisp.Symbols.Intern (Table, Name, Name'First, Name'Last, Id1, Error);
         pragma Assert (Error = Lisp.Types.Error_None);
      end;
   end loop;

   declare
      Name : constant String := "overflow";
   begin
      Lisp.Symbols.Intern (Table, Name, Name'First, Name'Last, Id1, Error);
      pragma Assert (Error = Lisp.Types.Error_Symbol_Table_Full);
   end;
end Test.Symbols;
