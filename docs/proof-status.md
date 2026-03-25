# Proof Status

- `Lisp.Config`: intended full SPARK proof, current status flow-clean, no unproved checks reported in the latest summary
- `Lisp.Types`: intended full SPARK proof, current status flow-clean, no unproved checks reported in the latest summary
- `Lisp.Arith`: intended overflow and contract proof, current status proved in the latest summary, no remaining unproved checks reported
- `Lisp.Text_Buffers`: intended state and append proof, current status flow-clean, no remaining unproved checks reported
- `Lisp.Symbols`: intended table validity proof, current status flow-clean, proof summary still reports pending contract-strengthening around callers rather than local logic
- `Lisp.Store`: intended arena validity proof, current status flow-clean, no remaining unproved checks reported in the latest summary
- `Lisp.Env`: intended frame validity proof, current status flow-clean but not proof-clean, remaining unproved checks are postcondition obligations around `Initialize`, `Define_Global`, and `Push_Frame`
- `Lisp.Runtime`: intended bootstrap validity proof, current status flow-clean, no remaining unproved checks reported in the latest summary
- `Lisp.Lexer`: intended token progress proof, current status not proof-clean, remaining unproved checks are array-index, range, and overflow obligations in `Next_Token`
- `Lisp.Parser`: intended runtime preservation proof, current status not proof-clean, remaining unproved checks are list-capacity/index and token-position obligations in `Make_List`, `Parse_List`, and `Parse_Expr`
- `Lisp.Printer`: intended canonical output proof, current status not proof-clean, remaining unproved check is a `Lookup_Image`/buffer validity precondition in `Print`
- `Lisp.Primitives`: intended contract and safety proof, current status not proof-clean, remaining unproved checks are argument index obligations plus store-validity propagation in `Apply`
- `Lisp.Eval`: intended fuel and contract proof, current status not proof-clean, remaining unproved checks are `Fuel - 1` range obligations, list/index bounds, and runtime-validity propagation through helper calls
- `Lisp.Driver`: intended end-to-end SPARK proof, current status flow-clean, no remaining unproved checks reported in the latest summary
- `Lisp.Model`: intended ghost reference semantics for the pure closed subset, current status scaffolded ghost model added, remaining proof work is termination/variant strengthening for recursive comparison predicates
- `Proof.Refinement`: intended executable-vs-model refinement theorem, current status scaffolded readable-result refinement lemma added, full theorem still pending
- `app/lisp-main.adb`: intentional non-SPARK wrapper

Latest project proof summary from `gnatprove`:

- total checks: `218`
- unproved: `35`
- assertions unproved: `32`
- functional contracts unproved: `2`
- termination unproved: `1`

Those remaining `35` unproved checks are not yet a clean proof gate. The dominant outstanding work is still in `Lisp.Lexer`, `Lisp.Parser`, `Lisp.Primitives`, `Lisp.Eval`, `Lisp.Store`, `Lisp.Env`, `Lisp.Printer`, plus one new model-side termination obligation.
