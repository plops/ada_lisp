with Lisp.Store;
with Lisp.Symbols;

package body Lisp.Printer with SPARK_Mode is
   use type Lisp.Types.Error_Code;
   use type Lisp.Types.Cell_Kind;

   procedure Print_List_Tail
     (RT     : in Lisp.Runtime.State;
      Ref    : in Lisp.Types.Cell_Ref;
      Buffer : in out Lisp.Text_Buffers.Buffer;
      Error  : out Lisp.Types.Error_Code)
   with
     Pre  => Lisp.Runtime.Valid (RT)
       and then Lisp.Text_Buffers.Valid (Buffer)
       and then (Ref = Lisp.Store.Nil_Ref or else Lisp.Store.Is_Valid_Ref (RT.Store, Ref)),
     Post => Lisp.Runtime.Valid (RT)
       and then Lisp.Text_Buffers.Valid (Buffer) is
   begin
      Error := Lisp.Types.Error_None;
      if Ref = Lisp.Store.Nil_Ref then
         return;
      elsif Lisp.Store.Kind_Of (RT.Store, Ref) = Lisp.Types.Cons_Cell then
         declare
            pragma Assert (Lisp.Store.Valid (RT.Store));
            Head_Ref : constant Lisp.Types.Cell_Ref := Lisp.Store.Car (RT.Store, Ref);
            Tail_Ref : constant Lisp.Types.Cell_Ref := Lisp.Store.Cdr (RT.Store, Ref);
         begin
            if Head_Ref = Lisp.Types.No_Ref
              or else (Tail_Ref /= Lisp.Store.Nil_Ref and then not Lisp.Store.Is_Valid_Ref (RT.Store, Tail_Ref))
            then
               Error := Lisp.Types.Error_Type;
               return;
            end if;
            Lisp.Text_Buffers.Append_Char (Buffer, ' ', Error);
            if Error /= Lisp.Types.Error_None then
               return;
            end if;
            Print (RT, Head_Ref, Buffer, Error);
            if Error /= Lisp.Types.Error_None then
               return;
            end if;
            Print_List_Tail (RT, Tail_Ref, Buffer, Error);
         end;
      else
         Lisp.Text_Buffers.Append_String (Buffer, " . ", Error);
         if Error /= Lisp.Types.Error_None then
            return;
         end if;
         Print (RT, Ref, Buffer, Error);
      end if;
   end Print_List_Tail;

   procedure Print
     (RT     : in Lisp.Runtime.State;
      Ref    : in Lisp.Types.Cell_Ref;
      Buffer : in out Lisp.Text_Buffers.Buffer;
      Error  : out Lisp.Types.Error_Code) is
   begin
      case Lisp.Store.Kind_Of (RT.Store, Ref) is
         when Lisp.Types.Nil_Cell =>
            Lisp.Text_Buffers.Append_String (Buffer, "nil", Error);
         when Lisp.Types.True_Cell =>
            Lisp.Text_Buffers.Append_String (Buffer, "t", Error);
         when Lisp.Types.Integer_Cell =>
            declare
               Img : constant String := Lisp.Types.Lisp_Int'Image (Lisp.Store.Integer_Value (RT.Store, Ref));
            begin
               if Img'Length > 0 and then Img (Img'First) = ' ' then
                  Lisp.Text_Buffers.Append_String (Buffer, Img (Img'First + 1 .. Img'Last), Error);
               else
                  Lisp.Text_Buffers.Append_String (Buffer, Img, Error);
               end if;
            end;
         when Lisp.Types.Symbol_Cell =>
            Lisp.Symbols.Lookup_Image (RT.Symbols, Lisp.Store.Symbol_Value (RT.Store, Ref), Buffer, Error);
         when Lisp.Types.Cons_Cell =>
            declare
               pragma Assert (Lisp.Store.Valid (RT.Store));
               Head_Ref : constant Lisp.Types.Cell_Ref := Lisp.Store.Car (RT.Store, Ref);
               Tail_Ref : constant Lisp.Types.Cell_Ref := Lisp.Store.Cdr (RT.Store, Ref);
            begin
               if Head_Ref = Lisp.Types.No_Ref
                 or else (Tail_Ref /= Lisp.Store.Nil_Ref and then not Lisp.Store.Is_Valid_Ref (RT.Store, Tail_Ref))
               then
                  Error := Lisp.Types.Error_Type;
                  return;
               end if;
               Lisp.Text_Buffers.Append_Char (Buffer, '(', Error);
               if Error /= Lisp.Types.Error_None then
                  return;
               end if;
               Print (RT, Head_Ref, Buffer, Error);
               if Error /= Lisp.Types.Error_None then
                  return;
               end if;
               Print_List_Tail (RT, Tail_Ref, Buffer, Error);
               if Error /= Lisp.Types.Error_None then
                  return;
               end if;
               Lisp.Text_Buffers.Append_Char (Buffer, ')', Error);
            end;
         when Lisp.Types.Primitive_Cell =>
            Lisp.Text_Buffers.Append_String (Buffer, "#<primitive>", Error);
         when Lisp.Types.Closure_Cell =>
            Lisp.Text_Buffers.Append_String (Buffer, "#<closure>", Error);
      end case;
   end Print;
end Lisp.Printer;
