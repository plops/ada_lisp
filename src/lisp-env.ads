with Lisp.Config;
with Lisp.Types;

package Lisp.Env with SPARK_Mode is
   Global_Frame : constant Lisp.Types.Frame_Id := 1;

   type State is private;

   procedure Initialize (Env_State : in out State) with Post => Valid (Env_State);
   function Valid (Env_State : State) return Boolean;
   function Frame_Count (Env_State : State) return Natural;

   procedure Lookup
     (Env_State : in State;
      Frame     : in Lisp.Types.Frame_Id;
      Name      : in Lisp.Types.Symbol_Id;
      Value     : out Lisp.Types.Cell_Ref;
      Found     : out Boolean)
   with Pre => Valid (Env_State);

   procedure Define_Global
     (Env_State : in out State;
      Name      : in Lisp.Types.Symbol_Id;
      Value     : in Lisp.Types.Cell_Ref;
      Error     : out Lisp.Types.Error_Code)
   with Pre => Valid (Env_State), Post => Valid (Env_State);

   procedure Push_Frame
     (Env_State : in out State;
      Parent    : in Lisp.Types.Frame_Id;
      Names     : in Lisp.Types.Symbol_Id_Array;
      Values    : in Lisp.Types.Cell_Ref_Array;
      Frame     : out Lisp.Types.Frame_Id;
      Error     : out Lisp.Types.Error_Code)
   with
     Pre => Valid (Env_State)
       and then Parent in 1 .. Frame_Count (Env_State)
       and then Names'First = 1
       and then Values'First = 1,
     Post => Valid (Env_State);

private
   subtype Binding_Index is Positive range 1 .. Lisp.Config.Max_Frame_Bindings;

   type Frame_Record is record
      Parent : Lisp.Types.Frame_Id := Lisp.Types.No_Frame;
      Count  : Natural range 0 .. Lisp.Config.Max_Frame_Bindings := 0;
      Names  : Lisp.Types.Symbol_Id_Array (Binding_Index) := (others => 0);
      Values : Lisp.Types.Cell_Ref_Array (Binding_Index) := (others => Lisp.Types.No_Ref);
   end record;

   type Frame_Array is array (Positive range 1 .. Lisp.Config.Max_Frames) of Frame_Record;

   type State is record
      Next_Free : Natural range 1 .. Lisp.Config.Max_Frames + 1 := 2;
      Frames    : Frame_Array;
   end record;

   function Frame_Parent_Valid
     (Frame_State : Frame_Record;
      Frame       : Positive) return Boolean is
     (Frame_State.Parent /= Lisp.Types.No_Frame
      and then Frame_State.Parent < Frame)
   with
     Pre => Frame in 1 .. Lisp.Config.Max_Frames;

   function Frame_Parent_Valid
     (Env_State : State;
      Frame     : Positive) return Boolean is
     (Frame_Parent_Valid (Env_State.Frames (Frame), Frame))
   with
     Pre => Frame in 1 .. Lisp.Config.Max_Frames;

   function Binding_Name_Unique
     (Frame_State : Frame_Record;
      Index       : Positive) return Boolean is
     (if Index in 1 .. Frame_State.Count and then Index > 1 then
         (for all J in 1 .. Index - 1 =>
            Frame_State.Names (Index) /= Frame_State.Names (J))
      else
         True);

   function Frame_Names_Unique
     (Frame_State : Frame_Record) return Boolean is
     (for all I in 1 .. Frame_State.Count =>
        (if I > 1 then
            (for all J in 1 .. I - 1 =>
               Frame_State.Names (I) /= Frame_State.Names (J))
         else
            True));

   function Binding_Name_Unique
     (Env_State : State;
      Frame     : Positive;
      Index     : Positive) return Boolean is
     (Binding_Name_Unique (Env_State.Frames (Frame), Index))
   with
     Pre => Frame in 1 .. Lisp.Config.Max_Frames;

   function Frame_Names_Unique
     (Env_State : State;
      Frame     : Positive) return Boolean is
     (Frame_Names_Unique (Env_State.Frames (Frame)))
   with
     Pre => Frame in 1 .. Lisp.Config.Max_Frames;

   function Names_Binding_Unique
     (Names : Lisp.Types.Symbol_Id_Array;
      Index : Positive) return Boolean is
     (if Index in Names'Range and then Index > Names'First then
         (for all J in Names'First .. Index - 1 => Names (Index) /= Names (J))
      else
         True);

   function Names_Unique (Names : Lisp.Types.Symbol_Id_Array) return Boolean is
     (for all I in Names'Range =>
        (if I > Names'First then
            (for all J in Names'First .. I - 1 => Names (I) /= Names (J))
         else
            True));

   function Valid (Env_State : State) return Boolean is
     (Env_State.Next_Free >= 2
      and then Env_State.Next_Free <= Lisp.Config.Max_Frames + 1
      and then Env_State.Frames (1).Parent = Lisp.Types.No_Frame
      and then (for all F in 2 .. Env_State.Next_Free - 1 =>
                  Frame_Parent_Valid (Env_State, F))
      and then (for all F in 1 .. Env_State.Next_Free - 1 =>
                  Frame_Names_Unique (Env_State, F)));
end Lisp.Env;
