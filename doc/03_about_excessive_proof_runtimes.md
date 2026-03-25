Long proof times in SPARK almost always happen when the SMT solvers are trying to prove a property that is actually unprovable (due to a missing loop invariant or a subtle bug), or when they get bogged down by nested quantifiers. Instead of failing immediately, the solvers explore massive search spaces until they hit the timeout limit for *every single unproved check*.

To improve speed, fail early during development, and eventually achieve full closure, you need a mix of **GNATprove CLI flags**, **targeted analysis**, and **prover-guided coding techniques**.

Here is the strategy to optimize your SPARK proof workflow.

### 1. The "Fail Early" CLI Options
By default, your script uses `--steps=1000`. If a check fails, the solver spends all 1000 steps trying different paths before giving up. When writing contracts, you want the solver to give up almost instantly if the proof isn't obvious.

Change your daily development command to this:

```bash
gnatprove -j0 -P lisp_prove.gpr --mode=prove --level=0 --timeout=1 -u <changed-file>
```
*   `--level=0`: Tells GNATprove to use only the fastest prover (usually CVC5) with very basic settings. It won't try complex, time-consuming heuristic combinations.
*   `--timeout=1`: Gives the prover exactly 1 second per Verification Condition (VC). If it can't prove it in 1 second, it's usually because you are missing a `pragma Loop_Invariant` or a `Post` condition, not because it needs more time.
*   *Once `level=0` passes, you can bump to `--level=1` or `--steps=1000` to catch the few remaining complex mathematical proofs.*

### 2. Isolate Specific Subprograms
If you changed `Eval`, you don't want to wait for `Make_Cons` to be proven. You can restrict GNATprove to a **single subprogram**. This is the biggest time-saver in SPARK development.

```bash
gnatprove -j0 -P lisp_prove.gpr -u lisp-eval.adb --limit-subp=Lisp.Eval.Eval
```
This isolates the SMT solver entirely to the `Eval` procedure. Fix the contracts here until it proves instantly, then move on.

### 3. Taming "Quantifier Blowup" (Crucial for `Lisp.Env` and `Lisp.Store`)
In my previous suggestion, I provided nested `for all` quantifiers to verify array states. While mathematically sound, nested quantifiers (e.g., checking uniqueness by iterating `I` and `J` inside an iteration of `F`) cause **Combinatorial Blowup** in SMT solvers, slowing them to a crawl.

**The Fix:** Break nested quantifiers into helper `Ghost` expression functions. Solvers handle single-level quantifiers much faster because it restricts how they instantiate the rules.

Instead of one giant `Valid` function in `Lisp.Env`, do this:

```ada
--  In lisp-env.ads
function Is_Frame_Unique (Env_State : State; F : Positive) return Boolean is
  (for all I in 1 .. Env_State.Frames(F).Count =>
     (for all J in I + 1 .. Env_State.Frames(F).Count =>
        Env_State.Frames(F).Names(I) /= Env_State.Frames(F).Names(J)))
with Ghost;

function Valid (Env_State : State) return Boolean is
  (Env_State.Next_Free in 2 .. Lisp.Config.Max_Frames + 1
   and then Env_State.Frames(1).Parent = Lisp.Types.No_Frame
   and then (for all F in 2 .. Env_State.Next_Free - 1 => Env_State.Frames(F).Parent < F)
   and then (for all F in 1 .. Env_State.Next_Free - 1 => Is_Frame_Unique(Env_State, F)));
```
By hiding the inner loop inside `Is_Frame_Unique`, the SMT solver only unfolds it when it strictly needs to look at a specific frame, drastically cutting down proof time.

### 4. Use `pragma Assert` as "Stepping Stones"
If a `Post` condition is failing (or timing out), don't try to guess why. SMT solvers work by chaining facts. If they are missing a middle fact, they spin out. Add `pragma Assert` halfway through your code to guide the prover and force an early failure if a state is wrong.

```ada
procedure Make_Cons (S : in out Arena; ...) is
begin
   -- Code adding the cons cell...
   
   -- Tell the prover exactly what changed:
   pragma Assert (S.Next_Free = S'Old.Next_Free + 1);
   pragma Assert (S.Cells(S.Next_Free - 1).Kind = Lisp.Types.Cons_Cell);
   
   -- If these asserts fail, GNATprove stops here instantly 
   -- rather than timing out on the Postcondition.
end Make_Cons;
```
If an `Assert` proves instantly, but the `Post` condition still spins/fails, you know exactly *what* the solver is confused about. 

### 5. Loop Invariants: The #1 Cause of Infinite Spinning
If a function with a `while` or `for` loop is taking a long time, it is almost guaranteed that the solver has lost track of the state of your arrays or variables because of a missing `pragma Loop_Invariant`.

In SPARK, loops are black boxes. If you modify an array inside a loop, the solver assumes the **entire array is corrupted** unless you tell it otherwise.

```ada
-- Inside Lisp.Env.Define_Global
for I in 1 .. Env_State.Frames(1).Count loop
   pragma Loop_Invariant (Valid (Env_State)); -- You have this, which is good!
   pragma Loop_Invariant (Env_State.Frames(1).Count = Env_State.Frames(1).Count'Loop_Entry); 
   -- ^ ADD THIS: Tell the solver the count isn't changing during the search
   
   if Env_State.Frames(1).Names(I) = Name then ...
```

### Recommended Workflow Summary

1.  Update `scripts/prove.sh` to accept arguments so you can easily run:
    `./scripts/prove.sh --level=0 --limit-subp=Lisp.Store.Make_Cons`
2.  Refactor nested `for all` expressions into single-level `Ghost` functions.
3.  When a subprogram hangs, `Ctrl+C`, add a `pragma Assert` in the middle of it, and re-run with `--limit-subp`.
4.  Once all files pass at `--level=0`, do a final clean run with `--level=1` or `--steps=1000` to ensure total closure.