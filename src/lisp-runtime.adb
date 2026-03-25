package body Lisp.Runtime with SPARK_Mode is
   use type Lisp.Types.Error_Code;

   procedure Bind_Primitive
     (RT    : in out State;
      Name  : in String;
      Prim  : in Lisp.Types.Primitive_Kind;
      Id    : out Lisp.Types.Symbol_Id;
      Error : out Lisp.Types.Error_Code) is
      Ref : Lisp.Types.Cell_Ref := Lisp.Types.No_Ref;
   begin
      Lisp.Symbols.Intern (RT.Symbols, Name, Name'First, Name'Last, Id, Error);
      if Error /= Lisp.Types.Error_None then
         return;
      end if;

      Lisp.Store.Make_Primitive (RT.Store, Prim, Ref, Error);
      if Error /= Lisp.Types.Error_None then
         return;
      end if;

      Lisp.Env.Define_Global (RT.Env, Id, Ref, Error);
   end Bind_Primitive;

   procedure Initialize (RT : out State; Error : out Lisp.Types.Error_Code) is
      Dummy : Lisp.Types.Symbol_Id := 0;
      Ref   : Lisp.Types.Cell_Ref := Lisp.Types.No_Ref;

      procedure Intern_Known
        (Name  : in String;
         Slot  : out Lisp.Types.Symbol_Id) is
      begin
         Lisp.Symbols.Intern (RT.Symbols, Name, Name'First, Name'Last, Slot, Error);
      end Intern_Known;
   begin
      Lisp.Symbols.Initialize (RT.Symbols);
      Lisp.Store.Initialize (RT.Store);
      Lisp.Env.Initialize (RT.Env);

      Intern_Known ("quote", RT.Known.Quote_Id);  if Error /= Lisp.Types.Error_None then return; end if;
      Intern_Known ("if", RT.Known.If_Id);        if Error /= Lisp.Types.Error_None then return; end if;
      Intern_Known ("lambda", RT.Known.Lambda_Id);if Error /= Lisp.Types.Error_None then return; end if;
      Intern_Known ("define", RT.Known.Define_Id);if Error /= Lisp.Types.Error_None then return; end if;
      Intern_Known ("begin", RT.Known.Begin_Id);  if Error /= Lisp.Types.Error_None then return; end if;
      Intern_Known ("atom", RT.Known.Atom_Id);    if Error /= Lisp.Types.Error_None then return; end if;
      Intern_Known ("eq", RT.Known.Eq_Id);        if Error /= Lisp.Types.Error_None then return; end if;
      Intern_Known ("cons", RT.Known.Cons_Id);    if Error /= Lisp.Types.Error_None then return; end if;
      Intern_Known ("car", RT.Known.Car_Id);      if Error /= Lisp.Types.Error_None then return; end if;
      Intern_Known ("cdr", RT.Known.Cdr_Id);      if Error /= Lisp.Types.Error_None then return; end if;
      Intern_Known ("null", RT.Known.Null_Id);    if Error /= Lisp.Types.Error_None then return; end if;
      Intern_Known ("+", RT.Known.Add_Id);        if Error /= Lisp.Types.Error_None then return; end if;
      Intern_Known ("-", RT.Known.Sub_Id);        if Error /= Lisp.Types.Error_None then return; end if;
      Intern_Known ("*", RT.Known.Mul_Id);        if Error /= Lisp.Types.Error_None then return; end if;
      Intern_Known ("<", RT.Known.Lt_Id);         if Error /= Lisp.Types.Error_None then return; end if;
      Intern_Known ("<=", RT.Known.Le_Id);        if Error /= Lisp.Types.Error_None then return; end if;

      Lisp.Store.Make_Primitive (RT.Store, Lisp.Types.Prim_Atom, Ref, Error);
      if Error = Lisp.Types.Error_None then
         Lisp.Env.Define_Global (RT.Env, RT.Known.Atom_Id, Ref, Error);
      end if;
      if Error /= Lisp.Types.Error_None then
         return;
      end if;

      Lisp.Store.Make_Primitive (RT.Store, Lisp.Types.Prim_Eq, Ref, Error);
      if Error = Lisp.Types.Error_None then
         Lisp.Env.Define_Global (RT.Env, RT.Known.Eq_Id, Ref, Error);
      end if;
      if Error /= Lisp.Types.Error_None then
         return;
      end if;

      Lisp.Store.Make_Primitive (RT.Store, Lisp.Types.Prim_Cons, Ref, Error);
      if Error = Lisp.Types.Error_None then
         Lisp.Env.Define_Global (RT.Env, RT.Known.Cons_Id, Ref, Error);
      end if;
      if Error /= Lisp.Types.Error_None then
         return;
      end if;

      Lisp.Store.Make_Primitive (RT.Store, Lisp.Types.Prim_Car, Ref, Error);
      if Error = Lisp.Types.Error_None then
         Lisp.Env.Define_Global (RT.Env, RT.Known.Car_Id, Ref, Error);
      end if;
      if Error /= Lisp.Types.Error_None then
         return;
      end if;

      Lisp.Store.Make_Primitive (RT.Store, Lisp.Types.Prim_Cdr, Ref, Error);
      if Error = Lisp.Types.Error_None then
         Lisp.Env.Define_Global (RT.Env, RT.Known.Cdr_Id, Ref, Error);
      end if;
      if Error /= Lisp.Types.Error_None then
         return;
      end if;

      Lisp.Store.Make_Primitive (RT.Store, Lisp.Types.Prim_Null, Ref, Error);
      if Error = Lisp.Types.Error_None then
         Lisp.Env.Define_Global (RT.Env, RT.Known.Null_Id, Ref, Error);
      end if;
      if Error /= Lisp.Types.Error_None then
         return;
      end if;

      Lisp.Store.Make_Primitive (RT.Store, Lisp.Types.Prim_Add, Ref, Error);
      if Error = Lisp.Types.Error_None then
         Lisp.Env.Define_Global (RT.Env, RT.Known.Add_Id, Ref, Error);
      end if;
      if Error /= Lisp.Types.Error_None then
         return;
      end if;

      Lisp.Store.Make_Primitive (RT.Store, Lisp.Types.Prim_Sub, Ref, Error);
      if Error = Lisp.Types.Error_None then
         Lisp.Env.Define_Global (RT.Env, RT.Known.Sub_Id, Ref, Error);
      end if;
      if Error /= Lisp.Types.Error_None then
         return;
      end if;

      Lisp.Store.Make_Primitive (RT.Store, Lisp.Types.Prim_Mul, Ref, Error);
      if Error = Lisp.Types.Error_None then
         Lisp.Env.Define_Global (RT.Env, RT.Known.Mul_Id, Ref, Error);
      end if;
      if Error /= Lisp.Types.Error_None then
         return;
      end if;

      Lisp.Store.Make_Primitive (RT.Store, Lisp.Types.Prim_Lt, Ref, Error);
      if Error = Lisp.Types.Error_None then
         Lisp.Env.Define_Global (RT.Env, RT.Known.Lt_Id, Ref, Error);
      end if;
      if Error /= Lisp.Types.Error_None then
         return;
      end if;

      Lisp.Store.Make_Primitive (RT.Store, Lisp.Types.Prim_Le, Ref, Error);
      if Error = Lisp.Types.Error_None then
         Lisp.Env.Define_Global (RT.Env, RT.Known.Le_Id, Ref, Error);
      end if;
      if Error /= Lisp.Types.Error_None then
         return;
      end if;

      Dummy := 0;
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
