with Lisp.Env;
with Lisp.Store;
with Lisp.Symbols;
with Lisp.Types;

package Lisp.Runtime with SPARK_Mode is
   type Well_Known_Symbols is record
      Quote_Id  : Lisp.Types.Symbol_Id := 0;
      If_Id     : Lisp.Types.Symbol_Id := 0;
      Lambda_Id : Lisp.Types.Symbol_Id := 0;
      Define_Id : Lisp.Types.Symbol_Id := 0;
      Begin_Id  : Lisp.Types.Symbol_Id := 0;
      Atom_Id   : Lisp.Types.Symbol_Id := 0;
      Eq_Id     : Lisp.Types.Symbol_Id := 0;
      Cons_Id   : Lisp.Types.Symbol_Id := 0;
      Car_Id    : Lisp.Types.Symbol_Id := 0;
      Cdr_Id    : Lisp.Types.Symbol_Id := 0;
      Null_Id   : Lisp.Types.Symbol_Id := 0;
      Add_Id    : Lisp.Types.Symbol_Id := 0;
      Sub_Id    : Lisp.Types.Symbol_Id := 0;
      Mul_Id    : Lisp.Types.Symbol_Id := 0;
      Lt_Id     : Lisp.Types.Symbol_Id := 0;
      Le_Id     : Lisp.Types.Symbol_Id := 0;
   end record;

   type State is record
      Symbols : Lisp.Symbols.Table;
      Store   : Lisp.Store.Arena;
      Env     : Lisp.Env.State;
      Known   : Well_Known_Symbols;
   end record;

   procedure Initialize (RT : out State; Error : out Lisp.Types.Error_Code);
   function Valid (RT : State) return Boolean;
   function Is_Reserved (RT : State; Name : Lisp.Types.Symbol_Id) return Boolean;
end Lisp.Runtime;
