with Lisp.Config;

package body Lisp.Lexer with SPARK_Mode is
   function Is_Space (C : Character) return Boolean is
     (C = ' ' or else C = ASCII.HT or else C = ASCII.LF or else C = ASCII.CR);

   function Is_Delimiter (C : Character) return Boolean is
     (Is_Space (C) or else C = '(' or else C = ')' or else C = Character'Val (39));

   function Is_Digit (C : Character) return Boolean is (C in '0' .. '9');

   procedure Next_Token
     (Source   : in String;
      Pos      : in Positive;
      Item     : out Token;
      Next_Pos : out Positive) is
      I     : Positive := Pos;
      Value : Long_Long_Integer := 0;
      Sign  : Long_Long_Integer := 1;
      Max_Abs_Int : constant Long_Long_Integer :=
        (if -Long_Long_Integer (Lisp.Config.Min_Int) > Long_Long_Integer (Lisp.Config.Max_Int)
         then -Long_Long_Integer (Lisp.Config.Min_Int)
         else Long_Long_Integer (Lisp.Config.Max_Int));
   begin
      while I <= Source'Last and then Is_Space (Source (I)) loop
         pragma Loop_Invariant (I in Pos .. Source'Last + 1);
         I := I + 1;
      end loop;
      pragma Assert (I in Pos .. Source'Last + 1);

      if I > Source'Last then
         Item := (Kind => Tok_EOF, First => I, Last => I, Int_Value => 0);
         Next_Pos := I;
         return;
      end if;

      pragma Assert (I in Source'Range);

      case Source (I) is
         when '(' =>
            Item := (Kind => Tok_LParen, First => I, Last => I, Int_Value => 0);
            Next_Pos := I + 1;
            return;
         when ')' =>
            Item := (Kind => Tok_RParen, First => I, Last => I, Int_Value => 0);
            Next_Pos := I + 1;
            return;
         when Character'Val (39) =>
            Item := (Kind => Tok_Quote, First => I, Last => I, Int_Value => 0);
            Next_Pos := I + 1;
            return;
         when '.' =>
            if I = Source'Last or else Is_Delimiter (Source (I + 1)) or else Source (I + 1) = '.' then
               Item := (Kind => Tok_Dot, First => I, Last => I, Int_Value => 0);
               Next_Pos := I + 1;
            else
               declare
                  J : Positive := I;
               begin
                  while J <= Source'Last and then not Is_Delimiter (Source (J)) and then Source (J) /= ')' loop
                     pragma Loop_Invariant (J in I .. Source'Last + 1);
                     J := J + 1;
                  end loop;
                  pragma Assert (J in I .. Source'Last + 1);
                  Item := (Kind => Tok_Symbol, First => I, Last => J - 1, Int_Value => 0);
                  Next_Pos := J;
               end;
            end if;
            return;
         when '-' =>
            if I < Source'Last and then Is_Digit (Source (I + 1)) then
               Sign := -1;
               I := I + 1;
            else
               Item := (Kind => Tok_Symbol, First => I, Last => I, Int_Value => 0);
               Next_Pos := I + 1;
               return;
            end if;
         when others =>
            null;
      end case;

      if Is_Digit (Source (I)) then
         declare
            J : Positive := I;
            Digit : Long_Long_Integer;
         begin
            while J <= Source'Last and then Is_Digit (Source (J)) loop
               pragma Loop_Invariant (J in I .. Source'Last + 1);
               pragma Loop_Invariant (Value in 0 .. Max_Abs_Int + 1);
               Digit := Long_Long_Integer (Character'Pos (Source (J)) - Character'Pos ('0'));
               if Value < Max_Abs_Int / 10
                 or else
                  (Value = Max_Abs_Int / 10 and then Digit <= Max_Abs_Int mod 10)
               then
                  Value := Value * 10 + Digit;
               else
                  Value := Max_Abs_Int + 1;
               end if;
               J := J + 1;
            end loop;

            pragma Assert (J >= I + 1);
            pragma Assert (J in I + 1 .. Source'Last + 1);
            Value := Value * Sign;
            if Value < Long_Long_Integer (Lisp.Config.Min_Int)
              or else Value > Long_Long_Integer (Lisp.Config.Max_Int)
            then
               Item := (Kind => Tok_Bad, First => Pos, Last => J - 1, Int_Value => 0);
            else
               Item := (Kind      => Tok_Integer,
                        First     => Pos,
                        Last      => J - 1,
                        Int_Value => Lisp.Types.Lisp_Int (Value));
            end if;
            Next_Pos := J;
            return;
         end;
      end if;

      declare
         J : Positive := I;
      begin
         while J <= Source'Last and then not Is_Delimiter (Source (J)) and then Source (J) /= ')' loop
            pragma Loop_Invariant (J in I .. Source'Last + 1);
            J := J + 1;
         end loop;
         pragma Assert (J in I .. Source'Last + 1);

         if J = I then
            Item := (Kind => Tok_Bad, First => I, Last => I, Int_Value => 0);
            Next_Pos := I + 1;
         elsif J - I = 3 and then Source (I .. J - 1) = "nil" then
            Item := (Kind => Tok_Nil, First => I, Last => J - 1, Int_Value => 0);
            Next_Pos := J;
         elsif J - I = 1 and then Source (I .. J - 1) = "t" then
            Item := (Kind => Tok_True, First => I, Last => J - 1, Int_Value => 0);
            Next_Pos := J;
         else
            Item := (Kind => Tok_Symbol, First => I, Last => J - 1, Int_Value => 0);
            Next_Pos := J;
         end if;
      end;
   end Next_Token;
end Lisp.Lexer;
