package body Lisp.Runtime with SPARK_Mode is
   use type Lisp.Types.Error_Code;

   procedure Intern_Known
     (RT      : in out State;
      Name    : in String;
      First   : in Positive;
      Last    : in Natural;
      Name_Id : out Lisp.Types.Symbol_Id;
      Error   : out Lisp.Types.Error_Code)
   with
     Pre  => Lisp.Symbols.Valid (RT.Symbols)
       and then Lisp.Store.Valid (RT.Store)
       and then Lisp.Env.Valid (RT.Env)
       and then Name'First = 1
       and then First in Name'Range
       and then Last in First .. Name'Last,
     Post => (if Lisp.Types."=" (Error, Lisp.Types.Error_None) then
                 Lisp.Symbols.Valid (RT.Symbols)
                 and then Lisp.Store.Valid (RT.Store)
                 and then Lisp.Env.Valid (RT.Env));

   procedure Bind_Primitive
     (RT      : in out State;
      Name_Id : in Lisp.Types.Symbol_Id;
      Prim    : in Lisp.Types.Primitive_Kind;
      Error   : out Lisp.Types.Error_Code)
   with
     Pre  => Lisp.Symbols.Valid (RT.Symbols)
       and then Lisp.Store.Valid (RT.Store)
       and then Lisp.Env.Valid (RT.Env),
     Post => (if Lisp.Types."=" (Error, Lisp.Types.Error_None) then
                 Lisp.Symbols.Valid (RT.Symbols)
                 and then Lisp.Store.Valid (RT.Store)
                 and then Lisp.Env.Valid (RT.Env)) is
      Ref : Lisp.Types.Cell_Ref;
   begin
      Lisp.Store.Make_Primitive (RT.Store, Prim, Ref, Error);
      if Error /= Lisp.Types.Error_None then
         return;
      end if;

      Lisp.Env.Define_Global (RT.Env, Name_Id, Ref, Error);
   end Bind_Primitive;

   procedure Intern_Known
     (RT      : in out State;
      Name    : in String;
      First   : in Positive;
      Last    : in Natural;
      Name_Id : out Lisp.Types.Symbol_Id;
      Error   : out Lisp.Types.Error_Code) is
   begin
      Lisp.Symbols.Intern (RT.Symbols, Name, First, Last, Name_Id, Error);
   end Intern_Known;

   procedure Initialize (RT : in out State; Error : out Lisp.Types.Error_Code) is
      Name_Id : Lisp.Types.Symbol_Id;
   begin
      Lisp.Symbols.Initialize (RT.Symbols);
      Lisp.Store.Initialize (RT.Store);
      Lisp.Env.Initialize (RT.Env);
      RT.Known := (others => 0);
      pragma Assert (Lisp.Symbols.Valid (RT.Symbols));
      pragma Assert (Lisp.Store.Valid (RT.Store));
      pragma Assert (Lisp.Env.Valid (RT.Env));

      Intern_Known (RT, "quote", 1, 5, Name_Id, Error);
      if Error /= Lisp.Types.Error_None then return; end if;
      RT.Known.Quote_Id := Name_Id;
      Intern_Known (RT, "if", 1, 2, Name_Id, Error);
      if Error /= Lisp.Types.Error_None then return; end if;
      RT.Known.If_Id := Name_Id;
      Intern_Known (RT, "lambda", 1, 6, Name_Id, Error);
      if Error /= Lisp.Types.Error_None then return; end if;
      RT.Known.Lambda_Id := Name_Id;
      Intern_Known (RT, "define", 1, 6, Name_Id, Error);
      if Error /= Lisp.Types.Error_None then return; end if;
      RT.Known.Define_Id := Name_Id;
      Intern_Known (RT, "begin", 1, 5, Name_Id, Error);
      if Error /= Lisp.Types.Error_None then return; end if;
      RT.Known.Begin_Id := Name_Id;
      Intern_Known (RT, "atom", 1, 4, Name_Id, Error);
      if Error /= Lisp.Types.Error_None then return; end if;
      RT.Known.Atom_Id := Name_Id;
      Intern_Known (RT, "eq", 1, 2, Name_Id, Error);
      if Error /= Lisp.Types.Error_None then return; end if;
      RT.Known.Eq_Id := Name_Id;
      Intern_Known (RT, "cons", 1, 4, Name_Id, Error);
      if Error /= Lisp.Types.Error_None then return; end if;
      RT.Known.Cons_Id := Name_Id;
      Intern_Known (RT, "car", 1, 3, Name_Id, Error);
      if Error /= Lisp.Types.Error_None then return; end if;
      RT.Known.Car_Id := Name_Id;
      Intern_Known (RT, "cdr", 1, 3, Name_Id, Error);
      if Error /= Lisp.Types.Error_None then return; end if;
      RT.Known.Cdr_Id := Name_Id;
      Intern_Known (RT, "null", 1, 4, Name_Id, Error);
      if Error /= Lisp.Types.Error_None then return; end if;
      RT.Known.Null_Id := Name_Id;
      Intern_Known (RT, "+", 1, 1, Name_Id, Error);
      if Error /= Lisp.Types.Error_None then return; end if;
      RT.Known.Add_Id := Name_Id;
      Intern_Known (RT, "-", 1, 1, Name_Id, Error);
      if Error /= Lisp.Types.Error_None then return; end if;
      RT.Known.Sub_Id := Name_Id;
      Intern_Known (RT, "*", 1, 1, Name_Id, Error);
      if Error /= Lisp.Types.Error_None then return; end if;
      RT.Known.Mul_Id := Name_Id;
      Intern_Known (RT, "<", 1, 1, Name_Id, Error);
      if Error /= Lisp.Types.Error_None then return; end if;
      RT.Known.Lt_Id := Name_Id;
      Intern_Known (RT, "<=", 1, 2, Name_Id, Error);
      if Error /= Lisp.Types.Error_None then return; end if;
      RT.Known.Le_Id := Name_Id;

      Bind_Primitive (RT, RT.Known.Atom_Id, Lisp.Types.Prim_Atom, Error);
      if Error /= Lisp.Types.Error_None then return; end if;
      Bind_Primitive (RT, RT.Known.Eq_Id, Lisp.Types.Prim_Eq, Error);
      if Error /= Lisp.Types.Error_None then return; end if;
      Bind_Primitive (RT, RT.Known.Cons_Id, Lisp.Types.Prim_Cons, Error);
      if Error /= Lisp.Types.Error_None then return; end if;
      Bind_Primitive (RT, RT.Known.Car_Id, Lisp.Types.Prim_Car, Error);
      if Error /= Lisp.Types.Error_None then return; end if;
      Bind_Primitive (RT, RT.Known.Cdr_Id, Lisp.Types.Prim_Cdr, Error);
      if Error /= Lisp.Types.Error_None then return; end if;
      Bind_Primitive (RT, RT.Known.Null_Id, Lisp.Types.Prim_Null, Error);
      if Error /= Lisp.Types.Error_None then return; end if;
      Bind_Primitive (RT, RT.Known.Add_Id, Lisp.Types.Prim_Add, Error);
      if Error /= Lisp.Types.Error_None then return; end if;
      Bind_Primitive (RT, RT.Known.Sub_Id, Lisp.Types.Prim_Sub, Error);
      if Error /= Lisp.Types.Error_None then return; end if;
      Bind_Primitive (RT, RT.Known.Mul_Id, Lisp.Types.Prim_Mul, Error);
      if Error /= Lisp.Types.Error_None then return; end if;
      Bind_Primitive (RT, RT.Known.Lt_Id, Lisp.Types.Prim_Lt, Error);
      if Error /= Lisp.Types.Error_None then return; end if;
      Bind_Primitive (RT, RT.Known.Le_Id, Lisp.Types.Prim_Le, Error);
      if Error /= Lisp.Types.Error_None then return; end if;

      pragma Assert (Lisp.Symbols.Valid (RT.Symbols));
      pragma Assert (Lisp.Store.Valid (RT.Store));
      pragma Assert (Lisp.Env.Valid (RT.Env));
      Error := Lisp.Types.Error_None;
   end Initialize;

   function Is_Reserved (RT : State; Name : Lisp.Types.Symbol_Id) return Boolean is
     (Name = RT.Known.Quote_Id
      or else Name = RT.Known.If_Id
      or else Name = RT.Known.Lambda_Id
      or else Name = RT.Known.Define_Id
      or else Name = RT.Known.Begin_Id
      or else Name = RT.Known.Atom_Id
      or else Name = RT.Known.Eq_Id
      or else Name = RT.Known.Cons_Id
      or else Name = RT.Known.Car_Id
      or else Name = RT.Known.Cdr_Id
      or else Name = RT.Known.Null_Id
      or else Name = RT.Known.Add_Id
      or else Name = RT.Known.Sub_Id
      or else Name = RT.Known.Mul_Id
      or else Name = RT.Known.Lt_Id
      or else Name = RT.Known.Le_Id
      or else Name = 0
      or else Name = 1
      or else Name = 2);
end Lisp.Runtime;
