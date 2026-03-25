with Lisp.Config;
with Lisp.Printer;
with Lisp.Runtime;
with Lisp.Text_Buffers;
with Lisp.Types;

procedure Test.Printer with SPARK_Mode => Off is
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

   Lisp.Text_Buffers.Clear (Buffer);
   for I in 1 .. Lisp.Config.Max_Output_Length loop
      Lisp.Text_Buffers.Append_Char (Buffer, 'x', Error);
      pragma Assert (Error = Lisp.Types.Error_None);
   end loop;
   Lisp.Text_Buffers.Append_Char (Buffer, 'y', Error);
   pragma Assert (Error = Lisp.Types.Error_Buffer_Full);
end Test.Printer;
