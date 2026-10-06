# TODO

## Bugs

- `+ New` runs `init()` again, which adds every param a second time (param
  ID collisions; norns warns this will become a load failure).
- `(note x)` with one argument only takes numbers 0 - 99, and values below
  10 are stored but never played.
- `sample` and `note` have no clear form; `(sample 15 (#f))` is the only
  way to empty a step.
- `(@ track)` ignores its argument (README says it is optional track).
- `append` is an empty stub.
- README lists `strtch`, the code has `strch`.
- Cell expressions are re-tokenized and re-parsed on every step; cache the
  parsed tree.
- With the `fi` keyboard layout there seems to be no way to type `'`.

## Musical features

- `amp` and `pan` shortcuts per hit (velocity is done, see `vel`).
- Non-destructive triggers: a `(trig sample note)` that fires now without
  rewriting the pattern, and a way for a cell to cancel its own step
  (conditional trigs).
- Pattern helpers: `(prob 30 expr)`, `(choose a b c)`, `(euclid k n)`, and
  a `(seq a b c)` that advances each time the cell is visited.
- A bar counter `(cyc)`, for "bar 3 of 4" logic; `ever` only tests
  modulo zero.
- Gate length and note-off: everything is one-shot, long samples can only
  be shortened with `end_frame`.
- Swing and ratchets: per-track `(swing 60)` and `(rpt 3)`.
- Softcut is initialised in `lib/_engines.lua` but unused: live resampling
  and delay ops.
- Note names and scales in lisp (`C3` is an undefined symbol today).
