package body Lisp.Store with SPARK_Mode is
   use type Lisp.Types.Cell_Kind;

   procedure Initialize (S : out Arena) is
   begin
      S.Cells := (others => (Kind => Lisp.Types.Nil_Cell));
      S.Cells (1) := (Kind => Lisp.Types.Nil_Cell);
      S.Cells (2) := (Kind => Lisp.Types.True_Cell);
      S.Next_Free := 3;
   end Initialize;

   function Valid (S : Arena) return Boolean is
   begin
      if S.Next_Free < 3 or else S.Next_Free > Lisp.Config.Max_Cells + 1 then
         return False;
      end if;

      if S.Cells (1).Kind /= Lisp.Types.Nil_Cell or else S.Cells (2).Kind /= Lisp.Types.True_Cell then
         return False;
      end if;

      for I in 3 .. S.Next_Free - 1 loop
         case S.Cells (I).Kind is
            when Lisp.Types.Cons_Cell =>
               if (S.Cells (I).Left_Value /= Lisp.Types.No_Ref and then S.Cells (I).Left_Value >= I)
                 or else
                  (S.Cells (I).Right_Value /= Lisp.Types.No_Ref and then S.Cells (I).Right_Value >= I)
               then
                  return False;
               end if;
            when Lisp.Types.Closure_Cell =>
               if (S.Cells (I).Params_Value /= Lisp.Types.No_Ref and then S.Cells (I).Params_Value >= I)
                 or else
                  (S.Cells (I).Body_Expr_Value /= Lisp.Types.No_Ref and then S.Cells (I).Body_Expr_Value >= I)
               then
                  return False;
               end if;
            when others =>
               null;
         end case;
      end loop;

      return True;
   end Valid;

   function Is_Valid_Ref (S : Arena; Ref : Lisp.Types.Cell_Ref) return Boolean is
     (Ref /= Lisp.Types.No_Ref and then Ref < S.Next_Free);

   function Kind_Of (S : Arena; Ref : Lisp.Types.Cell_Ref) return Lisp.Types.Cell_Kind is
   begin
      return S.Cells (Positive (Ref)).Kind;
   end Kind_Of;

   function Integer_Value (S : Arena; Ref : Lisp.Types.Cell_Ref) return Lisp.Types.Lisp_Int is
     (S.Cells (Positive (Ref)).Int_Value);

   function Symbol_Value (S : Arena; Ref : Lisp.Types.Cell_Ref) return Lisp.Types.Symbol_Id is
     (S.Cells (Positive (Ref)).Sym_Value);

   function Car (S : Arena; Ref : Lisp.Types.Cell_Ref) return Lisp.Types.Cell_Ref is
     (S.Cells (Positive (Ref)).Left_Value);

   function Cdr (S : Arena; Ref : Lisp.Types.Cell_Ref) return Lisp.Types.Cell_Ref is
     (S.Cells (Positive (Ref)).Right_Value);

   function Primitive_Value (S : Arena; Ref : Lisp.Types.Cell_Ref) return Lisp.Types.Primitive_Kind is
     (S.Cells (Positive (Ref)).Prim_Value);

   function Closure_Params (S : Arena; Ref : Lisp.Types.Cell_Ref) return Lisp.Types.Cell_Ref is
     (S.Cells (Positive (Ref)).Params_Value);

   function Closure_Body (S : Arena; Ref : Lisp.Types.Cell_Ref) return Lisp.Types.Cell_Ref is
     (S.Cells (Positive (Ref)).Body_Expr_Value);

   function Closure_Frame (S : Arena; Ref : Lisp.Types.Cell_Ref) return Lisp.Types.Frame_Id is
     (S.Cells (Positive (Ref)).Frame_Value);

   procedure Allocate
     (S     : in out Arena;
      Value : in Cell;
      Ref   : out Lisp.Types.Cell_Ref;
      Error : out Lisp.Types.Error_Code) is
   begin
      if S.Next_Free = Lisp.Config.Max_Cells + 1 then
         Ref := Lisp.Types.No_Ref;
         Error := Lisp.Types.Error_Arena_Full;
         return;
      end if;

      Ref := S.Next_Free;
      S.Cells (Positive (S.Next_Free)) := Value;
      S.Next_Free := S.Next_Free + 1;
      Error := Lisp.Types.Error_None;
   end Allocate;

   procedure Make_Integer
     (S     : in out Arena;
      Value : in Lisp.Types.Lisp_Int;
      Ref   : out Lisp.Types.Cell_Ref;
      Error : out Lisp.Types.Error_Code) is
   begin
      Allocate (S, (Kind => Lisp.Types.Integer_Cell, Int_Value => Value), Ref, Error);
   end Make_Integer;

   procedure Make_Symbol
     (S     : in out Arena;
      Value : in Lisp.Types.Symbol_Id;
      Ref   : out Lisp.Types.Cell_Ref;
      Error : out Lisp.Types.Error_Code) is
   begin
      Allocate (S, (Kind => Lisp.Types.Symbol_Cell, Sym_Value => Value), Ref, Error);
   end Make_Symbol;

   procedure Make_Cons
     (S     : in out Arena;
      Left  : in Lisp.Types.Cell_Ref;
      Right : in Lisp.Types.Cell_Ref;
      Ref   : out Lisp.Types.Cell_Ref;
      Error : out Lisp.Types.Error_Code) is
   begin
      if (Left /= Lisp.Types.No_Ref and then Left >= S.Next_Free)
        or else
         (Right /= Lisp.Types.No_Ref and then Right >= S.Next_Free)
      then
         Ref := Lisp.Types.No_Ref;
         Error := Lisp.Types.Error_Type;
         return;
      end if;

      Allocate
        (S,
         (Kind => Lisp.Types.Cons_Cell, Left_Value => Left, Right_Value => Right),
         Ref,
         Error);
   end Make_Cons;

   procedure Make_Primitive
     (S     : in out Arena;
      Prim  : in Lisp.Types.Primitive_Kind;
      Ref   : out Lisp.Types.Cell_Ref;
      Error : out Lisp.Types.Error_Code) is
   begin
      Allocate (S, (Kind => Lisp.Types.Primitive_Cell, Prim_Value => Prim), Ref, Error);
   end Make_Primitive;

   procedure Make_Closure
     (S              : in out Arena;
      Params         : in Lisp.Types.Cell_Ref;
      Body_Expr      : in Lisp.Types.Cell_Ref;
      Captured_Frame : in Lisp.Types.Frame_Id;
      Ref            : out Lisp.Types.Cell_Ref;
      Error          : out Lisp.Types.Error_Code) is
   begin
      if (Params /= Lisp.Types.No_Ref and then Params >= S.Next_Free)
        or else
         (Body_Expr /= Lisp.Types.No_Ref and then Body_Expr >= S.Next_Free)
      then
         Ref := Lisp.Types.No_Ref;
         Error := Lisp.Types.Error_Type;
         return;
      end if;

      Allocate
        (S,
         (Kind         => Lisp.Types.Closure_Cell,
          Params_Value => Params,
          Body_Expr_Value => Body_Expr,
          Frame_Value  => Captured_Frame),
         Ref,
         Error);
   end Make_Closure;

   function Readable_Value (S : Arena; Ref : Lisp.Types.Cell_Ref) return Boolean is
   begin
      if not Is_Valid_Ref (S, Ref) then
         return False;
      end if;

      case Kind_Of (S, Ref) is
         when Lisp.Types.Nil_Cell | Lisp.Types.True_Cell | Lisp.Types.Integer_Cell | Lisp.Types.Symbol_Cell =>
            return True;
         when Lisp.Types.Cons_Cell =>
            return Readable_Value (S, Car (S, Ref)) and Readable_Value (S, Cdr (S, Ref));
         when Lisp.Types.Primitive_Cell | Lisp.Types.Closure_Cell =>
            return False;
      end case;
   end Readable_Value;

   function Proper_List (S : Arena; Ref : Lisp.Types.Cell_Ref) return Boolean is
   begin
      if Ref = Nil_Ref then
         return True;
      elsif not Is_Valid_Ref (S, Ref) then
         return False;
      elsif Kind_Of (S, Ref) /= Lisp.Types.Cons_Cell then
         return False;
      else
         return Proper_List (S, Cdr (S, Ref));
      end if;
   end Proper_List;

   function List_Length (S : Arena; Ref : Lisp.Types.Cell_Ref) return Natural is
   begin
      if Ref = Nil_Ref then
         return 0;
      elsif not Is_Valid_Ref (S, Ref) or else Kind_Of (S, Ref) /= Lisp.Types.Cons_Cell then
         return 0;
      else
         return 1 + List_Length (S, Cdr (S, Ref));
      end if;
   end List_Length;
end Lisp.Store;
