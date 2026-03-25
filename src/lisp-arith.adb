with Lisp.Config;

package body Lisp.Arith with SPARK_Mode is
   procedure Try_Add
     (Left, Right : in Lisp.Types.Lisp_Int;
      Value       : out Lisp.Types.Lisp_Int;
      Error       : out Lisp.Types.Error_Code) is
      Sum : constant Long_Long_Integer :=
        Long_Long_Integer (Left) + Long_Long_Integer (Right);
   begin
      if Can_Add (Left, Right) then
         Value := Lisp.Types.Lisp_Int (Sum);
         Error := Lisp.Types.Error_None;
      else
         Value := 0;
         Error := Lisp.Types.Error_Integer_Overflow;
      end if;
   end Try_Add;

   procedure Try_Sub
     (Left, Right : in Lisp.Types.Lisp_Int;
      Value       : out Lisp.Types.Lisp_Int;
      Error       : out Lisp.Types.Error_Code) is
      Difference : constant Long_Long_Integer :=
        Long_Long_Integer (Left) - Long_Long_Integer (Right);
   begin
      if Can_Sub (Left, Right) then
         Value := Lisp.Types.Lisp_Int (Difference);
         Error := Lisp.Types.Error_None;
      else
         Value := 0;
         Error := Lisp.Types.Error_Integer_Overflow;
      end if;
   end Try_Sub;

   procedure Try_Mul
     (Left, Right : in Lisp.Types.Lisp_Int;
      Value       : out Lisp.Types.Lisp_Int;
      Error       : out Lisp.Types.Error_Code) is
      Product : constant Long_Long_Integer :=
        Long_Long_Integer (Left) * Long_Long_Integer (Right);
   begin
      if Can_Mul (Left, Right) then
         Value := Lisp.Types.Lisp_Int (Product);
         Error := Lisp.Types.Error_None;
      else
         Value := 0;
         Error := Lisp.Types.Error_Integer_Overflow;
      end if;
   end Try_Mul;
end Lisp.Arith;
