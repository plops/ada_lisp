with Interfaces;
with Lisp.Config;

package Lisp.Types with SPARK_Mode is
   subtype Lisp_Int is Integer range Lisp.Config.Min_Int .. Lisp.Config.Max_Int;

   subtype Cell_Ref   is Natural range 0 .. Lisp.Config.Max_Cells;
   subtype Frame_Id   is Natural range 0 .. Lisp.Config.Max_Frames;
   subtype Symbol_Id  is Natural range 0 .. Lisp.Config.Max_Symbols;
   subtype Fuel_Count is Natural range 0 .. Lisp.Config.Max_Fuel;

   No_Ref   : constant Cell_Ref := 0;
   No_Frame : constant Frame_Id := 0;

   type Cell_Kind is
     (Nil_Cell,
      True_Cell,
      Integer_Cell,
      Symbol_Cell,
      Cons_Cell,
      Primitive_Cell,
      Closure_Cell);

   type Primitive_Kind is
     (Prim_Atom,
      Prim_Eq,
      Prim_Cons,
      Prim_Car,
      Prim_Cdr,
      Prim_Null,
      Prim_Add,
      Prim_Sub,
      Prim_Mul,
      Prim_Lt,
      Prim_Le);

   type Error_Code is
     (Error_None,
      Error_Syntax,
      Error_Unbound_Symbol,
      Error_Arity,
      Error_Type,
      Error_Not_Callable,
      Error_Out_Of_Fuel,
      Error_Integer_Overflow,
      Error_Symbol_Too_Long,
      Error_Symbol_Table_Full,
      Error_Arena_Full,
      Error_Frame_Full,
      Error_Buffer_Full,
      Error_Reserved_Name,
      Error_Invalid_Define,
      Error_Invalid_Parameter_List,
      Error_Unexpected_Token,
      Error_Trailing_Input);

   subtype Cell_Index is Positive range 1 .. Lisp.Config.Max_Cells;
   type Cell_Ref_Array is array (Positive range <>) of Cell_Ref;
   type Symbol_Id_Array is array (Positive range <>) of Symbol_Id;
   type Char_Buffer is array (Positive range <>) of Character;

   type Error_Result is record
      Code : Error_Code := Error_None;
   end record;

   function Success (Error : Error_Code) return Boolean is (Error = Error_None);
end Lisp.Types;
