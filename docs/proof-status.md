# Proof Status

- `Lisp.Config`: intended full SPARK proof, current status pending
- `Lisp.Types`: intended full SPARK proof, current status pending
- `Lisp.Arith`: intended overflow and contract proof, current status builds and tests pass, proof cleanup still pending
- `Lisp.Text_Buffers`: intended state and append proof, current status flow-clean after initialization cleanup, prove pending
- `Lisp.Symbols`: intended table validity proof, current status flow-clean after initialization cleanup, prove pending
- `Lisp.Store`: intended arena validity proof, current status functional and flow-clean except recursive termination obligations
- `Lisp.Env`: intended frame validity proof, current status flow-clean after initialization cleanup, prove pending
- `Lisp.Runtime`: intended bootstrap validity proof, current status aliasing cleanup done, further contracts still pending
- `Lisp.Lexer`: intended token progress proof, current status executable but not yet proof-friendly enough for full checks
- `Lisp.Parser`: intended runtime preservation proof, current status executable, basic flow warnings reduced, proof pending
- `Lisp.Printer`: intended canonical output proof, current status executable, out-parameter initialization fixed, proof pending
- `Lisp.Primitives`: intended contract and safety proof, current status executable, stronger preconditions added, proof pending
- `Lisp.Eval`: intended fuel and contract proof, current status executable, helper initialization tightened, proof pending
- `Lisp.Driver`: intended end-to-end SPARK proof, current status executable end-to-end, proof pending
- `app/lisp-main.adb`: intentional non-SPARK wrapper
