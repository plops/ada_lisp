package body Lisp.Store with SPARK_Mode is
   use type Lisp.Types.Cell_Kind;

   procedure Initialize (S : out Arena) is
   begin
      S.Cells := (others => (Kind => Lisp.Types.Nil_Cell));
      S.Cells (1) := (Kind => Lisp.Types.Nil_Cell);
      S.Cells (2) := (Kind => Lisp.Types.True_Cell);
      S.Next_Free := 3;
   end Initialize;

   function Is_Valid_Ref (S : Arena; Ref : Lisp.Types.Cell_Ref) return Boolean is
     (Ref /= Lisp.Types.No_Ref and then Ref < S.Next_Free);

   function Kind_Of (S : Arena; Ref : Lisp.Types.Cell_Ref) return Lisp.Types.Cell_Kind is
   begin
      return S.Cells (Positive (Ref)).Kind;
   end Kind_Of;

   function Integer_Value (S : Arena; Ref : Lisp.Types.Cell_Ref) return Lisp.Types.Lisp_Int is
   begin
      case S.Cells (Positive (Ref)).Kind is
         when Lisp.Types.Integer_Cell =>
            return S.Cells (Positive (Ref)).Int_Value;
         when others =>
            return 0;
      end case;
   end Integer_Value;

   function Symbol_Value (S : Arena; Ref : Lisp.Types.Cell_Ref) return Lisp.Types.Symbol_Id is
   begin
      case S.Cells (Positive (Ref)).Kind is
         when Lisp.Types.Symbol_Cell =>
            return S.Cells (Positive (Ref)).Sym_Value;
         when others =>
            return 0;
      end case;
   end Symbol_Value;

   function Car (S : Arena; Ref : Lisp.Types.Cell_Ref) return Lisp.Types.Cell_Ref is
   begin
      case S.Cells (Positive (Ref)).Kind is
         when Lisp.Types.Cons_Cell =>
            pragma Assert (Cell_Refs_Below (S, Positive (Ref)));
            return S.Cells (Positive (Ref)).Left_Value;
         when others =>
            return Lisp.Types.No_Ref;
      end case;
   end Car;

   function Cdr (S : Arena; Ref : Lisp.Types.Cell_Ref) return Lisp.Types.Cell_Ref is
   begin
      case S.Cells (Positive (Ref)).Kind is
         when Lisp.Types.Cons_Cell =>
            pragma Assert (Cell_Refs_Below (S, Positive (Ref)));
            return S.Cells (Positive (Ref)).Right_Value;
         when others =>
            return Lisp.Types.No_Ref;
      end case;
   end Cdr;

   function Primitive_Value (S : Arena; Ref : Lisp.Types.Cell_Ref) return Lisp.Types.Primitive_Kind is
   begin
      case S.Cells (Positive (Ref)).Kind is
         when Lisp.Types.Primitive_Cell =>
            return S.Cells (Positive (Ref)).Prim_Value;
         when others =>
            return Lisp.Types.Prim_Atom;
      end case;
   end Primitive_Value;

   function Closure_Params (S : Arena; Ref : Lisp.Types.Cell_Ref) return Lisp.Types.Cell_Ref is
   begin
      case S.Cells (Positive (Ref)).Kind is
         when Lisp.Types.Closure_Cell =>
            return S.Cells (Positive (Ref)).Params_Value;
         when others =>
            return Lisp.Types.No_Ref;
      end case;
   end Closure_Params;

   function Closure_Body (S : Arena; Ref : Lisp.Types.Cell_Ref) return Lisp.Types.Cell_Ref is
   begin
      case S.Cells (Positive (Ref)).Kind is
         when Lisp.Types.Closure_Cell =>
            return S.Cells (Positive (Ref)).Body_Expr_Value;
         when others =>
            return Lisp.Types.No_Ref;
      end case;
   end Closure_Body;

   function Closure_Frame (S : Arena; Ref : Lisp.Types.Cell_Ref) return Lisp.Types.Frame_Id is
   begin
      case S.Cells (Positive (Ref)).Kind is
         when Lisp.Types.Closure_Cell =>
            return S.Cells (Positive (Ref)).Frame_Value;
         when others =>
            return Lisp.Types.No_Frame;
      end case;
   end Closure_Frame;

   function Allocatable_Value (S : Arena; Value : Cell) return Boolean is
     (case Value.Kind is
         when Lisp.Types.Cons_Cell =>
           (Value.Left_Value = Lisp.Types.No_Ref or else Value.Left_Value < S.Next_Free)
           and then
           (Value.Right_Value = Lisp.Types.No_Ref or else Value.Right_Value < S.Next_Free),
         when Lisp.Types.Closure_Cell =>
           (Value.Params_Value = Lisp.Types.No_Ref or else Value.Params_Value < S.Next_Free)
           and then
           (Value.Body_Expr_Value = Lisp.Types.No_Ref or else Value.Body_Expr_Value < S.Next_Free),
         when others =>
           True);

   procedure Allocate
     (S     : in out Arena;
      Value : in Cell;
      Ref   : out Lisp.Types.Cell_Ref;
     Error : out Lisp.Types.Error_Code)
   with
     Pre  => Valid (S) and then Allocatable_Value (S, Value),
     Post =>
       S.Next_Free in 3 .. Lisp.Config.Max_Cells + 1
       and then S.Cells (1).Kind = Lisp.Types.Nil_Cell
       and then S.Cells (2).Kind = Lisp.Types.True_Cell
       and then
       (if Lisp.Types."=" (Error, Lisp.Types.Error_None) then
           Ref = S'Old.Next_Free
           and then S.Next_Free = S'Old.Next_Free + 1
           and then Cell_Refs_Below (S, Positive (Ref))
        else
           Ref = Lisp.Types.No_Ref
           and then S.Next_Free = S'Old.Next_Free) is
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
      if S.Next_Free = Lisp.Config.Max_Cells + 1 then
         Ref := Lisp.Types.No_Ref;
         Error := Lisp.Types.Error_Arena_Full;
         return;
      end if;

      Ref := S.Next_Free;
      S.Cells (Positive (Ref)) := (Kind => Lisp.Types.Integer_Cell, Int_Value => Value);
      S.Next_Free := Ref + 1;
      Error := Lisp.Types.Error_None;
   end Make_Integer;

   procedure Make_Symbol
     (S     : in out Arena;
      Value : in Lisp.Types.Symbol_Id;
      Ref   : out Lisp.Types.Cell_Ref;
      Error : out Lisp.Types.Error_Code) is
   begin
      if S.Next_Free = Lisp.Config.Max_Cells + 1 then
         Ref := Lisp.Types.No_Ref;
         Error := Lisp.Types.Error_Arena_Full;
         return;
      end if;

      Ref := S.Next_Free;
      S.Cells (Positive (Ref)) := (Kind => Lisp.Types.Symbol_Cell, Sym_Value => Value);
      S.Next_Free := Ref + 1;
      Error := Lisp.Types.Error_None;
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

      if S.Next_Free = Lisp.Config.Max_Cells + 1 then
         Ref := Lisp.Types.No_Ref;
         Error := Lisp.Types.Error_Arena_Full;
         return;
      end if;

      Ref := S.Next_Free;
      S.Cells (Positive (Ref)) :=
        (Kind => Lisp.Types.Cons_Cell, Left_Value => Left, Right_Value => Right);
      S.Next_Free := Ref + 1;
      pragma Assert ((for all I in 3 .. Ref - 1 => Cell_Refs_Below (S, I)));
      pragma Assert (Cell_Refs_Below (S, Positive (Ref)));
      Error := Lisp.Types.Error_None;
   end Make_Cons;

   procedure Make_Primitive
     (S     : in out Arena;
      Prim  : in Lisp.Types.Primitive_Kind;
      Ref   : out Lisp.Types.Cell_Ref;
      Error : out Lisp.Types.Error_Code) is
   begin
      if S.Next_Free = Lisp.Config.Max_Cells + 1 then
         Ref := Lisp.Types.No_Ref;
         Error := Lisp.Types.Error_Arena_Full;
         return;
      end if;

      Ref := S.Next_Free;
      S.Cells (Positive (Ref)) := (Kind => Lisp.Types.Primitive_Cell, Prim_Value => Prim);
      S.Next_Free := Ref + 1;
      Error := Lisp.Types.Error_None;
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

      if S.Next_Free = Lisp.Config.Max_Cells + 1 then
         Ref := Lisp.Types.No_Ref;
         Error := Lisp.Types.Error_Arena_Full;
         return;
      end if;

      Ref := S.Next_Free;
      S.Cells (Positive (Ref)) :=
        (Kind            => Lisp.Types.Closure_Cell,
         Params_Value    => Params,
         Body_Expr_Value => Body_Expr,
         Frame_Value     => Captured_Frame);
      S.Next_Free := Ref + 1;
      pragma Assert ((for all I in 3 .. Ref - 1 => Cell_Refs_Below (S, I)));
      pragma Assert (Cell_Refs_Below (S, Positive (Ref)));
      Error := Lisp.Types.Error_None;
   end Make_Closure;

   function Readable_Value (S : Arena; Ref : Lisp.Types.Cell_Ref) return Boolean is
      Left_Ref  : Lisp.Types.Cell_Ref;
      Right_Ref : Lisp.Types.Cell_Ref;
   begin
      if not Is_Valid_Ref (S, Ref) then
         return False;
      end if;

      case S.Cells (Positive (Ref)).Kind is
         when Lisp.Types.Nil_Cell | Lisp.Types.True_Cell | Lisp.Types.Integer_Cell | Lisp.Types.Symbol_Cell =>
            return True;
         when Lisp.Types.Cons_Cell =>
            pragma Assert (Cell_Refs_Below (S, Positive (Ref)));
            Left_Ref := S.Cells (Positive (Ref)).Left_Value;
            Right_Ref := S.Cells (Positive (Ref)).Right_Value;
            pragma Assert (Left_Ref < Ref);
            pragma Assert (Right_Ref < Ref);
            pragma Assert (Left_Ref = Lisp.Types.No_Ref or else Is_Valid_Ref (S, Left_Ref));
            pragma Assert (Right_Ref = Lisp.Types.No_Ref or else Is_Valid_Ref (S, Right_Ref));
            return Readable_Value (S, Left_Ref) and Readable_Value (S, Right_Ref);
         when Lisp.Types.Primitive_Cell | Lisp.Types.Closure_Cell =>
            return False;
      end case;
   end Readable_Value;

   function Proper_List (S : Arena; Ref : Lisp.Types.Cell_Ref) return Boolean is
      Tail_Ref : Lisp.Types.Cell_Ref;
   begin
      if Ref = Nil_Ref then
         return True;
      elsif not Is_Valid_Ref (S, Ref) then
         return False;
      elsif S.Cells (Positive (Ref)).Kind /= Lisp.Types.Cons_Cell then
         return False;
      else
         pragma Assert (Cell_Refs_Below (S, Positive (Ref)));
         Tail_Ref := S.Cells (Positive (Ref)).Right_Value;
         pragma Assert (Tail_Ref < Ref);
         pragma Assert (Tail_Ref = Lisp.Types.No_Ref or else Is_Valid_Ref (S, Tail_Ref));
         return Proper_List (S, Tail_Ref);
      end if;
   end Proper_List;

   function List_Length (S : Arena; Ref : Lisp.Types.Cell_Ref) return Natural is
      Tail_Ref : Lisp.Types.Cell_Ref;
   begin
      if Ref = Nil_Ref then
         return 0;
      elsif not Is_Valid_Ref (S, Ref) or else S.Cells (Positive (Ref)).Kind /= Lisp.Types.Cons_Cell then
         return 0;
      else
         pragma Assert (Cell_Refs_Below (S, Positive (Ref)));
         Tail_Ref := S.Cells (Positive (Ref)).Right_Value;
         pragma Assert (Tail_Ref < Ref);
         pragma Assert (Tail_Ref = Lisp.Types.No_Ref or else Is_Valid_Ref (S, Tail_Ref));
         return 1 + List_Length (S, Tail_Ref);
      end if;
   end List_Length;
end Lisp.Store;
