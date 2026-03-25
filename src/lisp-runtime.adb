package body Lisp.Runtime with SPARK_Mode is
   use type Lisp.Types.Error_Code;

   procedure Bind_Primitive
     (RT      : in out State;
      Name_Id : in Lisp.Types.Symbol_Id;
      Prim    : in Lisp.Types.Primitive_Kind;
      Error   : out Lisp.Types.Error_Code) is
      Ref : Lisp.Types.Cell_Ref;
   begin
      Lisp.Store.Make_Primitive (RT.Store, Prim, Ref, Error);
      if Error /= Lisp.Types.Error_None then
         return;
      end if;

      Lisp.Env.Define_Global (RT.Env, Name_Id, Ref, Error);
   end Bind_Primitive;

   procedure Initialize (RT : in out State; Error : out Lisp.Types.Error_Code) is
   begin
      Lisp.Symbols.Initialize (RT.Symbols);
      Lisp.Store.Initialize (RT.Store);
      Lisp.Env.Initialize (RT.Env);
      RT.Known := (others => 0);

      Lisp.Symbols.Intern (RT.Symbols, "quote", 1, 5, RT.Known.Quote_Id, Error);
      if Error /= Lisp.Types.Error_None then return; end if;
      Lisp.Symbols.Intern (RT.Symbols, "if", 1, 2, RT.Known.If_Id, Error);
      if Error /= Lisp.Types.Error_None then return; end if;
      Lisp.Symbols.Intern (RT.Symbols, "lambda", 1, 6, RT.Known.Lambda_Id, Error);
      if Error /= Lisp.Types.Error_None then return; end if;
      Lisp.Symbols.Intern (RT.Symbols, "define", 1, 6, RT.Known.Define_Id, Error);
      if Error /= Lisp.Types.Error_None then return; end if;
      Lisp.Symbols.Intern (RT.Symbols, "begin", 1, 5, RT.Known.Begin_Id, Error);
      if Error /= Lisp.Types.Error_None then return; end if;
      Lisp.Symbols.Intern (RT.Symbols, "atom", 1, 4, RT.Known.Atom_Id, Error);
      if Error /= Lisp.Types.Error_None then return; end if;
      Lisp.Symbols.Intern (RT.Symbols, "eq", 1, 2, RT.Known.Eq_Id, Error);
      if Error /= Lisp.Types.Error_None then return; end if;
      Lisp.Symbols.Intern (RT.Symbols, "cons", 1, 4, RT.Known.Cons_Id, Error);
      if Error /= Lisp.Types.Error_None then return; end if;
      Lisp.Symbols.Intern (RT.Symbols, "car", 1, 3, RT.Known.Car_Id, Error);
      if Error /= Lisp.Types.Error_None then return; end if;
      Lisp.Symbols.Intern (RT.Symbols, "cdr", 1, 3, RT.Known.Cdr_Id, Error);
      if Error /= Lisp.Types.Error_None then return; end if;
      Lisp.Symbols.Intern (RT.Symbols, "null", 1, 4, RT.Known.Null_Id, Error);
      if Error /= Lisp.Types.Error_None then return; end if;
      Lisp.Symbols.Intern (RT.Symbols, "+", 1, 1, RT.Known.Add_Id, Error);
      if Error /= Lisp.Types.Error_None then return; end if;
      Lisp.Symbols.Intern (RT.Symbols, "-", 1, 1, RT.Known.Sub_Id, Error);
      if Error /= Lisp.Types.Error_None then return; end if;
      Lisp.Symbols.Intern (RT.Symbols, "*", 1, 1, RT.Known.Mul_Id, Error);
      if Error /= Lisp.Types.Error_None then return; end if;
      Lisp.Symbols.Intern (RT.Symbols, "<", 1, 1, RT.Known.Lt_Id, Error);
      if Error /= Lisp.Types.Error_None then return; end if;
      Lisp.Symbols.Intern (RT.Symbols, "<=", 1, 2, RT.Known.Le_Id, Error);
      if Error /= Lisp.Types.Error_None then return; end if;

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

      Error := Lisp.Types.Error_None;
   end Initialize;

   function Valid (RT : State) return Boolean is
     (Lisp.Symbols.Valid (RT.Symbols)
      and Lisp.Store.Valid (RT.Store)
      and Lisp.Env.Valid (RT.Env));

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
