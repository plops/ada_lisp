with Lisp.Env;
with Lisp.Eval;
with Lisp.Lexer;
with Lisp.Parser;
with Lisp.Printer;
with Lisp.Runtime;
with Lisp.Config;

package body Lisp.Driver with SPARK_Mode is
   use type Lisp.Types.Error_Code;
   use type Lisp.Lexer.Token_Kind;

   function To_One_Based (Source : String) return String is
      Result : String (1 .. Source'Length) := (others => ' ');
   begin
      for I in Source'Range loop
         Result (I - Source'First + 1) := Source (I);
      end loop;
      return Result;
   end To_One_Based;

   procedure Run
     (Source : in String;
      Buffer : in out Lisp.Text_Buffers.Buffer;
      Error  : out Lisp.Types.Error_Code) is
      Normalized : constant String := To_One_Based (Source);
      RT       : Lisp.Runtime.State;
      Expr     : Lisp.Types.Cell_Ref;
      Result   : Lisp.Types.Cell_Ref;
      Next_Pos : Natural;
      Dummy_Pos : Natural;
      Tok      : Lisp.Lexer.Token;
   begin
      if Normalized'Length = 0 then
         Error := Lisp.Types.Error_Syntax;
         return;
      end if;

      Lisp.Runtime.Initialize (RT, Error);
      if Error /= Lisp.Types.Error_None then
         return;
      end if;

      Lisp.Parser.Parse_One (Normalized, 1, RT, Expr, Next_Pos, Error);
      if Error /= Lisp.Types.Error_None then
         return;
      end if;

      if Next_Pos = 0 then
         Error := Lisp.Types.Error_Syntax;
         return;
      end if;

      Lisp.Lexer.Next_Token (Normalized, Positive (Next_Pos), Tok, Dummy_Pos);
      if Tok.Kind /= Lisp.Lexer.Tok_EOF then
         Error := Lisp.Types.Error_Trailing_Input;
         return;
      end if;

      Lisp.Eval.Eval (RT, Lisp.Env.Global_Frame, Expr, Lisp.Config.Max_Fuel, Result, Error);
      if Error /= Lisp.Types.Error_None then
         return;
      end if;

      Lisp.Printer.Print (RT, Result, Buffer, Error);
   end Run;
end Lisp.Driver;
