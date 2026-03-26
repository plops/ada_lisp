with Lisp.Env;
with Lisp.Runtime;
with Lisp.Store;
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
       and then Arg_Count <= Args'Length
       and then (for all I in 1 .. Arg_Count => Lisp.Store.Is_Valid_Ref (RT.Store, Args (I))),
     Post => Lisp.Runtime.Valid (RT)
       and then Lisp.Store.Cell_Count (RT.Store) >= Lisp.Store.Cell_Count (RT.Store'Old)
       and then Lisp.Env.Frames_Preserved (RT.Env'Old, RT.Env)
       and then
       (if Lisp.Types."=" (Error, Lisp.Types.Error_None) then
           Lisp.Store.Is_Valid_Ref (RT.Store, Result_Ref)
        else
           Result_Ref = Lisp.Types.No_Ref);
end Lisp.Primitives;
