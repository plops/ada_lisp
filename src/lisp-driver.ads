with Lisp.Text_Buffers;
with Lisp.Types;

package Lisp.Driver with SPARK_Mode is
   procedure Run
     (Source : in String;
      Buffer : in out Lisp.Text_Buffers.Buffer;
      Error  : out Lisp.Types.Error_Code)
   with
     Pre => Lisp.Text_Buffers.Valid (Buffer);
end Lisp.Driver;
