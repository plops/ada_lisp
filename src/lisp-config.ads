package Lisp.Config with SPARK_Mode is
   Max_Symbols        : constant := 128;
   Max_Symbol_Length  : constant := 32;
   Max_Cells          : constant := 4096;
   Max_Frames         : constant := 512;
   Max_Frame_Bindings : constant := 32;
   Max_List_Elements  : constant := 128;
   Max_Output_Length  : constant := 4096;
   Max_Fuel           : constant := 4096;
   Min_Int            : constant := -1_000_000_000;
   Max_Int            : constant :=  1_000_000_000;
end Lisp.Config;
