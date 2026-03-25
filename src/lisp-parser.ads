with Lisp.Env;
with Lisp.Runtime;
with Lisp.Store;
with Lisp.Symbols;
with Lisp.Types;

package Lisp.Parser with SPARK_Mode is
   procedure Parse_One
     (Source   : in String;
      Pos      : in Positive;
      RT       : in out Lisp.Runtime.State;
      Ref      : out Lisp.Types.Cell_Ref;
      Next_Pos : out Natural;
     Error    : out Lisp.Types.Error_Code)
   with
     Pre => Lisp.Symbols.Valid (RT.Symbols)
       and then Lisp.Store.Valid (RT.Store)
       and then Lisp.Env.Valid (RT.Env)
       and then Source'First = 1
       and then Pos in Source'Range
       and then Source'Last < Natural'Last,
     Post => Next_Pos > 0
       and then
       (if Lisp.Types."=" (Error, Lisp.Types.Error_None) then
           Lisp.Symbols.Valid (RT.Symbols)
           and then Lisp.Store.Valid (RT.Store)
           and then Lisp.Env.Valid (RT.Env));
end Lisp.Parser;
