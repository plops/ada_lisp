with Lisp.Config;
with Lisp.Types;

package Lisp.Arith with SPARK_Mode is
   function Can_Add (Left, Right : Lisp.Types.Lisp_Int) return Boolean is
     (if Right > 0 then Left <= Lisp.Config.Max_Int - Right
      elsif Right < 0 then Left >= Lisp.Config.Min_Int - Right
      else True);

   function Can_Sub (Left, Right : Lisp.Types.Lisp_Int) return Boolean is
     (Right /= Lisp.Config.Min_Int and then Can_Add (Left, -Right));

   function Can_Mul (Left, Right : Lisp.Types.Lisp_Int) return Boolean is
     (Long_Long_Integer (Left) * Long_Long_Integer (Right) >= Long_Long_Integer (Lisp.Config.Min_Int)
      and then
      Long_Long_Integer (Left) * Long_Long_Integer (Right) <= Long_Long_Integer (Lisp.Config.Max_Int));

   procedure Try_Add
     (Left, Right : in Lisp.Types.Lisp_Int;
      Value       : out Lisp.Types.Lisp_Int;
     Error       : out Lisp.Types.Error_Code)
   with
     Post =>
       (if Can_Add (Left, Right) then
           Lisp.Types."=" (Error, Lisp.Types.Error_None) and then Value = Left + Right
        else
           Lisp.Types."=" (Error, Lisp.Types.Error_Integer_Overflow));

   procedure Try_Sub
     (Left, Right : in Lisp.Types.Lisp_Int;
      Value       : out Lisp.Types.Lisp_Int;
     Error       : out Lisp.Types.Error_Code)
   with
     Post =>
       (if Can_Sub (Left, Right) then
           Lisp.Types."=" (Error, Lisp.Types.Error_None) and then Value = Left - Right
        else
           Lisp.Types."=" (Error, Lisp.Types.Error_Integer_Overflow));

   procedure Try_Mul
     (Left, Right : in Lisp.Types.Lisp_Int;
      Value       : out Lisp.Types.Lisp_Int;
     Error       : out Lisp.Types.Error_Code)
   with
     Post =>
       (if Can_Mul (Left, Right) then
           Lisp.Types."=" (Error, Lisp.Types.Error_None) and then Value = Left * Right
        else
           Lisp.Types."=" (Error, Lisp.Types.Error_Integer_Overflow));
end Lisp.Arith;
