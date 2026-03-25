with Lisp.Runtime;
with Lisp.Types;

package Lisp.Parser with SPARK_Mode is
   procedure Parse_One
     (Source   : in String;
      Pos      : in Positive;
      RT       : in out Lisp.Runtime.State;
      Ref      : out Lisp.Types.Cell_Ref;
      Next_Pos : out Natural;
      Error    : out Lisp.Types.Error_Code);
end Lisp.Parser;
