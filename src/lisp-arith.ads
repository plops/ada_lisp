with Lisp.Types;

package Lisp.Arith with SPARK_Mode is
   function Can_Add (Left, Right : Lisp.Types.Lisp_Int) return Boolean;
   function Can_Sub (Left, Right : Lisp.Types.Lisp_Int) return Boolean;
   function Can_Mul (Left, Right : Lisp.Types.Lisp_Int) return Boolean;

   procedure Try_Add
     (Left, Right : in Lisp.Types.Lisp_Int;
      Value       : out Lisp.Types.Lisp_Int;
      Error       : out Lisp.Types.Error_Code);

   procedure Try_Sub
     (Left, Right : in Lisp.Types.Lisp_Int;
      Value       : out Lisp.Types.Lisp_Int;
      Error       : out Lisp.Types.Error_Code);

   procedure Try_Mul
     (Left, Right : in Lisp.Types.Lisp_Int;
      Value       : out Lisp.Types.Lisp_Int;
      Error       : out Lisp.Types.Error_Code);
end Lisp.Arith;
