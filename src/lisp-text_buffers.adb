package body Lisp.Text_Buffers with SPARK_Mode is
   use type Lisp.Types.Error_Code;

   procedure Clear (B : in out Buffer) is
   begin
      B.Count := 0;
   end Clear;

   function Length (B : Buffer) return Natural is (B.Count);

   function Remaining (B : Buffer) return Natural is
     (Lisp.Config.Max_Output_Length - B.Count);

   function Image (B : Buffer) return String is
   begin
      if B.Count = 0 then
         return "";
      else
         declare
            Result : String (1 .. B.Count);
         begin
            for I in 1 .. B.Count loop
               Result (I) := B.Data (I);
            end loop;
            return Result;
         end;
      end if;
   end Image;

   procedure Append_Char
     (B     : in out Buffer;
      C     : in Character;
      Error : out Lisp.Types.Error_Code) is
   begin
      if B.Count = Lisp.Config.Max_Output_Length then
         Error := Lisp.Types.Error_Buffer_Full;
         return;
      end if;

      B.Count := B.Count + 1;
      B.Data (B.Count) := C;
      Error := Lisp.Types.Error_None;
   end Append_Char;

   procedure Append_String
     (B     : in out Buffer;
      S     : in String;
      Error : out Lisp.Types.Error_Code) is
      Local_Error : Lisp.Types.Error_Code := Lisp.Types.Error_None;
   begin
      for C of S loop
         Append_Char (B, C, Local_Error);
         if Local_Error /= Lisp.Types.Error_None then
            Error := Local_Error;
            return;
         end if;
      end loop;

      Error := Lisp.Types.Error_None;
   end Append_String;
end Lisp.Text_Buffers;
