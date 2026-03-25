with Lisp.Driver;
with Lisp.Text_Buffers;
with Lisp.Types;

procedure Test.Eval_Closure with SPARK_Mode => Off is
   use type Lisp.Types.Error_Code;
   Buffer : Lisp.Text_Buffers.Buffer;
   Error  : Lisp.Types.Error_Code;
begin
   Lisp.Text_Buffers.Clear (Buffer);
   Lisp.Driver.Run ("((lambda (x) x) 7)", Buffer, Error);
   pragma Assert (Error = Lisp.Types.Error_None);
   pragma Assert (Lisp.Text_Buffers.Image (Buffer) = "7");
end Test.Eval_Closure;
