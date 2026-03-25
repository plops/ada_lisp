with Lisp.Driver;
with Lisp.Text_Buffers;
with Lisp.Types;

procedure Test.End_To_End is
   use type Lisp.Types.Error_Code;
   Buffer : Lisp.Text_Buffers.Buffer;
   Error  : Lisp.Types.Error_Code;
begin
   Lisp.Text_Buffers.Clear (Buffer);
   Lisp.Driver.Run ("(begin (define fact (lambda (n) (if (<= n 1) 1 (* n (fact (- n 1)))))) (fact 5))", Buffer, Error);
   pragma Assert (Error = Lisp.Types.Error_None);
   pragma Assert (Lisp.Text_Buffers.Image (Buffer) = "120");
end Test.End_To_End;
