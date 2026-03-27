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
     Pre => Lisp.Runtime.Valid (RT)
       and then Source'First = 1
       and then Pos in Source'Range
       and then Source'Last < Natural'Last,
     Post => Next_Pos in Pos .. Source'Last + 1
       and then Lisp.Runtime.Valid (RT)
       and then Lisp.Runtime."=" (RT.Known, RT.Known'Old)
       and then
       (if Lisp.Runtime.Quote_If_Known (RT'Old) then
           Lisp.Runtime.Quote_If_Known (RT)
        else
           True)
       and then
       (if Lisp.Runtime.Quote_If_Begin_Known (RT'Old) then
           Lisp.Runtime.Quote_If_Begin_Known (RT)
        else
           True)
       and then
       (if Lisp.Types."=" (Error, Lisp.Types.Error_None) then
           Lisp.Store.Is_Valid_Ref (RT.Store, Ref)
        else
           Ref = Lisp.Types.No_Ref);
end Lisp.Parser;
