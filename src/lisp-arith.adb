with Lisp.Config;

package body Lisp.Arith with SPARK_Mode is
   function Can_Add (Left, Right : Lisp.Types.Lisp_Int) return Boolean is
   begin
      if Right > 0 then
         return Left <= Lisp.Config.Max_Int - Right;
      elsif Right < 0 then
         return Left >= Lisp.Config.Min_Int - Right;
      else
         return True;
      end if;
   end Can_Add;

   function Can_Sub (Left, Right : Lisp.Types.Lisp_Int) return Boolean is
   begin
      if Right = Lisp.Config.Min_Int then
         return False;
      end if;

      return Can_Add (Left, -Right);
   end Can_Sub;

   function Can_Mul (Left, Right : Lisp.Types.Lisp_Int) return Boolean is
      Product : constant Long_Long_Integer :=
        Long_Long_Integer (Left) * Long_Long_Integer (Right);
   begin
      return Product >= Long_Long_Integer (Lisp.Config.Min_Int)
        and Product <= Long_Long_Integer (Lisp.Config.Max_Int);
   end Can_Mul;

   procedure Try_Add
     (Left, Right : in Lisp.Types.Lisp_Int;
      Value       : out Lisp.Types.Lisp_Int;
      Error       : out Lisp.Types.Error_Code) is
      Sum : constant Long_Long_Integer :=
        Long_Long_Integer (Left) + Long_Long_Integer (Right);
   begin
      if Sum >= Long_Long_Integer (Lisp.Config.Min_Int)
        and then Sum <= Long_Long_Integer (Lisp.Config.Max_Int)
      then
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
      if Difference >= Long_Long_Integer (Lisp.Config.Min_Int)
        and then Difference <= Long_Long_Integer (Lisp.Config.Max_Int)
      then
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
      if Product >= Long_Long_Integer (Lisp.Config.Min_Int)
        and then Product <= Long_Long_Integer (Lisp.Config.Max_Int)
      then
         Value := Lisp.Types.Lisp_Int (Product);
         Error := Lisp.Types.Error_None;
      else
         Value := 0;
         Error := Lisp.Types.Error_Integer_Overflow;
      end if;
   end Try_Mul;
end Lisp.Arith;
