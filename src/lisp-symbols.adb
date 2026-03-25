package body Lisp.Symbols with SPARK_Mode is
   use type Lisp.Types.Error_Code;

   procedure Initialize (T : in out Table) is
   begin
      T :=
        (Count => 0,
         Slots => (others => (Length => 0, Chars => (others => ' '))));
   end Initialize;

   function Valid (T : Table) return Boolean is
   begin
      return T.Count <= Lisp.Config.Max_Symbols;
   end Valid;

   function Equal_Slice
     (T      : Table;
      Id     : Lisp.Types.Symbol_Id;
      Source : String;
      First  : Positive;
      Last   : Natural) return Boolean is
      Length : constant Natural := (if Last < First then 0 else Last - First + 1);
   begin
      if Id = 0 or else Id > T.Count then
         return False;
      end if;

      if T.Slots (Positive (Id)).Length /= Length then
         return False;
      end if;

      for Offset in 0 .. Length - 1 loop
         if T.Slots (Positive (Id)).Chars (Offset + 1) /= Source (First + Offset) then
            return False;
         end if;
      end loop;

      return True;
   end Equal_Slice;

   procedure Intern
     (T      : in out Table;
      Source : in String;
      First  : in Positive;
      Last   : in Natural;
      Id     : out Lisp.Types.Symbol_Id;
      Error  : out Lisp.Types.Error_Code) is
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
      T.Slots (T.Count).Length := Length;
      for Offset in 0 .. Length - 1 loop
         T.Slots (T.Count).Chars (Offset + 1) := Source (First + Offset);
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
