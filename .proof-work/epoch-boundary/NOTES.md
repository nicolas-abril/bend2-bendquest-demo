# BendQuest dev notes: language / tooling findings

Roadblocks and observations about Bend itself hit while building this
demo, per the owner's request. Game-side bugs are NOT logged here.

## 1. Globally installed `bend` is stale vs the repo

The `~/.bun/bin/bend` install (bend3-0.1.0.tgz) rejects numeric
successor patterns that the GUIDE and the repo compiler accept:

    def go(n: U32) -> U32:
      match n:
        case 0:
          0
        case 1+f:      # <- global bend: "mismatched pattern shapes
          go(f)        #    (this column matches numbers)"

`bun bend-ts/src/main.ts` on the same file is silent (correct). Every
build in this project therefore uses the repo-local compiler. A
re-pack/re-install of the global would fix it.

## 2. Stale-install corollary: pipe SIGPIPE kills builds silently

`bun bend-ts/src/main.ts f.bend -o out 2>&1 | head -5` can kill the
build via SIGPIPE with zero diagnostics when the compiler writes more
than head reads (observed as a 10-minute silent hang wrapper). Not a
Bend bug per se, but `-o` builds emit nothing on success, so any
pipe-truncated invocation is indistinguishable from a hang. A
`--progress` line (or any heartbeat) on -o builds would help.

## 3. Proof-layer findings (from the proof-filling pass on game.bend)

1. `%e` self-destructs its own equation and every sibling hypothesis:
   rewriting with `e : {islot(k) = SlotW{}}` re-types ALL hypotheses
   mentioning the LHS -- including `e` itself, which degrades to
   `{SlotW{} = SlotW{}}` and is dead afterwards. Workflow that works:
   never rewrite eagerly at the top of a match arm; save the one `%e`
   for the point where the definition re-creates the stuck test. When
   one fact must both reduce a verdict AND serve as evidence, don't
   `%e` at all -- re-`match` the scrutinee `as` a fresh equation and
   pass that (matches do not re-type hypotheses).

2. A rewrite LHS can collapse under the checker's automatic
   case-splitting and then hit the wrong occurrence: with
   `hel = Fail{_}` auto-split, `Bag::add(mb(hel), one(k))` collapses
   to bare `one(k)` and a replayed `%Bag::add_comm(mb(hel), one(k))`
   mangled an unrelated hypothesis mentioning `one(k)`. Fix pattern:
   factor rewrite chains into standalone lemmas over fully-abstract
   variables and apply them as terms.

3. Pleasant: `%e` transports non-equation goals (a `WellEquipped(...)`
   tuple goal) across constructor equations; 4-way right-nested `&`
   evidence destructures with flat `(a, b, c, d)` sugar; let-bound
   locals inside a def and top-level constants unfold transparently in
   conversion, so `damage_capped` needed no case split on `crit`.

## 4. Misc

- `Bool::if` does not exist (write the two-arm match); `or` must be
  qualified (`Bool::or`) because Either/Maybe/Parser/Result also
  export one -- but bare `and`/`not`/`lt` resolve fine with the same
  import set. Inconsistent ambiguity surface.
- Destructuring a `+T` parameter (`Assets{..} = a` with `a: +Assets`)
  is rejected ("expected a Many (+) binder"); passing the record
  plainly and letting the compiler place copies works.
- List<String> literal continuation lines starting with `++` are a
  syntax error (statements are line-based); `List::flatten` is the
  idiom.

## 5. COMPILER SCALING BUG (the big one): `-o`/`--compile` is
## quadratic on wide-record destructures; minutes-to-hours on this app

Checking is fast (whole game ~1 min), but `prepare` (bend-ts
book_prepare) explodes. Measured with phase timers on gallery.bend
(sprite gallery, a small file):

    [prep] ctr_scan:   1ms
    [prep] def_scan:  22ms
    [prep] prune1: 133722ms   <- 134s, of which:
      slow def icon_row:    106005ms
      slow def tile_row:     17054ms
      slow def player_cmds:   9053ms
      slow def mob_row:       1579ms
    (comp_new 14ms, file_emit 94ms -- emission itself is FINE)

The full game (~10k lines) ran 40+ minutes at 100% CPU in prepare
before we killed it.

Shape that triggers it: a wide single-ctor record destructure
(`Assets{a, b, ...26 fields...} = a`) with the rest of the body under
those binders -- worst when the body also contains a `~`-spliced
lambda (`List::map(i => spr(tiles, i, ...), List::range(16))`
capturing destructured fields; icon_row above is exactly that, and
106s for a 10-line function).

Suspected mechanism (from reading prepare.ts): `term_erase`'s `Lam`
case reopens every binder with `term_beta` and returns
`bend.Lam(k, (x) => term_rewrite(Var(k), x, body))` -- a full-body
copy per binder per open, and every later pass that opens the HOAS
closure pays another full-body rewrite. So cost ~ O(binders x body)
per pass, and a K-field destructure is K binders: 26-46-field game
records over multi-hundred-node bodies hit exactly this. Nothing here
is exotic user code -- "Python with records" writes this shape all
day. A memoized/environment-based substitution (or n-ary binder open)
in prepare would likely fix it.

Repro: `time bun bend-ts/src/main.ts bend-demos/app_bendquest/gallery.bend --compile > /dev/null`

Corollary: no progress output during the (long) prepare, so a big
build is indistinguishable from a hang (see item 2).

## 6. Workaround for item 5 that landed in this codebase

Split every wide record into a shallow top record of grouped
sub-records and open only the groups a function touches; wide opens
live only in tiny accessor defs; the two map-lambda-under-destructure
sites became explicit recursions. Measured effect on gallery.bend's
--compile: prepare 278s -> 0.16s (prune1 134s -> 32ms), total wall
0.73s. The refactor is invisible on the wire and to the sim (the
deterministic smoke pin still prints (4,8,19)).

Rule of thumb until the compiler fix: no destructure wider than ~14
binders above a non-trivial body, and never a ~-spliced lambda that
captures destructured fields.

## 7. Metal backend launch-compile is impractical for large programs

A -o build on macOS picks the Metal backend, and the runtime compiles
the device library at EVERY process launch. On this app (~74k-line
emitted source) MTLCompilerService ground for 15+ minutes without
finishing before we killed it (the process itself sits at
"compiling kernels..."). Fine for benchmark-sized programs, unusable
for an app you launch repeatedly. Workaround here: build.sh defaults
to -DPAR_BACKEND=0 (CPU threads; parallel lets still multicore, !
inert) and offers `metal` explicitly. A cached device library (as on
CUDA) would fix this properly.

## 8. Where a "small" build's minutes actually go (measured 07-30)

For this ~10k-line program: `bend --compile` emits in 3.4s (the
sub-record refactor of item 6 holding), but the emitted C is
1,073,170 lines: ~530k lines of host machine code (label-per-function
seq machine + par steps -- a ~50x expansion of the source) plus the
entire GPU device text embedded again as a string constant (excluded
by the preprocessor when PAR_BACKEND=0, so it costs parse-skip only).
clang on that file: 45s at -O0, 384s at -O1, 470s at -O2 -- and the
-O0 binary SEGFAULTS instantly (the musttail/preserve_none label
machine appears to require optimization to be stack-sound), so -O1 is
the fastest WORKING build and the dev loop floor is ~6.5 minutes.
String/data literals are innocent (2k of the 530k host lines); the
expansion is the uniform ~50x machine rendering itself.

Compiler-side wishes, in impact order: (1) a lower expansion factor
or split translation units so clang can parallelize; (2) a
precompiled/object-cached runtime+machine so only changed code
recompiles; (3) make the label machine -O0-safe to unlock 45s dev
builds; (4) omit the device text for CPU-only emissions. "A few
seconds for 10k lines" holds for bend itself but not yet for clang
on its output.

Two sharp edges hit while measuring: NUM_THREADS must be a power of
two (BAG_LEN divisibility static assert -- a friendlier message or
auto-rounding would help), and a failed clang exits so fast that a
timing harness which only reads the `real` line mistakes the failure
for a 0.9s success (report: check the binary, not the clock).

## 9. Regression after the 07-31 pull: `_` in a motive override is
## NotBound (guide example included)

GUIDE.md still teaches `%e : P` "with `_` marking the rewritten
position", but since the latest pull the underscore fails as an
unbound name -- including on the guide's own example shape:

    def wrap_id(a: Nat, b: Nat, e: {a = b : Nat}) -> {Nat::pred(S{a}) = b : Nat}:
      %e : {Nat::pred(_) = b : Nat}    # NotBound: name _
      {=}

Likely fallout of the recent parser cleanups ("tombstone purge" /
op-scan rework). BendQuest's one use (rejected_op_is_noop) was
rewritable as a plain `%e`, so this repo no longer depends on the
form -- but guide and checker currently disagree.

## 10. 07-31 pull: effects now require hand-written install-Op rows

The new effect protocol resolves every C-bodied def against a
constructor on bend-base/IO.bend's Op (CamelCase of the def name,
fields = args + continuation), and fails emission otherwise ("no
matching constructor on the install Op"). Base's own GFX effects
moved there. Programs cannot extend Op (bare module ids resolve only
inside the install, so no local module can be "IO"), and GUIDE.md
still says "a root program can declare its own" -- guide and
implementation disagree. Net effect: THERE IS NO PROGRAM-SIDE
FFI/EFFECT MECHANISM anymore; third-party effect packages cannot be
self-contained.

The workaround this demo ships (owner asked base stay untouched):
raylib.bend now pairs, BY NAME, with the three install rows this
program never otherwise uses -- Window, Blit, GfxEvents -- and
multiplexes the whole raylib surface over those three wires (draw +
meta ops on the Blit list; a C-side reply queue with priority over
input on GfxEvents). This works because io_bodies synthesizes the
effect body as an UNTYPED constructor application post-check, so the
Blit row's Image-typed field happily carries our List<U32> as a raw
term. It is a namespace hijack: it breaks the moment the program also
imports IO/GFX, and it is capped at the install rows' shapes. A real
fix needs the compiler to re-admit program-declared rows (the
pre-bend5 eff_load behavior) or an explicit extension point.

## 9. Migration to the 2026-08-05 compiler (src-split, dotted names)

The whole app was mechanically migrated to the current bend3 HEAD
(nicolas-dev, liveness-walk emitter). The transform catalog, for the
next reader: `Mod::name` -> `Mod.name` (base) / bare `name` (local
modules -- no file namespaces anymore, entry names are global; zero
collisions across our 872 top-level names); `F<A,B>` -> `F(A,B)` and
call-site generics become leading plain args; `K : T = v` constants
-> `def K() -> T: v` (uses stay bare); op2 chains fully parenthesized
(the new parser does not associate; rewritten left-assoc per the OLD
parser's PREC table); bodiless `if` fallthroughs -> mandatory
`elif`/`else` (whole trailing blocks wrapped); `a, b = x, y` parallel
lets -> `a & b = x & y`; backtick char literals -> U32 codepoints;
ctor literals qualified `Type.Ctor{..}` (expression positions need
it); `{a = b : T}` -> `{a == b : T}`, `{=}` -> `{==}`, `for all` ->
`forall`; do-block bodies strictly deeper than their head. Maybe IS
Result now (Done/Fail work unchanged); the raylib three-wire trick
(Window/Blit/GfxEvents) still holds and effs/raylib.c compiled
UNCHANGED against the current runtime.

Two compiler findings came out of it, filed in bend3/.devs/issues/:

- io_prebind_pure_let_copy_freed: a pure projection let BEFORE an
  effect bind made copy$ walk a freed word (runtime error 22) in
  game_loop; server.bend carries the one-line workaround (the read
  moved below the bind) with a comment.
- check_rewrite_refined_field_binder: ops_respect_requirements died
  on a leaked `error` field binder under %ei -- minimized to 70
  import-free lines, root-caused (the split mint's capture telescope
  level-ordered a forward reference written by ctx_rewrite) and
  FIXED in bend3's elab_split the same day; the original proof is
  restored and the kernel is fully proven again.

Measured on the m4 (4 perf cores) after migration, against item 8's
recorded baseline:

  bend -> C   2.1s, 355,679 lines   (was ~3s, ~1M lines)
  clang -O1   80s                   (was 384s -- 4.8x)
  clang -O2   77s                   (was 470s -- 6.1x)
  metal -O3   83s (PAR_BACKEND=1; kernels still compile at LAUNCH;
              the headless server runs under it)

-fbracket-depth=4096 is NO LONGER NEEDED on any lane (the emitter
flattens deep spelled expressions and renders inlinees braceless);
build.sh drops it. The headless server was verified end to end:
boots, accepts a TCP client, answers protocol errors, logs the
disconnect, and survives sustained ticking.

## 11. Re-checked on bend3 main, 2026-08-09

Two spellings had to move: BendQuest was migrated onto bend3's
`do-bind-elem` branch (54c05a81, elab_bnd/elab_elem), which is NOT
merged to main, so main still reads a do-bind's element off the LAST
ARGUMENT of the spelled type with no unfolding -- every IOR<->IO
boundary must therefore spell its own head. `dial` is an explicit
IO.bind again (its `do IO` body under an IOR annotation was the exact
"bad" regime that branch fixes), and the one crossing that binds an
IOR value inside a `do IO` block goes through a new IOR.run -- the
no-op dual of IOR.lift, which exists only to spell the IO head. Both
revert to the flat spelling the day that branch lands.

-fbracket-depth=4096 was still declared in effs/raylib.c's //$ link
line, three days after this file recorded it dead. Dropped: the
emitted C's deepest delimiter nesting measures 31, and bend3 now caps
BOTH spell paths at 64 (term_cexp since the literal wall, term_rexp
since 81e6e8ab).

Measured against the par-wrapper sinking change (bend3 comp.ts,
par_row): 2659 -> 2254 standalone STEP par_ wrappers (-405, -15%),
357,726 -> 356,468 lines, 12,097,134 -> 12,035,570 bytes (-0.5%).

  clang -O1 -c, 4 alternating runs each, seconds
    pre   79.79  80.80  86.47  80.35     min 79.79
    post  83.49  79.71  83.34  90.91     min 79.71

NO measurable compile-time change: the mins agree to 0.1% and the
spread (a 90.9s outlier) swamps any effect -- 405 fewer functions off
2,254 remaining is a 0.5% smaller file, and clang bills parse and
per-function passes, not the movement the wrappers contained. The full
build.sh dev lane runs 88s end to end and the headless server still
boots, accepts a client (connection #1), and logs the disconnect.
