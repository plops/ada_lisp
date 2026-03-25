with Lisp.Printer;
with Lisp.Runtime;
with Lisp.Text_Buffers;
with Lisp.Types;

procedure Test.Printer is
   use type Lisp.Types.Error_Code;
   RT     : Lisp.Runtime.State;
   Buffer : Lisp.Text_Buffers.Buffer;
   Error  : Lisp.Types.Error_Code;
begin
   Lisp.Runtime.Initialize (RT, Error);
   pragma Assert (Error = Lisp.Types.Error_None);
   Lisp.Text_Buffers.Clear (Buffer);
   Lisp.Printer.Print (RT, 1, Buffer, Error);
   pragma Assert (Error = Lisp.Types.Error_None);
   pragma Assert (Lisp.Text_Buffers.Image (Buffer) = "nil");
end Test.Printer;
