# Bend papercuts, from playing/testing BendQuest end to end

Observations about writing (and reading ~9k lines of) Bend, gathered
while driving a full campaign of this game with protocol bots and
fixing two live bugs in it. Compiler-side findings (prepare blowup,
clang wall, effect rows, Metal launch-compile) are already in
NOTES.md; this file adds the language-surface and runtime items on
top, ordered by tax paid. Every claim below was re-verified against
the repo compiler at HEAD (2026-08-06) with small probe files; two
first-draft claims did NOT survive that check and are recorded in
their corrected form (items 2 and 3).

## 1. Record ergonomics is the #1 tax on this codebase

No field access, no record-update syntax, no partial patterns
(verified: `Wide.Wide{c, ..} = w` is a parse error at HEAD). In
practice:

- Reading ONE field spells every field: the `WMeta.WMeta{phase, wno,
  seed, tick, t0, now, sigils, fame_t, nextpid, nextmid} = m`
  destructure appears ~15 times in world.bend, most of them to read a
  single component.
- Updating one field means a dedicated boilerplate function per field:
  `cs_move_sent`, `cs_set_name`, `cs_set_net`, ... client.bend is
  full of these hand-rolled lenses.
- A two-line bug fix (srv_zone's move_sent reset) required
  destructuring and respelling all 8 Ui fields.

`{m | sigils = x}` update sugar plus `{sigils, ..}` partial patterns
would shrink this app by a double-digit percentage. Note the feedback
loop with NOTES.md item 5: the language pushes you toward wide
destructures, and the compiler's prepare pass is quadratic on exactly
that shape.

## 2. Result-match pyramids: the language already has the answer
## (corrected -- first draft overclaimed)

Nested `match r: case Result.Done{..} -> match rr: ...` cascades are
the dominant texture of server.bend (drain_stat carried a
double-nested one). BUT: `do M(...)` is monad-generic -- the
elaborator rewrites binds/returns against M.bind/M.pure for ANY M --
so a Result-over-IO transformer is ~40 lines of user code TODAY and
gets full do-notation. This codebase now ships one: ior.bend defines
IOR(E, A) = IO(Result(E, A)) plus a try_op helper that flattens the
timeout-vs-op double Result ONCE; the client's join pipeline runs
through `do IOR(String, TCP):` (start_net in client.bend) and the
four channel-drain pyramids collapsed to single matches. Residual
ask: bend-base could ship this so codebases stop hand-rolling
pyramids by default.

One genuine rough edge was found here and FIXED in bend3 the same day
(elab_bnd, 2026-08-06): both element types of a `<-` bind came from
elab_targ = the LAST ARGUMENT OF THE SPELLED TYPE, no unfolding, no
regard for which monad's bind was being minted -- so a return
annotation or bound value spelled through an alias mis-typed the bind
and died with a confusing arrow mismatch. The fix follows this file's
earlier analysis: B now comes from the do-head's own spelled yield
(the law elab_ret already used -- every block suffix yields it, and
the outer annotation only ever CONVERTS, so any spelling is lawful),
and A resolves by unfolding the bound value's type head TO the do's
monad (aliases above it work; heads below it fall back to the
last-argument guess and the mint is settled by the check -- a plain
both-types mismatch on a real mistake, and outright ACCEPTANCE when
the guess is right, as for single-parameter aliases). Pinned in
bend3 by .devs/tests/check_do_bind_spelling.bend (the
ok/bad/rev/abv/ali ledger; the always-wrong below-multi-param case
carries no pin -- its rejection is conversion soundness); this app's
dial/connect_now dropped their boundary-crossing explicit binds the
same day. What remains is the standard transformer law, not a quirk:
lift raw lower-monad ops (mtl needs the same). The one residual ask:
bend-base could ship a Result-over-IO transformer so codebases stop
hand-rolling pyramids by default.

## 3. U32/Bool friction (corrected -- narrower than first drafted)

At HEAD, `if` accepts BOTH worlds: `if x == 3:`, `if b:` with
b: Bool, and `if String.eq(s, "x"):` all check (verified). The
match-on-Bool.T{} cascades in this codebase are a migration-era
idiom, not a language requirement, and could be rewritten as plain
`if` today.

What remains true: `&&`/`||` operate on U32 ONLY -- mixing a
Bool-returning predicate into a compound guard
(`(x == 3) && String.eq(s, "y")`) is a type error, so bridges like
`Bool.to_u32` still appear wherever predicates meet numeric tests.
Accepting Bool operands there too would finish the job. Also
confirmed deliberate at HEAD: op2 chains do not associate -- the
parser demands full parenthesization (its own error message says so),
which keeps compound guards Lisp-shaped:
`((zone == z) && (dead == 0)) && (chdist(mx, my, x, y) <= 1)`.

## 4. The fuel ceremony

Every long-lived fiber is `def loop(fuel: U32, ...)` + `case 1+f` +
`U32.MAX` at the spawn site -- totality ritual with no information
content, repeated 12+ times here (reader, writer, acceptor,
game_loop, frame_loop, cl_reader, ...). A blessed diverging-loop form
for IO fibers would delete the pattern.

## 5. Runtime wish, backed by a live bug: TCP.close vs pending recv

The connection leak fixed in server.bend (writer closed the socket on
send error while the reader was blocked in TCP.recv on the same fd;
if the close won the race, the recv never completed and the
connection zombified, holding the hero and its name) exists because
TCP.close semantics on an fd with a pending op in another fiber are
undefined-in-practice. If close CANCELLED pending ops (waking them
with Result.Fail, io_uring-style), the pre-fix code would have been
correct anyway. Worth defining in the runtime; until then the safe
pattern is single-closer discipline (see the writer/writer_drain
comment in server.bend).

## 6. What deserves explicit credit

- The checker is fast enough to lean on constantly: silent full check
  of the 10k-line app plus its 14 kernel proofs in ~0.8s.
- bend -> C emission is a non-issue post-liveness (~2s); the dev-loop
  floor is clang on the emitted C (~80s -O1 on an M4), per NOTES 8/9.
- The compiled runtime took a ~7-hour multiplayer soak -- 8+
  concurrent TCP clients, tens of thousands of wire commands,
  parallel per-zone mob AI every 120ms tick -- with zero crashes,
  zero memory faults, and no fiber/channel misbehavior beyond the
  app-level fd race above.
- The proven-kernel workflow is not decorative: scripted bots spamming
  every op sequence (buy/equip/unequip/quaff/alloc interleavings,
  stale and hostile inputs) never duped an item, minted gold, or
  over-equipped. Rejected op = no-op held everywhere, live.
