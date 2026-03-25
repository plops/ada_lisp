with Lisp.Env;
with Lisp.Types;

procedure Test.Env is
   use type Lisp.Types.Error_Code;
   Env_State : Lisp.Env.State;
   Names     : Lisp.Types.Symbol_Id_Array (1 .. 1) := (1 => 7);
   Values    : Lisp.Types.Cell_Ref_Array (1 .. 1) := (1 => 3);
   Frame     : Lisp.Types.Frame_Id;
   Value     : Lisp.Types.Cell_Ref;
   Found     : Boolean;
   Error     : Lisp.Types.Error_Code;
begin
   Lisp.Env.Initialize (Env_State);
   Lisp.Env.Push_Frame (Env_State, Lisp.Env.Global_Frame, Names, Values, Frame, Error);
   pragma Assert (Error = Lisp.Types.Error_None);
   Lisp.Env.Lookup (Env_State, Frame, 7, Value, Found);
   pragma Assert (Found);
   pragma Assert (Value = 3);
end Test.Env;
