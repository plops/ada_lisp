with Lisp.Config;
with Lisp.Types;

package Lisp.Store with SPARK_Mode is
   use type Lisp.Types.Cell_Kind;

   type Arena is private;

   Nil_Ref  : constant Lisp.Types.Cell_Ref := 1;
   True_Ref : constant Lisp.Types.Cell_Ref := 2;

   procedure Initialize (S : out Arena) with Post => Valid (S);
   function Valid (S : Arena) return Boolean;
   function Is_Valid_Ref (S : Arena; Ref : Lisp.Types.Cell_Ref) return Boolean;
   function Kind_Of (S : Arena; Ref : Lisp.Types.Cell_Ref) return Lisp.Types.Cell_Kind
   with
     Pre => Is_Valid_Ref (S, Ref);

   function Integer_Value (S : Arena; Ref : Lisp.Types.Cell_Ref) return Lisp.Types.Lisp_Int
   with
     Pre => Is_Valid_Ref (S, Ref) and then Kind_Of (S, Ref) = Lisp.Types.Integer_Cell;
   function Symbol_Value (S : Arena; Ref : Lisp.Types.Cell_Ref) return Lisp.Types.Symbol_Id
   with
     Pre => Is_Valid_Ref (S, Ref) and then Kind_Of (S, Ref) = Lisp.Types.Symbol_Cell;
   function Car (S : Arena; Ref : Lisp.Types.Cell_Ref) return Lisp.Types.Cell_Ref
   with
     Pre  => Valid (S) and then Is_Valid_Ref (S, Ref) and then Kind_Of (S, Ref) = Lisp.Types.Cons_Cell,
     Post => Car'Result = Lisp.Types.No_Ref or else Is_Valid_Ref (S, Car'Result);
   function Cdr (S : Arena; Ref : Lisp.Types.Cell_Ref) return Lisp.Types.Cell_Ref
   with
     Pre  => Valid (S) and then Is_Valid_Ref (S, Ref) and then Kind_Of (S, Ref) = Lisp.Types.Cons_Cell,
     Post => Cdr'Result = Lisp.Types.No_Ref or else Is_Valid_Ref (S, Cdr'Result);
   function Primitive_Value (S : Arena; Ref : Lisp.Types.Cell_Ref) return Lisp.Types.Primitive_Kind
   with
     Pre => Is_Valid_Ref (S, Ref) and then Kind_Of (S, Ref) = Lisp.Types.Primitive_Cell;
   function Closure_Params (S : Arena; Ref : Lisp.Types.Cell_Ref) return Lisp.Types.Cell_Ref
   with
     Pre => Valid (S) and then Is_Valid_Ref (S, Ref) and then Kind_Of (S, Ref) = Lisp.Types.Closure_Cell;
   function Closure_Body (S : Arena; Ref : Lisp.Types.Cell_Ref) return Lisp.Types.Cell_Ref
   with
     Pre => Valid (S) and then Is_Valid_Ref (S, Ref) and then Kind_Of (S, Ref) = Lisp.Types.Closure_Cell;
   function Closure_Frame (S : Arena; Ref : Lisp.Types.Cell_Ref) return Lisp.Types.Frame_Id
   with
     Pre => Is_Valid_Ref (S, Ref) and then Kind_Of (S, Ref) = Lisp.Types.Closure_Cell;

   procedure Make_Integer
     (S     : in out Arena;
      Value : in Lisp.Types.Lisp_Int;
      Ref   : out Lisp.Types.Cell_Ref;
      Error : out Lisp.Types.Error_Code)
   with Pre => Valid (S), Post => Valid (S);

   procedure Make_Symbol
     (S     : in out Arena;
      Value : in Lisp.Types.Symbol_Id;
      Ref   : out Lisp.Types.Cell_Ref;
      Error : out Lisp.Types.Error_Code)
   with Pre => Valid (S), Post => Valid (S);

   procedure Make_Cons
     (S     : in out Arena;
      Left  : in Lisp.Types.Cell_Ref;
      Right : in Lisp.Types.Cell_Ref;
      Ref   : out Lisp.Types.Cell_Ref;
      Error : out Lisp.Types.Error_Code)
   with Pre => Valid (S), Post => Valid (S);

   procedure Make_Primitive
     (S     : in out Arena;
      Prim  : in Lisp.Types.Primitive_Kind;
      Ref   : out Lisp.Types.Cell_Ref;
      Error : out Lisp.Types.Error_Code)
   with Pre => Valid (S), Post => Valid (S);

   procedure Make_Closure
     (S              : in out Arena;
      Params         : in Lisp.Types.Cell_Ref;
      Body_Expr      : in Lisp.Types.Cell_Ref;
      Captured_Frame : in Lisp.Types.Frame_Id;
      Ref            : out Lisp.Types.Cell_Ref;
      Error          : out Lisp.Types.Error_Code)
   with Pre => Valid (S), Post => Valid (S);

   function Readable_Value (S : Arena; Ref : Lisp.Types.Cell_Ref) return Boolean
   with
     Pre => Valid (S) and then (Ref = Lisp.Types.No_Ref or else Is_Valid_Ref (S, Ref)),
     Subprogram_Variant => (Decreases => Ref);

   function Proper_List (S : Arena; Ref : Lisp.Types.Cell_Ref) return Boolean
   with
     Pre => Valid (S) and then (Ref = Lisp.Types.No_Ref or else Is_Valid_Ref (S, Ref)),
     Subprogram_Variant => (Decreases => Ref);

   function List_Length (S : Arena; Ref : Lisp.Types.Cell_Ref) return Natural
   with
     Pre  => Valid (S) and then (Ref = Lisp.Types.No_Ref or else Is_Valid_Ref (S, Ref)),
     Post => List_Length'Result <= Natural (Ref),
     Subprogram_Variant => (Decreases => Ref);

private
   type Cell (Kind : Lisp.Types.Cell_Kind := Lisp.Types.Nil_Cell) is record
      case Kind is
         when Lisp.Types.Nil_Cell | Lisp.Types.True_Cell =>
            null;
         when Lisp.Types.Integer_Cell =>
            Int_Value : Lisp.Types.Lisp_Int := 0;
         when Lisp.Types.Symbol_Cell =>
            Sym_Value : Lisp.Types.Symbol_Id := 0;
         when Lisp.Types.Cons_Cell =>
            Left_Value  : Lisp.Types.Cell_Ref := Lisp.Types.No_Ref;
            Right_Value : Lisp.Types.Cell_Ref := Lisp.Types.No_Ref;
         when Lisp.Types.Primitive_Cell =>
            Prim_Value : Lisp.Types.Primitive_Kind := Lisp.Types.Prim_Atom;
         when Lisp.Types.Closure_Cell =>
            Params_Value : Lisp.Types.Cell_Ref := Lisp.Types.No_Ref;
            Body_Expr_Value : Lisp.Types.Cell_Ref := Lisp.Types.No_Ref;
            Frame_Value  : Lisp.Types.Frame_Id := Lisp.Types.No_Frame;
      end case;
   end record;

   type Cell_Array is array (Positive range 1 .. Lisp.Config.Max_Cells) of Cell;

   type Arena is record
      Next_Free : Natural range 1 .. Lisp.Config.Max_Cells + 1 := 3;
      Cells     : Cell_Array := (others => (Kind => Lisp.Types.Nil_Cell));
   end record;

   function Cell_Refs_Below
     (S   : Arena;
      Ref : Positive) return Boolean is
     (case S.Cells (Ref).Kind is
         when Lisp.Types.Cons_Cell =>
           (S.Cells (Ref).Left_Value = Lisp.Types.No_Ref or else S.Cells (Ref).Left_Value < Ref)
           and then
           (S.Cells (Ref).Right_Value = Lisp.Types.No_Ref or else S.Cells (Ref).Right_Value < Ref),
         when Lisp.Types.Closure_Cell =>
           (S.Cells (Ref).Params_Value = Lisp.Types.No_Ref or else S.Cells (Ref).Params_Value < Ref)
           and then
           (S.Cells (Ref).Body_Expr_Value = Lisp.Types.No_Ref or else S.Cells (Ref).Body_Expr_Value < Ref),
         when others =>
           True)
   with
     Pre => Ref in 1 .. Lisp.Config.Max_Cells;

   function Valid (S : Arena) return Boolean is
     (S.Next_Free in 3 .. Lisp.Config.Max_Cells + 1
      and then S.Cells (1).Kind = Lisp.Types.Nil_Cell
      and then S.Cells (2).Kind = Lisp.Types.True_Cell
      and then
      (for all I in 3 .. S.Next_Free - 1 => Cell_Refs_Below (S, I)));
end Lisp.Store;
