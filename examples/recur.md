# recur: a pattern that rebuilds itself

Files: `recur.seq` (and `recur-seed.seq`, written on first play).

A variation of the `techno` project that shows `(save)` and `(load)` being
called from pattern cells. The pattern starts sparse, writes more notes into
itself every bar, and when it has written enough it reloads the sparse
snapshot and starts again. One build takes 8 bars.

Copy `recur.seq` to `dust/data/NISPM/`, load it with `> Load project` in
the params menu and start playback (`shift + ctrl`).

There is no `.pset` with it, so it plays with the samples that are loaded.
Right after the script starts those are the ones of the default project,
which is what the sample numbers here expect.

## What it demonstrates

- `(save id)` and `(load id)` are ordinary functions, so a cell can snapshot
  the whole project and swap it back in while the sequencer runs.
- Cells that write notes into other steps: `(sample step id)` and
  `(note step value)`.
- State shared between cells through the init cell: a counter and a flag,
  changed with `set!` from inside lambdas.
- A sample parameter that follows that state: the bass filter opens as the
  pattern gets busier.

## The init cell

Open with `ctrl + i`.

```
(def scale (list 60 60 63 67 58 72))
(def hat (lambda () (begin (ctf (rnd 4000 16000)) (vel (/ (rnd 25 80) 100)))))
(def limit 32)
(def gen 0)
(def fresh 1)
(def add (lambda (st s) (when (= fresh 0) (begin (sample st s) (set! gen (+ gen 1))))))
(def tick (lambda () (if (= fresh 1) (begin (save (quote recur-seed)) (set! fresh 0)) (when (> gen limit) (begin (load (quote recur-seed)) (set! fresh 0))))))
```

| symbol  | role |
|:--------|:-----|
| `gen`   | number of notes written since the last reload |
| `limit` | the condition: reload once `gen` is above this |
| `fresh` | 1 until the sparse pattern has been saved, then 0 |
| `add`   | writes sample `s` at step `st` of the current track and counts it in `gen`; does nothing while `fresh` is 1, so the snapshot is always the sparse pattern |
| `tick`  | saves the snapshot on its first run, reloads it when `gen` is above `limit` |
| `hat`   | from `techno`: random filter cutoff and velocity for the hit on this step |
| `scale` | from `techno`: notes the bass picks from |

## The pattern

Each track is `sample note expression`. `--` is empty.

| step | 1: kick | 2: hats, clap | 3: rim, tom | 4: bass |
|:-----|:--------|:--------------|:------------|:--------|
| 1  | `0 C3` `(tick)`  | `(hat)`               | `4 C3` grow perc           | grow bass   |
| 2  |                  | `(hat)`               |                            |             |
| 3  |                  |                       |                            | `6 C3` filter |
| 4  |                  | `(hat)`               | `(note (@) (rnd 60 72))`   |             |
| 5  | `0 C3`           | `3 C3` grow hat       |                            |             |
| 6  |                  | `(hat)`               |                            |             |
| 7  |                  | `2 C3`                |                            |             |
| 8  |                  | `(hat)`               |                            |             |
| 9  | `0 C3`           | `(hat)`               |                            |             |
| 10 |                  | `(hat)`               |                            |             |
| 11 |                  |                       | `(note (@) (rnd 50 62))`   | `6 C3` filter |
| 12 |                  | `(hat)`               | `(jmp 0)`                  |             |
| 13 | `0 C3` ghost     | `3 C3` grow hat       |                            |             |
| 14 |                  | `(hat)`               |                            |             |
| 15 |                  | `2 C3`                |                            |             |
| 16 |                  | `(hat)`               |                            |             |

The expressions behind the names in the table:

| name      | expression | what it does |
|:----------|:-----------|:-------------|
| grow hat  | `(add (* 2 (rnd 1 8)) 1)` | writes a closed hat on a random even step |
| grow perc | `(add (rnd 1 12) (rnd 4 5))` | writes a rim or a tom on a random step of the 12 step loop |
| grow bass | `(add (rnd 1 16) 6) (note (rnd 1 16) (get scale (rnd 6)))` | writes a bass hit on a random step, and a note from the scale on another |
| filter    | `(ctf (+ 400 (* gen 150)))` | bass filter cutoff follows `gen` |
| ghost     | `(if (> (rnd 100) 65) (sample 15 0) (sample 15 (#f)))` | from `techno`: a kick on step 15 that comes and goes |

## How one cycle goes

1. Loading the project runs the init cell: `gen` is 0 and `fresh` is 1.
2. On the first step, `(tick)` saves the pattern as `recur-seed` and sets
   `fresh` to 0.
3. From then on the grow cells fire: two hats per bar, one bass hit per bar,
   and one rim or tom per pass of track 3. Track 3 loops every 12 steps
   because of the `(jmp 0)`, so it grows slightly faster than once per bar.
   That is a little over 4 notes per bar in total.
4. The `(hat)` cells sit on empty steps. When a hat is written there, the
   cell starts shaping it with a random cutoff and velocity.
5. The bass filter opens with `gen`, from 400 Hz to about 5 kHz.
6. After 8 bars `gen` is above 32. On the next step 1, `(tick)` loads
   `recur-seed`: the pattern is sparse again, `gen` is back to 0, and the
   filter closes.

Grow cells can write onto a step that already has a note, so the pattern
fills more slowly towards the end of a build.

## What is random and what is not

`add` and `tick` are not built in. They are defined in the init cell of this
project, and the grow cells call them.

Fixed: when the pattern grows and when it resets. The grow cells sit on fixed
steps and fire every time the playhead passes them, each writing exactly one
note. `gen` therefore rises at a steady rate, and the reload always comes
after 8 bars.

Random: where each new note lands, and for two of the tracks what it is.
`(rnd a b)` gives a whole number from `a` to `b`, `(rnd n)` one from 1 to `n`.

| cell | random choice |
|:-----|:--------------|
| grow hat `(add (* 2 (rnd 1 8)) 1)` | the step: 1 to 8, doubled, so one of 2, 4 ... 16. The sample is always 1, the closed hat. The odd steps are left to the clap and open hat. |
| grow perc `(add (rnd 1 12) (rnd 4 5))` | the step, 1 to 12, and the sample, 4 (rim) or 5 (tom) |
| grow bass `(add (rnd 1 16) 6)` | the step, 1 to 16. The sample is always 6. |
| grow bass `(note (rnd 1 16) (get scale (rnd 6)))` | a second, separate step, and which of the six notes in `scale` to write there |

So every build has the same shape and length, but fills different steps. A
step can be picked twice, so the 16 hat writes of one build usually leave
some of the 8 even steps empty, and each build sounds different.

Two more random cells come from `techno` and act on notes that are already
there: `(hat)` picks a cutoff and velocity each time a hat plays, and the
ghost cell on step 13 rolls each bar for a kick on step 15.

## Things to try

- Change `limit` in the init cell for a shorter or longer build. At a little
  over 4 notes per bar, 16 gives 4 bars and 64 gives about 15.
- Run `(set! fresh 1)` in the repl to take the pattern as it is now as the
  new sparse pattern. It is saved on the next step 1.
- Change the sample numbers in the grow cells, or add a grow cell to the
  kick track.

## Behaviour worth knowing

- `(load)` runs the init cell of the project it loads. Here that is what
  resets `gen` to 0. It also means a value kept in a `def` in the init cell
  does not survive a reload. `tick` sets `fresh` back to 0 right after the
  load for this reason.
- `(load)` restores mutes, bpm, length and track dividers as well as the
  notes. A track muted during the build comes back on the reload.
- `(save)` and `(load)` do not touch the sample params. Those are only saved
  and read through the params menu, as the `.pset` file.
- The id needs care. `(save "name")` keeps the quote characters in the file
  name, and a bare symbol such as `(save name)` is undefined and saves as
  `nil.seq`. Numbers work, `(save 1)`, and so does `(save (quote name))`,
  which can be typed on a keyboard layout that has no `'`.
- `(#f)` is not a stored false value. `(set! x (#f))` removes `x`, and every
  later use logs `Undefined: x`. The `fresh` flag is 1 or 0 because of this.
- Notes written by a cell are stored as numbers, the ones typed in the
  tracker as text. Both play and display the same.
