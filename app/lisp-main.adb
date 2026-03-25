pragma SPARK_Mode (Off);

with Ada.Command_Line;
with Ada.Text_IO;
with Lisp.Driver;
with Lisp.Text_Buffers;
with Lisp.Types;

procedure Lisp.Main is
   use type Lisp.Types.Error_Code;
   Buffer : Lisp.Text_Buffers.Buffer;
   Error  : Lisp.Types.Error_Code := Lisp.Types.Error_None;
begin
   Lisp.Text_Buffers.Clear (Buffer);

   if Ada.Command_Line.Argument_Count /= 1 then
      Ada.Text_IO.Put_Line ("usage: lisp-main '<expr>'");
      Ada.Command_Line.Set_Exit_Status (Ada.Command_Line.Failure);
      return;
   end if;

   Lisp.Driver.Run (Ada.Command_Line.Argument (1), Buffer, Error);
   if Error = Lisp.Types.Error_None then
      Ada.Text_IO.Put_Line (Lisp.Text_Buffers.Image (Buffer));
   else
      Ada.Text_IO.Put_Line ("error: " & Lisp.Types.Error_Code'Image (Error));
      Ada.Command_Line.Set_Exit_Status (Ada.Command_Line.Failure);
   end if;
end Lisp.Main;
