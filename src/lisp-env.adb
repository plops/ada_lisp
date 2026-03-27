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

   procedure Prove_Names_Unique_From_Bindings
     (Names : in Lisp.Types.Symbol_Id_Array)
   with
     Ghost,
     Pre =>
       (for all K in Names'Range => Names_Binding_Unique (Names, K)),
     Post =>
       Names_Unique (Names);

   procedure Prove_Preserved_Frame
     (Old_State : in State;
      New_State : in State;
      Frame     : in Positive)
   with
     Ghost,
     Pre =>
       Valid (Old_State)
       and then Frame in 1 .. Old_State.Next_Free - 1
       and then New_State.Frames (Frame) = Old_State.Frames (Frame),
     Post =>
       Frame_Names_Unique (New_State.Frames (Frame))
       and then
       (if Frame = 1 then
           New_State.Frames (Frame).Parent = Lisp.Types.No_Frame
        else
           Frame_Parent_Valid (New_State, Frame));

   procedure Prove_Preserved_Frame_Names_Unique
     (Old_Frame : in Frame_Record;
      New_Frame : in Frame_Record)
   with
     Ghost,
     Pre =>
       Frame_Names_Unique (Old_Frame)
       and then New_Frame = Old_Frame,
     Post =>
       Frame_Names_Unique (New_Frame);

   function Old_Frames_Preserved
     (Old_State : State;
      New_State : State;
      New_Frame : Positive) return Boolean is
     (New_Frame = Old_State.Next_Free
      and then New_State.Next_Free = New_Frame + 1
      and then
      (for all F in 1 .. New_Frame - 1 => New_State.Frames (F) = Old_State.Frames (F)));

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

   procedure Prove_Names_Unique_From_Bindings
     (Names : in Lisp.Types.Symbol_Id_Array) is
   begin
      pragma Assert (Names_Unique (Names));
   end Prove_Names_Unique_From_Bindings;

   procedure Prove_Preserved_Frame
     (Old_State : in State;
      New_State : in State;
      Frame     : in Positive) is
   begin
      Prove_Valid_Frame (Old_State, Frame);
      pragma Assert (New_State.Frames (Frame) = Old_State.Frames (Frame));
      Prove_Preserved_Frame_Names_Unique
        (Old_State.Frames (Frame), New_State.Frames (Frame));
      if Frame = 1 then
         pragma Assert (New_State.Frames (Frame).Parent = Lisp.Types.No_Frame);
      else
         pragma Assert
           (New_State.Frames (Frame).Parent = Old_State.Frames (Frame).Parent);
         pragma Assert (Frame_Parent_Valid (New_State, Frame));
      end if;
   end Prove_Preserved_Frame;

   procedure Prove_Preserved_Frame_Names_Unique
     (Old_Frame : in Frame_Record;
      New_Frame : in Frame_Record) is
   begin
      pragma Assert (Frame_Names_Unique (Old_Frame));
      pragma Assert (New_Frame = Old_Frame);
      pragma Assert (New_Frame.Count = Old_Frame.Count);
      for I in 1 .. New_Frame.Count loop
         pragma Loop_Invariant (I in 1 .. New_Frame.Count + 1);
         pragma Loop_Invariant
           ((for all K in 1 .. I - 1 => New_Frame.Names (K) = Old_Frame.Names (K)));
         pragma Loop_Invariant
           ((for all K in 1 .. I - 1 =>
               (if K > 1 then
                   (for all J in 1 .. K - 1 =>
                      New_Frame.Names (K) /= New_Frame.Names (J))
                else
                   True)));
         if I > 1 then
            pragma Assert
              ((for all J in 1 .. I - 1 =>
                  Old_Frame.Names (I) /= Old_Frame.Names (J)));
            pragma Assert
              ((for all J in 1 .. I - 1 =>
                  New_Frame.Names (J) = Old_Frame.Names (J)));
            pragma Assert (New_Frame.Names (I) = Old_Frame.Names (I));
            pragma Assert
              ((for all J in 1 .. I - 1 =>
                  New_Frame.Names (I) /= New_Frame.Names (J)));
         end if;
      end loop;
      pragma Assert (Frame_Names_Unique (New_Frame));
   end Prove_Preserved_Frame_Names_Unique;

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
            pragma Assert (Non_Global_Frames_Preserved (Old_State, Env_State));
            pragma Assert (Env_State.Next_Free = Old_State.Next_Free);
            for F in 2 .. Env_State.Next_Free - 1 loop
               pragma Loop_Invariant (F in 2 .. Env_State.Next_Free);
               pragma Loop_Invariant
                 ((for all J in 2 .. F - 1 => Env_State.Frames (J) = Old_State.Frames (J)));
               pragma Loop_Invariant
                 ((for all J in 2 .. F - 1 => Frame_Parent_Valid (Env_State, J)));
               pragma Loop_Invariant
                 ((for all J in 2 .. F - 1 => Frame_Names_Unique (Env_State.Frames (J))));
               pragma Assert (Env_State.Frames (F) = Old_State.Frames (F));
               Prove_Preserved_Frame (Old_State, Env_State, F);
               pragma Assert (Frame_Parent_Valid (Env_State, F));
               pragma Assert (Frame_Names_Unique (Env_State.Frames (F)));
            end loop;
            pragma Assert
              ((for all J in 2 .. Env_State.Next_Free - 1 =>
                  Env_State.Frames (J) = Old_State.Frames (J)));
            pragma Assert
              ((for all J in 2 .. Env_State.Next_Free - 1 => Frame_Parent_Valid (Env_State, J)));
            pragma Assert
              ((for all J in 2 .. Env_State.Next_Free - 1 => Frame_Names_Unique (Env_State.Frames (J))));
            pragma Assert (Valid (Env_State));
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
      for I in 1 .. Env_State.Frames (1).Count loop
         pragma Loop_Invariant (I in 1 .. Env_State.Frames (1).Count + 1);
         pragma Loop_Invariant
           ((for all K in 1 .. I - 1 =>
               (if K > 1 then
                   (for all J in 1 .. K - 1 =>
                      Env_State.Frames (1).Names (K) /= Env_State.Frames (1).Names (J))
                else
                   True)));
         for J in 1 .. I - 1 loop
            pragma Loop_Invariant (J in 1 .. I);
            pragma Loop_Invariant
              ((for all K in 1 .. J - 1 =>
                  Env_State.Frames (1).Names (I) /= Env_State.Frames (1).Names (K)));
            if Env_State.Frames (1).Names (I) = Env_State.Frames (1).Names (J) then
               Env_State := Old_State;
               Error := Lisp.Types.Error_Invalid_Parameter_List;
               return;
            end if;
         end loop;
      end loop;
      pragma Assert (Frame_Names_Unique (Env_State.Frames (1)));
      pragma Assert (Non_Global_Frames_Preserved (Old_State, Env_State));
      pragma Assert (Env_State.Next_Free = Old_State.Next_Free);
      for F in 2 .. Env_State.Next_Free - 1 loop
         pragma Loop_Invariant (F in 2 .. Env_State.Next_Free);
         pragma Loop_Invariant
           ((for all J in 2 .. F - 1 => Env_State.Frames (J) = Old_State.Frames (J)));
         pragma Loop_Invariant
           ((for all J in 2 .. F - 1 => Frame_Parent_Valid (Env_State, J)));
         pragma Loop_Invariant
           ((for all J in 2 .. F - 1 => Frame_Names_Unique (Env_State.Frames (J))));
         pragma Assert (Env_State.Frames (F) = Old_State.Frames (F));
         Prove_Preserved_Frame (Old_State, Env_State, F);
         pragma Assert (Frame_Parent_Valid (Env_State, F));
         pragma Assert (Frame_Names_Unique (Env_State.Frames (F)));
      end loop;
      pragma Assert
        ((for all J in 2 .. Env_State.Next_Free - 1 =>
            Env_State.Frames (J) = Old_State.Frames (J)));
      pragma Assert
        ((for all J in 2 .. Env_State.Next_Free - 1 => Frame_Parent_Valid (Env_State, J)));
      pragma Assert
        ((for all J in 2 .. Env_State.Next_Free - 1 => Frame_Names_Unique (Env_State.Frames (J))));
      pragma Assert (Valid (Env_State));
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

      for I in Names'Range loop
         pragma Loop_Invariant (I in Names'Range);
         pragma Loop_Invariant
           ((for all K in Names'First .. I - 1 => Names_Binding_Unique (Names, K)));
         for J in Names'First .. I - 1 loop
            pragma Loop_Invariant (J in Names'First .. I);
            pragma Loop_Invariant
              ((for all K in Names'First .. J - 1 => Names (I) /= Names (K)));
            if Names (J) = Names (I) then
               Frame := Lisp.Types.No_Frame;
               Error := Lisp.Types.Error_Invalid_Parameter_List;
               return;
            end if;
         end loop;
         if I > Names'First then
            pragma Assert (Names_Binding_Unique (Names, I));
         end if;
      end loop;
      Prove_Names_Unique_From_Bindings (Names);

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
      for I in 1 .. Env_State.Frames (Positive (Frame)).Count loop
         pragma Loop_Invariant (I in 1 .. Env_State.Frames (Positive (Frame)).Count + 1);
         pragma Loop_Invariant
           ((for all K in 1 .. I - 1 =>
               (if K > 1 then
                   (for all J in 1 .. K - 1 =>
                      Env_State.Frames (Positive (Frame)).Names (K) /=
                        Env_State.Frames (Positive (Frame)).Names (J))
                else
                   True)));
         pragma Loop_Invariant
           ((for all K in 1 .. I - 1 =>
               Env_State.Frames (Positive (Frame)).Names (K) = Names (K)));
         if I > 1 then
            pragma Assert
              ((for all J in 1 .. I - 1 =>
                  Env_State.Frames (Positive (Frame)).Names (J) = Names (J)));
            if Names_Unique (Names) then
               pragma Assert
                 ((for all J in 1 .. I - 1 =>
                     Names (I) /= Names (J)));
               pragma Assert
                 ((for all J in 1 .. I - 1 =>
                     Env_State.Frames (Positive (Frame)).Names (I) /=
                       Env_State.Frames (Positive (Frame)).Names (J)));
            end if;
         end if;
      end loop;
      pragma Assert (Frame_Names_Unique (Env_State.Frames (Positive (Frame))));
      pragma Assert (Old_Frames_Preserved (Old_State, Env_State, Positive (Frame)));
      pragma Assert (Positive (Frame) = Old_State.Next_Free);
      for F in 2 .. Positive (Frame) - 1 loop
         pragma Loop_Invariant (F in 2 .. Positive (Frame));
         pragma Loop_Invariant
           ((for all J in 2 .. F - 1 => Env_State.Frames (J) = Old_State.Frames (J)));
         pragma Loop_Invariant
           ((for all J in 2 .. F - 1 => Frame_Parent_Valid (Env_State, J)));
         pragma Loop_Invariant
           ((for all J in 2 .. F - 1 => Frame_Names_Unique (Env_State.Frames (J))));
         pragma Assert (Env_State.Frames (F) = Old_State.Frames (F));
         Prove_Preserved_Frame (Old_State, Env_State, F);
         pragma Assert (Frame_Parent_Valid (Env_State, F));
         pragma Assert (Frame_Names_Unique (Env_State.Frames (F)));
      end loop;
      pragma Assert
        ((for all J in 2 .. Positive (Frame) - 1 =>
            Env_State.Frames (J) = Old_State.Frames (J)));
      pragma Assert
        ((for all J in 2 .. Positive (Frame) - 1 => Frame_Parent_Valid (Env_State, J)));
      pragma Assert
        ((for all J in 2 .. Positive (Frame) - 1 => Frame_Names_Unique (Env_State.Frames (J))));
      pragma Assert (Env_State.Frames (1) = Old_State.Frames (1));
      pragma Assert (Frame_Names_Unique (Env_State.Frames (1)));
      pragma Assert
        ((for all J in 1 .. Positive (Frame) =>
            Frame_Names_Unique (Env_State.Frames (J))));
      pragma Assert (Valid (Env_State));
      Error := Lisp.Types.Error_None;
   end Push_Frame;
end Lisp.Env;
