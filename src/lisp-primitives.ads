with Lisp.Runtime;
with Lisp.Types;

package Lisp.Primitives with SPARK_Mode is
   procedure Apply
     (RT         : in out Lisp.Runtime.State;
      Prim       : in Lisp.Types.Primitive_Kind;
      Args       : in Lisp.Types.Cell_Ref_Array;
      Arg_Count  : in Natural;
      Result_Ref : out Lisp.Types.Cell_Ref;
      Error      : out Lisp.Types.Error_Code)
   with
     Pre => Lisp.Runtime.Valid (RT)
       and then Args'First = 1
       and then Arg_Count <= Args'Length;
end Lisp.Primitives;
