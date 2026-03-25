package body Lisp.Env with SPARK_Mode is
   use type Lisp.Types.Error_Code;

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

   function Valid (Env_State : State) return Boolean is
   begin
      if Env_State.Next_Free < 2 or else Env_State.Next_Free > Lisp.Config.Max_Frames + 1 then
         return False;
      end if;

      for F in 2 .. Env_State.Next_Free - 1 loop
         if Env_State.Frames (F).Parent = Lisp.Types.No_Frame
           or else Env_State.Frames (F).Parent >= F
         then
            return False;
         end if;
      end loop;

      for F in 1 .. Env_State.Next_Free - 1 loop
         for I in 1 .. Env_State.Frames (F).Count loop
            for J in I + 1 .. Env_State.Frames (F).Count loop
               if Env_State.Frames (F).Names (I) = Env_State.Frames (F).Names (J) then
                  return False;
               end if;
            end loop;
         end loop;
      end loop;

      return True;
   end Valid;

   function Frame_Count (Env_State : State) return Natural is (Env_State.Next_Free - 1);

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
   begin
      for I in 1 .. Env_State.Frames (1).Count loop
         if Env_State.Frames (1).Names (I) = Name then
            Env_State.Frames (1).Values (I) := Value;
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
      Error := Lisp.Types.Error_None;
   end Define_Global;

   procedure Push_Frame
     (Env_State : in out State;
      Parent    : in Lisp.Types.Frame_Id;
      Names     : in Lisp.Types.Symbol_Id_Array;
      Values    : in Lisp.Types.Cell_Ref_Array;
      Frame     : out Lisp.Types.Frame_Id;
      Error     : out Lisp.Types.Error_Code) is
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
         if I < Names'Last then
            for J in I + 1 .. Names'Last loop
               if Names (I) = Names (J) then
                  Frame := Lisp.Types.No_Frame;
                  Error := Lisp.Types.Error_Invalid_Parameter_List;
                  return;
               end if;
            end loop;
         end if;
      end loop;

      if Env_State.Next_Free = Lisp.Config.Max_Frames + 1 then
         Frame := Lisp.Types.No_Frame;
         Error := Lisp.Types.Error_Frame_Full;
         return;
      end if;

      Frame := Env_State.Next_Free;
      Env_State.Next_Free := Env_State.Next_Free + 1;
      Env_State.Frames (Positive (Frame)).Parent := Parent;
      Env_State.Frames (Positive (Frame)).Count := Names'Length;
      for I in 1 .. Names'Length loop
         Env_State.Frames (Positive (Frame)).Names (I) := Names (I);
         Env_State.Frames (Positive (Frame)).Values (I) := Values (I);
      end loop;
      Error := Lisp.Types.Error_None;
   end Push_Frame;
end Lisp.Env;
