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
end Lisp.Env;
