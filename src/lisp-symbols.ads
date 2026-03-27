with Lisp.Config;
with Lisp.Text_Buffers;
with Lisp.Types;

package Lisp.Symbols with SPARK_Mode is
   type Table is private;

   procedure Initialize (T : in out Table) with Post => Valid (T);
   function Valid (T : Table) return Boolean;
   function Interned (T : Table; Id : Lisp.Types.Symbol_Id) return Boolean
   with
     Pre => Valid (T);
   function Length_Of (T : Table; Id : Lisp.Types.Symbol_Id) return Natural
   with
     Pre => Valid (T);
   function Char_At
     (T     : Table;
      Id    : Lisp.Types.Symbol_Id;
      Index : Positive) return Character
   with
     Pre => Valid (T)
       and then Interned (T, Id)
       and then Index <= Length_Of (T, Id);

   function Entries_Preserved
     (Before : Table;
      After  : Table) return Boolean
   with
     Ghost,
     Pre => Valid (Before)
       and then Valid (After);

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
     Post => Valid (T)
       and then Entries_Preserved (T'Old, T)
       and then
       (if Lisp.Types."=" (Error, Lisp.Types.Error_None) then
           Interned (T, Id)
           and then Equal_Slice (T, Id, Source, First, Last)
        else
           Id = 0);

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
       and then Last in First .. Source'Last,
     Post =>
       (if Equal_Slice'Result then
           Interned (T, Id)
           and then Length_Of (T, Id) = Last - First + 1
           and then
           (for all Source_Index in First .. Last =>
              Char_At (T, Id, Source_Index - First + 1) = Source (Source_Index))
        else
           True);

   procedure Prove_Equal_Slice_Preserved
     (Before : in Table;
      After  : in Table;
      Id     : in Lisp.Types.Symbol_Id;
      Source : in String;
      First  : in Positive;
      Last   : in Natural)
   with
     Ghost,
     Pre => Valid (Before)
       and then Valid (After)
       and then Source'First = 1
       and then First in Source'Range
       and then Last in First .. Source'Last
       and then Entries_Preserved (Before, After)
       and then Equal_Slice (Before, Id, Source, First, Last),
     Post => Equal_Slice (After, Id, Source, First, Last);

   procedure Prove_Quote_If_Distinct
     (T        : in Table;
      Quote_Id : in Lisp.Types.Symbol_Id;
      If_Id    : in Lisp.Types.Symbol_Id)
   with
     Ghost,
     Pre => Valid (T)
       and then Equal_Slice (T, Quote_Id, "quote", 1, 5)
       and then Equal_Slice (T, If_Id, "if", 1, 2),
     Post => Quote_Id /= If_Id;

   procedure Prove_Different_Length_Ids_Distinct
     (T           : in Table;
      Left_Id     : in Lisp.Types.Symbol_Id;
      Left_Length : in Positive;
      Right_Id    : in Lisp.Types.Symbol_Id;
      Right_Length : in Positive)
   with
     Ghost,
     Pre => Valid (T)
       and then Interned (T, Left_Id)
       and then Interned (T, Right_Id)
       and then Length_Of (T, Left_Id) = Left_Length
       and then Length_Of (T, Right_Id) = Right_Length
       and then Left_Length /= Right_Length,
     Post => Left_Id /= Right_Id;

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
