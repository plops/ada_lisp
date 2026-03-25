package body Lisp.Env with SPARK_Mode is
   use type Lisp.Types.Error_Code;

   function Name_Not_In_Global
     (Env_State : State;
      Name      : Lisp.Types.Symbol_Id) return Boolean is
     (for all J in 1 .. Env_State.Frames (1).Count => Env_State.Frames (1).Names (J) /= Name);

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

   procedure Prove_Define_Global_Preserves_Valid
     (Old_State : in State;
      New_State : in State) is
   begin
      pragma Assert (New_State.Next_Free in 2 .. Lisp.Config.Max_Frames + 1);
      pragma Assert (New_State.Frames (1).Parent = Lisp.Types.No_Frame);
      for F in 2 .. New_State.Next_Free - 1 loop
         pragma Loop_Invariant (F in 2 .. New_State.Next_Free);
         pragma Loop_Invariant
           ((for all J in 2 .. F - 1 =>
               Frame_Parent_Valid (New_State, J) and then Frame_Names_Unique (New_State, J)));
         pragma Assert (New_State.Frames (F) = Old_State.Frames (F));
         pragma Assert (New_State.Frames (F).Count = Old_State.Frames (F).Count);
         pragma Assert
           ((for all I in 1 .. New_State.Frames (F).Count =>
               New_State.Frames (F).Names (I) = Old_State.Frames (F).Names (I)));
         pragma Assert (Frame_Parent_Valid (New_State, F));
         pragma Assert (Frame_Names_Unique (Old_State, F));
         pragma Assert (Frame_Names_Unique (New_State, F));
      end loop;
      pragma Assert (Valid (New_State));
   end Prove_Define_Global_Preserves_Valid;

   procedure Prove_Global_Unique_After_Append
     (Old_State : in State;
      New_State : in State;
      Name      : in Lisp.Types.Symbol_Id) is
   begin
      pragma Assert (Frame_Names_Unique (Old_State, 1));
      pragma Assert
        ((for all I in 1 .. Old_State.Frames (1).Count =>
            New_State.Frames (1).Names (I) = Old_State.Frames (1).Names (I)));
      for I in 1 .. Old_State.Frames (1).Count loop
         pragma Loop_Invariant (I in 1 .. Old_State.Frames (1).Count + 1);
         pragma Loop_Invariant
           ((for all J in 1 .. I - 1 => New_State.Frames (1).Names (J) /= Name));
         pragma Assert (New_State.Frames (1).Names (I) = Old_State.Frames (1).Names (I));
         pragma Assert (Old_State.Frames (1).Names (I) /= Name);
      end loop;
      pragma Assert (Frame_Names_Unique (New_State, 1));
   end Prove_Global_Unique_After_Append;

   procedure Prove_Push_Frame_Preserves_Valid
     (Old_State : in State;
      New_State : in State;
      New_Frame : in Positive) is
   begin
      pragma Assert (New_State.Next_Free in 3 .. Lisp.Config.Max_Frames + 1);
      pragma Assert (New_State.Frames (1).Parent = Lisp.Types.No_Frame);
      pragma Assert (New_State.Frames (1).Count = Old_State.Frames (1).Count);
      pragma Assert
        ((for all I in 1 .. New_State.Frames (1).Count =>
            New_State.Frames (1).Names (I) = Old_State.Frames (1).Names (I)));
      pragma Assert (Frame_Names_Unique (Old_State, 1));
      pragma Assert (Frame_Names_Unique (New_State, 1));
      for F in 2 .. New_Frame - 1 loop
         pragma Loop_Invariant (F in 2 .. New_Frame);
         pragma Loop_Invariant
           ((for all J in 2 .. F - 1 =>
               Frame_Parent_Valid (New_State, J) and then Frame_Names_Unique (New_State, J)));
         pragma Assert (New_State.Frames (F) = Old_State.Frames (F));
         pragma Assert (New_State.Frames (F).Count = Old_State.Frames (F).Count);
         pragma Assert
           ((for all I in 1 .. New_State.Frames (F).Count =>
               New_State.Frames (F).Names (I) = Old_State.Frames (F).Names (I)));
         pragma Assert (Frame_Parent_Valid (New_State, F));
         pragma Assert (Frame_Names_Unique (Old_State, F));
         pragma Assert (Frame_Names_Unique (New_State, F));
      end loop;
      pragma Assert (Frame_Parent_Valid (New_State, New_Frame));
      pragma Assert (Frame_Names_Unique (New_State, New_Frame));
      pragma Assert (Valid (New_State));
   end Prove_Push_Frame_Preserves_Valid;

   procedure Prove_Copied_Frame_Unique
     (Env_State : in State;
      Frame     : in Positive;
      Names     : in Lisp.Types.Symbol_Id_Array) is
   begin
      pragma Assert (Frame_Names_Unique (Env_State, Frame));
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
            pragma Assert (Frame_Names_Unique (Old_State, 1));
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
