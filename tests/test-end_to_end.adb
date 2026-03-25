with Lisp.Driver;
with Lisp.Text_Buffers;
with Lisp.Types;

procedure Test.End_To_End is
   use type Lisp.Types.Error_Code;
   Buffer : Lisp.Text_Buffers.Buffer;
   Error  : Lisp.Types.Error_Code;

   procedure Expect_Run
     (Source         : String;
      Expected_Error : Lisp.Types.Error_Code;
      Expected_Image : String := "") is
   begin
      Lisp.Text_Buffers.Clear (Buffer);
      Lisp.Driver.Run (Source, Buffer, Error);
      pragma Assert (Error = Expected_Error);
      if Expected_Error = Lisp.Types.Error_None then
         pragma Assert (Lisp.Text_Buffers.Image (Buffer) = Expected_Image);
      end if;
   end Expect_Run;
begin
   Expect_Run
     ("(begin (define fact (lambda (n) (if (<= n 1) 1 (* n (fact (- n 1)))))) (fact 5))",
      Lisp.Types.Error_None,
      "120");
   Expect_Run
     ("(begin (define id (lambda (x) x)) (id 7))",
      Lisp.Types.Error_None,
      "7");
   Expect_Run ("(", Lisp.Types.Error_Syntax);
   Expect_Run ("(+ 1 2) 3", Lisp.Types.Error_Trailing_Input);
   Expect_Run ("missing", Lisp.Types.Error_Unbound_Symbol);
   Expect_Run ("(car 1 2)", Lisp.Types.Error_Arity);
   Expect_Run ("(+ 1 nil)", Lisp.Types.Error_Type);
   Expect_Run ("(define if 1)", Lisp.Types.Error_Reserved_Name);
   Expect_Run ("((lambda (x) (define y x)) 1)", Lisp.Types.Error_Invalid_Define);
   Expect_Run
     ("(begin (define loop (lambda (x) (loop x))) (loop 0))",
      Lisp.Types.Error_Out_Of_Fuel);
end Test.End_To_End;
