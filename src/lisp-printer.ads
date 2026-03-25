with Lisp.Runtime;
with Lisp.Store;
with Lisp.Text_Buffers;
with Lisp.Types;

package Lisp.Printer with SPARK_Mode is
   procedure Print
     (RT     : in Lisp.Runtime.State;
      Ref    : in Lisp.Types.Cell_Ref;
      Buffer : in out Lisp.Text_Buffers.Buffer;
      Error  : out Lisp.Types.Error_Code)
   with
     Pre  => Lisp.Runtime.Valid (RT)
       and then Lisp.Text_Buffers.Valid (Buffer)
       and then Lisp.Store.Is_Valid_Ref (RT.Store, Ref),
     Post => Lisp.Runtime.Valid (RT)
       and then Lisp.Text_Buffers.Valid (Buffer);
end Lisp.Printer;
