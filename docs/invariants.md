# Core Invariants

Global invariants:

- Every cell only references smaller cell refs.
- Every frame only references smaller frame ids.

Package-local validity rules:

- `Lisp.Symbols`: used slots are unique by textual content and `Count` never decreases except during initialization.
- `Lisp.Store`: refs `1` and `2` are the canonical `nil` and `t` cells; every used child ref is `No_Ref` or smaller than the owner cell ref.
- `Lisp.Env`: frame `1` is the global frame, every non-global frame has a smaller parent id, and names in a frame are unique in the used prefix.
- `Lisp.Runtime`: validity of the runtime implies validity of symbols, store, and environment, and the cached reserved-name ids refer to interned symbols in the frozen order.
