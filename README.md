# Bendquest

A cooperative RPG in `bend3-demos/app_bendquest`, updated to the sibling `bend2-core`
compiler. Three zones, bosses, equipment, quests, chat, a shop, character
customization, and a cooperative final fight. HOST opens a server dashboard;
PLAY joins a server. Run another instance to play on your own host.

## Build and play

On macOS, with Bun, Clang, and Homebrew raylib installed:

```sh
cd app_bendquest
./build.sh
./run.sh                  # graphical menu: HOST or PLAY
./run.sh server 4977      # headless server
```

The executable is `.build/bendquest`; `./bendquest` and `./run.sh` launch it.
The build and checks use the sibling `bend2-core` checkout; set `BEND2_CORE`
to use another location. `run.sh` supplies the game directory for
the font, database, and screenshots. A server listens on TCP port 4977 by
default. Players enter the host's address and port in PLAY. Native runtime
options can follow the game arguments, for example `--threads 4 --gpu off`.
`./build.sh release` enables additional C optimization.

Controls: WASD/arrows move, SPACE attacks, E spins, Q drinks a potion,
F talks/uses portals, B opens the shop, I opens inventory, TAB shows quests,
T opens chat, H opens the hall of fame, and ESC closes panels. Use QUIT or
the window's close button to leave.

Server profiles, coins, cosmetics, and completed runs are stored in
`bendquest_db.txt`. Use the host dashboard's save-and-stop button before
backing up that file. Saves replace the database atomically.

## Checks and bots

```sh
./check-proofs.sh                 # original guarantees and added preservation proofs
./check.sh                        # proofs and gameplay regression checks
python3 bot.py 4977 adventurer 25  # quests, movement, combat, chat, hall of fame
python3 shopbot.py 4977           # funded potion purchase
BQ_AUTO=join BQ_NAME=visitor ./run.sh
BQ_AUTO=host ./run.sh
```

Both bots exit unsuccessfully when their checks fail. The combat bot searches
walkable cardinal paths to NPCs and monsters using the map sent by the server. The graphical autopilot
runs 640 frames, writes `bq_*.png` screenshots, and exits. Run a server on 4977
before the join autopilot. Use a fresh server for the shop bot's starting-gold
check.

## Port notes

All gameplay and drawing code is Bend, built by `../../bend2-core/bend2/main.ts`. The
original module boundaries are retained. `support.bend` contains the small
part of the old prelude the game needs; `compat.bend` and `effs/` adapt its
character lists, channels, sockets, and raylib commands to the current runtime.
No Bend3 compiler or runtime is needed. The C build disables warning analysis
for the generated dispatch function, as the original build did.

`game.bend` is the verified kernel used by the server. It contains all 15
original theorems and their supporting lemmas, with no `@unsafe`, axioms, or
unfinished proofs. `proofs.bend` presents the original statements against
those exact functions: item conservation, exact purchases and potion
consumption, funded-shop liveness, stat budgets, equipment legality, damage
bounds and minimum damage, survival of one hit from full health, movement
bounds, and adjacency. The proof migration uses explicit equality transports
and delays dependent hypotheses until after their data has been matched.

Both build and check scripts require a clean proof check. The main entry also
imports the proof statements, so compiling it directly checks them. Gameplay
regression tests and the bots exercise the native integration separately.
The UI, network orchestration, and compatibility adapters still use `@unsafe`
for the old sharing rules and word-counted loops; the kernel proofs do not
establish memory safety or correctness of those adapters.

The optional UI font is VT323 by Peter Hull / The VT323 Project Authors,
licensed under the SIL Open Font License 1.1. Raylib's default font is used
when `font.ttf` is absent.

`NOTES.md`, `PAPERCUTS.md`, and the standalone `gallery.bend`, `spike.bend`,
and `srvmain.bend` files retain their original Bend3 history and syntax.
Use `main.bend` and the scripts above for the current game.

## Additional world proofs

[PROOF_PLAN.md](PROOF_PLAN.md) tracks the six requested extensions. None is
claimed complete until its full server-level obligations are checked.
`health.bend` proves bounded healing, non-harming healing, damage bounds,
and survival of a sub-health hit, plus refinement from the efficient Base
arithmetic to the inductive specification. The server uses these rules for
potions, regeneration, boss healing, damage subtraction, and health clamping.
`health_check.bend` also exercises the U32 boundary, including overflow-sized
heals. `numeric.bend` now proves the general word/Nat round trips, and the live U32
health wrappers are proved to exactly refine those rules without output
wraparound. `growth.bend` proves maximum health is monotone in level and vitality, even
at the word ceiling. The server now adds charm health before saturation and
conversion, avoiding wraparound. `rewards.bend` contains the server's XP loop,
gold/item grants, and side-quest payouts, with proofs that they preserve
health bounds and legal equipment. `rewards_check.bend` covers level-up
boundaries and the server adapters. Reward eligibility/exactly-once payment,
XP overflow accounting, and full command/tick preservation remain open.

`vitals.bend` now owns the player vital-state record used by the server. Its
`Vitals.OK` proof includes health bounds and agreement between health and the
dead flag. Initialization, damage, death, waiting, regeneration, and respawn
preserve it; hitting a dead player is a complete no-op. The hit and upkeep
adapters use these transitions. Whole-player-list hit/upkeep preservation is now checked below; full command preservation and the remaining world invariants remain open.

`monsters.bend` owns the monster record and the strike/lifecycle transitions
used by the server. It proves health/dead-flag consistency, bounded
regeneration, valid initialization, permanent boss death, and at most one
kill event across arbitrary hits before respawn. A lethal hit followed by
further hits emits exactly one kill event. `monsters_check.bend` exercises
the live strike and AI adapters. This does not yet establish exactly-once
quest or run payouts, ID uniqueness, or the full world invariant.

`roster.bend` implements the server's shared monster-list lookup, concatenation,
and strikes. Proofs now lift monster validity through a whole-list strike,
preserve every complete record during lookup (up to reordering), preserve
list length during strikes, return the requested ID, and make missing-ID
strikes exact no-ops. `roster_check.bend` exercises full-record list results
and the server adapters. Unique-ID allocation and the remaining full-world obligations are still open.

`ai.bend` contains the checked monster update used by the server, including
its parallel four-zone composition. It preserves health/dead-flag validity
for every output monster, rejects attacks from dead monsters or while a
post-upkeep cooldown remains, and preserves permanent boss death for any
plan. Single-list updates preserve monster count even with missing or extra
plans. `ai_check.bend` exercises these functions and the server adapters.
Planning's movement/target choices remain separate proof obligations; tick
composition for these invariants is now checked below.

`zones.bend` proves that the four-zone partition is a permutation of every
complete input record when all zones are valid (0–3). The actual AI update
preserves every ID-and-zone key through that reordering and preserves total
monster count. Strikes likewise conserve IDs and zones through lookup,
damage, and reinsertion. Both transitions preserve valid zones. These proofs
do not establish unique-ID allocation or full initial-world validity; those
remain prerequisites for the complete world invariant.

`players.bend` now owns the complete shared player record used by the server.
Its initializer, lookup, ordered hit-list processing, and upkeep preserve
health/dead-flag validity and legal equipment; both list updates preserve
player count. Lookup also conserves complete records and returns the requested
ID. Dead hits preserve the entire player and emit no new death. Names use
shared character lists internally, with a proved conversion round trip.
`players_check.bend` checks complete record results and the server adapters.
Movement legality, other player commands, and allocation remain open in the
proof plan.

`simulation.bend` now composes the actual tick: phase gating, player upkeep,
monster AI, and ordered player hits. The server plans AI against the prepared
player roster, so upkeep runs once before monster decisions. Checked laws
preserve the established player/monster invariants and counts across arbitrary
tick sequences, specify phase gating and event order, and retain every metadata
field except the incremented tick word. `simulation_check.bend` exercises the
pipeline and live adapters. This closes tick composition for those invariants;
it does not complete `WorldOK`, and tick-word overflow accounting remains open.

`inventory.bend` now owns the actual purchase, equip/unequip, stat allocation,
and potion transitions for complete player records and rosters. Its laws
preserve health/dead-flag validity and legal equipment across command
sequences, including health clamping when a charm is removed. Dead players,
rejected operations, and distant purchases cannot change the selected player.
All fields outside hero and health remain identical; lookup conserves the
roster and updates the selected player only. The kernel's exact purchase,
potion, equipment-transfer, and stat-accounting laws are lifted to these
actual player commands.

Potion healing now uses the exact kernel acceptance decision, fixing a
U32-count comparison that could consume a potion without healing when the
inventory count crossed the word boundary. `inventory_check.bend` includes
that boundary case and actual server command adapters. Shop proximity still
comes from the map adapter; connection ownership, the remaining commands,
initialization, and the other `WorldOK` requirements remain open.

`payouts.bend` now composes the actual kill payout: XP/level results, gold,
kill score, main-quest progress, side-quest rewards, loot/find bonuses, and
boss bonuses. The selected player and complete roster remain valid, and
sigil advancement preserves every player's validity. Checked laws retain
IDs, names, positions, health, death state, timers, and cosmetics, conserve
rosters, and preserve validity through payout sequences. Exact-effect laws
cover XP receipts, gold amounts, item census changes, and reward notices.
`payouts_check.bend` exercises full records and live server adapters.

This establishes state preservation by payouts. The catalog supplies reward
amounts and drop choices; kill eligibility, duplicate suppression through the
strike/reward boundary, quest lifecycle accounting, final run payments, and
numeric bounds remain in `PROOF_PLAN.md`.

`navigation.bend` and `interactions.bend` now own movement controls, NPC
conversations, and portal routing. Their actual server transitions preserve
player validity and complete rosters. A separate `Navigation.Bounds` predicate
requires a valid zone and coordinates within the game's width and height;
these commands preserve it through arbitrary command sequences. Portal/grid
and NPC constants used by the rest of the game now delegate to these modules.
Incoming movement directions are proved to become values 0–3.

Movement controls and portal crossings preserve the complete profile outside
position. The elder's initial conversation advances the quest and credits ten
score; repeating the conversation on that resulting player retains it exactly.
`interactions_check.bend` exercises complete records and actual server replies.
The later terrain, locomotion, and landscape modules establish portal-arrival
walkability and tick-time movement legality. Initialization and reference/
allocation invariants remain open in the proof plan.

`combat.bend` owns attack/spin admission, their cooldown updates, and player
lookup in both server commands. Checked laws preserve health/equipment validity,
positions, and every field outside the selected cooldown. Dead, cooling, and
inactive commands are exact player no-ops; ready attacks set four ticks and
spins set twenty-five. A second same-kind attempt retains the first result
and is rejected. Actor dispatch is tied to the committed player, and lookup
preserves other records and roster size. `combat_check.bend` exercises these
laws' implementations and the actual server commands in JS and native C.

Target selection, damage correctness, and the mixed command/tick attack-rate
theorem remain open. Admission preservation and admission traces alone do not
establish the complete combat or WorldOK guarantees.

`battle.bend` now composes actual monster strikes, conditional kill payouts,
world sigils/phase/finish-time changes, and ordered reward notices. Both normal
attacks and spins use this checked commit. It preserves the established
health/equipment/monster-zone invariant and roster counts, including through
mixed combat-command/tick sequences. A strike without a kill event cannot pay;
a reported kill with a present killer produces exactly one reward notice.
Notices retain the payout receipt and player snapshot used for formatting,
including intermediate game-over messages during a multi-kill spin.

`battle_check.bend` checks complete states and notices. Planning still supplies
targets, damage, catalog amounts, and drop choices. Full position/walkability,
ID/reference, lifecycle/reload reward uniqueness, and numeric accounting proofs
remain open in `PROOF_PLAN.md`; `Simulation.OK` is still a partial invariant.


`terrain.bend` owns the shared map representation, authoritative world record,
and the tile lookup and movement functions used by the server. Its laws prove
exact map conversion/lookup, grid bounds, cardinal movement (at most one axis
changes by at most one tile), and collision preservation for players and
monsters. Zone, heading, and moving flags are retained. Rejected movement
retains the complete position; accepted movement commits the specified step.

Tile lookup now rejects invalid zones and coordinates before flattening them,
fixing row aliasing and U32 offset wraparound. Missing maps/cells are solid.
`terrain_check.bend` exercises these rules and the real server adapters.
`Terrain.On` combines position bounds and walkability on the actual maps;
movement preserves it from a valid starting position. The following locomotion and landscape modules lift this to whole ticks and
generated spawn/portal locations. Unique IDs/references and the complete
`WorldOK` remain open.


`locomotion.bend` now owns the server's map-derived player plans and phase-gated
preparation. Its laws carry `Terrain.On` through complete player upkeep,
respawn, lookup, lethal/nonlethal hits, whole-roster hit lists, and the complete
tick. Arbitrary tick sequences preserve every player's bounds and walkability,
as well as the existing health/equipment/monster-zone invariant and player
count. Exact position laws distinguish normal cardinal movement from revival
at the specified spawn point; a dead waiting player does not commit its plan.

These position theorems require valid initial player positions and a valid,
walkable spawn point on the actual maps. `Locomotion.WorldOn` checks player
positions in a full world; it is not the complete `WorldOK`. Generated spawn and portal-arrival walkability are discharged by
`landscape.bend` below; monster planning and ID/reference invariants remain open. `locomotion_check.bend` checks full records, event order, and the
server integration.


`landscape.bend` owns the map generator used by the server, including seeded
terrain, corridor/room stamping, and all four zone maps. Its 45 checked laws
prove that generated zone maps contain 510 cells for every seed, the actual
spawn is bounded and walkable, and every forward/backward portal arrival is
bounded and walkable in each valid zone. These witnesses discharge the spawn
premise in player creation and arbitrary tick sequences on generated maps.
The actual MOVE, HALT, TALK, and ENTER handlers preserve walkability, including
lookup/reinsertion and arbitrary sequences of those commands.

`landscape_check.bend` exercises real movement along corridors and to village
NPCs, actual portal transitions, map sizes, hash boundary vectors, and clipped
generation. Universal reachability/completability, monster placement/planning,
mixed closure across every command, and the remaining WorldOK requirements
are still tracked in `PROOF_PLAN.md`. The corridor tests are finite checks;
they are not a proof of all-seed world completion.


`habitat.bend` proves bounds and walkability for the actual monster records.
Its 35 laws retain exact positions through damage, waiting, regeneration,
lifecycle ticks, and attacks. They lift positional validity through monster
lookup/reinsertion, strikes, AI lists, filtering, and the four-zone AI run.
Movement and respawn require `Habitat.PlanOn` destination witnesses; missing
plans use Rest and extra plans remain ignored by the actual AI implementation.

This module adds proofs without changing runtime behavior. The active movement planner now supplies these witnesses through `pursuit.bend`
below. Respawn planning and initial monster placement remain open. These conditional preservation laws do not establish the
complete monster initialization or WorldOK theorem.


`pursuit.bend` now owns the server's cardinal chase and active AI planning.
Its 30 laws prove that chase/wander destinations remain walkable and in the
original zone, supply `Habitat.PlanOn` for the actual active plan, and preserve
monster positions through AI execution. Chase changes at most one coordinate
by at most one tile; when the preferred axis is blocked, its fallback starts
from the original position. These statements hold for arbitrary target
coordinates. They also cover the server's planning order after lifecycle
upkeep, including the cooldown value used to choose an attack.

`pursuit_check.bend` checks blocked-axis fallback, village collision, target
retention/clearing, attack admission, tick scheduling, and the actual server
adapter. Target acquisition/reference validity, damage accounting, respawn
planning, and initial monster placement are separate remaining obligations.


`remainders.bend` and `placement.bend` prove bounds for the actual word
remainder operations used by spawning, then prove that the original seeded
spawn rule produces bounded, walkable positions in every valid zone for every
seed. The fallback corridor premise is constructed from the actual generated
maps. These proofs do not assume that word modulo is bounded.

`population.bend` owns the monster catalog, initial rosters, fresh worlds,
and respawn plans used by the server. Its laws prove monster health and
positional validity at initialization and discharge respawn destinations'
`Habitat.PlanOn` requirements. `planning.bend` owns lifecycle-aware planning
and four-zone tick completion. Its laws combine player and monster positional
validity through complete ticks and arbitrary tick sequences on generated
maps, including dormant, active, and respawning monsters, arbitrary target
contexts, and missing or extra contexts. Health/equipment/monster-zone
preservation is retained alongside the positional invariant.

The four modules add 82 safe laws; `placement_check.bend` adds 36 runtime
regressions. They are required by the normal proof and test commands.
Target acquisition and damage inputs remain outside the safe closure.
Initial monster ID uniqueness is now universally proved by `identity.bend`
below. Player/connection allocator wraparound, references, all-command
composition, and the remaining numbered obligations remain open.


`identity.bend` adds 39 safe laws over the actual monster roster and transitions.
`Identity.Unique` requires each ID to differ from every later ID; zones cannot
hide a duplicate. The exact initial ID sequence is proved independent of the
maps, then its distinct and nonzero IDs are witnessed. Permutations and the
existing identity-conservation witnesses carry uniqueness through strikes,
spins, phase-gated ticks, lifecycle respawn, and arbitrary mixed combat/tick
sequences. Fresh-world trace theorems discharge the initial validity premises.

This module changes no runtime implementation. Player/connection IDs,
allocation on wraparound, target references, and full all-command WorldOK
preservation still require proofs. The checked mixed trace contains combat
and ticks; it is not the complete server command dispatcher.


`allocation.bend` now supplies player and connection IDs. It normalizes zero
away, searches past active IDs, and wraps the cursor from U32 maximum to one.
Its 12 safe laws prove every successful allocation is nonzero and unused,
with a nonzero next cursor. Search has a finite roster-length-based budget;
failure is explicit. A free normalized hint is always accepted immediately.

`admission.bend` adds 17 safe laws for the actual player-creation transition.
It rejects zero or already-bound connection IDs, preserves player/connection
ID uniqueness, health/equipment validity, and generated-map walkability.
The outcome theorem distinguishes exact rejection from prepending one fresh
player while retaining the old records. The server handles allocation failure
before changing connection state or announcing a player. Connection acceptance
uses the same allocator and closes the new socket on allocation failure.

`allocation_check.bend` adds 24 wraparound, collision, full-state preservation,
and repeated-creation regressions. These changes fix the old counters' unchecked
U32 increment. Full session ownership, queued-message/reference validity,
removal and all-command uniqueness closure, and allocator search completeness
under a cardinality bound remain separate proof obligations.


`playerids.bend` adds 67 safe laws connecting creation's unique player and
connection IDs to actual roster operations. Lookup/removal/reinsertion,
inventory actions, interactions, combat admission, payouts, damage, upkeep,
respawn, complete ticks, and full combat preserve both kinds of uniqueness.
Frame-projection laws connect the ID claims to the fields actually retained
by those handlers. Arbitrary mixed sequences of creation, removal, inventory,
interaction, combat, and lifecycle-aware ticks retain uniqueness from a fresh
world. The sequence calls the same pure functions as the server.

This batch changes no runtime implementation. The effectful connection
roster/dispatcher and authentication remain outside this theorem. Unique IDs
do not establish that monster target references remain valid after player
removal; reference cleanup and the complete WorldOK are still open.


`references.bend` adds 52 safe laws and fixes player removal's dangling monster
references. `world.Bq.del_plr` now uses its checked removal: after taking the
player out, each monster target is either zero (no target) or an ID present in
the remaining roster. Existing valid targets stay unchanged. All other monster
fields and their order, world metadata, maps, and surviving player records are
retained. This also repairs references that were already missing.

The proof covers every input state, repeated removals, and initialization for
every seed. Removal preserves health/equipment validity, walkable positions,
monster-ID uniqueness, and player/connection-ID uniqueness. The existing mixed
player-ID trace now calls this same handler; `playerids.bend` has 68 laws.
`references_check.bend` adds 24 regression cases, including the original bug,
U32 boundary IDs, duplicate input IDs, dead bosses, and exact world comparisons.

This reference invariant expresses existence or the zero sentinel. Same-zone,
alive-target, session ownership, and reference preservation by every other
command/tick still need proofs as part of the complete WorldOK obligation.


`membership.bend` adds 50 safe laws for roster membership and target references.
Exact lookup is preserved by player permutations and matching ID projections;
checked inventory, interaction, combat-admission, and payout frames connect
those facts to the actual handlers. Ordered damage and upkeep preserve existing
player membership, and successful creation adds a player without losing old
members. This includes actual membership of ID zero, distinct from the
no-target sentinel used by monster references.

Complete monster strikes, ordered battle execution, and attack/spin commands
preserve valid references through conditional rewards. A command-sequence
witness covers creation, removal, inventory, interactions, and combat, using the
existing `PlayerIds.trace` operations, with initialization discharged for every
seed. This batch changes no runtime behavior. AI target selection and complete
tick/reference closure remain open; arbitrary internal tick contexts cannot be
assumed to contain valid player IDs.


`targeting.bend` now owns the actual candidate filter, first-ID lookup, nearest
search, acquisition, retention, and AI-context construction. Its 43 safe laws
connect every selected ID and coordinates to a full player record in the
supplied roster. That record matches the requested zone, has a live flag, and
lies outside the village. Selection may instead return the exact no-target
value. Lookup returns the requested ID; valid retained targets remain exact,
and missing or distant targets trigger acquisition.

The live tick path uses the checked Data filter and context builder directly.
Legacy tuple interfaces remain adapters. The existing strict nearest comparison,
acquisition cutoff of 4, retention cutoff of 9, order/tie behavior, and duplicate
or sentinel input behavior are retained. `targeting_check.bend` adds 30 cases.
The proof gate includes this module. AI execution/tick reference closure is covered by `ai_refs.bend` below.
Nearest-search minimality and acquisition liveness under reachable roster
invariants, and complete WorldOK remain separate obligations.


`ai_refs.bend` adds 46 safe laws connecting target selection to complete AI
execution, world ticks, and mixed command/tick sequences. Monster upkeep
preserves target IDs; rest retains valid targets, attacks and movement use
valid plan references, and respawn creates the zero sentinel. List execution,
zone processing, and post-AI player damage preserve existence-or-zero target
references. The final roster proof includes players killed by those hits.

The server now calls `AIRefs.finish`, which generates its own checked contexts
from post-upkeep players. Damage values are supplied separately and cannot
inject targets. `tick_valid_world` and `fresh_trace_valid` cover complete ticks
and mixed sequences from every initial seed. These prove monster target
reference validity; full WorldOK, connection/session invariants, combat gates,
reward liveness, persistence, and world completion retain their broader scope.
`ai_refs_check.bend` adds 27 lifecycle, zone, death, wraparound, and sequence cases.


`nonzero.bend` adds 48 safe laws: zero is absent from player IDs and their
connection IDs after admission, removal, inventory, interaction, combat,
payouts, and complete selected ticks. The theorem composes these operations
from every fresh world seed, including failed admission and allocator wrap.
Member witnesses imply nonzero fields, and looking up player zero always
fails in these reachable rosters. The strict gate includes this module.

This is a pure roster invariant. Active connection records, queued sessions,
authentication, and the combined WorldOK/dispatcher proof remain separate
obligations. This proof addition does not change runtime behavior.


`worldstate.bend` combines the checked pure-world invariants: health/equipment,
walkable player and monster positions on the seeded maps, unique monster and
player/connection IDs, nonzero player/connection IDs, and monster target
references. Its 37 safe laws prove fresh initialization and preservation
through creation, removal, inventory, interactions, full combat/rewards, and
selected ticks, including mixed sequences from every seed.

The tick contract requires `Planning.rules(timer)`, the canonical spawn
coordinates used by the server; timer values and damage lists are unrestricted.
`WorldState.Schedule` records this condition for each tick. It is not an
authorization witness. `WorldState.OK` is the pure-world component of the
requested full server WorldOK: active connections, matching session/player
bindings, and complete dispatcher integration still need to be connected.


`Sessions.State` in `sessions.bend` is the pure connection descriptor used by
join, identification, and player binding. Its 27 safe laws prove valid lifecycle
initialization/preservation, exact CID/PID preservation through HELLO, and
unchanged complete descriptors after HELLO on bound or playing connections.
Name validation allows 1–12 characters using bounded structural traversal.

Repeated HELLO after CREATE now returns `ERR |already playing` and retains
the original player, profile name, and playing state. Before CREATE, a client
may still select another available name. This is a lifecycle fix; credential
ownership/authentication and the complete connection/world correspondence
remain open proof obligations.

`./check.sh` includes 29 connection lifecycle cases. After `./build.sh`, run
`python3 check-sessions.py` for the native protocol regression. It checks
rejected and repeated HELLO, unchanged chat identity and player IDs, continued
gameplay after rejection, name reservation, disconnect, and reconnect.


`connections.bend` adds 24 safe laws and defines `Connections.WorldOK`, combining
the pure world invariant with connection lifecycle validity, unique nonzero
CIDs, and bidirectional player correspondence. Playing connections match actual
player records by CID, PID, and name; unbound connections have no world player
using their CID; every world player has a matching connection.

Fresh initialization, allocated connection joins, and HELLO on a selected
connection plus the remaining roster preserve this invariant. Allocation
safety derives absence from world players using reverse correspondence.
Selection/reordering, CREATE, disconnect, rebind/world replacement, and full
dispatcher preservation remain to be connected; this does not complete the
server-wide proof. The new module is mandatory in the strict gate.

`selection.bend` adds 43 safe laws for first-match connection selection,
conservation of complete descriptors, CID correctness, selection completeness,
missing-CID no-ops, and preservation of the bidirectional connection/player
invariant under permutations. It extends HELLO preservation to selection by
arbitrary CID and composes join/HELLO sequences. `selection_check.bend` checks
the pure operations and compares the legacy server selector, including its
output channels. This is a proof of the pure descriptor operations; the
channel-bearing legacy adapter is covered by regression tests. CREATE,
disconnect, world replacement and complete dispatcher correspondence remain
open in `PROOF_PLAN.md`.

`creation.bend` adds 30 safe laws for joint player admission and connection
binding. Successful CREATE preserves the full world/connection invariant;
rejection preserves both states, and arbitrary join/HELLO/CREATE sequences
preserve it from every seeded initial world. `creation_check.bend` supplies
27 pure-operation regressions in `./check.sh`. Run `./check-creation.sh` for
those cases plus 17 native comparisons against the real `on_create` handler,
including its profile/cosmetic gate, output channels and unchanged maps. The
server uses native-only nonblocking channel effects, so these handler tests
are a separate native target using the same macOS/raylib dependencies as
`build.sh`. The fixture retains the full application effect registry but runs
only its test entrypoint. The channel-bearing adapter's universal
refinement, disconnect and remaining dispatcher obligations stay open.

`player_membership.bend` adds 17 safe laws relating full player records,
unique IDs and first-match deletion. `disconnect.bend` adds 19 laws proving
joint connection/player removal preserves the combined world invariant,
retains other players, removes the departed PID and composes with all prior
connection lifecycle operations for every seed. `disconnect_check.bend` adds
23 pure regressions to `./check.sh`. `./check-disconnect.sh` runs those natively
plus 17 actual `on_gone` comparisons, including monster targets, map retention,
closure of the departing channel and continued use of every retained channel.
It uses the same native macOS/raylib test setup as `check-creation.sh`.
World-changing command/tick correspondence, world replacement, authentication
and the universal effectful server bridge remain open in `PROOF_PLAN.md`.

`bindings.bend` and `frame_bindings.bend` add 66 safe laws carrying the
connection/player correspondence through updated and reordered player records.
Exact PID/CID/name preservation is derived from the existing inventory,
interaction, combat and payout frames. The resulting world theorems cover
inventory and interaction commands, full combat admission/strike/reward
composition, and arbitrary mixtures with join/HELLO/CREATE/disconnect for every
seed. Player membership witnesses refer to the actual updated records.
Tick correspondence, world replacement, authentication and the universal
effectful server bridge remain open; see `PROOF_PLAN.md`.

`tick_bindings.bend` adds 22 safe laws extending the combined world/connection
invariant through the actual AI tick, including damage, death, upkeep, revival
and player-list reordering. Arbitrary finite mixtures of ticks, ordinary commands
and join/HELLO/CREATE/disconnect preserve that invariant from every seed. Ticks
use the server's canonical spawn coordinates, with unrestricted damage lists
and timer values. World replacement and the complete effectful dispatcher
bridge remain open, as do authentication, reward liveness and the other
obligations tracked in `PROOF_PLAN.md`.

`allocation_search.bend` and `admission_search.bend` add 26 safe laws toward
successful roster reconstruction on world restart. Search failure is equivalent
to occupancy of every candidate actually visited. A finite cardinality proof
then constructs an actual fresh allocation when the search visits more distinct
candidates than there are occupied entries. Admission preserves the exact old
roster and inserts the requested new player when its CID is nonzero and unused.
This success theorem still requires distinctness of the bounded U32 candidate
sequence; proving that premise for every capacity-valid roster, and completing
restart/rebinding, remain open. See `PROOF_PLAN.md` for the unchanged full scope.

`word_successor.bend` adds 39 safe laws connecting the allocator's actual
binary arithmetic to a natural-number cycle. Its successor increases by one
below MAX and wraps MAX to one; arbitrary finite candidate sequences refine
that same cycle exactly. An exact capacity witness contains an actual full
word and its decoded value, avoiding a closed unary expansion of U32 MAX.
Distinctness of the cycle's bounded prefixes and reconstruction capacity
remain the next dependencies for unconditional restart success.

`nat_cycle.bend`, `allocation_complete.bend`, `nat_capacity.bend` and
`id_capacity.bend` add 51 safe laws completing the allocator's distinctness and
capacity dependencies. Candidate prefixes are distinct through wrap up to
capacity; distinct positive IDs cannot outnumber the ID space. An available
nonzero ID guarantees allocation success on a valid ID roster. For player
admission, a new nonzero unused CID on a unique, nonzero CID roster guarantees
success, with no assumed search distinctness or roster-size bound. Restart
still needs to preserve those CID conditions through the reconstruction loop
and prove the final connection rebinding.

`rebuild.bend` adds 22 safe reconstruction laws, and the server's restart loop
now delegates to its checked `Rebuild.world` function. Every old player with a
valid CID is successfully recreated when rebuilding a valid, disjoint roster;
CID/name/appearance are preserved in the loop's exact reversed insertion order.
The complete pure-world invariant and map data are preserved. The previous
loop's name conversion is proved equivalent for every state and roster.
`./check-rebuild.sh` compares full worlds with the previous loop natively;
its 20 cases also run in `./check.sh`. Final connection rebinding and the full
effectful restart composition remain open in `PROOF_PLAN.md`.

`rebinding.bend` adds 33 safe laws for restart's CID lookup and connection
updates. Unique CIDs make member lookup return the actual matching PID for
any fallback. Waiting connections remain unchanged; playing replacements
preserve phase/name/CID and restore bidirectional player correspondence when
the stated replacement-member and reservation conditions hold. Rebinding is
then idempotent. The reconstruction conditions are now discharged by the
pure restart proof below; the full effectful adapter remains open. `./check-rebinding.sh`
runs 26 native lookup/pure comparisons and 14 actual server/channel cases;
the 26 lookup/pure cases also run in `./check.sh`.

`reversal.bend`, `restart_profiles.bend`, `restart.bend` and
`restart_trace.bend` add 33 safe laws completing pure restart correspondence.
For any old `Connections.WorldOK`, `Restart.run_ok` proves the complete world
and bidirectional connection invariant after reconstruction and rebinding,
for every new world number, seed and time. No capacity, successful-admission,
replacement-member or old/new PID-equality premise is assumed. Profiles and
new map data are retained. `RestartTrace.fresh_trace` extends this to arbitrary
mixed lifecycle/gameplay/tick/restart sequences while updating the map seed.
`./check-restart.sh` runs 21 comparisons/trace cases and 12 native server
readdition-plus-rebinding cases with retained channels; the 21 cases also
run in `./check.sh`. Effectful adapter refinement, restart dispatch, messages,
save effects, authentication and the other scopes remain in `PROOF_PLAN.md`.

`connection.bend` and `channel_restart.bend` add 25 safe laws and are now on
the live server path. The connection record keeps its affine raw name and
channel handle. Descriptor conversion round trips exactly; rebinding preserves
every channel handle/generation and raw name in order, and its descriptors
exactly refine the pure rebinding result. A single affine traversal constructs
the descriptor and evidence needed to prove restart validity without copying
the connection roster. The live restart computes the exact old-world-plus-one
number and seed hash from the old metadata, then calls the checked channel
restart. The surrounding save/message sequence retains its previous behavior.
`./check-channels.sh` runs 15 descriptor/channel-handle cases and 10 complete
native restart comparisons, including saved database text and ordered output
messages. Its files are written in an isolated temporary directory. Universal
IO/delivery/durability and the remaining dispatch obligations stay open.


`restart_metadata.bend`, `world_seed.bend`, `lifecycle_seed.bend`,
`seeded_world.bend` and `seeded_trace.bend` add 62 safe laws. Reconstruction
preserves every metadata field except the player-ID allocation cursor, and
its resulting maps equal the landscape generated from its actual stored seed.
`SeededWorld.OK` joins that map equality to the full world/connection invariant
indexed by the world's own seed. Fresh worlds and the actual affine channel
restart satisfy it. Commands, lifecycle operations and complete ticks preserve
the stored seed; arbitrary mixed pure traces retain agreement between that
seed and the seed supplied to map-dependent operations, even across restarts.
The trace's terrain wrapper reconstructs maps from its packed seed; refinement
of every legacy server adapter and the outer effectful dispatcher is still
required. These laws do not establish network delivery or save durability.

`world_clock.bend` contains the safe clock update now called by the server.
Twelve laws prove its exact whole-world result, preservation of maps and the
stored seed, and preservation of the complete world/connection invariant.
Repeated updates keep the last supplied time; setting the existing time is
an exact no-op. Mixed trace proofs now include explicit clock updates alongside
lifecycle commands, gameplay, ticks and restarts. These are state-preservation
claims for arbitrary supplied U32 times, not assumptions that the external
clock is monotonic or cannot wrap. `./check-clock.sh` runs 12 native comparisons
with the preserved original clock body and eight mixed trace cases; all 20
also run in the regular JavaScript gate.

`live_tick.bend` adds 16 safe laws and now drives the actual server tick.
It prepares player upkeep once, derives damage inputs from the prepared
monster roster, runs the checked target/tick pipeline, and retains the actual
map data. The full world/connection invariant remains indexed by the world's
stored seed. Tick events and the original snapshot clock are retained.
The safe output adapter returns that checked world alongside exactly the
formatter's affine message list; formatting cannot replace the world or lose
its supplied output through that adapter. Legacy message formatting and IO
delivery remain separate obligations. `monster_damage.bend` supplies the
actual attack catalogue and damage inputs, preserving existing U32 arithmetic;
this does not close the remaining overflow/accounting obligations.
`./check-live-tick.sh` runs 50 native comparisons with the preserved original
attack and tick bodies, including complete returned worlds and every ordered
output message. The same cases also run in the JavaScript gate.

`live_commands.bend` adds 17 safe laws for the actual inventory, movement,
NPC and portal adapters. The checked command path derives shop proximity from
the selected player and portal sigils from the actual world metadata. Its
complete player result refines the existing command model; all metadata,
monsters and actual maps are retained. The full world/connection invariant
holds after commands and arbitrary finite command sequences. Notices and the
formatter's affine message list are retained exactly by the safe output
adapter. The actual server helpers delegate to these checked functions.
`./check-live-commands.sh` runs 52 native comparisons of complete returned
worlds and ordered messages against preserved original command bodies;
the same cases run in the regular JS gate. Combat adapters, remaining wire
dispatch, legacy formatting and IO delivery remain in the proof plan.

`live_combat.bend` adds 18 safe laws for the actual attack/spin admission,
execution and output adapters. Admission runs once; the planner returns hit
inputs and visual data. The checked executor preserves the full world and
connection invariant, actual maps, stored seed and exact battle notices.
Rejected admission discards even a supplied lethal plan and combat visual.
The output adapter retains the returned world and formatter's ordered lines.
`./check-live-combat.sh` compares 60 native results with the original combat
adapters; these cases also run in the JS gate. Planner eligibility, arithmetic,
reward liveness, legacy formatting and outer IO remain separate obligations.

`combat_targets.bend` and `target_plans.bend` add 40 safe laws for ordered
combat selection and binding the attack input to its selected monster. The
filter includes exactly eligible source records, preserves their order and
unique IDs, and first selection chooses its head. Eligible targets share the
player's zone, have dead flag zero, and are within Chebyshev distance one.
Under unique IDs, subsequent lookup returns that exact selected record.
Attack now produces no hit on a miss, eliminating the old ID-zero sentinel
edge case. `./check-combat-targets.sh` runs 56 new cases plus all 60 previous
live combat comparisons natively; the new cases also run in `check.sh`.
Spin input binding, damage arithmetic, reward liveness and the other remaining
full proof scopes stay open in PROOF_PLAN.md.

`spin_plans.bend` adds 15 safe laws for the actual spin hit list. It uses a
dependent payload sequence with one entry per selected monster, calls the
affine builder once, and constructs each hit with that monster's ID. Proofs
retain exact target order/count, all damage/reward payloads and spin visual;
each hit's ID resolves to its eligible source record under unique monster IDs.
`./check-spin-plans.sh` runs 48 new cases plus the previous60 live combat
comparisons natively. The new cases also run in `check.sh`. Sequential combat,
damage arithmetic and the other full proof scopes remain in PROOF_PLAN.md.

`combat_frame.bend` adds 22 safe proofs for sequential combat. A strike retains
every field and relative order of all other-ID monster records, including
through rewards. For the actual spin hit list, each target's eligible source
and exact lookup are proved against the intermediate world before its hit.
Uniqueness comes from the existing world invariant. The attack origin is fixed;
attacker-position framing, complete phase/finalization behavior and the other
full proof scopes remain open. This addition changes proofs only.

The proof gate also checks 21 current-attacker laws: battle rewards preserve
player identity, position, health/death state and cooldowns, and each spin
hit has an eligible target relative to its intermediate attacker record.
Full phase/finalization and end-to-end proof scopes remain in PROOF_PLAN.md.

The proof gate includes 14 admitted-actor laws: accepted combat returns the
exact updated roster member with the requested PID, and the live executor
preserves its identity, position and vital-state frame through rewards.

Spin planning now runs through the checked `live_spin.bend` adapter. Its seven
laws bind the admitted actor and world snapshots to the proved hit sequence.
`check-live-spin.sh` checks the new snapshot cases and prior spin/combat cases
natively; the normal check script includes the same new JavaScript cases.

Normal attacks now use the checked `live_attack.bend` planner as well. Its11
laws bind actor, target and command context to the executed hit while retaining
critical and visual fields. `check-live-attack.sh` runs the new attack cases and
prior target/combat comparisons natively; the normal gate includes them in JS.

The proof gate also checks22 completed-command anti-spam laws. After an accepted
attack or spin, an immediate same-kind live command cannot execute its supplied
hit plan, including after rewards, level-ups and player reordering. Tick/respawn
and broader scheduling obligations remain in PROOF_PLAN.md.

Twelve additional laws cover immediate combat retries whether the first request
was accepted or rejected. The second same-kind command emits no combat effects
and preserves complete world/player data, allowing only lookup roster ordering.

Clock updates also preserve combat retry rejection: seven safe laws cover both
command kinds and arbitrary timestamps, with the updated time retained exactly.

Finite same-kind combat streams now have a checked induction: after the first
request, every retry is inert, with arbitrary per-request clocks, scores and
planners evaluated against the actual evolving world.

Cooldown proofs now cover actual player upkeep: living players decrement each
counter with saturation at zero, damage preserves counters, waiting dead players
retain them, and revival resets them. Enough living-player upkeep steps restore
combat availability in active phase.

The actual live tick now has an ID-paired cooldown theorem: active upkeep applies
its live/dead/respawn rules once, monster hits preserve the resulting counters,
and inactive ticks leave them unchanged, allowing target-lookup roster ordering.

Cooldown tracking now recovers the actual player after each live tick, preserving
its PID/CID pairing through death, waiting and revival. Valid-world proofs also
establish exact PID lookup, and finite tick histories carry this tracking at
every step.

Mixed combat proofs show that using the other attack type preserves an existing
cooldown, including through rewards and commands by other players. A subsequent
retry of the protected attack remains inert.

Commands by a different player preserve your identity, position, health state
and both combat cooldowns through admission and rewards. A locked attack or
spin remains unavailable after such a command, including one of the same kind.

Finite combat streams may mix players, attack types, timestamps, scores and
planners. Once an attack or spin is accepted, its cooldown stays locked through
that stream, and every protected retry is inert. These streams contain clock
updates and combat commands; elapsed gameplay ticks are a separate obligation.

Partially elapsed cooldowns remain protected too: any positive remaining value
blocks a retry and survives an intervening combat command. Live-tick proofs
recover the actual remaining cooldown, including death/waiting behavior, and
compose it with combat while accounting for respawn resets.

Exact combat-transition proofs cover zero and nonzero cooldowns. A tracked
player keeps both counters unless their own command is accepted, which stamps
only its attack type. This rule follows the actual final roster through rewards
and also covers dead/inactive players, expiry, and reuse after respawn.

Mixed live-history proofs follow an actual player through arbitrary finite
combat/tick sequences, including death, waiting, respawn, expiry and reuse.
Every step records the exact cooldown transition and proves blocked commands
inert. The final player is recoverable by the original PID; seeded-world
validity is preserved from an initially valid world.

Quantitative cooldown proofs count active live upkeep ticks along the actual
mixed history. Without another accepted use of that attack type, the remaining
counter is at most the initial counter minus those ticks, floored at zero.
Waiting/inactive ticks pause progress; revival can clear the counter earlier.
Enough counted ticks plus a living player and active phase guarantee actual
admission of the next command by the original player ID.

Lethal attack proofs connect the actual first eligible target, unique monster
lookup, sufficient calculator damage, and admitted actor to exactly one reward
notice from LiveCombat.run using LiveAttack.plan. Calculator inputs are the
actual prepared world/player and selected monster. These are conditional kill
and reward guarantees; catalog damage bounds and eventual progression remain
separate obligations.

Lethal spin proofs derive one reward notice per eligible selected monster when
its actual calculated damage reaches its current HP. The proof follows every
hit through the actual updated world and preserves the recipient through
payouts, including a boss kill that changes phase before later spin hits.
Individual kill reports retain each selected monster's original identity.

Dead-monster reward proofs preserve the complete dead record through arbitrary
ordered strikes with changing player IDs, damage and payout plans. Such traces
produce no reward notices for that monster; rewards for other monsters remain
possible. The interval contains no tick or respawn, and final lookup is derived
from preserved membership and uniqueness.

Exactly-once reward proofs now begin with a real lethal hit on an eligible,
uniquely identified monster and an existing recipient. The hit derives the
actual corpse and first reward; arbitrary later strike commands add no rewards
for that MID. The complete interval therefore contains exactly one such reward
notice, while other monsters can still reward their killers. Tick/respawn
lifetimes remain a separate proof obligation.

Dead-monster reward exclusion now follows actual timed LiveCombat commands,
including admission, arbitrary affine planners, rejected requests and changing
players/attack types. Every real command result is retained. A proved lethal
prefix followed by any such no-tick command stream still contains exactly one
reward for the original monster; final corpse lookup is derived.

Actual lethal attacks now construct the complete exactly-once certificate from
admission, actual first target selection, monster-ID uniqueness and sufficient
calculated damage. The full affine attack builder and arbitrary later timed
combat planners are each consumed once. The combined theorem derives exactly
one reward for the killed monster across the initial attack and the entire
no-tick suffix, retaining the actual worlds, maps and results.

Spin reward certificates now cover every actual selected target when each
calculated hit is lethal. Earlier hits preserve later targets and contribute
no rewards for them; after death, remaining hits contribute no further reward.
Any selected member can then be followed through an arbitrary timed no-tick
combat suffix, with exactly one reward across the complete spin and suffix.
The actual full spin builder and later affine planners are each consumed once.

Spin's exactly-once proof also covers mixed lethal and nonlethal hits. Only the
tracked selected target must receive lethal damage from its own actual power;
other selected powers are unrestricted. Its certificate follows the actual
ordered spin and any later timed no-tick combat commands, including preceding
rewards or phase changes, without rerunning affine planners.

Monster lifetime proofs now classify the actual tick/AI transition: a dead
monster becomes alive exactly when a nonpermanent ready tick commits Spawn.
Waiting retains death while changing the timer; permanent corpses stay dead.
The certificate preserves the monster ID and zone and excludes an attack from
that dead-monster transition. Ordered roster tracking uses the actual plan at
its position, including missing-plan defaults; final ID lookup requires unique
IDs. Complete live-world tick/reward history composition remains in progress.

Lifetime certificates now follow actual zone filtering and the plan position
within that zone, through the merged AI output and active Planning.finish.
They retain the exact updated monster and its respawn event; final lookup by
original ID is derived under uniqueness. Full LiveTick and mixed reward-history
composition remain in progress.

Lifetime tracking now covers complete LiveTick.run, including inactive worlds
and actual context selection after player upkeep. After a tick without respawn,
any finite sequence of timed combat commands produces no further reward for
that monster. The proof follows the changed corpse record, including its timer.
Multiple interleaved ticks and reward histories across respawns remain open.

Permanent death now has a mixed-history proof: from a valid seeded world, any
finite sequence of actual ticks and timed combat commands preserves the exact
corpse record and emits no further reward for its ID. Combined with a verified
lethal result and valid resulting world, this preserves exactly one reward
through the whole mixed suffix. Ordinary respawn lifetimes remain in progress.

Ordinary dead monsters now have an actual mixed-history lifetime certificate.
It follows timer changes up to the first real respawn tick and proves no new
combat reward for the tracked ID in that prefix. The proof retains the exact
remaining history; a later legitimate kill can reward the respawned monster.
If no respawn occurs, the certified prefix covers the complete history.

A verified lethal reward now composes with the ordinary dead-lifetime
certificate: the initial result plus all actual mixed tick/combat entries up
to respawn contains exactly one reward for that monster. If no respawn occurs,
this covers the complete mixed history. The wrappers preserve the actual
planner and maps and derive post-command world validity from the input world.
