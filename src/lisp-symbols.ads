with Lisp.Config;
with Lisp.Text_Buffers;
with Lisp.Types;

package Lisp.Symbols with SPARK_Mode is
   type Table is private;

   procedure Initialize (T : in out Table) with Post => Valid (T);
   function Valid (T : Table) return Boolean;

   procedure Intern
     (T      : in out Table;
      Source : in String;
      First  : in Positive;
      Last   : in Natural;
      Id     : out Lisp.Types.Symbol_Id;
      Error  : out Lisp.Types.Error_Code)
   with
     Pre  => Valid (T)
       and then Source'First = 1
       and then First in Source'Range
       and then Last in First .. Source'Last,
     Post => Valid (T);

   procedure Lookup_Image
     (T           : in Table;
      Id          : in Lisp.Types.Symbol_Id;
      Dest_Buffer : in out Lisp.Text_Buffers.Buffer;
      Error       : out Lisp.Types.Error_Code)
   with
     Pre => Valid (T) and Lisp.Text_Buffers.Valid (Dest_Buffer);

   function Equal_Slice
     (T      : Table;
      Id     : Lisp.Types.Symbol_Id;
      Source : String;
      First  : Positive;
      Last   : Natural) return Boolean
   with
     Pre => Valid (T)
       and then Source'First = 1
       and then First in Source'Range
       and then Last in First .. Source'Last;

private
   subtype Char_Index is Positive range 1 .. Lisp.Config.Max_Symbol_Length;
   type Symbol_Slot is record
      Length : Natural range 0 .. Lisp.Config.Max_Symbol_Length := 0;
      Chars  : Lisp.Types.Char_Buffer (Char_Index) := (others => ' ');
   end record;

   type Slot_Array is array (Positive range 1 .. Lisp.Config.Max_Symbols) of Symbol_Slot;

   type Table is record
      Count : Natural range 0 .. Lisp.Config.Max_Symbols := 0;
      Slots : Slot_Array;
   end record;

   function Valid (T : Table) return Boolean is (T.Count <= Lisp.Config.Max_Symbols);
end Lisp.Symbols;
