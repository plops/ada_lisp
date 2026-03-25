# Frozen v1 Semantics

```text
expr   ::= integer
         | nil
         | t
         | symbol
         | ' expr
         | ( )
         | ( expr+ )
         | ( expr+ . expr )
```

Frozen evaluation rules:

- Data kinds: `nil`, `t`, integers, symbols, cons cells, primitive function values, closure values.
- `nil` and `t` are reserved constants, not ordinary bindable identifiers.
- Only `nil` is false. Everything else is true.
- `'x` is reader sugar for `(quote x)`.
- The printer is canonical. It does not emit quote shorthand. It prints `nil` instead of `()`.
- Dotted pairs are supported in the reader and printer.
- Special forms: `quote`, `if`, `begin`, `lambda`, `define`.
- `lambda` takes exactly two arguments: parameter list and one body expression.
- `define` only supports `(define <symbol> <expr>)`, only at top level, and may not redefine reserved names.
- Application order is strict left-to-right: operator first, then arguments left-to-right.
- `car nil = nil` and `cdr nil = nil`.
- `atom` returns `t` for anything that is not a cons cell.
- `eq` returns `t` when refs are identical, or when two integers have the same numeric value, or when two symbols have the same symbol id; otherwise `nil`.
- One evaluation per fresh runtime. No REPL in v1. Use `(begin ...)` for multi-step programs.
- No macros, quasiquote, mutation of cons cells, strings, characters, vectors, floating point, variadics, GC, tail-call promises, or FFI.

Reserved names, in frozen order:

1. `quote`
2. `if`
3. `lambda`
4. `define`
5. `begin`
6. `atom`
7. `eq`
8. `cons`
9. `car`
10. `cdr`
11. `null`
12. `+`
13. `-`
14. `*`
15. `<`
16. `<=`
