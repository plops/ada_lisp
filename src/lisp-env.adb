package body Lisp.Env with SPARK_Mode is
   use type Lisp.Types.Error_Code;

   function Name_Not_In_Frame
     (Frame_State : Frame_Record;
      Name        : Lisp.Types.Symbol_Id) return Boolean is
     (for all J in 1 .. Frame_State.Count => Frame_State.Names (J) /= Name);

   function Name_Not_In_Global
     (Env_State : State;
      Name      : Lisp.Types.Symbol_Id) return Boolean is
     (Name_Not_In_Frame (Env_State.Frames (1), Name));

   function Non_Global_Frames_Preserved
     (Old_State : State;
      New_State : State) return Boolean is
     (New_State.Next_Free = Old_State.Next_Free
      and then
      (for all F in 2 .. Old_State.Next_Free - 1 => New_State.Frames (F) = Old_State.Frames (F)));

   procedure Prove_Define_Global_Preserves_Valid
     (Old_State : in State;
      New_State : in State)
   with
     Ghost,
     Pre =>
       Valid (Old_State)
       and then Non_Global_Frames_Preserved (Old_State, New_State)
       and then New_State.Frames (1).Parent = Lisp.Types.No_Frame
       and then Frame_Names_Unique (New_State, 1),
     Post => Valid (New_State);

   procedure Prove_Global_Unique_After_Append
     (Old_State : in State;
      New_State : in State;
      Name      : in Lisp.Types.Symbol_Id)
   with
     Ghost,
     Pre =>
       Valid (Old_State)
       and then Name_Not_In_Global (Old_State, Name)
       and then New_State.Next_Free = Old_State.Next_Free
       and then New_State.Frames (1).Parent = Lisp.Types.No_Frame
       and then New_State.Frames (1).Count = Old_State.Frames (1).Count + 1
       and then (for all I in 1 .. Old_State.Frames (1).Count =>
                   New_State.Frames (1).Names (I) = Old_State.Frames (1).Names (I))
      and then New_State.Frames (1).Names (New_State.Frames (1).Count) = Name,
     Post => Frame_Names_Unique (New_State, 1);

   procedure Prove_Valid_Frame
     (Env_State : in State;
      Frame     : in Positive)
   with
     Ghost,
     Pre =>
       Valid (Env_State)
       and then Frame in 1 .. Env_State.Next_Free - 1,
     Post =>
       Frame_Names_Unique (Env_State.Frames (Frame))
       and then
       (if Frame = 1 then
           Env_State.Frames (Frame).Parent = Lisp.Types.No_Frame
        else
           Frame_Parent_Valid (Env_State, Frame));

   procedure Prove_Frame_Names_Preserved
     (Old_State : in State;
      New_State : in State;
      Frame     : in Positive)
   with
     Ghost,
     Pre =>
       Frame in 1 .. Old_State.Next_Free - 1
       and then Frame_Names_Unique (Old_State, Frame)
       and then New_State.Frames (Frame).Count = Old_State.Frames (Frame).Count
       and then (for all I in 1 .. Old_State.Frames (Frame).Count =>
                   New_State.Frames (Frame).Names (I) = Old_State.Frames (Frame).Names (I)),
     Post => Frame_Names_Unique (New_State, Frame);

   procedure Prove_Appended_Frame_Names_Unique
     (Old_State : in State;
      New_State : in State;
      Frame     : in Positive;
      Name      : in Lisp.Types.Symbol_Id)
   with
     Ghost,
     Pre =>
       Frame in 1 .. Old_State.Next_Free - 1
       and then Frame_Names_Unique (Old_State, Frame)
       and then Name_Not_In_Frame (Old_State.Frames (Frame), Name)
       and then New_State.Frames (Frame).Count = Old_State.Frames (Frame).Count + 1
       and then (for all I in 1 .. Old_State.Frames (Frame).Count =>
                   New_State.Frames (Frame).Names (I) = Old_State.Frames (Frame).Names (I))
       and then New_State.Frames (Frame).Names (New_State.Frames (Frame).Count) = Name,
     Post => Frame_Names_Unique (New_State, Frame);

   procedure Prove_Frame_Binding_Unique
     (Env_State : in State;
      Frame     : in Positive;
      Index     : in Positive)
   with
     Ghost,
     Pre =>
       Frame in 1 .. Env_State.Next_Free - 1
       and then Index <= Env_State.Frames (Frame).Count
       and then Frame_Names_Unique (Env_State, Frame),
     Post => Binding_Name_Unique (Env_State, Frame, Index);

   function Old_Frames_Preserved
     (Old_State : State;
      New_State : State;
      New_Frame : Positive) return Boolean is
     (New_Frame = Old_State.Next_Free
      and then New_State.Next_Free = New_Frame + 1
      and then
      (for all F in 1 .. New_Frame - 1 => New_State.Frames (F) = Old_State.Frames (F)));

   procedure Prove_Push_Frame_Preserves_Valid
     (Old_State : in State;
      New_State : in State;
      New_Frame : in Positive)
   with
     Ghost,
     Pre =>
       Valid (Old_State)
       and then Old_Frames_Preserved (Old_State, New_State, New_Frame)
       and then Frame_Parent_Valid (New_State, New_Frame)
       and then Frame_Names_Unique (New_State, New_Frame),
     Post => Valid (New_State);

   procedure Prove_Copied_Frame_Unique
     (Env_State : in State;
      Frame     : in Positive;
      Names     : in Lisp.Types.Symbol_Id_Array)
   with
     Ghost,
     Pre =>
       Frame in 1 .. Lisp.Config.Max_Frames
       and then Names'First = 1
      and then Names_Unique (Names)
      and then Env_State.Frames (Frame).Count = Names'Length
      and then (for all I in Names'Range => Env_State.Frames (Frame).Names (I) = Names (I)),
     Post => Frame_Names_Unique (Env_State, Frame);

   procedure Prove_Frame_Unique_From_Names
     (Env_State : in State;
      Frame     : in Positive;
      Names     : in Lisp.Types.Symbol_Id_Array)
   with
     Ghost,
     Pre =>
       Frame in 1 .. Lisp.Config.Max_Frames
       and then Names'First = 1
       and then Names_Unique (Names)
       and then Env_State.Frames (Frame).Count = Names'Length
       and then (for all I in Names'Range => Env_State.Frames (Frame).Names (I) = Names (I)),
     Post => Frame_Names_Unique (Env_State, Frame);

   procedure Prove_Names_Binding_Unique
     (Names : in Lisp.Types.Symbol_Id_Array;
      Index : in Positive)
   with
     Ghost,
     Pre =>
       Names'First = 1
       and then Index in Names'Range
       and then Names_Unique (Names),
     Post => Names_Binding_Unique (Names, Index);

   procedure Initialize (Env_State : in out State) is
   begin
      Env_State :=
        (Next_Free => 2,
         Frames    =>
           (others =>
              (Parent => Lisp.Types.No_Frame,
               Count  => 0,
               Names  => (others => 0),
               Values => (others => Lisp.Types.No_Ref))));
   end Initialize;

   function Frame_Count (Env_State : State) return Natural is (Env_State.Next_Free - 1);

   procedure Prove_Valid_Frame
     (Env_State : in State;
      Frame     : in Positive) is
   begin
      if Frame = 1 then
         pragma Assert (Env_State.Frames (Frame).Parent = Lisp.Types.No_Frame);
      else
         pragma Assert (Frame_Parent_Valid (Env_State, Frame));
      end if;
      pragma Assert (Frame_Names_Unique (Env_State, Frame));
   end Prove_Valid_Frame;

   procedure Prove_Frame_Names_Preserved
     (Old_State : in State;
      New_State : in State;
      Frame     : in Positive) is
   begin
      for I in 1 .. New_State.Frames (Frame).Count loop
         pragma Loop_Invariant (I in 1 .. New_State.Frames (Frame).Count + 1);
         pragma Loop_Invariant
           ((for all K in 1 .. I - 1 => Binding_Name_Unique (New_State, Frame, K)));
         Prove_Frame_Binding_Unique (Old_State, Frame, I);
         for J in I + 1 .. New_State.Frames (Frame).Count loop
            pragma Loop_Invariant (J in I + 1 .. New_State.Frames (Frame).Count + 1);
            pragma Loop_Invariant
              ((for all K in I + 1 .. J - 1 =>
                  New_State.Frames (Frame).Names (I) /= New_State.Frames (Frame).Names (K)));
            pragma Assert (Old_State.Frames (Frame).Names (I) /= Old_State.Frames (Frame).Names (J));
            pragma Assert (New_State.Frames (Frame).Names (I) = Old_State.Frames (Frame).Names (I));
            pragma Assert (New_State.Frames (Frame).Names (J) = Old_State.Frames (Frame).Names (J));
         end loop;
         pragma Assert (Binding_Name_Unique (New_State, Frame, I));
      end loop;
      pragma Assert
        ((for all K in 1 .. New_State.Frames (Frame).Count =>
            Binding_Name_Unique (New_State, Frame, K)));
   end Prove_Frame_Names_Preserved;

   procedure Prove_Appended_Frame_Names_Unique
     (Old_State : in State;
      New_State : in State;
      Frame     : in Positive;
      Name      : in Lisp.Types.Symbol_Id) is
   begin
      for I in 1 .. New_State.Frames (Frame).Count loop
         pragma Loop_Invariant (I in 1 .. New_State.Frames (Frame).Count + 1);
         pragma Loop_Invariant
           ((for all K in 1 .. I - 1 => Binding_Name_Unique (New_State, Frame, K)));
         if I < New_State.Frames (Frame).Count then
            Prove_Frame_Binding_Unique (Old_State, Frame, I);
         end if;
         for J in I + 1 .. New_State.Frames (Frame).Count loop
            pragma Loop_Invariant (J in I + 1 .. New_State.Frames (Frame).Count + 1);
            pragma Loop_Invariant
              ((for all K in I + 1 .. J - 1 =>
                  New_State.Frames (Frame).Names (I) /= New_State.Frames (Frame).Names (K)));
            if J = New_State.Frames (Frame).Count then
               pragma Assert (I in 1 .. Old_State.Frames (Frame).Count);
               pragma Assert (New_State.Frames (Frame).Names (J) = Name);
               pragma Assert (Old_State.Frames (Frame).Names (I) /= Name);
               pragma Assert (New_State.Frames (Frame).Names (I) = Old_State.Frames (Frame).Names (I));
            else
               pragma Assert (Old_State.Frames (Frame).Names (I) /= Old_State.Frames (Frame).Names (J));
               pragma Assert (New_State.Frames (Frame).Names (I) = Old_State.Frames (Frame).Names (I));
               pragma Assert (New_State.Frames (Frame).Names (J) = Old_State.Frames (Frame).Names (J));
            end if;
         end loop;
         if I < New_State.Frames (Frame).Count then
            pragma Assert (Binding_Name_Unique (New_State, Frame, I));
         end if;
      end loop;
      pragma Assert
        ((for all K in 1 .. New_State.Frames (Frame).Count =>
            Binding_Name_Unique (New_State, Frame, K)));
   end Prove_Appended_Frame_Names_Unique;

   procedure Prove_Frame_Unique_From_Names
     (Env_State : in State;
      Frame     : in Positive;
      Names     : in Lisp.Types.Symbol_Id_Array) is
   begin
      for I in 1 .. Env_State.Frames (Frame).Count loop
         pragma Loop_Invariant (I in 1 .. Env_State.Frames (Frame).Count + 1);
         pragma Loop_Invariant
           ((for all K in 1 .. I - 1 => Binding_Name_Unique (Env_State, Frame, K)));
         pragma Loop_Invariant (Names_Unique (Names));
         Prove_Names_Binding_Unique (Names, I);
         for J in I + 1 .. Env_State.Frames (Frame).Count loop
            pragma Loop_Invariant (J in I + 1 .. Env_State.Frames (Frame).Count + 1);
            pragma Loop_Invariant
              ((for all K in I + 1 .. J - 1 =>
                  Env_State.Frames (Frame).Names (I) /= Env_State.Frames (Frame).Names (K)));
            pragma Assert (Names (I) /= Names (J));
            pragma Assert (Env_State.Frames (Frame).Names (I) = Names (I));
            pragma Assert (Env_State.Frames (Frame).Names (J) = Names (J));
         end loop;
         pragma Assert (Binding_Name_Unique (Env_State, Frame, I));
      end loop;
      pragma Assert
        ((for all K in 1 .. Env_State.Frames (Frame).Count =>
            Binding_Name_Unique (Env_State, Frame, K)));
   end Prove_Frame_Unique_From_Names;

   procedure Prove_Frame_Binding_Unique
     (Env_State : in State;
      Frame     : in Positive;
      Index     : in Positive) is
   begin
      for K in 1 .. Env_State.Frames (Frame).Count loop
         pragma Loop_Invariant (K in 1 .. Env_State.Frames (Frame).Count + 1);
         if K = Index then
            pragma Assert (Binding_Name_Unique (Env_State, Frame, K));
         end if;
      end loop;
      pragma Assert (Binding_Name_Unique (Env_State, Frame, Index));
   end Prove_Frame_Binding_Unique;

   procedure Prove_Names_Binding_Unique
     (Names : in Lisp.Types.Symbol_Id_Array;
      Index : in Positive) is
   begin
      for K in Names'Range loop
         pragma Loop_Invariant (K in Names'Range);
         if K = Index then
            pragma Assert (Names_Binding_Unique (Names, K));
         end if;
      end loop;
      pragma Assert (Names_Binding_Unique (Names, Index));
   end Prove_Names_Binding_Unique;

   procedure Prove_Define_Global_Preserves_Valid
     (Old_State : in State;
      New_State : in State) is
   begin
      pragma Assert (New_State.Next_Free in 2 .. Lisp.Config.Max_Frames + 1);
      pragma Assert (New_State.Frames (1).Parent = Lisp.Types.No_Frame);
      pragma Assert (Frame_Names_Unique (New_State.Frames (1)));
      for F in 2 .. New_State.Next_Free - 1 loop
         pragma Loop_Invariant (F in 2 .. New_State.Next_Free);
         pragma Loop_Invariant
           ((for all J in 2 .. F - 1 => Frame_Parent_Valid (New_State, J)));
         pragma Loop_Invariant
           ((for all J in 2 .. F - 1 => Frame_Names_Unique (New_State, J)));
         Prove_Valid_Frame (Old_State, F);
         pragma Assert (New_State.Frames (F) = Old_State.Frames (F));
         pragma Assert (Frame_Parent_Valid (New_State, F));
         Prove_Frame_Names_Preserved (Old_State, New_State, F);
         pragma Assert (Frame_Names_Unique (New_State, F));
      end loop;
      pragma Assert
        ((for all J in 2 .. New_State.Next_Free - 1 => Frame_Parent_Valid (New_State, J)));
      pragma Assert
        ((for all J in 2 .. New_State.Next_Free - 1 => Frame_Names_Unique (New_State, J)));
      pragma Assert (Valid (New_State));
   end Prove_Define_Global_Preserves_Valid;

   procedure Prove_Global_Unique_After_Append
     (Old_State : in State;
      New_State : in State;
      Name      : in Lisp.Types.Symbol_Id) is
   begin
      Prove_Valid_Frame (Old_State, 1);
      Prove_Appended_Frame_Names_Unique (Old_State, New_State, 1, Name);
   end Prove_Global_Unique_After_Append;

   procedure Prove_Push_Frame_Preserves_Valid
     (Old_State : in State;
      New_State : in State;
      New_Frame : in Positive) is
   begin
      pragma Assert (New_State.Next_Free in 3 .. Lisp.Config.Max_Frames + 1);
      pragma Assert (New_State.Frames (1).Parent = Lisp.Types.No_Frame);
      pragma Assert (New_State.Frames (1) = Old_State.Frames (1));
      Prove_Valid_Frame (Old_State, 1);
      Prove_Frame_Names_Preserved (Old_State, New_State, 1);
      for F in 2 .. New_Frame - 1 loop
         pragma Loop_Invariant (F in 2 .. New_Frame);
         pragma Loop_Invariant
           ((for all J in 2 .. F - 1 => Frame_Parent_Valid (New_State, J)));
         pragma Loop_Invariant
           ((for all J in 2 .. F - 1 => Frame_Names_Unique (New_State, J)));
         Prove_Valid_Frame (Old_State, F);
         pragma Assert (New_State.Frames (F) = Old_State.Frames (F));
         pragma Assert (Frame_Parent_Valid (New_State, F));
         Prove_Frame_Names_Preserved (Old_State, New_State, F);
         pragma Assert (Frame_Names_Unique (New_State, F));
      end loop;
      pragma Assert (Frame_Parent_Valid (New_State, New_Frame));
      pragma Assert (Frame_Names_Unique (New_State.Frames (New_Frame)));
      pragma Assert
        ((for all J in 2 .. New_Frame - 1 => Frame_Parent_Valid (New_State, J)));
      pragma Assert
        ((for all J in 2 .. New_Frame - 1 => Frame_Names_Unique (New_State, J)));
      pragma Assert (Valid (New_State));
   end Prove_Push_Frame_Preserves_Valid;

   procedure Prove_Copied_Frame_Unique
     (Env_State : in State;
      Frame     : in Positive;
      Names     : in Lisp.Types.Symbol_Id_Array) is
   begin
      Prove_Frame_Unique_From_Names (Env_State, Frame, Names);
   end Prove_Copied_Frame_Unique;

   procedure Lookup
     (Env_State : in State;
      Frame     : in Lisp.Types.Frame_Id;
      Name      : in Lisp.Types.Symbol_Id;
      Value     : out Lisp.Types.Cell_Ref;
      Found     : out Boolean) is
      Current : Lisp.Types.Frame_Id := Frame;
   begin
      while Current /= Lisp.Types.No_Frame loop
         for I in 1 .. Env_State.Frames (Positive (Current)).Count loop
            if Env_State.Frames (Positive (Current)).Names (I) = Name then
               Value := Env_State.Frames (Positive (Current)).Values (I);
               Found := True;
               return;
            end if;
         end loop;
         Current := Env_State.Frames (Positive (Current)).Parent;
      end loop;

      Value := Lisp.Types.No_Ref;
      Found := False;
   end Lookup;

   procedure Define_Global
     (Env_State : in out State;
      Name      : in Lisp.Types.Symbol_Id;
      Value     : in Lisp.Types.Cell_Ref;
      Error     : out Lisp.Types.Error_Code) is
      Old_State : constant State := Env_State;
   begin
      for I in 1 .. Env_State.Frames (1).Count loop
         pragma Loop_Invariant
           ((for all J in 1 .. I - 1 => Env_State.Frames (1).Names (J) /= Name));
         if Env_State.Frames (1).Names (I) = Name then
            Env_State.Frames (1).Values (I) := Value;
            pragma Assert (Env_State.Frames (1).Count = Old_State.Frames (1).Count);
            pragma Assert
              ((for all J in 1 .. Env_State.Frames (1).Count =>
                  Env_State.Frames (1).Names (J) = Old_State.Frames (1).Names (J)));
            Prove_Valid_Frame (Old_State, 1);
            Prove_Frame_Names_Preserved (Old_State, Env_State, 1);
            pragma Assert (Frame_Names_Unique (Env_State, 1));
            Prove_Define_Global_Preserves_Valid (Old_State, Env_State);
            Error := Lisp.Types.Error_None;
            return;
         end if;
      end loop;

      if Env_State.Frames (1).Count = Lisp.Config.Max_Frame_Bindings then
         Error := Lisp.Types.Error_Frame_Full;
         return;
      end if;

      Env_State.Frames (1).Count := Env_State.Frames (1).Count + 1;
      Env_State.Frames (1).Names (Env_State.Frames (1).Count) := Name;
      Env_State.Frames (1).Values (Env_State.Frames (1).Count) := Value;
      pragma Assert (Name_Not_In_Global (Old_State, Name));
      Prove_Global_Unique_After_Append (Old_State, Env_State, Name);
      pragma Assert (Frame_Names_Unique (Env_State, 1));
      Prove_Define_Global_Preserves_Valid (Old_State, Env_State);
      Error := Lisp.Types.Error_None;
   end Define_Global;

   procedure Push_Frame
     (Env_State : in out State;
      Parent    : in Lisp.Types.Frame_Id;
      Names     : in Lisp.Types.Symbol_Id_Array;
      Values    : in Lisp.Types.Cell_Ref_Array;
      Frame     : out Lisp.Types.Frame_Id;
      Error     : out Lisp.Types.Error_Code) is
      Old_State : constant State := Env_State;
   begin
      if Names'Length /= Values'Length then
         Frame := Lisp.Types.No_Frame;
         Error := Lisp.Types.Error_Arity;
         return;
      end if;

      if Names'Length > Lisp.Config.Max_Frame_Bindings then
         Frame := Lisp.Types.No_Frame;
         Error := Lisp.Types.Error_Frame_Full;
         return;
      end if;

      if not Names_Unique (Names) then
         Frame := Lisp.Types.No_Frame;
         Error := Lisp.Types.Error_Invalid_Parameter_List;
         return;
      end if;

      if Env_State.Next_Free = Lisp.Config.Max_Frames + 1 then
         Frame := Lisp.Types.No_Frame;
         Error := Lisp.Types.Error_Frame_Full;
         return;
      end if;

      Frame := Env_State.Next_Free;
      Env_State.Next_Free := Env_State.Next_Free + 1;
      Env_State.Frames (Positive (Frame)).Parent := Parent;
      Env_State.Frames (Positive (Frame)).Count := Names'Length;
      Env_State.Frames (Positive (Frame)).Names (1 .. Names'Length) := Names;
      Env_State.Frames (Positive (Frame)).Values (1 .. Values'Length) := Values;
      pragma Assert (Frame_Parent_Valid (Env_State, Positive (Frame)));
      Prove_Copied_Frame_Unique (Env_State, Positive (Frame), Names);
      Prove_Push_Frame_Preserves_Valid (Old_State, Env_State, Positive (Frame));
      Error := Lisp.Types.Error_None;
   end Push_Frame;
end Lisp.Env;
