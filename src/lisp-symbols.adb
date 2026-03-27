package body Lisp.Symbols with SPARK_Mode is
   use type Lisp.Types.Error_Code;
   use type Lisp.Types.Symbol_Id;

   procedure Initialize (T : in out Table) is
   begin
      T :=
        (Count => 0,
         Slots => (others => (Length => 0, Chars => (others => ' '))));
   end Initialize;

   function Interned (T : Table; Id : Lisp.Types.Symbol_Id) return Boolean is
     (Id /= 0 and then Id <= T.Count);

   function Length_Of (T : Table; Id : Lisp.Types.Symbol_Id) return Natural is
     (if not Interned (T, Id) then 0 else T.Slots (Positive (Id)).Length);

   function Char_At
     (T     : Table;
      Id    : Lisp.Types.Symbol_Id;
      Index : Positive) return Character is
     (T.Slots (Positive (Id)).Chars (Index));

   function Entries_Preserved
     (Before : Table;
      After  : Table) return Boolean is
     (After.Count >= Before.Count
      and then
      (for all I in 1 .. Before.Count =>
         After.Slots (I).Length = Before.Slots (I).Length
         and then
         (for all J in 1 .. Before.Slots (I).Length =>
            After.Slots (I).Chars (J) = Before.Slots (I).Chars (J))));

   function Equal_Slice
     (T      : Table;
      Id     : Lisp.Types.Symbol_Id;
      Source : String;
      First  : Positive;
      Last   : Natural) return Boolean is
     (Interned (T, Id)
      and then Length_Of (T, Id) = Last - First + 1
      and then
      (for all Source_Index in First .. Last =>
         Char_At (T, Id, Source_Index - First + 1) = Source (Source_Index)));

   procedure Prove_Equal_Slice_Preserved
     (Before : in Table;
      After  : in Table;
      Id     : in Lisp.Types.Symbol_Id;
     Source : in String;
     First  : in Positive;
     Last   : in Natural) is
   begin
      pragma Assert (Interned (Before, Id));
      pragma Assert (Interned (After, Id));
      pragma Assert (Length_Of (After, Id) = Length_Of (Before, Id));
      pragma Assert (Length_Of (Before, Id) = Last - First + 1);
      pragma Assert (Length_Of (After, Id) = Last - First + 1);

      for Source_Index in First .. Last loop
         pragma Loop_Invariant
           (for all J in First .. Source_Index - 1 =>
              Char_At (After, Id, J - First + 1) = Source (J));
         pragma Assert
           (Char_At (After, Id, Source_Index - First + 1) =
            Char_At (Before, Id, Source_Index - First + 1));
         pragma Assert
           (Char_At (Before, Id, Source_Index - First + 1) =
            Source (Source_Index));
      end loop;

      pragma Assert (Equal_Slice (After, Id, Source, First, Last));
   end Prove_Equal_Slice_Preserved;

   procedure Prove_Quote_If_Distinct
     (T        : in Table;
      Quote_Id : in Lisp.Types.Symbol_Id;
      If_Id    : in Lisp.Types.Symbol_Id) is
   begin
      pragma Assert (Length_Of (T, Quote_Id) = 5);
      pragma Assert (Length_Of (T, If_Id) = 2);
      if Quote_Id = If_Id then
         pragma Assert (Length_Of (T, Quote_Id) = 5);
         pragma Assert (Length_Of (T, Quote_Id) = 2);
      end if;
   end Prove_Quote_If_Distinct;

   procedure Prove_Different_Length_Ids_Distinct
     (T            : in Table;
      Left_Id      : in Lisp.Types.Symbol_Id;
      Left_Length  : in Positive;
      Right_Id     : in Lisp.Types.Symbol_Id;
      Right_Length : in Positive) is
   begin
      pragma Assert (Length_Of (T, Left_Id) = Left_Length);
      pragma Assert (Length_Of (T, Right_Id) = Right_Length);
      if Left_Id = Right_Id then
         pragma Assert (Length_Of (T, Left_Id) = Left_Length);
         pragma Assert (Length_Of (T, Left_Id) = Right_Length);
      end if;
   end Prove_Different_Length_Ids_Distinct;

   procedure Intern
     (T      : in out Table;
      Source : in String;
      First  : in Positive;
      Last   : in Natural;
      Id     : out Lisp.Types.Symbol_Id;
      Error  : out Lisp.Types.Error_Code) is
      Old_T  : constant Table := T;
      Length : constant Natural := (if Last < First then 0 else Last - First + 1);
   begin
      if Length = 0 then
         Id := 0;
         Error := Lisp.Types.Error_Syntax;
         return;
      end if;

      if Length > Lisp.Config.Max_Symbol_Length then
         Id := 0;
         Error := Lisp.Types.Error_Symbol_Too_Long;
         return;
      end if;

      for I in 1 .. T.Count loop
         if Equal_Slice (T, Lisp.Types.Symbol_Id (I), Source, First, Last) then
            Id := Lisp.Types.Symbol_Id (I);
            Error := Lisp.Types.Error_None;
            return;
         end if;
      end loop;

      if T.Count = Lisp.Config.Max_Symbols then
         Id := 0;
         Error := Lisp.Types.Error_Symbol_Table_Full;
         return;
      end if;

      T.Count := T.Count + 1;
      pragma Assert (Entries_Preserved (Old_T, T));
      T.Slots (T.Count).Length := Length;
      pragma Assert (Entries_Preserved (Old_T, T));
      for Source_Index in First .. Last loop
         pragma Loop_Invariant (Entries_Preserved (Old_T, T));
         pragma Loop_Invariant (T.Slots (T.Count).Length = Length);
         pragma Loop_Invariant
           (for all J in First .. Source_Index - 1 =>
              T.Slots (T.Count).Chars (J - First + 1) = Source (J));
         T.Slots (T.Count).Chars (Source_Index - First + 1) := Source (Source_Index);
      end loop;
      Id := Lisp.Types.Symbol_Id (T.Count);
      Error := Lisp.Types.Error_None;
   end Intern;

   procedure Lookup_Image
     (T           : in Table;
      Id          : in Lisp.Types.Symbol_Id;
      Dest_Buffer : in out Lisp.Text_Buffers.Buffer;
      Error       : out Lisp.Types.Error_Code) is
   begin
      if Id = 0 or else Id > T.Count then
         Error := Lisp.Types.Error_Unbound_Symbol;
         return;
      end if;

      for I in 1 .. T.Slots (Positive (Id)).Length loop
         Lisp.Text_Buffers.Append_Char
           (Dest_Buffer, T.Slots (Positive (Id)).Chars (I), Error);
         if Error /= Lisp.Types.Error_None then
            return;
         end if;
      end loop;

      Error := Lisp.Types.Error_None;
   end Lookup_Image;
end Lisp.Symbols;
