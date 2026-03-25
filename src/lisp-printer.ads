with Lisp.Runtime;
with Lisp.Text_Buffers;
with Lisp.Types;

package Lisp.Printer with SPARK_Mode is
   procedure Print
     (RT     : in Lisp.Runtime.State;
      Ref    : in Lisp.Types.Cell_Ref;
      Buffer : in out Lisp.Text_Buffers.Buffer;
      Error  : out Lisp.Types.Error_Code);
end Lisp.Printer;
