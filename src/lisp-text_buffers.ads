with Lisp.Config;
with Lisp.Types;

package Lisp.Text_Buffers with SPARK_Mode is
   type Buffer is private;

   function Valid (B : Buffer) return Boolean;
   procedure Clear (B : in out Buffer) with Post => Valid (B);
   function Length (B : Buffer) return Natural;
   function Remaining (B : Buffer) return Natural;
   function Image (B : Buffer) return String;

   procedure Append_Char
     (B     : in out Buffer;
      C     : in Character;
      Error : out Lisp.Types.Error_Code)
   with
     Pre  => Valid (B),
     Post => Valid (B);

   procedure Append_String
     (B     : in out Buffer;
      S     : in String;
      Error : out Lisp.Types.Error_Code)
   with
     Pre  => Valid (B),
     Post => Valid (B);

private
   subtype Buffer_Index is Positive range 1 .. Lisp.Config.Max_Output_Length;
   type Storage_Array is array (Buffer_Index) of Character;

   type Buffer is record
      Count : Natural range 0 .. Lisp.Config.Max_Output_Length := 0;
      Data  : Storage_Array := (others => ' ');
   end record;

   function Valid (B : Buffer) return Boolean is (B.Count <= Lisp.Config.Max_Output_Length);
end Lisp.Text_Buffers;
