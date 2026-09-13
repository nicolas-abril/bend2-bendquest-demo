# World proof obligations

Requested scope: prove all six extensions discussed after the original 15
kernel guarantees, one by one. A checked helper is progress, not completion
of a server-level property. Runtime tests supplement proofs; they do not
replace them. Keep the game in this repository and use sibling bend2-core.

## 1. Commands and ticks preserve a valid world — in progress

Latest live inventory/interaction adapters: `LiveCommands.run` now drives
the real hero-operation, movement, NPC and portal world/output wrappers. It
derives shop proximity from the selected player and explicit portal entry
from actual stored sigils. The full simulation refines the existing checked
command model, while metadata, monsters and actual map data are retained.
Full intrinsic world/connection validity and exact adapter output are proved.
Remaining combat adapters, wire dispatch, legacy formatting and IO stay open.

Latest live tick: the actual `Bq.tick_world` now uses safe `LiveTick.run`
and `LiveTick.emit`. The proof covers its prepared monster damage selection,
complete tick state, retained actual maps, stored seed and full bidirectional
connection invariant. The safe output adapter retains that world and exactly
the formatter's message list. Snapshot clock and event data are retained.
Legacy message construction and outer IO/dispatch/delivery remain open.

Latest clock adapter: the actual server `Bq.set_now` now delegates to safe
`WorldClock.set`. Its universal whole-world equality preserves every field
except the requested current time. The full intrinsic seed/map/world/connection
invariant is preserved; mixed trace theorems now admit clock updates between
any commands, ticks or restarts. This does not assert external-clock monotonicity
or eliminate elapsed-time wraparound obligations in scope 5.

Latest metadata composition: `SeededWorld.OK` now ties world and connection
validity to the world's actual stored seed and exact map data. Reconstruction
preserves every metadata field except its allocation cursor. Commands,
lifecycle operations and complete ticks preserve the seed, and arbitrary
mixed pure traces preserve its agreement with the seed selected for maps.
The actual affine channel restart preserves this stronger invariant. The
trace terrain wrapper regenerates maps from its packed seed; universal
refinement of remaining legacy adapters and outer IO dispatch remains open.

Latest live adapter: `ChannelRestart.restart_ok` now connects the server's
actual channel-bearing reconstruction/rebind implementation to the pure world
and connection invariant. Exact channel handles/raw names and descriptor
refinement are checked universally, including the actual next-world input
calculation. The remaining outer IO/dispatch, delivery and persistence
obligations are still open; native old/new effect comparisons supplement
these proofs without replacing those obligations.

Latest completed composition: `Restart.run_ok` preserves the combined pure
world and bidirectional connection invariant through actual reconstruction
and the checked rebinding model. `RestartTrace.fresh_trace` covers arbitrary
mixed lifecycle, gameplay, ticks and restarts with changing seeds. All
reconstruction/rebinding correspondence premises are derived from the old
invariant. Universal effectful adapter/dispatch refinement and the other
server-level obligations below remain open; see the final validation entry.

Required invariant and closure obligations:

- Player and monster health stays between zero and its current maximum.
  Dead/alive flags, respawn health, maximum-health changes, and lists of hits
  must agree with that invariant. Initial worlds and newly created players
  must satisfy it.
- Positions have valid zones and coordinates and lie on walkable tiles;
  movement, respawn, creation, and portal transitions preserve this.
- Player, connection, and monster IDs are unique, with matching references;
  allocation cannot collide on wraparound, and removal preserves other entries.
- Equipment stays legal across every transition, including XP/level rewards;
  the existing hero-operation theorem is only one part of this obligation.
- Define `WorldOK`, prove initialization, then preservation for every
  authoritative command and tick (including their sequential compositions).

Completed foundation: `health.bend` checks without unsafe annotations, holes,
foreign effects, or unfilled laws. It proves clamping and healing bounds,
valid healing never decreases health, damage never increases health,
damage preserves a valid upper bound, and damage below current health leaves
positive health. Refinement lemmas connect the efficient implementations to
these specifications. `world.bend` uses the exact health implementations for
potions, regeneration, boss regeneration, player/monster damage subtraction,
and post-operation health clamping.

Completed numeric dependency: `numeric.bend` proves generic word round trips,
natural-number round trips within the word's representable range, and Base's
actual U32 codecs. A `Fits<n, k>` witness contains an actual n-bit word and
an equality to k; it is constructed for every decoded word and proved closed
under decreasing the natural value. It is not an assumed bound.
`health.bend` now proves all three live U32 wrappers exactly refine their
natural-number rules. Healing and clamping are bounded for every word input;
healing cannot harm valid health; damage preserves valid bounds and a
strictly sub-health hit leaves positive health. These are universal proofs,
not consequences inferred from `health_check.bend`.

Completed maximum-health foundation: `growth.bend` proves the actual maximum
formula is monotone in level and vitality, then transports that result through
the saturated word conversion. It proves preservation of an existing health
bound for any level/vitality growth and for individual level/vitality steps,
with fixed charm bonus and ceiling. `world.bend` now calls `Growth.maximum`
with the U32 ceiling, adding the charm bonus before conversion. This fixes
the previous wraparound in both the raw maximum and the charm addition.

Completed reward-handler dependency: `rewards.bend` contains the actual XP
loop, gold grant, item grant, and side-quest payout functions used by the
server. Universal proofs establish that every iteration of the XP loop and
every grant preserves a valid health bound and `WellEquipped`. The maximum
calculation includes the actual equipped charm, which level-ups and grants
retain. The XP loop is structurally recursive with explicit fuel; the server
uses the original 20-step budget and level cap. Legacy tuple adapters remain
in `world.bend` and are exercised by the regression checks.

This proves state preservation by payouts, not their eligibility, frequency,
or exact numeric accounting. XP addition still uses wrapping U32 arithmetic;
its representability/accounting obligation remains in item 5. Quest reward eligibility, loot selection, strike-to-reward composition,
and full command dispatch remain outside the safe proof closure. The complete
payout composition for state validity is now checked below.

Completed player vital-state dependency: `vitals.bend` owns the server's actual
six-field vital-state representation. `Vitals.OK` requires health below its
maximum and either a live flag with positive health or a dead flag with zero
health. Proofs cover initialization, damage, death, respawn, waiting,
regeneration, and upkeep. Live damage exactly refines saturating natural
subtraction; hits on dead players preserve the entire state and report no
new death. The maximum-health formula is proved positive for every hero with
a positive ceiling, discharging revival's positive-health requirement.

Player creation, the actual hit-list adapter, and the actual upkeep adapter
call these checked transitions. Complete player lookup, hit-list, and upkeep
preservation are now checked below. Event formatting, map-based movement
planning, other player commands, and the remaining world invariants remain outside
this safe closure; native and JS adapter tests are supporting evidence only.
Completed monster lifecycle dependency: `monsters.bend` owns the server's
actual monster record and strike/tick transitions. `Monsters.OK` requires
bounded health and agreement between health and the dead flag. Initialization,
hits, waiting, regeneration, and changes to movement/target/cooldown fields
preserve it. A zero maximum supplied at initialization is normalized to one;
ordinary monster and boss maxima are unchanged. The live strike and AI
adapters use these functions, and respawn uses the proved initializer.
The permanent-death marker is proved to keep a monster dormant and unchanged.
Whole-list strike preservation is now proved below. The checked AI list
composition is described below; these results do not prove walkability or
target legality.

Completed monster-roster dependency: the server's repeatedly reused monster
lists now explicitly use the shared list grade. `roster.bend` owns lookup,
concatenation, and the whole-list strike implementation used by the server.
`Roster.OK` requires `Monsters.OK` for every entry. Lookup preserves validity
of both the selected record and the remaining list; concatenation and a full
strike preserve validity of the entire result list.

The lookup proof also gives a standard permutation witness relating all
complete original records to the selected record plus the remainder. Thus
lookup does not drop, duplicate, or alter records. Strikes preserve list
length. Word-comparison reflection in `numeric.bend` proves that a selected
monster has exactly the requested U32 ID; lookup succeeds when that ID occurs,
and a missing-ID strike preserves the exact original list with no event or
damage. The first-entry lookup law covers selection even with duplicate IDs;
this is not a proof that world allocation prevents duplicates.

The remaining legacy tuple/option adapters are exercised by native and JS
regressions. ID uniqueness and full command preservation remain open; player-list
hit/upkeep and tick composition for these invariants are now checked below.

Completed monster-AI list dependency: `ai.bend` applies data-only plans through
checked lifecycle transitions. The server uses `AI.step`, `AI.run`, and the
parallel four-zone `AI.run_zones` implementation. Their preservation proofs
establish health/dead-flag consistency for the entire output roster for any
plans. Missing plans still apply upkeep; extra plans cannot create monsters.
The single-list update preserves the number of monsters.

Dead monsters cannot emit attack hits, including on their respawn tick.
Permanent boss death remains unchanged for every plan. An attack is rejected
when its post-upkeep cooldown is nonzero, and a successful attack resets it
to nine. Planning may inspect the lifecycle result, but the checked update
commits only one upkeep; regression cases check regeneration and cooldowns.

The legacy planner still chooses positions, targets, and damage. These
proofs do not establish walkability, target ownership, legal attack range,
or damage correctness. The valid-zone/partition obligation is now proved
below. Player-hit list application and tick composition for the established
invariants are now checked below.

Completed zone and identity conservation dependency: `zones.bend` defines
`Zones.Valid` with explicit evidence that a zone is 0, 1, 2, or 3, and
`Zones.All` requires this for every monster in a roster. Grouping such a
roster into the server's four zone lists is proved to be a permutation of the
complete original records. Filtering therefore neither drops nor duplicates
records under this explicit valid-zone condition.

The actual monster spawn, damage, upkeep, movement, respawn, and AI commit
functions preserve their specified ID and zone. Single-list AI updates preserve
the complete sequence of `(ID, zone)` keys for any plans. For the actual
four-zone update, `Zones.run_zones_conserves` supplies both a full-record
permutation of the input and equality of that reordered input's keys with
the output's keys. `Zones.run_zones_count` separately proves total count
preservation. These guarantees allow health, positions, and other mutable
fields to change as specified by the update.

`Zones.strike_conserves` provides the same conservation evidence for the
actual lookup/damage/reinsertion path, including missing targets. Both strikes
and the four-zone AI update preserve `Zones.All`, so their valid-zone condition
is preserved under composition. The proofs include missing/extra plans and
arbitrary damage; they require no unique-ID assumption.

This is not yet a proof that allocation supplies unique IDs, or that initial
world construction satisfies every invariant. Those obligations, player
references, positions/walkability, and complete server command preservation
remain open. Arbitrary words outside zones 0–3 are not silently assumed valid;
partition conservation is explicitly conditional on `Zones.All`.

Completed player-list dependency: `players.bend` owns the complete player
record used by the server, including position, vital state, hero, style,
quests, counters, and name. Its records and lists explicitly use shared data.
Names are stored as shared character lists and converted at legacy text
boundaries; the stored-name conversion round trip is proved for every name.

`Players.OK` combines bounded health, agreement between health and the dead
flag, and `WellEquipped` for the current hero. Fresh-player creation now uses
a checked initializer. Lookup proves that the selected record and all others
remain valid, returns the requested ID, succeeds when present, and preserves
every complete record up to permutation. Missing lookup returns the exact
original list; duplicates still select the first entry, without assuming
that allocation permits or prevents duplicates.

The actual `Players.apply_hits` used by the server processes hits in order,
with each hit seeing the preceding result. It preserves `Players.OK` for
every player and preserves list length across arbitrary hit lists. Hitting
a dead player preserves its complete record and emits no death event.
The actual `Players.upkeep_all` likewise preserves validity and length for
any coordinate plans, including missing/extra plans. Respawn retains the
profile and resets position/vitals through the checked transition; the
server formats the resulting death and revival events at its text boundary.

Movement planning still determines proposed coordinates; these theorems do
not establish their walkability or adjacency. Inventory/stat commands and kill payouts are lifted below; other quest
commands and identity allocation still need lifting through the whole player state. Tick composition for the established invariants is
checked below. The player validity
predicate does not yet include those additional WorldOK obligations.

Completed tick-composition dependency: `simulation.bend` owns the metadata
record and the actual two-stage tick used by `world.bend`. `Simulation.OK`
combines player health/dead-flag consistency and legal equipment, monster
health/dead-flag consistency, and valid monster zones. It intentionally does
not stand in for the full `WorldOK` above.

`Simulation.begin` checks the phase and applies player upkeep once. The
server plans monster actions against the resulting player roster, then calls
`Simulation.finish` once. The latter performs the four-zone monster update,
converts every emitted hit without loss or reordering, and applies those hits
to the updated players. `Simulation.tick_ok` proves preservation through the
composition for any plans, and `Simulation.trace_ok` lifts it to arbitrary
sequences of ticks. Player and monster counts are preserved through both a
tick and a tick sequence, with the explicit valid-zone hypothesis for monster
partitioning.

Separate exact-effect laws ensure the pipeline cannot satisfy preservation
merely by skipping work: non-active phases preserve both complete rosters
and emit no gameplay events; active ticks run upkeep, AI, and all emitted
hits in order. Upkeep events precede hit events. The hit conversion has a
proved inverse on complete ordered `(target, damage)` payloads. Metadata
proofs specify every field independently: a tick retains phase, seed, world,
time fields, progression, and allocation counters, and increments only the
tick word. That increment still uses U32 wraparound; this does not discharge
the numeric/accounting obligation in item 5.

Map-based planning and output formatting remain in the legacy adapter. The
server snapshot still uses the pre-increment tick number, while stored
metadata advances. The proofs cover the full gameplay-state pipeline for the
listed invariants, not map validity, legal targets/moves, unique references,
all command handlers, world initialization, or the full `WorldOK`.

Completed inventory-command dependency: `inventory.bend` owns the complete
player and roster transitions used by purchase, equip/unequip, allocation,
and potion commands. `Inventory.step_ok`, `run_ok`, and `trace_ok` preserve
player health/dead-flag consistency and legal equipment. Positive health is
preserved even when removing an equipped charm lowers the current maximum;
the exact live clamp/heal functions are included in this proof.

Separate exact-effect laws cover successful potion healing, exactly one
consumed potion, purchase item/gold accounting, equipment item conservation,
and the stat budget. The selected hero refines the original kernel operation
when the player is alive and the shop condition is satisfied. Dead-player
commands, rejected kernel operations, and purchases outside shop range retain
the complete selected player. A missing target retains the complete roster.
Lookup may reorder records as before; a full-record permutation plus equality
of all fields outside hero and health proves conservation of identity,
position, cooldowns, XP, quests, counters, cosmetics, and names. List length is
preserved through individual commands and arbitrary command sequences.

The server now derives shop/potion flags from the kernel operation and uses
these transitions. Potion healing is triggered by the exact kernel acceptance
decision, replacing a wrapping inventory-count comparison. In particular,
consuming from 2^32 potions now heals while leaving exactly 2^32-1 potions.
The UI buy notice also uses acceptance rather than converted gold equality.
No numeric bound on reachable inventory counts is assumed by these proofs;
reachability/accounting remains in item 5.

Shop proximity now uses the checked interaction helper described below. These
inventory laws do not establish connection ownership, all movement/reference
invariants, or initial-world validity. Reward-path and combat/tick composition
for the established invariants are added below; the full WorldOK remains open.

Completed kill-payout dependency: `payouts.bend` owns the complete player and
roster transitions used by `kill_reward`, `on_mob_kill`, `sigil_advance`, and
`advance_if_boss`. The actual XP result feeds the gold grant, main-quest and
kill-score update, side-quest reward, loot/find bonus, and boss bonus in order.
Safe player/roster validity proofs cover this full composition and arbitrary
sequences of payout requests. Both live and dead vital states remain
consistent, and level changes preserve health and legal equipped items.

Exact-effect laws bind the player XP/hero/level receipt to the authoritative
XP loop, prove the exact natural-number gold credit and item census change,
and specify side-completion and loot notification payloads. Separate frame
laws preserve IDs, connection IDs, positions, health, dead flags, respawn and
combat timers, cosmetics, and names. Whole-roster conservation supplies an
actual permutation of complete input records plus equality of these unchanged
fields. Sigil updates preserve their order and every player; payout lookup
preserves count, and a missing killer retains the complete roster.

The world adapter supplies catalog-derived amounts, drop selection, and
scoring thresholds as a data plan. The checked path owns quest counter updates,
claim-bit guards, find-bit updates, reward application, and the final roster.
Legacy text adapters format the returned side/loot/level receipts and boss/run
messages. World phase/sigil metadata and strike-to-reward dispatch are now
checked in the battle composition below. The payout module alone does not
establish that a payout
request is eligible, that it can occur only once, or that all quest/run
lifecycle requirements are met. The existing U32 arithmetic in XP, scores,
quest counters, and multipliers remains an explicit item-5 obligation.

Talk, movement/portal commands, and combat/tick composition are lifted below.
Initialization, references, allocation, and the remaining WorldOK components
still need proofs. No numbered requirement is complete.

Completed interaction/navigation dependency: `navigation.bend` and
`interactions.bend` own the actual movement-control, halt, NPC-talk, and portal
transitions. `Interaction.step_ok`, `run_ok`, and `trace_ok` preserve the
established health/dead-flag and equipment invariants for complete players and
rosters. Exact field/frame laws preserve identity, hero, vitals, cosmetics,
side-quest counters and claims, kills, found items, and names. Movement and
portal commands additionally retain the complete quest and metadata records.

`Navigation.Bounds` separately requires a finite valid zone, x below the
shared grid width, and y below its height. The route proof enumerates every
valid source zone and discharges all destination-zone obligations for arbitrary
portal flags and sigil words. Landing bounds use checked portal-rule witnesses;
the live default rules prove their own arrival bounds. The Rift forward route
requires the exact sigil word seven. Move/halt keep coordinates; talk retains
position; enter installs the checked landing. Lookup transfers bounds through
its complete-record permutation, and individual commands and arbitrary
command sequences preserve `Navigation.All` on the entire roster.

The live grid/portal coordinates, NPC positions, and talk-score constant in
`data.bend` delegate to these safe definitions, so the constants are shared
with generation/rendering and the existing inventory shop adapter. A word-level
mask proof establishes that every incoming direction becomes a value below
four, and the move-position law binds that mask to the updated player.

Separate exact-effect laws cover direction/moving changes, quest start and
its ten-point word credit, portal event payloads, and repeated elder dialogue:
after the quest-start result, talking again retains the complete player and
emits only the current dialogue (or nothing when out of range). Roster count,
complete-frame conservation, and missing-target no-op guarantees are checked.
The score credit remains U32 arithmetic; numeric accounting is still item 5.

These bounds are conditional on bounded input players and are separate from
`Players.OK` and `Simulation.OK`; they do not silently strengthen the earlier
tick theorems. Generated-map walkability at portal arrivals, tick-time movement
legality, initial-world bounds, and mixed command/tick position bounds,
references and unique-ID allocation remain open. No numbered requirement is
complete.

Completed player-combat admission dependency: `combat.bend` now owns the
actual attack/spin admission, cooldown updates, and whole-player lookup used
by both server commands. `Combat.prepare_ok`, `run_ok`, and `trace_ok` preserve
health/dead-flag consistency and equipment validity. Position equality and
roster-bound laws retain `Navigation.All`. A complete frame retains every
player field except cooldowns; a separate law retains the other attack's
cooldown. Roster permutation/frame conservation, count preservation, and
missing-target exact no-op are proved without assuming unique IDs.

Admission rejects a dead flag of one, a positive selected cooldown, or any
phase unequal to one. Accepted attacks set four ticks; spins set twenty-five.
The shared constants in `data.bend` now delegate to this module. `dead_rejected`,
`cooling_rejected`, and `inactive_rejected` state exact complete-player no-ops.
`live_ready` supplies the positive effect for a live, ready player in phase one.
`prepare_repeat` proves a second same-kind attempt with the same phase is
rejected, retains the complete post-first-attempt player, and cannot reset the
cooldown. `admit_ready` and `admit_rejected` tie actor dispatch to the exact
committed player; rejected or missing actors produce no combat dispatch.

The server adapters still select targets, compute damage, and format events.
Strikes, kill payouts, and mixed combat/tick preservation of the established
invariants are now composed below. Target legality and the mixed command/tick
attack-rate bound remain open. Admission traces are explicitly not full combat
traces.
No numbered item is complete.

Completed strike/payout composition dependency: `battle.bend` now owns the
actual ordered strike-to-reward path used by normal attacks, spins, and the
standalone kill-payout adapter. It consumes `Roster.strike`'s actual kill event;
no event skips payout entirely. A present event dispatches `Payout.run`, with
its kind fixed to the actual slain monster rather than an arbitrary plan kind.
Missing killers retain the post-strike world without rewards or metadata changes.
The live adapters supply catalog amounts, damage, and target IDs as data plans.

`Battle.strike_ok` and `run_ok` preserve `Simulation.OK` through individual and
arbitrary ordered strikes. `execute_ok` and `command_ok` compose this with actual
attack/spin admission; an absent admitted actor cannot execute any supplied
plan. `transition_ok` and `trace_ok` compose these commands with the actual
checked tick for arbitrary mixed sequences. Player and monster counts are
preserved throughout these compositions. `Simulation.OK` still means player
health/dead-flag/equipment validity plus monster health/dead-flag/zone validity;
it is not full WorldOK and does not include position bounds or walkability.

The checked metadata transition adds the appropriate sigil, preserves unrelated
metadata fields, and records phase two and the current finish time for the final
boss. Typed notices carry the exact payout receipt, slain-monster identity,
elapsed time, completion flag, and player snapshot at that point in the sequence.
Spin notices concatenate in strike order, including a game-over snapshot before
any later strike's awards. The live formatter consumes those snapshots.

`strike_no_kill` proves that an unreported kill cannot pay, mutate players or
metadata, or emit a reward notice. `strike_reported` proves that an actual kill
event and a present killer produce exactly one reward notice; the checked payout
calculations supply its receipt. This is positive dispatch liveness for an
individual reported kill. It does not yet prove global exactly-once rewards
across arbitrary roster traces, unique-ID allocation, respawns, quest/run
lifecycles, finalization, or save/reload. Those remain item 2.

The spin planner precomputes target/damage/catalog plans from the original
monster roster and hero snapshot. The commit applies them sequentially to the
updated state. The differential cases below verify compatibility, including
duplicate IDs and multi-boss ordering. Planner target/range legality, damage
correctness, catalog accounting, initial-world validity, walkability, references,
and ID allocation retain their outstanding proof obligations.

Completed terrain/movement dependency: `terrain.bend` owns the actual shared
map lists and complete world record used by the server. Generation still builds
its existing linear maps, then converts each once into the shared representation.
Both conversion round trips are proved. World reconstruction preserves the
complete simulation and maps, with exact projection/round-trip laws.

The live tile lookup now checks zone 0–3, x < 30, and y < 17 before computing
a natural-number row offset. In-bounds lookup exactly follows the row-major
map list; missing maps/cells and invalid coordinates return a solid tile.
This fixes previous row aliasing (x = 30) and wrapped U32 offsets. Map and zone
lookup laws cover selected entries after arbitrary prefixes and missing entries.

`Terrain.On<maps,pos>` combines `Navigation.Bounds` with a proof that the actual
tile is walkable. The exact player step, moving-flag gate, and monster step
preserve this predicate from a valid starting position. They separately preserve
bounds and a stronger cardinal-step relation: unchanged zone, at most one axis
changing, and displacement at most one tile. Solid destinations retain the
complete position; accepted steps commit the exact proposal. Zone, heading,
and moving flags are preserved. Monster movement retains its village gate.
Direction decoding is proved equal to the legacy four-way rule, including
unknown words selecting down. U32 conversions are justified by representability.

These 53 laws are part of the strict safe closure and the server calls their
actual implementations. They do not establish initial-world validity, spawn or
portal-arrival walkability, whole-player/monster tick position preservation,
unique IDs/references, or every command's closure. `Simulation.OK` remains the
previous partial invariant; `Terrain.On` is an additional predicate with an
explicit valid-start hypothesis. The full `WorldOK` remains open.

Completed whole-player locomotion dependency: `locomotion.bend` owns the actual
map-derived planner used by single-player upkeep, whole-roster upkeep, and the
phase-gated tick preparation. The server still plans monsters against the
prepared player roster, then calls the checked finish wrapper. World assembly
uses the checked map/simulation constructor.

`Locomotion.On` and `All` require each complete player's position to satisfy
`Terrain.On` on the actual maps. The real upkeep commit preserves this predicate,
including movement, waiting while dead, and revival. Exact-effect laws connect
the committed coordinates to the terrain step, specify the complete resulting
position, and distinguish cardinal movement from respawn at the supplied
coordinates. No health, profile, or roster is replaced by a position-only model.

The actual lookup's permutation transports walkability to the selected player
and every remaining entry. Damage preserves positions, including clearing the
moving flag on death. Whole-roster strikes and arbitrary ordered hit lists
therefore preserve every player's walkability. These results lift through the
actual tick preparation, AI-hit application, and arbitrary tick sequences.
Separate laws retain `Simulation.OK` and player count. Tick refinement is an
exact equality to the established simulation pipeline with these actual plans.

The 37 laws are checked in the strict safe closure. Position preservation
requires valid initial player positions and `Locomotion.Spawn`: a bounded,
walkable spawn point on the actual maps. Generated-world initialization has not
yet discharged that premise. `Locomotion.WorldOn` concerns all player positions
in the complete world, not the full WorldOK. Portal-arrival walkability, monster
position/planning preservation, IDs/references, and other command composition
remain open. The health/equipment/monster-zone predicate is unchanged.

## 2. Rewards happen exactly once — monster event dependency proved

`monsters.bend` proves that reporting a kill leaves the monster dead and that
hitting a dead monster preserves the entire record, reports no kill, and
deals zero damage. Induction over arbitrary sequences of the exact live hit
transition proves at most one kill event before any intervening respawn. A
lethal hit on a live monster reports a kill; that hit followed by arbitrary
further hits reports exactly one event. This includes positive kill-event
liveness, not just absence of duplicate events.

The battle composition now connects each actual reported kill to its reward
and proves positive dispatch liveness when the killer exists. Per-monster
event uniqueness still needs lifting through arbitrary roster/ID/respawn traces.
Quest and run reward lifecycles, finalization, and persistence also need
end-to-end proofs. The full item remains open:

Prove each monster death produces at most one kill event/reward before a
legitimate respawn. Prove each quest pays once per defined quest lifecycle,
and each completed run pays coins once. Cover multiple player attacks,
spin attacks, repeated commands, repeated finalization, and persisted/reloaded
run state. Prove the intended reward does occur, not merely that no rewards
can repeat. State legitimate repeatable rewards explicitly.

## 3. Combat restrictions cannot be bypassed — monster AI dependency started

The checked tick now proves that inactive phases preserve both complete
rosters and emit no gameplay events for every plan. This covers tick-time
combat. Player command admission is now checked as described above.

The checked monster AI now proves dead monsters emit no hit, permanent boss
death is unchanged for any plan, nonzero post-upkeep cooldowns reject attacks,
and successful attacks set cooldown nine. These are transition guarantees;
target/range validation and mixed command/tick rate bounds remain open. The
battle composition above now preserves the established state invariants
through strikes, payouts, and mixed combat/tick sequences. The player admission dependency above
now proves dead/cooldown/phase rejection and same-kind immediate-repeat rejection.

Prove dead players and inactive phases cannot attack; positive cooldowns
reject attacks; successful attacks set cooldowns, and only ticks reduce them.
Prove targets are in the same zone and legal attack range. Lift to sequences
of commands between ticks so command spam cannot increase the attack rate.
Cover normal attacks, spins, and monster attacks, not just the hero damage
formula.

## 4. Commands respect player ownership — pending

Define the identity model explicitly: a display name alone is not proof of
ownership of a saved profile. Prove the connection-to-player binding used by
command dispatch; other characters cannot be selected through client input.
Cover HELLO/CREATE repetition, reconnect/disconnect, connection states,
malformed messages, profile/cosmetic access, and duplicate identities.
Changing the protocol to establish ownership may be necessary; do not assume
unauthenticated clients already provide valid identity evidence.

## 5. Conversions and saves preserve state — numeric dependency started

General Nat/U32 conversion round trips under explicit representability bounds
are now proved in `numeric.bend`. Still required:
prove the actual reachable stats, currencies, counters, and IDs respect those
bounds or use representations that cannot overflow. Prove pure encoding and
decoding preserve valid profiles, balances, ownership, and completed runs,
with explicit string/protocol constraints. Reject invalid persisted data.
State the separate host-filesystem assumptions required for crash-safe writes;
do not treat a pure codec theorem as a proof of filesystem durability.

## 6. Generated worlds are completable — pending

For every accepted seed, establish paths through walkable tiles from spawn
to required NPCs, bosses, and portals, including return paths and gate state.
The actual movement primitives now have cardinal-step and collision-preservation
proofs (item 1); lift those to complete reachable-world transitions. Prove progression gates and quests admit a
completion sequence. State the player/cooperation and scheduling assumptions
for combat/progression liveness; reachability alone is not a win guarantee.

## Validation and continuation

- Run `./check-proofs.sh` for the safe proof closure and `./check.sh` for
  gameplay and numeric-boundary checks. Builds also require the proof check.
- Rebuild and run native server/bot/GUI checks when authoritative behavior or
  representations change. Use isolated databases and stop test processes.
- Mutation checks should demonstrate rejection of violating implementations.
- Never mark an item complete from a narrower helper or a finite test.

Latest validation:

- The original 15 witnesses and all numeric, health, growth, and reward
  preservation laws check with no unsafe definitions, holes, or axioms.
- All 127 gameplay/numeric/reward/vital-state/monster/roster/AI/player/tick regressions pass. The reward cases cover
  exact thresholds, multiple level-ups, charm retention, the level cap,
  exhausted fuel, partial budgets, and the actual server adapters/payouts.
- All 15 reward/grant regressions also passed a compiled native C executable.
- Mutating the live XP loop to reset the hero during a level-up is rejected
  at `Rewards.loop_health`. Previous uncapped/wrapping-heal, reversed-damage,
  and uncapped-maximum mutations were also rejected by the safe proofs.
- The rebuilt XP-loop game passed shop/combat bots, graphical join/host,
  UTF-8 networking, and save/restart. The combat bot reached level 2, died,
  and respawned at full health. Artifacts:
  `/private/tmp/bendquest-final-j33h40gs`.
- After installing the checked gold/item/side-quest grants, the final rebuild
  passed the same complete native harness again. The combat bot reached
  level 2 and collected loot. Final artifacts:
  `/private/tmp/bendquest-final-ae263wts`.

Additional vital-state validation:

- All fourteen death/respawn/vital cases pass in JavaScript and native C,
  including exact/overkill hits, repeated hits against a dead player,
  timer boundaries, cooldown saturation, regeneration, the actual server
  hit-list adapter, and the actual server respawn adapter.
- One death emits two outputs by design: a broadcast and a server log entry.
  The repeated-hit adapter test checks that subsequent hits do not repeat them.
- Mutations that leave nonzero health on death, revive with zero health, or
  ignore damage are rejected by `Vitals.fall_ok`, `Vitals.revive_ok`, and
  `Vitals.hit_gate_ok`, respectively.
- The rebuilt vital-state game passed native shop/combat bots, graphical
  join/host, UTF-8 networking, and save/restart. Artifacts:
  `/private/tmp/bendquest-final-mokeh71a`.

Additional monster validation:

- All twenty monster regressions pass in JavaScript and native C. They cover
  lethal/nonlethal/overkill hits, duplicate-kill rejection, emitted kill
  metadata, initialization, permanent boss death, ordinary respawn, waiting,
  Maw regeneration, and adjacent attacks/cooldowns through the server AI.
- Mutations duplicating a dead monster's kill event, suppressing the lethal
  event, or allowing permanent-death respawn are rejected at
  `Monsters.dead_hit_noop`, `Monsters.finish_killed`, and
  `Monsters.permanent_death_stays`, respectively.
- The rebuilt native game passed shop/combat bots, graphical join/host,
  UTF-8 networking, and save/restart. The combat bot collected loot, leveled
  up, died, and respawned while the rewritten monster AI ran. Artifacts:
  `/private/tmp/bendquest-final-47tqcmz0`.

Additional roster validation:

- All thirteen roster regressions pass in JavaScript and native C. They
  compare complete records for first/middle/last lookup, missing/empty lists,
  zero/maximum IDs, first duplicate selection, concatenation, and multi-monster
  strikes through the actual server adapters.
- Mutations dropping an unselected prefix, comparing against the wrong ID,
  or skipping lookup entirely are rejected by the safe proof closure.
- The shared-list native build passed shop/combat bots, graphical join/host,
  UTF-8 networking, and save/restart. Artifacts:
  `/private/tmp/bendquest-final-ssojoj_j`.

Additional AI validation:

- All thirteen AI regressions pass in JavaScript and native C, including
  upkeep once, cooldown rejection, ready attacks, permanent death, respawn,
  missing/extra plans, and the actual server's four-zone composition.
- Mutations bypassing cooldown, failing to reset it, attacking while dormant,
  and dropping a monster are rejected by the safe proof closure at
  `AI.active_ok`, `AI.attack_ok`, `AI.commit_ok`, and `AI.run_ok`.
- The gameplay bot now searches walkable cardinal paths. Its previous greedy
  navigation could stall against terrain before reaching the elder; the
  gameplay success criteria are unchanged.
- The rebuilt AI-list game passed shop/combat bots, graphical join/host,
  UTF-8 networking, and save/restart. The bot reached level two and exercised
  deaths and respawns. Artifacts: `/private/tmp/bendquest-final-59m09bw_`.

Additional zone/identity validation:

- All 51 new zone/conservation laws check in the same safe closure as the
  original 15 witnesses. All 94 existing gameplay regressions pass.
- Mutations changing a spawned monster's ID, moving a damaged monster to
  zone zero, or omitting the Rift partition are rejected at
  `Zones.spawn_positive_key`, `Zones.finish_key`, and `Zones.partition_perm`.
- This addition changes proofs and their mandatory imports; the authoritative
  gameplay transitions are unchanged. Native gameplay validation from the
  preceding AI integration remains recorded above.

Additional player validation:

- All 41 player/name/list laws check in the strict safe closure.
- All twenty-one new player regressions pass in JavaScript and native C. They
  compare complete records, including hero, names, cosmetics, quest state,
  counters, position, and vital state. Cases cover lookup, missing/duplicate
  IDs, ordered multi-player hits, repeated death hits, movement proposals,
  timer boundaries, respawn, missing/extra upkeep plans, and live adapters.
- Mutations dropping a name character, resetting a hero during damage, or
  dropping a player during upkeep are rejected at `Players.name_round_trip`,
  `Players.finish_hit_ok`, and `Players.upkeep_all_ok`.
- The native player-list build passed shop/combat bots, graphical join/host,
  UTF-8 networking, and save/restart. The combat bot collected loot, reached
  level two, died, and respawned. Artifacts:
  `/private/tmp/bendquest-final-affq23_z`.
- The shop bot now goes through the cleared spawn passage; its former route
  could meet random terrain at (9,7). A new JS/native regression checks
  actual server movement through the cleared passage on a generated map.

Additional tick-composition validation:

- All 27 tick-composition laws check in the strict safe proof closure.
- All twelve new tick regressions pass in JavaScript and native C. They cover
  regeneration before damage, revival before AI, event ordering, inactive and
  unknown phases, empty state, the U32 tick boundary, repeated ticks, and the
  real server's planning/snapshot adapters.
- The live-server regression moves a player into a monster's attack range
  during upkeep and checks the resulting damage in that same tick. It also
  checks that snapshots retain the prior tick while metadata advances.
- Mutations dropping an AI hit, reversing upkeep/death event order, or changing
  phase during a tick are rejected by `Simulation.attacks_round_trip`,
  `Simulation.finish_active_events`, and `Simulation.advance_exact`.

- The rebuilt tick-pipeline game passed shop/combat bots, graphical join/host,
  UTF-8 networking, and save/restart. The bot collected loot, reached level
  two, died, and respawned. Artifacts: `/private/tmp/bendquest-final-bqwraus2`.

Additional inventory-command validation:

- All 37 inventory laws check in the strict safe proof closure alongside the
  original 15 witnesses and prior preservation modules.
- All thirty inventory regressions pass in JavaScript and native C. They
  compare full player records and cover exact purchases, failed purchases,
  equipment transfers, maximum-health changes, allocations, dead commands,
  lookup conservation, repeated commands, healing saturation, and the 2^32
  potion-count boundary. Server cases check actual position/zone shop gates,
  response counts, wire-index clamping, and preservation of maps/metadata.
- Mutations dropping potion healing, resetting XP, and allowing dead players
  to act are rejected at `Inventory.accept_ok`, `Inventory.commit_frame`, and
  `Inventory.step_ok`. Transcripts: `/private/tmp/bqinventorymutations`.

- The strict proof gate and all 157 JavaScript regressions pass. The rebuilt
  native game passed shop/combat bots, graphical join/host, UTF-8 networking,
  and save/restart. The bot collected loot, reached level two, died, and
  respawned. Screenshots were inspected for host, character creation, and
  in-game rendering. Artifacts: `/private/tmp/bendquest-final-9sin2o8_`.

Additional kill-payout validation:

- All 76 payout laws check in the strict safe proof closure, with no unsafe
  annotations, holes, or foreign effects in the module.
- All twenty-one new regressions pass in JavaScript and native C. They compare
  complete players for XP/level changes, one-health and dead players, main
  quest completion, all three side rewards, repeat claims, repeated loot,
  combined quest/loot payouts, sigil updates, missing killers, and sequences.
  Server cases also check maps, monsters, metadata, and output counts.
- Twenty-six differential snapshots match the prior server's complete player
  records, monster records, metadata, and ordered event payloads. Cases cover
  all ten monster kinds with normal/rare variants, non-active/unknown phases,
  matching/nonmatching quest stages, duplicate roster IDs, and missing killers.
  Sources and transcripts: `/private/tmp/bqpayouts` and `/private/tmp/bqpayoutsref`.
- Mutations losing a gold grant, resetting XP, erasing names, and suppressing
  a loot notice are rejected at `Payout.gold_amount_hero`,
  `Payout.finish_xp_ok`, `Payout.profile_frame`, and `Payout.kill_finish_exact`.
  Transcripts: `/private/tmp/bqpayoutmutations`.

- The strict proof gate and all 178 JavaScript regressions pass. The rebuilt
  native game passed shop/combat bots, graphical join/host, UTF-8 networking,
  and save/restart. The combat bot collected loot, leveled up, died, and
  respawned. Host and in-game screenshots were inspected. Artifacts:
  `/private/tmp/bendquest-final-47qaq0ng`.

Additional interaction/navigation validation:

- All 14 navigation and 60 interaction laws check in the strict safe closure.
- All thirty-seven new regressions pass in JavaScript and native C. They check
  complete records, direction masking, halt, initial/repeated/later-stage NPC
  conversations, radius and zone gates, malformed words, all forward/backward
  routes, the Rift lock, and complete roster results. Server cases verify
  actual sigils, maps, monster records, metadata, and reply counts.
- Two hundred ten differential snapshots match the prior server's complete
  player/monster/metadata records and ordered event payloads. They cover valid
  and invalid source zones, exact/adjacent portal tiles, sigil variants, NPC
  selections/stages/ranges, U32 extremes, movement masks, and missing targets.
  Sources/transcripts: `/private/tmp/bqinteractions` and
  `/private/tmp/bqinteractionsref`.
- Mutations introducing zone four, an out-of-bounds portal arrival, repeated
  quest credit, or a missing portal notice are rejected at
  `Navigation.route_valid`, `Navigation.rules_ok`, `Interaction.elder_gate_ok`,
  and `Interaction.finish_enter_exact`. Transcripts:
  `/private/tmp/bqinteractionmutations`.

- The strict proof gate and all 215 JavaScript regressions pass. The rebuilt
  native game passed shop/combat bots, graphical join/host, UTF-8 networking,
  and save/restart. The combat bot talked to the elder, collected loot,
  leveled up, died, and respawned. Host and in-game screenshots were inspected.
  Artifacts: `/private/tmp/bendquest-final-atcdbsrk`.

Additional player-combat admission validation:

- All 41 new laws check in the strict safe closure alongside the original
  15 witnesses and previous modules, without unsafe annotations or holes.
- All 34 new regressions pass in JavaScript and native C. They compare complete
  players, admission actors, and rosters for live/dead/ready/cooling cases,
  maximum cooldowns, inactive/unknown phases, missing/duplicate IDs, repeated
  attacks, and independent attack/spin cooldowns. Server cases compare complete
  worlds for rejection, damage, empty attacks/spins, repeated damage suppression,
  and preservation of other players, metadata, and maps.
- All 226 differential snapshots match the prior server's complete player,
  monster, metadata, map, and ordered-event results, including malformed words,
  target positions, dead monsters, multi-target spins, repeated commands, all
  ten monster kinds, normal/rare kills, rewards, and missing/duplicate players.
  Sources/transcripts: `/private/tmp/bqcombat` and `/private/tmp/bqcombatref`.
- Mutations bypassing the dead gate, using a zero spin cooldown, resetting XP,
  or dropping an admitted actor are rejected by the safe proof closure.
  Transcripts: `/private/tmp/bqcombatmutations`.

- The strict proof gate and all 249 JavaScript regressions pass. The rebuilt
  native game passed shop/combat bots, graphical join/host, UTF-8 networking,
  and save/restart. The combat bot talked to the elder, collected loot,
  leveled up, died, and respawned. Fourteen screenshots were captured and the
  in-game rendering was inspected. Artifacts:
  `/private/tmp/bendquest-final-gk1535w1`.

Additional battle-composition validation:

- All 56 new laws check in the strict safe closure alongside the original 15
  witnesses and prior modules. There are no unsafe annotations or holes in
  `battle.bend` or its proof dependency closure.
- All 23 new complete-state/notice regressions pass in JavaScript and native C.
  They cover nonlethal/zero/missing/dead targets, exact kill rewards, missing
  killers, mismatched plan kinds, sequential damage/deaths, all boss metadata
  effects, intermediate game-over snapshots, sigil advancement, and composed
  ready/rejected/missing/cooling command admission.
- All 291 differential snapshots match the prior server's complete player,
  monster, metadata, map, and ordered-event results. Cases include normal/spin
  commands, missing and duplicate IDs, all monster kinds, rare kills, direct
  repeated strikes, multiple boss orderings, phase variants, and missing killers.
  Sources/transcripts: `/private/tmp/bqbattle` and `/private/tmp/bqbattleref`.
- Mutations paying without a kill, reversing notice order, losing a player
  snapshot, resetting finish time, or suppressing a reward notice are rejected
  by the strict safe proof closure. Transcripts: `/private/tmp/bqbattlemutations`.

- The strict proof gate and all 272 JavaScript regressions pass. All 23 battle
  and 34 server-combat cases pass in native C. Five native boss/reward snapshots
  also match the prior server's complete states and ordered message payloads.
- The rebuilt native game passed shop/combat bots, graphical join/host, UTF-8
  networking, and save/restart. The bot collected loot, leveled up, died, and
  respawned. Fourteen screenshots were captured and in-game rendering inspected.
  The build, regressions, and gameplay were repeated after a concurrent compiler
  update; the compiler hash remained unchanged during that final validation.
  Final artifacts: `/private/tmp/bendquest-final-yphust2s`.

Additional terrain/movement validation:

- All 53 new laws check in the strict safe closure alongside the original 15
  witnesses and prior modules. All 309 JavaScript regressions pass.
- All 37 terrain regressions pass in JavaScript and native C, covering exact
  row-major lookup, malformed words, missing maps/cells, all tile classes,
  map conversion, four directions, boundaries, collisions, halt, village
  restrictions, full world reconstruction, and the actual server adapters.
- Native combat, battle, tick, player, and interaction regressions also pass:
  164 native cases including the new terrain suite.
- All 1,267 differential snapshots match the prior server for valid coordinates:
  complete battle worlds/notices, all four maps for four seeds, 960 player and
  monster movements, and complete ticks across phases and tick-word boundaries.
  Sources/transcripts: `/private/tmp/bqterrain` and `/private/tmp/bqterrainref`.
  The comparison is batched to bound compiler memory use.
- Mutations dropping a map cell, bypassing collision, treating out-of-bounds
  tiles as floor, introducing diagonal movement, and losing world maps are
  rejected by the strict proof closure. Transcripts:
  `/private/tmp/bqterrainmutations`.
- The native compiler's Nat-table optimization could not lower constructor-valued
  direction entries. Direction classification now uses Boolean choices, with a
  universal equality proof against the original decoding rule. No compiler or
  language-kernel edits were made for this integration.
- The rebuilt game passed shop/combat bots, graphical join/host, UTF-8 networking,
  and restart. The combat bot leveled up, died, and respawned. Fourteen screenshots
  were captured; in-game and host rendering were inspected. Artifacts:
  `/private/tmp/bendquest-final-jy73av2k`.
- An additional native persistence check seeded a UTF-8 profile and completed
  run, bought a cosmetic, and verified the exact balance, ownership mask, name,
  world number, and complete hall-of-fame payload after saving and restarting.
  This covers actual saved contents beyond the basic harness's file-exists check.
  Script: `/private/tmp/bqterrain/save_roundtrip.py`; artifacts:
  `/private/tmp/bendquest-save-1x86haom`. This finite check does not discharge the
  universal codec and filesystem obligations in item 5.
- Game and compiler sources remained unchanged throughout final validation;
  hashes are recorded in `/private/tmp/bqterrain/validated_hashes.json`.

Additional whole-player locomotion validation:

- All 37 laws check in the strict safe closure. All 333 JavaScript regressions
  pass, including 24 new full-record and event-order checks for planning,
  collision, halt, death, revival, phase gating, tick wrap, and tick sequences.
- The new suite and existing player, simulation, terrain, and battle suites pass
  in native C: 117 cases in total.
- All 260 differential upkeep/tick snapshots match the prior server's complete
  records, maps, metadata, and ordered messages. Cases include generated seeds,
  all phases, timer/word boundaries, empty/duplicate-ID rosters, directions,
  and death/respawn. Sources/transcripts: `/private/tmp/bqlocomotion` and
  `/private/tmp/bqlocomotionref`.
- Six mutations are rejected: bypassing collision, shifting respawn y, skipping
  accepted movement, moving on death, dropping plans, and ignoring phase gating.
  Transcripts: `/private/tmp/bqlocomotionmutations`.
- The rebuilt game passed shop/combat bots, graphical host/join, UTF-8 networking,
  and save/restart. The bot collected loot, leveled up, died, and respawned.
  In-game and host screenshots were inspected. Artifacts:
  `/private/tmp/bendquest-final-394tt0ft`.
- Exact purchased-cosmetic ownership, coin balance, UTF-8 name, world number, and
  complete hall-of-fame payload survived native save/restart. Artifacts:
  `/private/tmp/bendquest-save-pmj0hwj2`.
- Source/build hashes: `/private/tmp/bqlocomotion/validated_hashes.json`. The
  compiler was subsequently edited; the next integration must validate against
  its new revision.

Completed generated-terrain dependency: `landscape.bend` contains the actual
seeded map generator used by `world.bend`. Its 45 safe laws prove fixed zone
map length, walkable bounded spawn and all portal arrivals for every seed,
creation and tick positional preservation with the generated spawn premise
discharged, and preservation through the actual MOVE/HALT/TALK/ENTER handlers,
lookup/reinsertion, and arbitrary interaction sequences. The generator keeps
the original random tile rules, clearing order, and parallel four-zone build.

Monster positional preservation with valid supplied plans is now proved by
`habitat.bend`, described below. The next dependency is to discharge those
conditions for actual server planning and initial monster placement, then
complete all-command composition and ID/reference obligations. No numbered item is complete yet; the full
WorldOK and items 2–6 retain their scope above.


Additional generated-landscape validation:

- All 45 new laws check in the strict safe closure, alongside the original 15
  witnesses and every prior module. All 355 JavaScript regressions pass.
- All 22 new regressions and existing terrain, locomotion, interaction, and
  battle suites pass in native C: 143 cases. These exercise complete corridor
  walks, village NPC access, portal transitions, word hashes, and generation
  boundaries, in addition to the earlier complete-state checks.
- All 158 map/hash/initial-world snapshots and all 260 complete upkeep/tick
  snapshots match the previous server. Map comparisons retain every tile,
  including seeds at word boundaries, all valid zones, invalid-zone behavior,
  clipped trees, and wrapped tree indices. Sources/transcripts:
  `/private/tmp/bqlandscape` and `/private/tmp/bqlandscaperef`.
- Six mutations are rejected by the strict proof closure: dropping a map cell,
  solid spawn, solid forward/backward arrivals, shifting the arrival coordinate,
  and teleporting on a movement-control command. Transcripts:
  `/private/tmp/bqlandscapemutations`.

- The rebuilt generator passed native combat/shop bots, graphical host/join,
  UTF-8 networking, and save/restart. In-game and host screenshots were
  inspected. The combat bot collected loot, leveled up, died, and respawned.
  Final artifacts: `/private/tmp/bendquest-final-h7s0t1k9`.
- Exact cosmetic ownership, coin balance, UTF-8 name, world number, and the
  complete hall-of-fame payload survived native save/restart. Artifacts:
  `/private/tmp/bendquest-save-p4ondwd2`.
- Native regressions, build, gameplay, and persistence were repeated after a
  concurrent compiler update. Game and compiler sources stayed unchanged
  through final validation. Hashes: `/private/tmp/bqlandscape/validated_hashes.json`.

Completed conditional monster-position dependency: `habitat.bend` adds 35
safe laws over the actual monster, roster, and AI implementations. Exact
position equalities cover spawning, damage, waiting, regeneration, lifecycle
updates, and attacks. Bounds/walkability are preserved by lookup/reinsertion,
strikes, filtering/concatenation, AI list execution, and four-zone composition.
`Habitat.PlanOn` requires movement and respawn destinations to be bounded and
walkable in the original zone; `Habitat.Plans` aligns these witnesses with the
actual monster and plan lists, including missing and extra plans.

The server's actual planner and initialization must still discharge these
premises. This is a conditional preservation theorem, not a complete proof
of monster placement or the full WorldOK invariant. No numbered item is
complete, and items 2–6 retain their full requested scope.

Additional monster-position validation:

- All 35 laws check in the mandatory strict proof closure with the original
  15 witnesses, landscape, and all preceding modules. No runtime implementation
  changed in this batch.
- Five mutations are rejected: damage moving a monster, attacks moving their
  actor, movement missing its planned destination, respawn missing its planned
  destination, and regeneration moving a monster. Transcripts:
  `/private/tmp/bqhabitatmutations`.
- The final installed strict proof gate and all 355 JavaScript regressions
  pass with both new modules included. Runtime sources and the compiler match
  the native gameplay/persistence validation recorded above; this batch only
  adds proofs and their mandatory import. Final hashes:
  `/private/tmp/bqhabitat/validated_hashes.json`.


Completed active monster-planning dependency: `pursuit.bend` is the actual
implementation called by the server for cardinal chase and active AI plans.
Its 30 safe laws discharge active plans' `Habitat.PlanOn` premise from an
initially valid monster position, for arbitrary target coordinates and damage
words. Walking, fallback, and chasing retain zone and walkability; cardinal
chase changes at most one axis by at most one tile. Active AI execution
preserves monster positions, including planning after lifecycle upkeep.

The planner retains the old axis priority, blocked-axis fallback, target
retention/clearing, wander/chase schedules, and adjacent attack decisions.
Target acquisition still supplies the selected target record. Reference
validity, exact damage accounting, and the remaining combat obligations have
not been inferred from this positional theorem. Respawn planning and initial
monster placement still need proofs; full WorldOK and all numbered scopes
remain open.

Additional active-planning validation:

- All 30 laws check in the strict closure with all prior modules and the
  original 15 witnesses. All 374 JavaScript regressions pass.
- All 19 new regressions and the existing AI, terrain, locomotion, and battle
  suites pass in native C: 116 cases.
- All 504 chase/AI-plan comparisons and all 260 complete upkeep/tick snapshots
  match the prior server. These cover blocked/open/generated maps, target
  acquisition variants, lifecycle phases, and word/tick boundaries. Sources:
  `/private/tmp/bqpursuit` and `/private/tmp/bqpursuitref`.
- Four mutations are rejected: bypassing collision, taking the fallback from
  the first move instead of the original position, swapping planned x/y, and
  shifting planned x. Transcripts: `/private/tmp/bqpursuitmutations`.
- The installed strict proof gate and all 374 JavaScript regressions pass.
  The rebuilt native game passed combat/shop bots, graphical host/join, UTF-8
  networking, and restart. The bot leveled up, died, respawned, and collected
  loot; game and host screenshots were inspected. Artifacts:
  `/private/tmp/bendquest-final-3nj841hn`.
- Exact cosmetic ownership, balance, UTF-8 profile, world number, and the full
  hall-of-fame payload survived native save/restart. Artifacts:
  `/private/tmp/bendquest-save-zqccxve6`.
- Game and compiler sources remained unchanged through final validation.
  Hashes: `/private/tmp/bqpursuit/validated_hashes.json`.


Completed generated-population and full positional-tick dependencies:

- `remainders.bend` adds 14 safe laws proving bounds for Base's actual U32
  remainder by 13 and 26. Structural induction follows the word division
  implementation; the finite remainder-step cases have explicit bounds.
- `placement.bend` adds 20 laws for the unchanged spawn rule. The candidate
  coordinates are bounded, and every seed's actual generated maps supply the
  walkable fallback corridor. Spawn retains the requested valid zone.
- `population.bend` adds 27 laws over the catalog, spawn, initial roster,
  fresh world, and respawn functions now called by the server. Initial and
  respawned monsters satisfy health, zone, bounds, and walkability invariants.
  The safe population wrapper has an exact refinement law; it prevents large
  symbolic roster expansion during checking without changing its result.
- `planning.bend` adds 21 laws connecting dormant/active/respawn plans to the
  actual AI executor and full phase-gated tick completion. `initial_positions`,
  `tick_positions`, and `trace_positions` establish both player and monster
  positional validity on generated maps. The old health/equipment/monster-zone
  invariant is also preserved by arbitrary tick sequences.

These results discharge the earlier initial-placement and respawn-planning
premises. They hold for arbitrary supplied target contexts, so they do not
assume correctness of target acquisition or damage. They do not prove those
inputs correct either. `Planning.Positions` plus `Simulation.OK` is still only
part of WorldOK. Unique initial IDs, allocator wraparound, reference validity,
all-command/mixed-sequence closure, and all other numbered obligations retain
their full scope. No numbered item is complete.

Additional population/planning validation:

- All 82 laws check in the strict safe closure alongside every prior module
  and the original 15 witnesses. All 410 JavaScript regressions pass, including
  36 new cases for modulo boundaries, initial worlds, spawn positions,
  lifecycle respawn, permanent boss death, and missing/extra contexts.
- New placement and existing pursuit, AI, monster, locomotion, and battle
  suites pass in native C: 135 cases.
- All 276 spawn/population/boss/initial-world snapshots, 504 chase/AI-plan
  snapshots, and 260 complete upkeep/tick snapshots match the previous game.
  Each comparison uses a distinct temporary input filename. Earlier runs
  whose temporary inputs overlapped are retained as unverified artifacts and
  are excluded from this evidence. Sources and final transcripts:
  `/private/tmp/bqplacement` and `/private/tmp/bqplacementref`.
- Five mutations are rejected by the strict proof closure: wrong remainder
  subtraction, fallback outside the cleared corridor, boss outside the map,
  swapped respawn coordinates, and ignored tick phase gating. Transcripts:
  `/private/tmp/bqplacementmutations`.
- The installed strict proof gate and all 410 JavaScript regressions pass.
  The rebuilt native game passed combat/shop bots, graphical join/host,
  UTF-8 networking, and save/restart. The bot collected loot, leveled up,
  died, and respawned. In-game and host screenshots were inspected.
  Artifacts: `/private/tmp/bendquest-final-zm4aajg3`.
- Exact purchased-cosmetic ownership, coin balance, UTF-8 profile, world
  number, and complete hall-of-fame payload survived native save/restart.
  Artifacts: `/private/tmp/bendquest-save-54ridmzy`.
- Game and compiler sources remained unchanged through final installed
  validation. Hashes: `/private/tmp/bqplacement/validated_hashes.json`.


Completed monster-ID uniqueness dependency:

- `identity.bend` adds 39 safe laws. Its recursive `Unique` predicate requires
  every monster ID to differ from all subsequent IDs, independently of zone.
  A universal contradiction law rejects equal IDs, even in different zones.
- The actual spawn and population functions have exact ID/zone projection
  proofs. `initial_exact` connects the real initial roster to its complete
  fixed sequence: bosses 1–4, then 109–101, 209–201, and 309–301. Distinctness
  and absence of sentinel ID zero are checked witnesses, transported to the
  actual records for every map and therefore every seed.
- Uniqueness and absence are preserved by full-record permutations followed
  by the existing ID/zone conservation relation. Strikes, spins, four-zone AI,
  complete phase-gated ticks, actual lifecycle-aware planning, and arbitrary
  combat/tick sequences retain unique monster IDs. Fresh-world trace laws
  discharge the initialization premises with `Population.fresh_ok` and the
  new uniqueness witness.

These results establish monster-ID uniqueness for initialization and the
checked combat/tick transitions. They do not establish player or connection
ID uniqueness, allocator behavior on wraparound, target-reference validity,
or closure of every authoritative command. The checked mixed trace covers
combat and ticks, not the complete dispatcher. No numbered item is complete;
all remaining obligations in items 1–6 retain their original scope.

Additional identity validation:

- All 39 laws check in the strict closure with the original 15 witnesses and
  every previous module. No runtime implementation changed in this batch.
- The strict closure rejects duplicated boss IDs, overlapping zone ID ranges,
  a duplicate-ID witness whose two entries have different zones, and an AI
  respawn that changes its ID. Transcripts:
  `/private/tmp/bqidentitymutations`.
- The final installed strict gate and all 410 JavaScript regressions pass.
  Runtime sources, compiler, and native binary are unchanged from the validated
  combat/shop bots, graphical gameplay, UTF-8 networking, and save/restart
  recorded for the population/planning integration. This batch adds proofs
  and their mandatory import; it changes no runtime implementation.
- Final source/build hashes: `/private/tmp/bqidentity/validated_hashes.json`.


Completed collision-safe allocation and player-admission dependencies:

- The previous player and connection counters incremented U32 values without
  checking active IDs. `allocation.bend` replaces this with a bounded search
  through nonzero candidates, checking the current ID roster and wrapping
  maximum to one. Its 12 safe laws prove successful results are nonzero and
  absent from the supplied roster, including after wraparound; the next cursor
  is nonzero. Failure is explicit, and a free normalized hint succeeds at once.
- `admission.bend` owns the actual player-creation transition called by
  `world.bend`. Its 17 laws preserve unique player IDs and unique connection
  bindings, health/equipment/monster-zone validity, and player bounds and
  walkability on generated maps. The outcome theorem states exact rejection
  or the exact addition of one fresh player on an unused nonzero connection.
- The server's connection acceptance calls the same allocator over its active
  connection IDs. CREATE retains its profile/cosmetic checks, then handles
  allocation failure before setting connection state or emitting join notices.
  The no-space path closes the newly accepted socket or rejects CREATE.

The allocation theorem concerns active IDs, not historical identities or
queued messages. Connection-list extraction and socket effects remain legacy
adapters. Full connection-roster/state-machine preservation, player removal,
all-command/mixed-sequence uniqueness closure, target/reference validity, and
ownership/authentication remain open. Search completeness for every roster
smaller than the usable ID space has not been inferred from the safety proof
or finite tests; it remains an explicit obligation. No numbered item is complete,
and all other original obligations retain their scope.

Additional allocation/admission validation:

- All 29 laws check in the strict safe closure alongside the original 15
  witnesses and every preceding module. All 434 JavaScript regressions pass,
  including 24 new cases covering zero/MAX hints, occupied and duplicate IDs,
  wraparound, exact complete-world preservation, repeated/zero connection
  rejection, sequential creation, and explicit search failure.
- Allocation, player, simulation, combat, and battle suites pass in native C:
  114 cases. The full game emits C successfully with the new server handlers.
- Four mutations are rejected: allocating zero, returning an unchecked ID,
  bypassing duplicate-connection rejection, and claiming success after
  allocation failure. Transcripts: `/private/tmp/bqallocationmutations`.
- The installed strict proof gate and all 434 regressions pass. The rebuilt
  native game passed combat/shop bots, graphical host/join, UTF-8 networking,
  and save/restart. The bot collected loot, leveled up, died, and respawned;
  in-game and host screenshots were inspected. Artifacts:
  `/private/tmp/bendquest-final-kmtdkvmk`.
- Native network checks pass for CREATE before HELLO, repeated CREATE,
  HELLO/CREATE repetition on an existing player connection, distinct active
  player IDs, disconnect removal, reconnect, unowned-cosmetic rejection, and
  successful creation after that rejection. Artifacts:
  `/private/tmp/bendquest-allocation-network-79yi_fqk`;
  script: `/private/tmp/bqallocation/protocol_check.py`.
- Exact cosmetic ownership, balance, UTF-8 profile, world number, and complete
  hall-of-fame payload survived native save/restart. Artifacts:
  `/private/tmp/bendquest-save-2xazvx29`.
- Game and compiler sources remained unchanged through final validation.
  Source/build ledger: `/private/tmp/bqallocation/validated_hashes.json`.


Completed player-ID preservation and mixed-sequence dependencies:

- `playerids.bend` adds 67 safe laws. A shared projection chooses player IDs
  or connection IDs and is proved equivalent to the lists used by admission.
  Standard full-record permutations preserve uniqueness and ID absence.
  Lookup preserves both kinds of uniqueness; the removed record's IDs occur
  nowhere in the remaining roster. Removal and same-ID replacement preserve
  uniqueness. The existing full-record permutation witness retains the exact
  other records, not just their count.
- Checked projections connect inventory, interaction, combat-admission, and
  payout frames to actual player/connection fields. Both kinds of uniqueness
  are preserved by those complete roster operations. Damage, death, upkeep,
  and revival retain player and connection IDs, including ordered hit lists
  and missing/extra upkeep plans.
- Full phase-gated ticks, actual lifecycle-aware planning, complete attack/spin
  payout composition, and arbitrary combat/tick sequences preserve both ID
  invariants. `PlayerIds.trace_unique` combines creation, removal, inventory,
  interaction, complete combat, and actual planned ticks; `fresh_trace_unique`
  discharges initialization with the fresh world's empty player roster.

The mixed sequence calls the same pure operations used by the game. It does
not replace the effectful server dispatcher or prove its connection-state
machine. Connection-roster uniqueness, ownership/authentication, target
reference cleanup after disconnect, reachable nonzero-ID closure, and the
remaining complete WorldOK obligations still require proofs. In particular,
uniqueness is not a substitute for valid references. No numbered item is
complete; all other requested obligations retain their scope.

Additional player-ID validation:

- All 67 laws check in the strict safe closure with the original 15 witnesses
  and every preceding module. This batch changes no runtime implementation.
- Five mutations are rejected: hiding connection IDs in inventory frames,
  hiding player IDs in combat frames, hiding connection IDs in payout frames,
  changing player ID on damage, and rebinding connection ID on respawn.
  Transcripts: `/private/tmp/bqplayeridsmutations`.
- The final installed strict gate and all 434 JavaScript regressions pass.
  Runtime sources, compiler, and native binary are unchanged from the validated
  combat/shop bots, graphical gameplay, UTF-8 networking, and save/restart
  recorded for the allocation/admission integration. This batch adds proofs
  and their mandatory import; it changes no runtime implementation.
- Final source/build hashes: `/private/tmp/bqplayerids/validated_hashes.json`.
- A concrete deletion probe confirms that the current unchanged server
  removal adapter can leave a monster targeting a deleted player. Clearing
  those targets and proving reference validity remain required; the ID
  uniqueness theorem does not imply this property. Probe and transcript:
  `/private/tmp/bqplayerids/reference_probe.bend` and `reference-probe.txt`.


Completed player-removal target-reference dependency:

- The dangling-target probe above exposed a runtime defect. `world.Bq.del_plr`
  now calls `References.remove`, which removes the first matching player and
  reconciles monster targets against the actual remaining player roster.
  Targets naming a remaining player and zero sentinels stay unchanged; all
  other targets become zero. Preexisting missing targets are repaired too.
- `references.bend` has 52 safe laws. Removal establishes existence-or-zero
  references without an input validity premise. Per-record and ordered roster
  frame equalities retain every other monster field, count, and order. The
  actual remaining player records, full metadata, and maps are retained.
  Reconciliation is idempotent. Removing an absent player from a world with
  valid references leaves the complete simulation state unchanged.
- Removal preserves player/monster health and equipment, monster zones,
  generated-map bounds and walkability, and monster-ID uniqueness. A new law
  in `playerids.bend` preserves player and connection IDs through this handler;
  that module now has 68 laws and its mixed trace calls the same removal.
- Spawn, bosses, complete population, and fresh worlds have valid references
  for every seed. Repeated removal sequences preserve reference validity,
  partial simulation validity, and positions.

This closes the reproduced deletion bug and these removal/initialization
obligations. It does not yet prove reference preservation by all commands and
ticks, same-zone/alive-target constraints, the effectful connection dispatcher,
full WorldOK, or ownership/authentication. Zero remains the no-target sentinel,
not a claim that player zero exists. All six numbered scopes remain open with
their original obligations.

Additional target-reference validation:

- All 52 laws and the updated 68 player-ID laws check in the strict closure,
  including the original 15 witnesses and every preceding module. All 458
  JavaScript regressions pass, including 24 new removal/reference cases.
- Six deliberate mutations are rejected: retaining a missing target, clearing
  a valid target, changing another monster field, dropping a monster, checking
  against the pre-removal roster, and spawning with a missing target.
  Transcripts: `/private/tmp/bqreferencesmutations`.
- The installed strict gate and all 458 regressions pass. Native removal,
  allocation, player, simulation, combat, and battle suites pass: 138 cases.
  The rebuilt game passed combat/shop bots, graphical host/join, and UTF-8
  networking. In-game join and host screenshots were inspected. Artifacts:
  `/private/tmp/bendquest-final-j8gfvrwg`.
- Native CREATE/HELLO repetition, disconnect, reconnect, distinct active IDs,
  and rejected-cosmetic checks passed. Artifacts:
  `/private/tmp/bendquest-allocation-network-s4ejhmh8`.
- Exact profile, cosmetic ownership, balance, world number, and complete
  hall-of-fame payload survived native save/restart. Artifacts:
  `/private/tmp/bendquest-save-aagbiyvb`.
- Source and compiler hashes stayed fixed through validation. Source/build
  ledger: `/private/tmp/bqreferences/validated_hashes.json`.


Completed command-reference preservation dependencies:

- `membership.bend` adds 50 safe laws. `Membership.projection` connects exact
  `Players.has_id` lookup to the actual player-ID projection. Full-record
  permutations and equal ID projections preserve the lookup result for every
  ID, including absence. The composable membership witness allows permutation,
  changed records with the same IDs, and prepending a player; it proves actual
  existing membership is retained, including ID zero. Addition does not claim
  to preserve absence.
- Inventory, interactions, combat admission, and payouts supply these witnesses
  using their checked frames and permutations. Single and ordered player hits,
  upkeep, phase-gated preparation, and admission preserve existing membership.
  Reference transfer reuses these witnesses for every monster in the roster.
- Monster damage retains an existing target or clears it on a kill. Roster
  lookup/permutation, complete strikes, conditional payouts, ordered battle
  execution, and complete attack/spin commands preserve reference validity.
- Creation establishes reference preservation through both exact rejection and
  successful addition. `Membership.change_world` and `trace_world` cover the
  command-only fragment of the existing `PlayerIds.run_change`/`trace`:
  creation, removal, inventory, interactions, and complete combat. The explicit
  `Membership.Commands` witness excludes tick entries. `fresh_trace_world`
  discharges initial reference validity for every seed.

These are proofs about existence-or-zero references and actual roster
membership, not a completed WorldOK theorem or ownership/authentication proof.
The actual server's target selector, AI execution, and complete planned ticks
still need reference proofs. The internal `Planning.Input` accepts arbitrary
contexts; a concrete counterexample supplies target 999 to a world containing
only player 1 and creates a missing target. This is evidence against proving
unconditional reference closure over that internal input type, not evidence
that the network dispatcher accepts such contexts. The next obligation is to
prove the selector that constructs these contexts from the authoritative
player roster. Probe and transcript: `/private/tmp/bqmembership/arbitrary_tick_probe.bend`
and `/private/tmp/bqmembership/arbitrary-tick-probe.txt`.
All six numbered scopes retain their full original obligations and remain open.

Additional command-reference validation:

- The strict closure checks all 50 new laws, the original 15 witnesses, and
  every preceding module without unsafe definitions, axioms, or holes.
- Six mutations are rejected: assigning a missing target after nonlethal or
  lethal monster damage, inventing membership in an empty roster, admitting
  arbitrary tick contexts as checked commands, and weakening either ID
  equality or the added-roster shape to a vacuous equality. Transcripts:
  `/private/tmp/bqmembershipmutations`.
- The final installed strict gate and all 458 JavaScript regressions pass.
  Runtime sources, compiler, and native binary match the native validation
  recorded for the preceding reference-removal integration: 138 native cases,
  combat/shop bots, graphical host/join, disconnect/reconnect, UTF-8 networking,
  and exact save/restart. This batch adds proofs and their mandatory import;
  it changes no runtime behavior.
- Final source/build hashes: `/private/tmp/bqmembership/validated_hashes.json`.


Completed authoritative target-selection dependency:

- `targeting.bend` has 43 safe laws and owns the implementation now used by the
  server: candidate filtering, first-ID lookup, nearest search, acquisition,
  retention, and complete context-list construction. Full-record membership
  witnesses tie candidate ID and coordinates to an actual player in the
  supplied roster. Separate field laws pin those coordinates to the actual
  player position and eligibility to the requested zone, live flag, and
  outside-village predicate.
- Every selected target is either the exact absent value or has that source
  witness. Successful lookup returns the requested ID. Selected targets
  satisfy the existing existence-or-zero reference predicate. These source
  and reference results need no uniqueness assumption on the input roster.
- Exact laws cover first-match lookup, empty acquisition, zero-target
  acquisition, retaining a found nonzero target through distance 9, and
  reacquiring when a target is absent or beyond that radius. Search step laws
  pin the strict comparison and candidate/best updates; acquisition refinement
  fixes the initial ID 0 and distance 4. Runtime behavior keeps the earlier
  candidate on a tie and requires acquisition distance below 4.
- The live tick handler directly filters post-upkeep player records into Data
  candidates and calls the checked context-list builder for each monster zone.
  Damage amounts are separate inputs to that builder and cannot change target
  provenance. The old affine tuple interfaces delegate through conversion
  adapters; the live context path avoids those conversions.

This establishes the source of the server's contexts; it does not yet prove
reference preservation through complete AI execution and world ticks. Global
nearest minimality and positive acquisition/liveness guarantees still need
proofs under the reachable roster conditions, including nonzero unique IDs.
For arbitrary duplicate IDs, legacy acquisition chooses an ID and then reads
its first matching coordinates; those may differ from the nearer duplicate's
coordinates. A zero-ID nearest candidate retains the legacy sentinel result.
These cases are preserved and tested, not used to claim unconditional range
or liveness guarantees for malformed rosters. Full WorldOK, dispatcher and
session ownership, and all other original obligations remain open. No numbered
scope is complete.

Additional target-selection validation:

- All 43 new laws check in the strict closure with the original 15 witnesses
  and every preceding module. The 30 new regressions cover candidate eligibility,
  village edges, exact coordinates, distance 3/4 and 9/10 boundaries, tie order,
  reacquisition, duplicate/sentinel/MAX IDs, unsigned coordinate edges, legacy
  adapters, and the live context builder.
- All 488 JavaScript regressions pass. Native targeting, reference-removal,
  simulation, pursuit, combat, and battle suites pass: 142 cases. All 504
  old/new AI-plan comparisons and 260 world/upkeep comparisons match. Scripts
  and transcripts: `/private/tmp/bqtargeting`.
- Nine mutations are rejected: fabricated coordinates, wrong-zone/dead/village
  candidates, invented lookup results, expanded retention/acquisition radii,
  changing tie behavior, and fabricated context targets. Transcripts:
  `/private/tmp/bqtargetingmutations`.
- The installed strict proof gate and all 488 regressions pass. The rebuilt
  native game passed combat/shop bots, graphical host/join, and UTF-8
  networking. Join-game and host screenshots were inspected. Artifacts:
  `/private/tmp/bendquest-final-vk7brpkm`.
- Native CREATE/HELLO repetition, distinct active IDs, disconnect/reconnect,
  and rejected-cosmetic checks passed. Artifacts:
  `/private/tmp/bendquest-allocation-network-pjrdsji3`.
- Exact profile, cosmetic ownership, balance, world number, and complete
  hall-of-fame payload survived native save/restart. Artifacts:
  `/private/tmp/bendquest-save-w99lif1x`.
- Final sources and compiler match the validation snapshot and rebuilt game.
  The compiler update to `11522966fba5420200f1eedbeba1f666a4573546c15cb716579f4a2cd9a880aa`
  predates this snapshot, staged/native regression runs, and native build.
  The interrupted installed regression run was restarted and passed in full.
  Source/build ledger: `/private/tmp/bqtargeting/validated_hashes.json`.


Completed AI execution and full-tick target-reference closure:

- `ai_refs.bend` adds 46 safe laws. Monster wait, vital upkeep, and every tick
  lifecycle branch retain the previous target exactly. AI rest retains a valid
  target; move/attack plans supply valid references; respawn resets the target
  to zero. Complete AI execution, missing/extra plan handling, zone filtering,
  and merged results preserve references relative to the supplied player roster.
- Checked pursuit and lifecycle planners satisfy the plan-reference contract
  from the target selector's source witnesses. The context-list proof includes
  the missing-context fallback. No claim is made that arbitrary externally
  supplied internal planning contexts are valid.
- Upkeep preserves player membership before selection. The pure authoritative
  `AIRefs.finish` builds its own contexts from those post-upkeep player records,
  executes AI, then applies player damage. Membership transport proves that
  resulting monster references still name the final roster, including targets
  killed by the ordered hits. The server's live finish adapter calls this exact
  implementation and supplies only separate catalog damage lists.
- `tick_valid_world` proves complete tick target-reference preservation.
  `AIRefs.trace_valid` composes creation, removal, inventory, interactions,
  complete combat, and the actual selected tick; `fresh_trace_valid` discharges
  reference initialization for every seed. The command witness classifies the
  command-only variant of `PlayerIds.Change`; it is not authentication or
  action authorization. Tick inputs contain damage amounts, not unchecked IDs
  or coordinates, and targets are recomputed against each current roster.

This closes existence-or-zero monster-target preservation across these actual
pure world transitions and their compositions. It does not turn remembered
references into an assertion that all referenced players remain alive or in the
same zone after later hits or portal commands; admission-time eligibility is a
separate combat obligation. Full WorldOK still needs its other components and
server-dispatch/connection integration. All six numbered scopes retain their
original requirements and remain open.

Additional full-tick reference validation:

- The strict closure checks all 46 new laws together with the original 15
  witnesses and every preceding module. The 27 new regressions cover movement
  before selection, village/zone transitions, player death and revival, monster
  wait/respawn/permanent death, empty rosters, MAX IDs, tick wrap, inactive
  phases, lethal and simultaneous hits, damage-list lengths, zone processing,
  the live server adapter, fresh tick traces, and mixed create/tick/remove traces.
- All 515 JavaScript regressions pass. Native full-tick references, targeting,
  removal, simulation, pursuit, combat, and battle suites pass: 169 cases.
  All 260 old/new world/upkeep comparisons match, including complete state
  and event output. Scripts and transcripts: `/private/tmp/bqairefs`.
- Six mutations are rejected: retargeting during vital upkeep, invented attack,
  rest, or movement targets, discarding referenced players in the finish step,
  and weakening the attack-plan witness. Transcripts:
  `/private/tmp/bqairefsmutations`.
- The installed strict gate and all 515 regressions pass. The rebuilt native
  game passed combat/shop bots, graphical host/join, and UTF-8 networking.
  Join-game and host screenshots were inspected. Artifacts:
  `/private/tmp/bendquest-final-9xf1hnwq`.
- Native CREATE/HELLO repetition, distinct active IDs, disconnect/reconnect,
  and rejected-cosmetic checks passed. Artifacts:
  `/private/tmp/bendquest-allocation-network-t9ilfskp`.
- Exact profile, cosmetic ownership, balance, world number, and complete
  hall-of-fame payload survived native save/restart. Artifacts:
  `/private/tmp/bendquest-save-mgpjs5g3`.
- Final source/compiler/build ledger: `/private/tmp/bqairefs/validated_hashes.json`.


Completed nonzero player and player-to-connection ID preservation:

- `nonzero.bend` adds 48 safe laws. `Nonzero.All` requires zero to be absent
  from both ID projections. It is stronger than uniqueness in the relevant
  respect: uniqueness alone permits one zero entry. No health, location,
  membership, or authentication premise is substituted for this requirement.
- Creation uses the actual `Admission.add_outcome`: rejection leaves the
  state unchanged; successful creation supplies the allocator's nonzero PID
  witness and the admission gate's nonzero CID witness. Existing entries are
  retained, including through cursor wraparound. Search completeness remains
  distinct from successful-allocation safety.
- Removal uses the actual take/permutation result. Inventory, interactions,
  combat admission, and payouts use their existing exact frame-preservation
  proofs. Ordered hits, upkeep, all battle branches, planning finish, and the
  live selected-tick wrapper preserve both nonzero projections.
- `Nonzero.trace` covers mixed `AIRefs.Transition` sequences; `fresh_trace`
  discharges initialization for every seed. `member` extracts nonzero fields
  from actual membership witnesses. `fresh_trace_zero_missing` proves zero
  cannot resolve to an actual player after any such sequence. This is the
  precise absence property behind the monster-target sentinel convention.
- The proof module is mandatory in `proofs.bend` and `check-proofs.sh`.
  Runtime sources are unchanged. Active connection-roster uniqueness and
  bindings, queued-session identity, authentication, complete WorldOK, and
  effectful dispatcher integration remain open. None of the six numbered
  scopes is marked complete.

Nonzero-ID validation:

- The full strict closure checks the 48 new laws, original 15 witnesses, and
  every preceding module. All 515 JavaScript regressions pass in the staged
  tree; installed sources match it exactly, and the installed strict gate passes. Transcripts: `/private/tmp/bqnonzero`.
- Direct witness probes accept IDs 1 and MAX_U32, reject zero player IDs,
  and independently reject zero connection IDs. Rejections occur at the
  attempted proof witness, with the expected Bool equality mismatch.
- Every runtime source, compiler/kernel, emitted C file, and native binary
  matches the preceding `/private/tmp/bqairefs/validated_hashes.json` ledger.
  A fresh C emission from the installed main matches the prior C byte for
  byte. Consequently its 169 native cases, 260 world comparisons, bots, graphical
  host/join, protocol, and exact save/reload validation still apply. This
  proof-only batch does not claim a new native build or gameplay run.
- Source/build ledger: `/private/tmp/bqnonzero/validated_hashes.json`.


Completed combined pure-world invariant and mixed transition closure:

- `worldstate.bend` adds 37 safe laws. `WorldState.OK<seed,state>` is a
  conjunction of `Simulation.OK`, `Planning.Positions`, monster ID uniqueness,
  player/connection ID uniqueness, nonzero player/connection IDs, and monster
  target-reference validity. These are explicit fields, not a Bool named OK
  or a premise that merely restates the desired output property.
- `tick_refines` relates the live `AIRefs.tick` to `Planning.tick` using
  contexts generated from the actual post-upkeep roster. It covers both phase
  branches and transports the existing tick health, position, and ID proofs.
  Target-reference preservation comes from the authoritative selection proof.
- Exact inventory, combat, and payout frames now transport player walkability
  across roster permutations. Complete ordered battle execution combines that
  with monster strike-position preservation, including kills and rewards.
  `Landscape.run_on` supplies the already checked portal/control/NPC paths.
- Successful admission combines allocator freshness, CID admission, spawn
  walkability, and reference preservation. Rejected admission preserves the
  entire invariant. Removal combines actual roster extraction with monster
  reference reconciliation and preserves every remaining component.
- `WorldState.trace` proves the conjunction after mixed `AIRefs.Transition`
  sequences. `fresh_trace` supplies the initial invariant for every seed.
  `Schedule` requires canonical spawn coordinates for each selected tick,
  witnessed as `rules == Planning.rules(timer)` for an arbitrary U32 timer.
  The actual `Bq.simulation_rules` supplies exactly this constructor.
  Damage lists are arbitrary; no target/coordinate contexts are caller inputs.
- These theorems concern the actual pure transition functions called by the
  server adapters. They are not authentication/command-gating proofs, and
  they do not yet connect the active effectful connection roster to the world
  player roster. Seed/map identity across effectful world replacement and
  complete dispatcher coverage also remain in the final integration audit.
  This establishes the combined pure-world component; it does not mark scope
  1 complete or weaken any of the six original numbered scopes.
- The new module is mandatory in the strict proof gate. Runtime implementations
  are unchanged in this batch.

Combined-world validation:

- The full strict closure checks all 37 laws, the original 15 witnesses, and
  all previous modules. All 515 JavaScript regressions pass. Installed sources
  match the staged tree, and the installed strict gate passes. Transcripts:
  `/private/tmp/bqworldstate`.
- Direct schedule witnesses accept timers 0 and MAX_U32, while rejecting
  invalid respawn coordinates. A mixed create/tick/remove/tick witness proves
  the combined invariant for every seed, with MAX connection ID, damage,
  and timer values in its inputs.
- A fresh C emission from installed main is byte-identical to the existing
  emitted C. Runtime sources, compiler/kernel, and native binary also match
  the previous validated ledger. The preceding 169 native cases, 260 world
  comparisons, bots, graphical host/join, protocol and exact save/reload
  validation remain applicable; no new gameplay run is claimed in this
  proof-only batch.
- A separate native probe confirms an existing connection lifecycle defect:
  repeated HELLO accepts a new name and changes the connection to creation
  state while preserving its PID and existing world player. SAY then stops
  working although PING is processed, and CREATE is rejected. An independent
  client still sees the retained player. This is a remaining server-level
  obligation, not a failure of the pure-world theorem. Reproduction:
  `/private/tmp/bqworldstate/hello_lifecycle_probe.py`; artifacts:
  `/private/tmp/bendquest-hello-lifecycle-gzizz4pi`.
- Source/build ledger: `/private/tmp/bqworldstate/validated_hashes.json`.


Checked connection lifecycle and repeated-HELLO repair:

- `sessions.bend` adds 27 safe laws. The pure descriptor contains CID, phase,
  PID, and profile name. `Sessions.OK` requires a nonzero CID and a valid
  fresh/awaiting-creation/playing lifecycle, including zero PID before creation,
  nonzero PID while playing, and valid names after identification.
- `hello_outcome` classifies every actual result: rejection preserves the
  entire descriptor; success requires zero PID, phase 0 or 1, a valid name,
  and no matching name in the supplied other-connection roster. Success
  preserves CID/PID and changes only phase and profile name. This is not a
  credential ownership or authentication theorem.
- `bound_locked`, `playing_locked`, and `bound_trace` prove complete descriptor
  preservation under repeated HELLO, including invalid or different requested
  names and arbitrary other descriptors. `hello_ok` and `trace_ok` preserve
  lifecycle validity. `fresh_ok` covers allocated connection IDs.
- `bind_ok`, `bind_pid`, `bind_reservation`, and `bind_locked` prove that binding
  an allocated PID to a valid creation-ready descriptor preserves CID/name,
  sets that exact PID and playing phase, and locks subsequent HELLO.
- The 1–12-character validator uses bounded structural traversal, avoiding
  a machine-word length counter. Universal one/twelve-character acceptance
  and thirteen-character-prefix rejection laws pin the limit. Name comparison
  reflexivity and online-head membership are checked.
- The actual server join, HELLO and successful CREATE paths call `fresh`,
  `hello`, and `bind`. Adapter conversion uses the existing checked player-name
  conversion routines. Rejected HELLO reconstructs the original Conn and
  retains its output channel; accepted changes come from the pure result.
  The old minified HELLO adapter was replaced with readable functions.
- The previously reproduced repeated-HELLO bug is repaired: a playing client
  receives an error and keeps its descriptor. Pre-create name selection,
  case-sensitive reservations, and UTF-8 names retain their existing behavior.
- `check-sessions.py` is a permanent native regression for the defect and
  surrounding lifecycle behavior. The strict proof gate includes the new
  module, and `sessions_check.bend` adds 29 cases.
- Full active-connection roster uniqueness, world-player membership and
  matching bindings, disconnect/rebind preservation, queued-session reuse,
  complete effectful dispatcher correspondence, and credential ownership
  remain open. This does not mark any of the six numbered scopes complete.

Connection-lifecycle validation:

- All 27 safe laws check with the original 15 witnesses and all preceding
  modules. All 544 JavaScript regressions pass; native lifecycle and allocation
  suites pass 53 cases. Scripts/transcripts: `/private/tmp/bqsessions`.
- Six mutations are rejected at the relevant new laws: bypassing the PID or
  phase guard, retaining an invalid old name on acceptance, changing a PID
  during HELLO, allowing thirteen-character names, and ignoring the allocated
  PID during binding. Transcripts: `/private/tmp/bqsessionsmutations`.
- The permanent native regression failed against the old executable at the
  repeated-HELLO step, then passed against staged and installed repaired builds.
  Snapshot waits select exact expected player IDs to avoid buffered old frames.
  Installed artifacts: `/var/folders/rg/h0_4_ww91836bk315x2n0qfm0000gn/T/bendquest-session-check-hw2irxqd`.
- The installed strict gate and native build pass. Installed emitted C matches
  the staged build exactly. The rebuilt game passed combat/shop bots, graphical
  host/join, and UTF-8 networking. Screenshots were inspected. Artifacts:
  `/private/tmp/bendquest-final-2hg400n5`.
- Broader native CREATE/HELLO repetition, distinct active IDs, removal/reconnect,
  and rejected-cosmetic checks pass with the repaired HELLO expectation.
  Artifacts: `/private/tmp/bendquest-allocation-network-t86tzq2b`.
- Exact profile, cosmetic ownership, balance, world number and complete
  hall-of-fame payload survive save/restart. Artifacts:
  `/private/tmp/bendquest-save-t_agt2g6`.
- Source/compiler/build ledger: `/private/tmp/bqsessions/validated_hashes.json`.


Bidirectional connection/world invariant and join/HELLO foundations:

- `connections.bend` adds 24 safe laws. `Connections.OK` requires valid session
  descriptors, unique CIDs, connection-to-player links, and reverse coverage
  of every world player. `Link.Playing` and `Present` carry actual record
  membership plus exact CID, PID and name equalities and nonzero bound PIDs.
  `Link.Waiting` requires zero PID and absence of its CID from world players.
  `all_nonzero` derives CID nonzero from session lifecycle validity.
- `Connections.WorldOK` combines this relation with `WorldState.OK` rather
  than replacing the established health/equipment/position/identity/reference
  components. `fresh_world` proves initialization for every seed.
- `hello_link` preserves forward links: waiting descriptors retain their CID
  and zero PID; playing descriptors are exactly unchanged. `hello_present`
  preserves reverse witnesses, including when the selected descriptor is the
  witness for the player. `hello_ok` and `hello_world` combine all components
  for the selected-head-plus-others arrangement used by the HELLO adapter.
- `unused_players` uses reverse coverage to derive that a CID absent from
  connection records is absent from player records. Thus `join_ok`,
  `allocate_ok`, and `join_world` prove new allocated connection descriptors
  cannot collide with a world player's CID. No extra absence premise is
  assumed about the player list. Failed allocation preserves the roster.
- Runtime code is unchanged. These proofs target the descriptor construction
  and selected-connection update already used by join/HELLO; correspondence
  through the effectful take/reordering adapter is still required. CREATE,
  disconnect, rebind/world replacement, other world transitions, and complete
  dispatcher preservation of this strengthened invariant remain open. All six
  original numbered scopes retain their requirements and remain incomplete.

Bidirectional roster validation:

- The 24 new laws check in the strict closure with the original 15 witnesses
  and all prior modules. All 544 JavaScript regressions pass. Installed sources
  match the staged tree, and the installed strict proof gate passes.
- Direct witnesses accept a matching playing connection/player pair and reject
  wrong CID, wrong name, zero CID, orphaned playing connection, and orphaned
  world player. Scripts and complete transcripts: `/private/tmp/bqconnections`.
- Fresh C emission from installed main is byte-identical to the existing C.
  Runtime sources, compiler/kernel, and native binary match the previous
  validated ledger. Its 53 native cases, HELLO protocol regression, broader
  networking, bots, graphical host/join, and exact save/reload evidence remain
  applicable. No new gameplay run is claimed for this proof-only batch.
- Final source/build ledger: `/private/tmp/bqconnections/validated_hashes.json`.


Connection selection and arbitrary-CID HELLO preservation:

- `selection.bend` adds 43 safe laws. `Selection.Perm` relates complete
  descriptors, including phase, PID and name. `take_restores` establishes a
  permutation between the original roster and the selected descriptor plus
  the remainder. `take_count` preserves exact length, `take_inside` supplies
  actual original membership, and `take_id` gives the requested CID.
- `take_head` proves first-match behavior even for duplicate-CID inputs.
  `take_success` proves a present CID is found, and `take_missing` proves an
  absent CID leaves the exact roster unchanged with no selected record.
  For unique inputs, `take_separated` proves the selected CID occurs nowhere
  in the remainder. These laws impose no machine-word cardinality bound.
- Permutation transport preserves valid sessions, unique CIDs, every forward
  connection/player link and every reverse player/connection membership
  witness. `take_ok` and `take_world` preserve the full connection invariant
  and its conjunction with the existing pure world invariant.
- `hello_ok` and `hello_world` now cover selection by an arbitrary CID from
  the original descriptor roster, including a missing-CID no-op. `step_world`
  and `trace_world` compose join allocation and selected HELLO operations.
  These traces cover connection-only operations with a fixed world.
- The server runtime is unchanged. The pure selector follows the legacy
  `Bq.take_conn` first-match algorithm, whose descriptor and channel behavior
  is checked by regression tests. Universal refinement of the channel-bearing
  adapter is still open; these tests are not presented as its proof.
  Joint CREATE/disconnect preservation, world-changing commands and ticks,
  world replacement, ownership/authentication and the full effectful server
  bridge remain outstanding. All six numbered scopes remain open.

Connection-selection validation (results recorded after installation):
- All 43 new laws check in the mandatory safe closure with the original 15
  witnesses and all prior proof modules. All 582 JavaScript regressions pass;
  the 38 new selector/HELLO/legacy-adapter cases also pass natively. The
  installed strict proof gate and installed selector regressions pass.
- Adapter cases compare complete selected/remainder descriptors and consume
  a distinct marker from each original output channel. They cover absent,
  first/middle/last, zero/MAX and duplicate CIDs, UTF-8 names, and mixed phase
  and PID payloads. Pure HELLO cases additionally check reordering on rejection,
  online-name reservation, bound identity, and missing-CID no-ops.
- Four deliberate defects are rejected: dropped skipped descriptor, lookup
  by PID, duplicated selected descriptor, and resetting the HELLO selection.
  Positive witnesses cover selecting a bound player after a fresh join and
  join/HELLO traces with allocator wraparound for every seed.
- Fresh C emission from installed main is byte-identical to the existing C.
  Runtime, compiler/kernel and native game build match the previous validated
  ledger; its game/bot/GUI/protocol/save evidence remains applicable. No new
  full-game playthrough is claimed for this proof-only batch.
- Scripts and transcripts: `/private/tmp/bqselection`. Final source/build
  ledger: `/private/tmp/bqselection/validated_hashes.json`.


Joint CREATE and mixed connection/player lifecycle preservation:

- `creation.bend` adds 30 safe laws. `insert_ok` establishes forward and
  reverse links for the newly spawned player and bound session, retains all
  other links and coverage, preserves valid session lifecycles and unique
  CIDs, and uses exact CID/PID/name equalities. `ready_unbound` derives zero
  PID from phase 1 and `Sessions.OK`. `replace_present` rules out an old
  player relying on that waiting session by contradiction with its positive
  binding witness. `extend_links` uses unique connection CIDs to preserve
  other waiting sessions' absence from the expanded player roster.
- `commit_world` combines this result with `WorldState.commit`, including
  fresh PID allocation and all existing health/equipment/position/identity/
  reference components. `finish_ok` follows actual `Admission.Outcome`
  evidence: a rejected allocation returns the previous world and session,
  while a positive allocated PID binds the matching selected descriptor.
- `selected_ok`, `taken_ok` and `create_ok` cover the phase-1 gate, arbitrary
  cosmetic/profile permission result, first-match CID selection and missing
  connections. The permission Boolean is the external cosmetic gate's result;
  this theorem proves preservation for either result, not ownership semantics
  or authentication. `unready`, `denied`, `missing` and `finish_failed` also
  give exact no-op statements at their respective operation boundaries.
- `step_ok`, `trace_ok` and `fresh_trace` now compose arbitrary joins, HELLOs
  and CREATEs, updating both world and descriptor roster after each step, from
  every seeded initial world. They include rejected/repeated requests and
  allocator failure/wraparound cases covered by the existing allocator.
- Runtime sources are unchanged. The pure CREATE composition uses the same
  admission and binding functions already called by the server. Native
  handler comparisons exercise the legacy adapter, its profile/cosmetic gate,
  message channels, appearance normalization and retention of world maps.
  These comparisons supplement the safe theorem; they are not a universal
  proof of the channel-bearing/effectful server adapter. Disconnect, world
  changes by commands/ticks, world replacement and the complete server bridge
  remain outstanding. All six original numbered scopes remain open.

Joint CREATE validation (results recorded after installation):
- All 30 laws check in the mandatory safe closure with the original 15
  witnesses and all previous modules. All 609 JavaScript regressions pass.
  The 27 new pure cases and 17 actual-server CREATE comparisons pass natively;
  the installed proof gate, pure tests and `check-creation.sh` pass.
- The real-handler fixture checks first/middle/last selection, existing players,
  missing CIDs, pre-HELLO and repeated CREATE, UTF-8 identity, zero/MAX allocator
  hints, MAX CID, occupied PID skipping, unowned hat/cape rejection, appearance
  normalization, retained output channels, and unchanged world maps. The
  fixture retains the full game effect registry and links the game's existing
  macOS/raylib dependencies; only the test entrypoint is executed.
- Four deliberate defects are rejected: successful creation left unbound,
  CID used instead of allocated PID, other sessions discarded, and a failed
  candidate world committed. A positive witness checks a mixed multiplayer
  trace with wraparound, denial/retry and repeated CREATE for every world seed.
- Fresh installed-game C emission is byte-identical to the existing C. Runtime
  sources, compiler/kernel and native game build match the previous ledger;
  earlier game/bot/GUI/protocol/save evidence remains applicable. No new
  full-game playthrough is claimed for this proof-only batch.
- Scripts/transcripts: `/private/tmp/bqcreation`; final source/build ledger:
  `/private/tmp/bqcreation/validated_hashes.json`.


Joint disconnect and complete connection lifecycle preservation:

- `player_membership.bend` adds 17 safe laws. `same_id` derives full-record
  equality for two members with the same PID under unique player IDs;
  `different_pid` separates members with distinct CIDs. `absent_member` handles
  either ID projection. A structural erase-by-PID specification preserves
  nonmatching actual member records and absence facts, and contains no target
  PID. `take_filter` proves it equals the server's first-match player removal
  on unique rosters; no duplicate-input equivalence is claimed.
- `disconnect.bend` adds 19 safe laws. Forward links survive removal because
  other playing sessions have different PIDs, and other waiting sessions retain
  their absence from the player roster. Reverse coverage excludes the departing
  descriptor for every retained player. `selected_ok` combines this with
  `WorldState.remove` and the exact `References.remove_state` roster projection.
  `run_ok` includes the existing first-match connection selector and absent CID.
- `retained_player` preserves every other complete player record; `removed_absent`
  proves the removed PID occurs nowhere afterwards. `zero_world` and `waiting`
  prove disconnecting an unbound session preserves the exact valid world.
  `missing` is an unconditional exact no-op given an absent CID. Existing
  reference reconciliation proves targets to removed players are cleared and
  all remaining references valid; all prior pure-world components are preserved.
- `step_ok`, `trace_ok` and `fresh_trace` compose arbitrary join, HELLO, CREATE
  and disconnect operations, including removal/reconnect and repeated absent
  disconnects, from every world seed. This extends the prior lifecycle theorem;
  world-changing commands/ticks and replacement still need correspondence with
  the connection invariant. ID reuse is allocator-safe; the theorem does not
  assume or establish delivery ordering of external network events.
- Runtime sources are unchanged. Native `on_gone` comparisons exercise actual
  player deletion, monster reference repair and output-channel handling.
  These tests supplement the safe pure theorem, without replacing the still-open
  universal proof of the channel-bearing/effectful server adapter. Authentication,
  reward liveness, numeric/save properties and world completability remain within
  their original scopes. All six numbered obligations remain open.

Joint disconnect validation (results recorded after installation):
- All 36 new laws check in the mandatory safe closure with the original 15
  witnesses and every previous proof module. All 632 JavaScript regressions
  pass. The 23 pure disconnect cases and 17 real-handler comparisons pass
  natively; installed proof, pure-test and `check-disconnect.sh` gates pass.
- Handler cases verify complete player/monster/metadata and descriptor results,
  unchanged maps, closure of the selected original channel, and preservation
  and continued use of each retained original channel. They cover waiting and
  bound clients, independent roster orders, multiple monster targets, first/
  middle/last and absent CIDs, MAX IDs, UTF-8 and other-player target retention.
  Mixed pure traces include repeated disconnects and CID reuse with new PIDs.
- Four deliberate defects are rejected: deleting by CID instead of PID,
  retaining the departing connection, retaining the removed player, and
  discarding a surviving player. A positive all-seed lifecycle witness includes
  multiplayer creation, wraparound, disconnect/reconnect and removal of all
  players. Test scripts and transcripts: `/private/tmp/bqdisconnect`.
- Fresh installed-game C emission is byte-identical to the existing C. Runtime,
  compiler/kernel and native game build match the previous ledger; prior game,
  bot, graphical, protocol and save/reload evidence remains applicable. No new
  full-game playthrough is claimed for this proof-only batch.
- Final source/build ledger: `/private/tmp/bqdisconnect/validated_hashes.json`.


Connection correspondence through world-changing commands:

- `bindings.bend` adds 32 safe laws. Full player permutations preserve forward
  links, reverse coverage and waiting-session CID absence. `Bindings.Header`
  contains exact PID, CID and name; it permits every gameplay field to change.
  `align` constructs a structural pair witness from equal projected lists.
  `aligned_member` produces membership of an actual updated player, with equal
  identity fields, rather than treating the old full record as unchanged.
- `aligned_absent`, `aligned_links` and `aligned_covers` transport the complete
  connection invariant to updated rosters. `conserved_ok` combines full-record
  permutation with exact header equality. These intermediate results concern
  connection correspondence; health/position/equipment/ID bounds are supplied
  separately by the established pure-world transition theorems.
- `frame_bindings.bend` adds 34 safe laws. Exact header projections are proved
  for the existing inventory, interaction, combat and payout frames. Their
  existing conservation witnesses then provide `Connections.OK` preservation
  for each corresponding roster operation. No new frame-conservation premise
  is assumed about the live command implementations.
- The complete battle composition transports that invariant through kill
  rewards, no-kill results, monster strikes, strike lists, combat admission
  and command execution. It uses the actual `Battle`/`Payout`/`Combat` functions,
  including list reordering, multi-strike rewards and boss progression.
- `inventory_world`, `interaction_world` and `fight_world` combine these results
  with `WorldState` preservation. `run_ok`, `step_ok`, `trace_ok` and `fresh_trace`
  cover inventory, interaction and full combat commands interleaved with all
  proved connection lifecycle operations from every seed. Unilateral player
  creation/removal are not exposed as ordinary commands: the combined alphabet
  uses the already-proved joint lifecycle operations, matching their role in
  server dispatch.
- Runtime sources are unchanged. These are preservation theorems for existing
  pure operations, not new authentication or command-ownership claims. Ticks
  still need PID/CID/name correspondence, followed by combined schedules, world
  replacement and the full channel-bearing/effectful dispatcher bridge. Reward
  liveness, numeric/save obligations and world completability retain their
  original scope. All six numbered obligations remain open.

Command binding validation (results recorded after installation):
- All 66 new laws check in the mandatory safe closure with the original 15
  witnesses and every previous proof module. All 632 JavaScript regressions
  pass; installed sources match the validated staged sources and the installed
  strict proof gate passes.
- Direct witnesses accept updated gameplay fields with unchanged binding, and
  reject changed PID, CID or name, dropped players and duplicated players.
  An all-seed positive witness composes multiplayer creation, inventory changes,
  interactions, multi-strike combat/rewards and disconnects. Scripts and
  transcripts: `/private/tmp/bqbindings`.
- Fresh installed-game C emission is byte-identical to the existing C. Runtime,
  compiler/kernel and native game build match the previous ledger; its native
  regression, protocol, game/bot/GUI and save/reload evidence remains applicable.
  No new native or full-game run is claimed for this proof-only batch.
- Final source/build ledger: `/private/tmp/bqbindings/validated_hashes.json`.


Connection correspondence through complete ticks and mixed traces:

- `tick_bindings.bend` adds 22 safe laws. `finish_hit_header` and
  `finish_upkeep_header` preserve exact PID/CID/name through both death and
  revival branches, and their wrappers cover actual damage and upkeep.
  The header projection also covers missing/short/long movement-plan lists,
  paused and active tick preparation, and arbitrary spawn/timer arguments at
  this correspondence-only layer.
- A strike may reorder the roster through first-match selection. Its theorem
  combines the existing full-record permutation with the new header equality;
  `apply_hits` composes arbitrary attack lists, including repeated and absent
  targets, using actual sequential roster results.
- `finish`, `actions`, `planning_finish` and `planning_tick` lift this result
  through AI attack generation and the checked planning refinement. `tick` and
  `run_tick` reach the actual `AIRefs` tick used by the server, via the existing
  exact refinement with contexts selected from the post-upkeep player list.
  This layer needs neither health/position assumptions nor canonical spawn
  coordinates to establish connection correspondence alone.
- `world` combines that correspondence with the existing complete pure-world
  theorem. This combined result uses `Planning.rules(timer)`, retaining the
  canonical spawn coordinates needed for walkability. Damage lists and timers
  remain unrestricted. `step_ok`, `trace_ok` and `fresh_trace` cover arbitrary
  finite mixtures of actual ticks, inventory/interaction/combat commands and
  joint join/HELLO/CREATE/disconnect operations, for every seed.
- Runtime sources are unchanged. This closes tick correspondence in the mixed
  pure transition alphabet. World replacement/rebinding and the universal
  channel-bearing/effectful server bridge remain before full server closure.
  Preservation does not establish caller ownership, combat rate limits,
  reward liveness, save properties or world completability. All six numbered
  obligations remain open with their original scope.

Tick correspondence validation (results recorded after installation):
- All 22 new laws check in the mandatory safe closure with the original 15
  witnesses and every previous proof module. All 632 JavaScript regressions
  pass. Installed files match the validated staged sources, and the installed
  strict proof gate passes.
- Four deliberate runtime mutations are rejected: renaming a player on death,
  renaming on revival, changing the CID on death, and changing the PID on
  revival. The two name mutations fail specifically at the new header laws.
  A positive witness covers every seed/world/initial-time with ticks before,
  between and after multiplayer lifecycle, inventory, interaction, combat and
  disconnect operations; damage/timer inputs include zero and U32 MAX.
  Scripts and transcripts: `/private/tmp/bqtickbindings`.
- Fresh installed-game C emission is byte-identical to the existing C. Runtime,
  compiler/kernel and native build hashes match the prior ledger; previous
  native regression, protocol, game/bot/GUI and save/reload evidence remains
  applicable. No new native or full-game run is claimed for this proof-only
  batch. Final ledger: `/private/tmp/bqtickbindings/validated_hashes.json`.


Successful allocation dependency for world restart:

- The actual restart rebuilds players with `Admission.add` and then rebinds
  each connection by CID. If a rebuild admission fails, the legacy rebind
  lookup retains the old PID. Proving full correspondence therefore requires
  successful reconstruction, not only conditional freshness of returned IDs.
- `allocation_search.bend` adds 19 safe laws. First-match deletion preserves
  membership of every different ID and removes exactly one entry when its
  target is present. `subset_cut` and `cardinality` prove that a distinct list
  included in any list has no greater length. The containing list may include
  duplicates, and membership uses the allocator's actual U32 equality tests.
- `visits` follows the allocator's actual normalized successor, including
  MAX-to-one wrap. `failed_cover` and `cover_failed` establish both directions:
  a scan returns `None` exactly when all candidates in its fuel-bounded visit
  sequence are occupied (with the scan's occupancy argument correctly related
  to the actual membership test). `visits_length` relates the sequence to fuel.
- `failure_bound` and `cannot_fail` use the finite cardinality result.
  `scan_complete` constructs an actual returned choice, exact `Some` equality
  and the established freshness witness, when the visit sequence is distinct
  and its length exceeds the occupied-list length. `find_complete` instantiates
  the live `length + 1` budget and normalized hint. It retains the explicit
  distinctness premise for that exact candidate sequence; it does not assume
  success or infer it from runtime tests.
- `admission_search.bend` adds seven safe laws. Nonzero, unused CIDs pass the
  real rejection gate. `choose_complete` and `add_complete` carry constructive
  allocation success through the actual admission function. `nonzero` proves
  its returned PID is positive; `inserted` gives the exact new player record
  followed by the entire unchanged old roster, using requested CID/style/name
  and the canonical spawn coordinates.
- The remaining numeric obligation is to prove sufficient distinctness of
  the actual U32 successor sequence for every capacity-valid admission and to
  derive the required capacity bound for reconstruction from a valid old
  roster. This batch does not claim unconditional allocation completeness,
  reconstruction success, restart/rebinding preservation or the complete
  effectful server bridge. All six numbered obligations remain open.

Bounded allocation success validation (results recorded after installation):
- All 26 new laws check in the mandatory safe closure with the original 15
  witnesses and every previous proof module. All 632 JavaScript regressions
  pass. Installed files match the validated staged sources, and the installed
  strict proof gate passes.
- Nine constructive allocation witnesses cover empty/dense/sparse rosters,
  zero hints, MAX and pre-MAX wrap, duplicate occupied entries and reserved-zero
  entries. False distinctness and insufficient-fuel witnesses are rejected.
  A success witness covers arbitrary seed/style/name for a wraparound admission,
  including its positive PID and exact inserted roster; zero and occupied CIDs
  are rejected as successful-admission witnesses.
- Three deliberate allocator defects are rejected. For collision starvation,
  the mutated allocator's original safety proofs were updated to its still-safe
  behavior and independently checked; the new `failed_cover` law then rejects
  it. This confirms the new obligation detects a failure that conditional
  freshness permits. Dropping a free result and returning a zero next cursor
  are also rejected. Scripts and transcripts: `/private/tmp/bqallocsearch`.
- Fresh installed-game C emission is byte-identical to the existing C. Runtime,
  compiler/kernel and native build hashes match the prior ledger; previous
  native regression, protocol, game/bot/GUI and save/reload evidence remains
  applicable. No new native or full-game run is claimed for this proof-only
  batch. Final ledger: `/private/tmp/bqallocsearch/validated_hashes.json`.


Exact successor arithmetic for the allocation search:

- `word_successor.bend` adds 39 safe laws. `adc_zero`, `adc_carry`, `add_one`
  and `u32_add_one` prove the actual Base binary adder with one agrees with
  `Word.inc`, rather than assuming arithmetic primitives coincide.
- `zero_cmp`, `inc_zero` and `u32_inc_zero` connect the actual binary equality
  test to the all-ones flag: increment reaches zero exactly for a full word.
  `full_inc`, `one_value`, `nonfull_below` and `full_eq` provide exact endpoint
  and strict-before-end facts for arbitrary bit widths.
- `u32_refines` proves the live `Allocation.next` is exactly the word successor
  that returns one at the full word and increments otherwise. `word_next_value`
  and `u32_next_value` refine that to `nat_next`, whose endpoint and increasing
  branches are proved by `nat_next_wrap` and `nat_next_advance`.
- `Capacity<n,maximum>` contains an actual n-bit word, a proof that it is full,
  and its exact natural value. `capacity_exact` proves that value equals the
  generic `Numeric.limit(n)`; it is not an assumed bound or a smaller capacity.
  The witness form avoids forcing a closed 2^32-sized unary natural during
  type conversion. `word_next_value_at` preserves the same arithmetic theorem
  at U32 width using this exact capacity representation.
- Word/decoded zero tests agree. Nonzero words and normalized hints have
  positive decoded values; every word is bounded by its exact capacity, which
  is positive for positive widths. `ones_full`, `range` and `u32_range`
  construct exact capacities, including a packed U32 witness; capacity
  existence is proved, not left as an assumption. `visits_refine` and `find_visits` connect
  arbitrary finite sequences from the actual allocator to the natural cycle,
  retaining its real normalized hint, length-plus-one fuel and wrap behavior.
- Runtime and compiler sources are unchanged. The next obligations remain
  distinctness of natural cycle prefixes up to capacity, transfer back to U32
  ID uniqueness, and the capacity bound for reconstruction from valid old
  rosters. This batch does not assume those results, claim unconditional search
  success, or close restart/rebinding or the full effectful server invariant.
  All six numbered obligations remain open.

Exact successor validation (results recorded after installation):
- All 39 new laws check in the mandatory safe closure with the original 15
  witnesses and every previous proof module. All 632 JavaScript regressions
  pass. Installed files match the validated staged sources, and the installed
  strict proof gate passes.
- Numeric witnesses cover every four-bit value and ten U32 cases from zero
  through carry boundaries to MAX. Incorrect numeric capacity, a nonfull
  capacity word and zero capacity are rejected; a packed full-U32 capacity
  existence witness checks. An arbitrary-fuel/normalized-
  hint witness checks the complete visit-sequence refinement. These finite
  examples supplement the universal checked laws; they do not establish the
  still-open distinctness/capacity obligations.
- A deliberate add-two successor mutation, with its positivity witness updated,
  still passes the previous allocation and conditional search-success proof
  closures. `WordSuccessor.u32_refines` rejects it. This demonstrates that the
  new arithmetic contract detects a gap left by conditional freshness/search
  guarantees. Scripts and transcripts: `/private/tmp/bqwordsuccessor`.
- Fresh installed-game C emission is byte-identical to the existing C. Runtime,
  compiler/kernel and native build hashes match the prior ledger; previous
  native regression, protocol, game/bot/GUI and save/reload evidence remains
  applicable. No new native or full-game run is claimed for this proof-only
  batch. Final ledger: `/private/tmp/bqwordsuccessor/validated_hashes.json`.


Cycle distinctness, derived capacity and successful admission:

- `nat_cycle.bend` adds 22 safe laws. An increasing prefix from one is distinct
  up to the cycle capacity. The actual natural successor is injective on
  positive inputs; zero is explicitly excluded because zero and the endpoint
  both map to one. Mapping successor over positive distinct lists preserves
  distinctness and shifts the actual visit sequence by one. Induction on the
  starting value therefore proves `visits_unique` for every positive in-range
  start and every prefix no longer than capacity, including wrapped prefixes.
  It does not assume that the cycle is distinct.
- `allocation_complete.bend` adds seven safe laws transferring natural
  inequality, absence and uniqueness back to actual U32 IDs through the checked
  word equality reflection and exact visit-sequence refinement. `find_complete`
  and `admission_complete` thus eliminate the former visit-distinctness premise;
  at this intermediate layer they require room in the exact U32 capacity.
- `nat_capacity.bend` adds seven safe laws deriving the cardinality bound for
  distinct positive naturals at or below a maximum. Lowering all values above
  one preserves uniqueness, positivity and the decremented upper bound. At
  most one entry is lost, because zero is excluded and one cannot repeat.
  Induction on the maximum proves length no greater than capacity without
  enumerating a closed U32-sized list or assuming a roster-size limit.
- `id_capacity.bend` adds 15 safe laws. Word round-trip injectivity transports
  actual U32 distinctness to decoded naturals; nonzero IDs decode positively
  and every word is bounded by the exact full-word capacity. `capacity` derives
  the ID-list size bound; `room` derives strict room by adjoining any unused
  positive ID. `find_available` supplies the constructively proved U32 capacity
  and proves the actual allocator returns a fresh choice for every hint on a
  unique, nonzero ID roster with an available nonzero ID.
- Player PID and CID projections have equal lengths. An unused positive CID
  extends a valid CID roster, so its derived capacity bound gives room for the
  PID search even though PID values differ from CIDs. `admission_available`
  proves actual `Admission.add` succeeds from unique/nonzero existing CIDs and
  a positive unused new CID, with no capacity, search-distinctness, or roster-
  size premise. The existing successful-admission contract supplies the exact
  inserted player, unchanged old roster and positive returned PID.
- These complete the numeric/search dependencies identified for restart.
  The remaining reconstruction proof must establish/preserve prefix CID
  uniqueness, nonzero IDs and absence of each next old player's CID, then
  prove final player/connection correspondence under rebinding. Runtime sources
  are unchanged; full restart and the effectful server bridge are still open.
  No authentication, reward-liveness, save or completability claim follows from
  these numeric theorems. All six numbered obligations retain their full scope.

Cycle/capacity validation (results recorded after installation):
- All 51 new laws check in the mandatory safe closure with the original 15
  witnesses and every previous proof module. All 632 JavaScript regressions
  pass. Installed files match the validated staged sources, and the installed
  strict proof gate passes.
- 112 cycle witnesses cover capacities one through six, every valid start and
  every prefix length through capacity. A too-long prefix and injectivity
  including zero are rejected. 127 cardinality witnesses cover all subsets
  through capacity six, in reversed order; duplicate, zero and out-of-bound
  entries are rejected as valid cardinality inputs.
- Actual U32 witnesses establish search success for every hint on a roster
  containing MAX, one and two; the packed U32 capacity and available-ID theorem
  both discharge success without assumed distinctness or size. A multiplayer
  admission witness covers every hint, seed, style and name using only the
  existing CID uniqueness/nonzero facts and an unused positive CID. These
  examples supplement the universal checked laws. Scripts and transcripts:
  `/private/tmp/bqnatcycle`.
- Fresh installed-game C emission is byte-identical to the existing C. Runtime,
  compiler/kernel and native build hashes match the prior ledger; previous
  native regression, protocol, game/bot/GUI and save/reload evidence remains
  applicable. No new native or full-game run is claimed for this proof-only
  batch. Final ledger: `/private/tmp/bqnatcycle/validated_hashes.json`.


Successful player reconstruction in the live restart path:

- `rebuild.bend` adds 22 safe laws. `Rebuild.step` calls actual `Admission.add`
  with the old player's CID, appearance and name. `Rebuild.run` walks the old
  roster, accumulating the actual resulting world. `Rebuild.Valid` records CID
  uniqueness/nonzero IDs; `Separate` records that remaining old CIDs are absent
  from the accumulated roster.
- `step_success` uses the completed capacity/admission theorem, without a
  size bound or assumed success. `step_players` gives the exact fresh spawn
  followed by the entire old accumulated roster. CID projections, current CID
  validity and separation from the remaining input are proved through that
  actual result, including arbitrary PID cursors and wraparound.
- `run_profiles` proves the exact resulting CID/appearance/name list is the
  reversed input inserted before the previous accumulated profiles. Old CID
  uniqueness, nonzero IDs and disjointness establish every successful step;
  the proof does not silently permit missing or duplicated rebuilt players.
  Full gameplay fields are reset by the actual `Players.spawn` insertion.
- `run_world` preserves the established complete pure-world invariant.
  `from_world` derives the required CID facts from that invariant. The exact
  Terrain wrapper preserves maps and refines the simulation result;
  `fresh_world` and `fresh_profiles` apply for every new world/seed/time.
- `legacy_step_refines` and `legacy_refines` prove the old loop's pure operation
  (including its shared/linear name round trip) equals the new loop for all
  states and rosters, even rejected admissions. The server's `Bq.readd_plrs`
  now delegates directly to `Rebuild.world`; the proven function is on the
  actual runtime path. Native/JS comparisons also exercise the old `World`
  adapter, original style/name extraction and full Terrain wrapper.
- `rebuild_check.bend` adds 20 regressions and `check-rebuild.sh` makes native
  comparisons permanent. Cases include multiple orders, changed old gameplay
  fields, appearance, Unicode/empty names, zero/MAX hints, occupied PID search,
  MAX CID, existing/invalid/duplicate CIDs, seeded populations and exact
  expected rosters. Invalid-CID cases check legacy behavior equivalence; they
  are not presented as satisfying the successful-reconstruction preconditions.
- This closes successful pure reconstruction and connects it to the live
  readdition path. The next correspondence obligation is final connection
  rebinding by CID to the actual rebuilt records; the old-PID fallback must be
  ruled out for playing connections. Full effectful restart/save/message
  composition, authentication, reward liveness and other original obligations
  remain open. All six numbered scopes remain unchanged.

Live reconstruction validation (results recorded after installation):
- All 22 new laws check in the mandatory safe closure with the original 15
  witnesses and every prior proof module. All 652 JavaScript regressions pass,
  including 20 new reconstruction cases. The installed build and strict proof
  gate pass. Staged and installed native reconstruction comparisons pass;
  the 44 native creation cases and 40 native disconnect cases also pass.
- A universal witness combines the complete pure-world invariant with exact
  reconstructed profiles for every valid old world and arbitrary new world,
  seed and time. Deliberately dropping a player, losing appearance or losing
  a name is rejected by the reconstruction laws. Scripts and transcripts:
  `/private/tmp/bqrebuild`.
- The installed native game was rebuilt and exercised with both bots, graphical
  join and host autopilots, UTF-8 networking, HELLO/CREATE rejection and identity
  checks, disconnect/reconnect, and database reload. New client and host
  screenshots were inspected. A separate save/restart check preserves exact
  purchased cosmetics, coin balance, UTF-8 name, world number and full hall-
  of-fame payload. Artifact locations are in the batch's gameplay, sessions,
  protocol and save transcripts.
- Runtime behavior is preserved by the checked pure loop refinement and full
  old-adapter comparisons; only server readdition now delegates to the safe
  implementation. The compiler/kernel and unrelated source hashes are unchanged.
  Full connection rebinding and effectful restart composition remain open.
  Final ledger: `/private/tmp/bqrebuild/validated_hashes.json`.


Connection rebinding rules (reconstruction correspondence still open):

- `rebinding.bend` adds 33 safe laws. `lookup` models the existing server's
  first-CID lookup with its old-PID fallback; `lookup_absent` proves exact
  fallback behavior, and `lookup_member` proves the actual member's PID is
  returned for every fallback under CID uniqueness. No caller-supplied
  equality between old and new PIDs is assumed.
- `repid` replaces only PID. Checked projections preserve CID, lifecycle
  phase and name. `lifecycle`/`repid_ok` preserve a valid playing session when
  both old and replacement PIDs are positive; zero and one phases contradict
  a positive old PID, and invalid phases are uninhabited. Waiting lookup is
  an exact descriptor no-op when its CID is absent.
- `Target` explicitly records an actual replacement player, its full-record
  membership, matching CID/name and positive old binding, or an unbound
  waiting connection with an absent CID. `Reserved` records an actual old
  connection for a new player. These are hypotheses to be established from
  reconstruction, not axioms or assertions that restart is already proved.
- `one_link`, `one_ok`, `run_links` and `run_all` establish forward links and
  lifecycle validity. Positive replacement PIDs are derived from membership
  and the roster's nonzero invariant. Connection membership, reverse player
  coverage and CID uniqueness are preserved by `run_member`, `run_covers`
  and `run_unique`; `run_ok` combines these into `Connections.OK` under the
  explicitly stated targets/reservations and roster/session invariants.
- Already linked connections are exact no-ops (`one_same`, `run_same`), and
  `run_idempotent` proves that rebinding a successfully rebound roster again
  does not change any descriptor. Phase/name preservation and CID projection
  hold even on invalid inputs; validity claims retain their premises.
- `rebinding_check.bend` has 26 cases comparing pure lookup with actual server
  lookup and checking exact descriptor results, including CID/PID confusion,
  roster order, mixed waiting/playing sessions, Unicode, MAX values, rejected
  proof premises, actual reconstruction and allocator wraparound.
  `rebinding_server_check.bend` has 14 native cases using actual server
  `rebind_conns`; marked output channels must retain their data and remain
  usable. `check-rebinding.sh` runs both fixtures natively.
- This batch does not change runtime code. The universal bridge from
  `Rebuild.fresh_profiles` to all replacement targets and reverse
  reservations remains next, followed by full restarted `Connections.WorldOK`
  and channel/effectful adapter composition. Native adapter comparisons are
  tests, not a universal adapter refinement proof. All six original scopes
  remain open and unchanged.

Rebinding validation (recorded after installation):
- All 33 laws check in the mandatory safe closure alongside the original 15
  witnesses and every existing proof module. All 678 JavaScript cases pass;
  the 26 new lookup/descriptor cases and 14 actual server/channel comparisons
  also pass natively. Installed sources match the checked stage and the
  installed strict proof gate passes.
- A checked mixed-roster witness constructs both directions of correspondence
  with different old/new PIDs, reversed player/connection order and a waiting
  connection. Another witness covers any lookup fallback; repeated rebinding
  preserves the resulting descriptors. These examples exercise the universal
  laws without claiming the still-open reconstruction transport theorem.
- Deliberately returning the fallback for a found player, resetting phase,
  losing the name or dropping the connection tail is rejected by the laws.
  Missing-player membership, duplicate-CID uniqueness and zero replacement
  PID cannot be supplied as valid proof inputs. Probe scripts/transcripts:
  `/private/tmp/bqrebinding`.
- Fresh game C emission is byte-identical to the installed C. Runtime source,
  native binary and compiler/kernel hashes match the prior ledger, so the
  fresh bots/GUI/protocol/save evidence recorded by the reconstruction batch
  remains applicable. No new full-game run is claimed for this proof-only
  batch. Final ledger: `/private/tmp/bqrebinding/validated_hashes.json`.


Complete pure restart and mixed trace composition:

- `reversal.bend` adds five safe laws. Accumulating reversal is related to
  ordinary concatenation by a full-player-record `Players.Perm`; its empty
  accumulator is therefore a permutation of the original roster. Its exact
  profile projection equals `Rebuild.reverse_into`, accounting for the live
  reconstruction loop's insertion order without assuming order preservation.
- `restart_profiles.bend` adds 17 safe laws. Profile equality allows new PIDs
  and gameplay state while retaining CID, style and name. Structural alignment
  yields actual replacement records and their full-record membership. It also
  transports absent CIDs. Old forward links therefore produce all rebinding
  targets, and old reverse coverage produces actual connection reservations
  for every new player. This is bidirectional correspondence, not a count or
  ID-list approximation.
- `restart.bend` adds seven safe laws. `Restart.correspondence` combines the
  full-record reversal permutation with exact new profile equality.
  `rebind_proven` extracts actual CID uniqueness and nonzero PIDs from the new
  world invariant, then discharges every premise of `Rebinding.run_ok`.
  `Restart.run_ok` combines this with `Rebuild.fresh_world/fresh_profiles` and
  derives old roster validity from the supplied old `Connections.WorldOK`.
- Consequently, for any valid old world and connection roster, and every new
  world number, seed and time, pure reconstruction plus rebinding preserves
  complete world validity, session lifecycle/unique CIDs, and both directions
  of actual player/connection matching. No size/capacity bound, assumed
  admission success, replacement membership, ready-made reservation or
  equality between old/new PIDs is an extra premise of the final theorem.
  `run_maps` retains the new map family; `run_profiles` retains the exact
  reconstructed CID/style/name list.
- `restart_trace.bend` adds four safe laws. The trace carries the current
  seed with the world/connection result. It composes the existing complete
  lifecycle/gameplay/tick transitions with replacement by a freshly rebuilt
  world; each replacement updates the seed used by subsequent transitions.
  `step_ok`, `trace_ok` and `fresh_trace` establish the invariant for arbitrary
  mixed input lists, including multiple restarts and changing seeds/times.
- `restart_check.bend` has 21 old-adapter comparisons and exact trace cases.
  `restart_server_check.bend` has 12 native comparisons of the actual server
  readdition-plus-rebinding operations, checking complete simulation state,
  maps, descriptors and retained usable output channels. Cases cover mixed
  waiting/playing, roster order, changed old gameplay/appearance, Unicode,
  MAX values, repeated restarts, disconnect/create and tick interleavings,
  and post-restart rejected bound renaming. Invalid roster cases only check
  legacy behavior; they do not satisfy the universal proof's premises.
- This completes pure restart correspondence and mixed pure composition.
  Runtime code is unchanged in this batch. The server already calls safe
  `Rebuild.world`, but its channel-bearing rebind adapter, seed/world/time
  extraction, restart dispatch, database save and message effects still need
  universal refinement/composition. Native comparisons are finite supporting
  evidence. Full authentication, reward liveness/accounting, combat rates,
  persistence/durability and world completion scopes remain open unchanged.

Pure restart/trace validation (recorded after installation):
- All 33 new laws check in the mandatory safe closure with the original 15
  witnesses and every previous proof module. All 699 JavaScript cases pass;
  the 21 new old-adapter/trace cases and 12 actual server composition/channel
  cases pass natively. Installed sources match the checked stage, and the
  installed strict proof gate passes.
- A universal probe accepts any old valid world, connection roster and new
  world/seed/time. Another supplies arbitrary changed PIDs to structural
  profile membership. A constructive multiplayer trace creates two players,
  restarts with arbitrary first seed, ticks with arbitrary damage lists,
  disconnects one player, restarts with arbitrary second seed and ticks again;
  initial world/seed/time are arbitrary, and both MAX and zero world numbers
  occur in the sequence. All witnesses check safely.
- Retaining old bindings, dropping reconstructed players, using the wrong new
  seed or retaining the old seed for subsequent trace steps is rejected by
  the corresponding restart laws. A changed CID, changed name or missing
  player cannot supply the required reconstruction alignment. Scripts and
  transcripts: `/private/tmp/bqrestart`.
- Fresh installed-game C emission is byte-identical to the prior native C.
  Runtime sources, compiler/kernel and native binary hashes are unchanged,
  so the reconstruction batch's fresh bots/GUI/protocol/save evidence remains
  applicable; no new full-game run is claimed for this proof-only batch.
  Final ledger: `/private/tmp/bqrestart/validated_hashes.json`.


Live channel-bearing restart and affine descriptor refinement:

- `connection.bend` adds 15 safe laws and owns the live `Connection.Record`.
  Its fields retain the previous representation and ordering: CID, phase,
  PID, channel handle and affine raw character list. `Bq.Conn` is now a safe
  type alias; the server and the three tests that matched its old constructor
  use the moved constructor. No shared-name rewrite of the live record is
  required. Ordinary affine proof parameters cover actual connection records.
- Raw-name conversion and full connection reconstruction round trip exactly.
  `repid` changes only PID. The actual `one`/`rebind` preserve channel handles
  (including generation), raw names and list order. Their descriptor projection
  equals `Rebinding.one/run` for every roster and record, even invalid inputs;
  world/lifecycle validity claims retain the required old-world premise.
- `Described` and `Rebound` carry actual computed descriptors plus before/after
  equalities. `describe_one/describe_cons/describe` construct these in one
  affine traversal. This resolves the need to both inspect the old descriptor
  and prove the updated descriptor without consuming the affine connection
  roster twice. Erased connection indices are used only in proof types.
- `channel_restart.bend` adds ten safe laws. `finish/run_refines` give exact
  descriptor-result equality with `Restart.finish/run`. `run_with_view/run_ok`
  transport the old world invariant through the single-traversal witness and
  the completed pure restart theorem. `run_channels/run_names` preserve the
  exact original handle list and raw name list for every input roster.
- `restart` extracts the actual old metadata, uses U32 old-world-plus-one,
  hashes old seed with old time via `Landscape.hash`, and keeps that time.
  `restart_refines/restart_ok` specialize the universal theorem to those
  exact inputs. `restart_channels/restart_names` preserve the live channels
  and names through the complete channel-bearing operation, with no assumed
  replacement membership, allocation success or equality of old/new PIDs.
- The live server's descriptor adapters, PID lookup and rebinding delegate to
  the checked functions. `Bq.restart_world` calls `ChannelRestart.restart`;
  `restart_ready` then performs the existing database save, START, zone/name
  messages, new-world event and log entry in their original order, returning
  the checked world and connections with the updated database. The pure
  operation is therefore on the real path, not only a parallel test model.
- `connection_check.bend` adds 15 JS/native comparisons of complete records,
  including distinct channel generations, Unicode, MAX values, absent/duplicate
  lookup behavior and retained phase/name. Synthetic handles are compared as
  data only. `restart_effects_check.bend` preserves the previous full restart
  body as an independent native sequencing oracle; ten cases compare complete
  world/maps/descriptors, returned database serialization, actual saved text,
  ordered per-connection messages, log entries and still-usable channels.
  The native gate runs in an isolated temporary directory, including DB writes.
- The safe theorem now covers the actual channel-bearing reconstruction and
  rebinding computation. The surrounding effectful save/send/log functions,
  delivery under full/disconnected channels, database durability, exact
  dispatcher/metadata/map association and other legacy command adapters still
  need universal refinement/composition. In particular, native effect equality
  is finite supporting evidence, not a universal IO theorem. All six original
  property scopes remain open and unchanged.

Live channel restart validation (recorded after installation):
- All 25 new laws check in the mandatory safe closure alongside the original
  15 witnesses and all prior proof modules. All 714 JavaScript cases pass.
  Staged and installed builds pass; installed source bytes and emitted C
  match the validated stage. All 202 installed native cases pass: creation44,
  disconnect40, reconstruction20, rebinding40, pure restart/trace33 and the
  new connection/full-effect comparisons25.
- Universal witnesses cover actual affine channel-bearing rosters, complete
  restart validity, exact handle lists and raw names. Replacing a channel,
  erasing a raw name, dropping a connection tail, retaining old bindings or
  using incorrect next-world/seed inputs is rejected by the safe laws.
- Ten native comparisons execute both the preserved prior restart IO body
  and the installed restart operation. Complete world/map/descriptor results,
  returned and actually saved database text, ordered messages for every
  connection, log entries and usable channels agree. Saves run in isolated
  temporary directories, including MAX world-number wrap and Unicode data.
- The newly rebuilt installed game passes both bots, graphical join and host
  autopilots, UTF-8 socket and save reload checks, multiplayer HELLO/CREATE
  rejection/identity behavior, disconnect/reconnect and cosmetic rejection.
  New client and host screenshots were inspected. A separate native
  save/restart test preserves exact purchased cosmetics, coin balance, UTF-8
  name, world number and the complete hall-of-fame payload. Artifact paths
  are recorded in `/private/tmp/bqchannels` transcripts.
- Runtime code changed in this batch and received fresh build/game validation.
  Compiler/kernel and unrelated repository source hashes are unchanged.
  Universal outer IO/delivery/durability and remaining authoritative adapter
  obligations remain open as stated above; finite effect comparisons do not
  close them. Final ledger: `/private/tmp/bqchannels/validated_hashes.json`.

## Stored metadata, map seed and mixed-trace agreement

- `RestartMetadata` adds 16 universal laws over actual admission and
  reconstruction. Its frame masks only `next_player`; phase, world number,
  seed, tick, started/now clocks, sigils, fame and monster cursor are retained.
  This applies to all rosters and failed admissions without a validity or
  capacity premise. Fresh reconstruction has the exact requested world
  number, seed and time; its maps equal `Landscape.maps` of the actual seed.
- `WorldSeed` adds 21 laws through actual combat, payouts, admission, removal,
  all six `PlayerIds.Change` variants, planned ticks and complete `AIRefs`
  ticks. `LifecycleSeed` adds 11 laws through selection, creation, rejected
  commands, disconnect, frame commands and complete tick bindings. These
  seed-preservation statements require no valid-world premise.
- `SeededWorld` adds five laws. Its invariant includes the full existing
  world and bidirectional connection invariant indexed by the actual stored
  seed, together with equality of actual terrain maps to that seed's maps.
  Fresh worlds, pure restarts and the actual affine channel-bearing restart
  preserve it. No connection roster is copied to obtain proof evidence.
- `SeededTrace` adds nine laws extending the existing mixed trace invariant
  with equality between the actual stored seed and the packed seed supplied
  to map-dependent transitions. Arbitrary finite mixed lifecycle, commands,
  ticks and restarts preserve it, including an unconditional fresh-world
  theorem. Conversion to a terrain world retains the exact simulation and
  yields the stronger `SeededWorld.OK` invariant.
- The trace conversion builds maps from its packed seed; it is not itself
  a theorem that every legacy effectful dispatcher retains its terrain map
  field. Actual pure restart maps and its channel-bearing refinement are
  covered. Universal legacy adapter/dispatcher refinement, IO delivery and
  persistence remain open, as do the other five original property scopes.
  All six requested scopes remain open; none has been narrowed or completed.

Stored metadata/map-seed validation (recorded after installation):
- All 62 added laws check in the installed mandatory safe proof closure.
  The original 15 theorem statements are unchanged and remain mandatory.
  All 714 existing JavaScript regression cases pass with the new closure.
- Deliberate metadata mutations are rejected: admission resetting tick or
  seed by `RestartMetadata.advance`, tick seed drift by the existing
  `Simulation.advance_exact`, boss seed drift by `Battle.end_meta_exact`, and
  retaining the old map seed on restart by `RestartTrace.step_ok`. These
  are temporary mutation copies; installed runtime sources were not changed.
- Fresh C emission is byte-for-byte identical to the previously validated
  installed C. All runtime sources, binaries, compiler and kernel hashes are
  unchanged. The previous 202 native cases and fresh bot/GUI/network/save
  evidence in `/private/tmp/bqchannels` therefore still apply to that exact
  runtime; they were not rerun or counted as new tests in this proof-only batch.
- Installed source bytes match the checked stage. Backup and transcripts are
  in `/private/tmp/bqmetadata`; the final source/build/compiler ledger is
  `/private/tmp/bqmetadata/validated_hashes.json`. All six original property
  scopes remain open, with the limits stated above.

## Authoritative clock update and mixed clock/gameplay traces

- `WorldClock` adds 12 safe laws. The actual `set` implementation replaces
  only `Simulation.Meta.now`; `exact` specifies the complete returned terrain
  world for every metadata field, roster and map payload. Additional laws
  prove exact simulation projection, retained map data and seed, installed
  time, last-update-wins, and no-op for the existing time.
- `state_ok` preserves all six components of `WorldState.OK`: health and
  equipment, positions, monster IDs, player/connection IDs, nonzero IDs and
  matching monster references. `connections` retains the full bidirectional
  connection invariant. `seeded` preserves `SeededWorld.OK` indexed by the
  actual world seed and actual retained maps. These proofs do not assume the
  requested time increases, is below MAX, or matches a sampled host clock.
- The server's former generated `Bq.set_now` body is replaced by a direct
  checked delegate to `WorldClock.set`. `RestartTrace.Time` uses the same
  state update. Existing arbitrary mixed trace laws and stronger stored-seed
  trace laws now include this case, preserving all previous input cases.
- `clock_check.bend` retains the original server clock body as its independent
  oracle. Twelve full-world comparisons include waiting/playing/ended/arbitrary
  phases, backwards time, zero/MAX, Unicode, nontrivial player state and map
  payloads. Eight mixed traces cover time updates, ticks, creation, disconnect
  and restart order, checking world number, both seeds, time, tick and bindings.
  Native and JS execution exercise the actual installed server delegate.
- Clock progression, deadlines, wrapping elapsed-time arithmetic and external
  scheduling assumptions remain obligations in their original scopes. This
  state-preservation theorem does not establish cooldown or reward liveness.
  Other authoritative adapters and outer IO/delivery/persistence remain open;
  all six requested scopes are retained and remain open.

Authoritative clock validation (recorded after installation):
- All 12 new laws and the extended mixed-trace laws pass the installed
  mandatory proof gate. The original 15 statements remain byte-for-byte
  unchanged. All 734 JavaScript regression cases pass, including 20 added
  clock/trace cases. The same 20 cases pass natively against the retained
  original clock body and actual new server delegate.
- Four deliberate mutations fail `WorldClock.exact`: retaining old time,
  resetting the seed, resetting the tick and dropping the actual maps.
- The staged native build passes and its exact binary/C are installed.
  Installed sources match the checked stage. Fresh tests of that installed
  binary pass both bots, graphical join/host autopilots, UTF-8 socket and
  save reload, multiplayer session/identity/rejection and protocol checks.
  New client and host screenshots were inspected. A separate save/restart
  test preserves exact cosmetics, coins, Unicode name, world number and the
  hall-of-fame payload. Evidence is in `/private/tmp/bqclock` transcripts.
- Compiler/kernel and unrelated prior source hashes are unchanged. The
  final ledger is `/private/tmp/bqclock/validated_hashes.json`; the backup
  path is in `/private/tmp/bqclock/backup.txt`. Other authoritative adapters,
  outer IO, clock arithmetic/liveness, authentication, persistence and the
  remaining original scope obligations stay open. All six scopes remain open.

## Authoritative tick preparation, maps and affine output

- `LiveTick` adds 16 safe laws and is now on the actual `Bq.tick_world` path.
  Its runtime `run` calls player upkeep once through `Locomotion.begin`,
  then derives per-zone damage lists from that prepared monster roster and
  invokes the existing checked `AIRefs.finish`. Inactive worlds supply empty
  damage lists. The proof specification `at` relates this exact preparation
  to the existing complete tick theorem; it is not used to repeat upkeep at
  runtime. Canonical spawn rules use the same supplied respawn timer.
- `monster_damage.bend` contains the actual catalogue, boss threshold/rarity
  arithmetic and post-monster-tick damage-list calculation. Data and legacy
  world helpers delegate to it. The catalogue fallback remains 42 for kinds
  outside 0..8. Existing U32 multiplication, threshold and rarity wrapping
  behavior is retained. The new state-preservation theorem permits arbitrary
  damage values; it does not prove that those arithmetic expressions cannot
  overflow or that every possible rare flag is reachable.
- Packing retains the complete simulation, actual map data, event list and
  supplied snapshot clock. `run_simulation` refines the actual pipeline;
  `run_maps`, `run_seed`, `run_clock` and `run_events` connect its actual output
  to the input world and prepared computation. `seeded` preserves all world
  and bidirectional connection invariants indexed by the actual stored seed.
  Map equality transports also cover the map-dependent preparation used to
  select damage inputs, rather than assuming an unrelated external seed.
- `emit_world` and `emit_lines` are universal over an arbitrary renderer with
  affine output. The adapter returns the exact checked world and the exact
  renderer list. `run_emitted` proves the full intrinsic world invariant for
  that returned world. The real server uses this adapter with `Bq.render_tick`,
  whose legacy player-event-before-snapshot ordering is retained. It does not
  independently construct or replace the returned world.
- `live_tick_check.bend` preserves the original attack catalogue, boss formula,
  post-tick damage loop and full tick/output pipeline as an independent oracle.
  Fifty JS/native cases compare catalogue/formula boundaries, rare/MAX values,
  regeneration/respawn damage inputs, and complete worlds plus every ordered
  All/To/Zone/Log output. They include multiple zones, lethal simultaneous hits,
  movement, respawns, permanent corpses, cooldown, tick wrap, inactive phases,
  fresh seeds, Unicode, arbitrary retained maps and successive ticks.
- Universal legacy message formatting, socket/channel delivery, the remaining
  command/dispatch adapters and outer effects are still open. This batch does
  not establish combat/reward liveness, authentication or overflow freedom.
  All six original requested scopes remain unchanged and open.

Authoritative tick validation (recorded after installation):
- All 16 new laws pass the installed mandatory safe proof gate with the
  original 15 statements unchanged. All 784 JavaScript regression cases pass.
  Fifty new comparisons also pass natively, including complete returned
  worlds and every ordered output message against the preserved old pipeline.
- A constructive universal witness instantiates the emitted-world theorem
  from actual fresh worlds for every seed, world number, time, respawn timer
  and affine renderer, without an assumed world-validity premise.
- Six deliberate mutants are rejected: maps, rosters, events, snapshot clock,
  formatter-world replacement and dropped renderer output. The map mutant
  keeps its still-true simulation projection proof valid; the actual map
  preservation contract rejects it independently.
- The checked staged native binary/C are installed byte-for-byte. Fresh
  installed game tests pass both bots, graphical join/host autopilots, UTF-8
  socket/save reload, multiplayer session/identity/rejection and protocol
  checks. New client and host screenshots were inspected. A separate native
  save/restart test preserves cosmetics, coins, Unicode name, world number
  and the complete hall-of-fame payload. Transcripts are in
  `/private/tmp/bqlivetick`.
- Compiler/kernel and unrelated prior source hashes are unchanged. The final
  ledger is `/private/tmp/bqlivetick/validated_hashes.json`; backup is recorded
  in `backup.txt` there. Legacy formatter correctness, remaining authoritative
  command/dispatch adapters, IO delivery, reward/combat liveness, authentication,
  arithmetic/accounting, persistence and completion remain open as specified.
  All six original requested scopes remain unchanged and open.

## Live inventory, movement, NPC and portal adapters

- `LiveCommands` adds 17 safe laws. Its result contains the actual terrain
  world and a typed inventory/interaction notice. Inventory uses a single
  `Players.take`, derives shop proximity from the actual selected position,
  and invokes the existing `Inventory.apply_taken`. Interactions use actual
  `Interaction.run`. Explicit `Enter` reads sigils from the received world's
  metadata; the actual server's `cmd_enter` uses that case.
- A full frame equality masks only the player roster, retaining every
  metadata field, the complete monster roster and actual map data. The exact
  simulation refines `PlayerIds.run_change` for the command computed from
  the same received world. This includes the actual inventory near-shop
  choice and the stored sigils used for explicit portal entry.
- `seeded` transports the existing complete command/connection preservation
  proof to the returned terrain world, indexed by its actual stored seed
  and exact retained maps. `trace_seeded` closes arbitrary finite sequences
  of these live commands. The pure input type also permits general hero and
  interaction operations; it is not itself a theorem of wire parser admission.
- Inventory and interaction notices are retained exactly. The generic safe
  emitter returns the checked world and exactly the affine formatter list.
  `run_emitted` proves the full intrinsic invariant on that returned world.
  The live renderer receives data and returns only messages; it cannot replace
  the returned world through this adapter.
- Actual `Bq.cmd_hop`, `interaction_command`, `cmd_enter`, inventory_result and
  interaction_result delegate to the safe implementations/output adapter.
  Existing buy/equip/unequip/allocate/potion and movement/halt/talk wrappers
  therefore use the checked path. Sigil and inventory-nearness helpers are
  safe direct delegates. Legacy message construction retains its old contents
  and ordering; universal formatting correctness remains a separate obligation.
- `live_commands_check.bend` retains original full lookup/result/command
  bodies, including wire item/stat/slot normalization, as independent oracles.
  52 JS/native cases compare complete metadata/player/monster/map state and
  every ordered message. Cases cover shop boundaries and MAX coordinates,
  funded/poor/distant/dead purchases, equipment, charm health changes, potions,
  stat allocation, missing players, direction masks, NPC stages, portal sigils
  and returns, plus consecutive purchases/drinks/talks/equipment/movement.
- This establishes state/refinement/output contracts for the installed pure
  command adapters. Actual combat input selection and adapters, the complete
  wire dispatcher, universal legacy formatting and outer IO/delivery remain
  open. Reward/combat liveness, authentication, arithmetic/accounting, save
  codecs/durability and traversal/completion retain their original scopes.
  All six requested scopes remain unchanged and open.

Live command validation (recorded after installation):
- All 17 new laws check in the installed mandatory safe closure with the
  original 15 statements unchanged. All 836 JavaScript regression cases pass.
  The 52 added cases also pass natively, comparing complete worlds and every
  ordered message against the preserved original command adapters.
- Constructive universal witnesses derive validity after arbitrary live
  command sequences from fresh worlds and actual Connect/HELLO/CREATE traces
  for every world number, seed and time, without an assumed initial-validity
  premise. The latter proves an exact nonempty roster with player ID 1 and
  connection ID 1 before the command sequence. Six deliberate
  mutations of maps, monsters, inventory/interaction notices, emitted world
  and emitted lines are rejected by the new safe contracts.
- The checked staged native binary/C are installed byte-for-byte with the
  validated sources. Fresh installed-game tests pass both bots, graphical
  join/host autopilots, UTF-8 socket and save reload, multiplayer sessions and
  protocol rejection/identity checks. New client and host screenshots were
  inspected. A separate native save/restart test retains exact cosmetics,
  coins, Unicode name, world number and complete hall-of-fame payload.
  Transcripts and artifacts are recorded in `/private/tmp/bqlivecommands`.
- Compiler/kernel and unrelated prior source hashes remain unchanged. The
  final ledger is `/private/tmp/bqlivecommands/validated_hashes.json`; backup
  is recorded in `backup.txt` there. Remaining combat adapters, wire dispatch,
  legacy formatter correctness, outer IO/delivery and the other five full
  requested property scopes remain open. All six scopes remain unchanged.

Live combat admission, planning and output (18 safe laws):
- `live_combat.bend` admits the actual player once using the current world
  phase, supplies that admitted actor and original metadata/monsters to the
  planner, and executes through the existing checked battle transition.
  Planners return only hit inputs and a visual descriptor. The actual attack
  and spin wrappers now delegate to this path, retaining their existing
  targeting, damage, critical-hit and payout calculations.
- The exact simulation result refines `Battle.command`; actual maps and
  stored seed are retained. The full intrinsic `SeededWorld.OK`, including
  bidirectional player/connection correspondence, holds for arbitrary typed
  planners given a valid incoming world. Rejected admission discards all
  supplied hits and visuals and preserves the admitted roster exactly.
  This permits the existing lookup reorder; it is not a claim that rejected
  lookup preserves the original roster's list order.
- Battle notices and accepted visuals are retained exactly. The affine
  renderer returns only messages; the safe emitter retains the result world
  and the renderer's exact ordered list. Actual formatting keeps FX before
  battle notices. Legacy message contents and IO delivery remain open.
- `check-live-combat.sh` runs the 60 new cases natively; `check.sh` runs them
  in JavaScript. The comparisons retain original complete combat adapter
  bodies and compare every world field and ordered message. Cases cover
  empty/missing/dead/cooling/inactive actors, target range/zone/order, lethal
  ordinary/rare/warden/boss hits, spin kill sequences, multiplayer competing
  attacks, repeated commands and deliberately hostile rejected plans.
- All six original proof scopes remain OPEN. This adapter preservation
  theorem does not establish the remaining planner range/zone/damage
  properties, positive reward liveness, authenticated ownership, reachable
  arithmetic/save correctness, all-seed completion, full wire dispatch or
  outer effects. Existing original 15 statements are unchanged.

Live combat validation (recorded after installation):
- All 18 new laws check in the installed mandatory safe closure with the
  original 15 statements unchanged. All 896 JavaScript regression cases pass;
  the 60 added comparisons also pass natively, including every returned world
  field and ordered message against the preserved original combat adapters.
- A constructive universal witness starts from actual Connect/HELLO/CREATE
  for every world number, seed and time, proves the exact nonempty roster,
  and derives the full emitted-world invariant for arbitrary typed combat
  planners and affine renderers. No initial validity premise is assumed.
  Eight deliberate mutations of maps, notices, visuals, accepted hits,
  rejection behavior, emitted world and emitted lines fail the new contracts.
- The checked native C and binary are installed byte-for-byte. Fresh tests
  pass both bots, graphical join/host autopilots, UTF-8 sockets, multiplayer
  sessions, protocol rejection/identity checks and save reload. New client
  and host screenshots were inspected. Separate native save/restart checks
  preserve exact cosmetics, coins, Unicode name, world and hall-of-fame data.
- Transcripts and artifacts are in `/private/tmp/bqlivecombat`; its final
  `validated_hashes.json` records installed files and its `backup.txt` records
  the prior version. Compiler/kernel and unrelated source hashes are intact.
  All six original full scopes remain OPEN, including target/damage planner
  correctness, positive reward liveness, authentication, arithmetic/save
  proofs, all-seed completion, full wire dispatch and outer effects.

Combat target selection and attack plan binding (40 safe laws):
- `combat_targets.bend` has 33 laws for the actual ordered full-record filter
  and short-circuit first selection. Every selected record comes from the
  original monster roster, has the same zone as the supplied player point,
  has dead flag zero, and has actual Chebyshev distance at most one. Conversely,
  every eligible input record is included. The result is an order-preserving
  subsequence and preserves unique monster IDs. First selection equals the
  head of the complete filter; None implies every input record is ineligible.
- With the established unique-MID invariant, looking up any selected ID in
  the original roster returns its exact eligible complete record. These
  witnesses cover both the emitted spin ID list and first attack selection.
  Duplicate-ID inputs retain old selection behavior, but the subsequent
  lookup theorem explicitly requires uniqueness; it is not assumed for
  arbitrary malformed rosters. Eligibility uses the existing dead flag, not
  an added HP predicate. The metric preserves the original U32 max/min formula.
- `target_plans.bend` has 7 laws binding the actual attack input to that first
  record. An affine builder supplies damage/payout only, so it cannot replace
  the selected target ID. Damage, payout and visual fields are retained
  exactly. None builds no inputs and no visual, regardless of the builder.
  This fixes a latent sentinel case: the old planner emitted a hit for ID 0
  on a miss, which could damage an unrelated out-of-range ID-zero monster.
  The fix does not need a nonzero-MID premise. Generated game IDs were already
  nonzero; ordinary gameplay behavior is preserved.
- Actual `Bq.chdist`, `mids_in_reach`, and `mob_in_reach` delegate to the safe
  selectors. Attack uses the Maybe result directly through TargetPlans.attack;
  spin uses the proved ordered ID list. Original catalog damage, critical-hit,
  payout and spin input-building calculations remain as before.
- 56 new JS/native cases compare selectors to preserved original bodies AND
  literal expected full records, IDs and distances; exercise zero/MAX words,
  boundary geometry, duplicate IDs, ordering and all rejection conditions;
  and compare full live command worlds/messages. Six literal miss regressions
  include ID-zero monsters, and a counterexample confirms the original defect.
  The native gate also reruns all 60 live combat comparisons (116 total).
- All six original full scopes remain OPEN. Selected target correctness does
  not close spin hit-plan binding, sequential strike eligibility, damage/
  arithmetic correctness, positive reward liveness, authentication, pure save
  proofs, all-seed completion, the full dispatcher or outer IO. The original
  15 proof statements are unchanged.

Combat selection validation (recorded after installation):
- All 40 new laws check in the installed mandatory safe closure. The original
  15 statements are unchanged. All 952 JavaScript cases pass, and the 56 new
  cases plus all 60 previous live combat comparisons pass natively (116).
- Constructive universal witnesses start from actual Connect/HELLO/CREATE
  for every world number, seed and time, prove the exact nonempty player
  roster, and derive eligible-source/lookup guarantees for the actual spin
  ID list and attack inputs. The unique-MID premise follows from the created
  world invariant rather than being assumed. Nine deliberate mutations of
  eligibility, selection, attack target, missed hits and damage retention fail
  the new contracts. The original ID-zero miss defect is reproduced by a
  regression oracle; literal expected-world tests verify the correction.
- The checked native C and binary are installed byte-for-byte. Fresh tests
  pass both bots, graphical join/host autopilots, UTF-8 sockets, multiplayer
  sessions, protocol rejection/identity checks and save reload. New client
  and host screenshots were inspected. Separate native save/restart checks
  preserve exact cosmetics, coins, Unicode name, world and hall-of-fame data.
- Transcripts and artifacts are in `/private/tmp/bqcombat_targets`; its final
  `validated_hashes.json` records installed files and `backup.txt` identifies
  the prior version. Compiler/kernel and unrelated source hashes are intact.
  All six original full scopes remain OPEN, including spin hit-plan binding,
  sequential combat eligibility, damage arithmetic, positive reward liveness,
  authentication, pure save proofs, all-seed completion, full dispatch and IO.

Indexed spin hit plans (15 safe laws):
- `spin_plans.bend` connects the actual ordered selected monster records to
  the hit list used by Battle.execute. An ordinary affine builder is called
  once on the entire selected list and must return `Powers(selected)`: a
  dependent sequence with exactly one damage/payout payload per record.
  The safe planner takes target IDs directly from those records. It cannot
  silently truncate a short payload list or accept extra payloads.
- `run_ids` proves exact equality between every planned hit ID, in order,
  and the existing selected spin ID list. `run_count` proves exact selected
  record count; `run_powers` retains every builder payload in order. Input
  ID and payload laws establish the corresponding pointwise properties.
  Empty selection gives an empty hit list and the original spin animation;
  ready/run visual laws retain the exact player zone and coordinates.
- Given the established unique-MID invariant, `run_sources` proves each
  actual planned hit points to the eligible complete record subsequently
  found by the battle roster lookup. It composes the earlier filter source,
  completeness/order/uniqueness and lookup proofs. Payload builders cannot
  replace the selected target IDs.
- Actual `Bq.plan_spin` now uses this checked path. Its `spin_powers` callback
  retains the original monster/hero/metadata snapshot and existing damage,
  defense lookup and payout calculations, returning exactly the indexed
  payload structure. Admission and complete battle execution remain on the
  previously checked LiveCombat path. Legacy battle_spin_inputs is retained
  as an independent original-body comparison and for older helper callers.
- 48 new JS/native cases check exact full inputs and visuals, all 11 payout
  fields, distinct ordered payloads, all catalog monster kinds, hero/equipment
  changes, metadata wrap cases, duplicate/zero/MAX IDs, mixed eligibility and
  complete live worlds/messages for multi-kill and multiplayer sequences.
  The native gate also reruns the previous60 live combat cases (108 total).
- All six original full scopes remain OPEN. Binding each planned hit to an
  initially eligible target does not prove all later sequential strike/phase
  behavior, damage arithmetic/catalog semantics, positive reward liveness,
  authentication, pure save correctness, all-seed completion, full dispatch
  or outer IO. The original15 proof statements are unchanged.

Indexed spin planning validation (recorded after installation):
- All 15 new laws check in the installed mandatory safe closure. The original
  15 statements are unchanged. All 1000 JavaScript cases pass. The 48 new
  cases plus the previous60 live combat comparisons pass natively (108).
- Constructive universal witnesses start from actual Connect/HELLO/CREATE
  for every world number, seed and time, prove the exact nonempty player
  roster, and derive eligible-source/lookup guarantees and exact target order
  for the actual spin input list. The unique-MID premise follows from the
  created world invariant, with no assumed initial-validity premise.
- Seven deliberate mutations of IDs, damage, payout, list tail/order, visual
  and selection fail the safe contracts. Two malformed @unsafe payload
  builders (too short/too long) are rejected by the dependent result type.
  Runtime cases compare all damage/payout fields with the preserved original
  calculator using varied hero, monster and metadata snapshots, plus exact
  literal payloads and complete multiplayer worlds/messages.
- The checked native C and binary are installed byte-for-byte. Fresh tests
  pass both bots, graphical join/host autopilots, UTF-8 sockets, multiplayer
  sessions, protocol rejection/identity checks and save reload. New client
  and host screenshots were inspected. Separate native save/restart checks
  preserve exact cosmetics, coins, Unicode name, world and hall-of-fame data.
- Transcripts and artifacts are in `/private/tmp/bqspin_plans`; its final
  `validated_hashes.json` records installed files and `backup.txt` identifies
  the prior version. Compiler/kernel and unrelated source hashes are intact.
  All six original full scopes remain OPEN, including sequential combat
  eligibility, damage arithmetic, positive reward liveness, authentication,
  pure save proofs, all-seed completion, full dispatch and outer IO.

Sequential combat frame (22 safe laws, proof-only change):
- `combat_frame.bend` proves exact equality of all non-target monster records
  before and after an actual strike, including every field and their relative
  order. It removes only the struck MID for this comparison. This frame law
  needs no health, uniqueness or eligibility premise and extends through the
  actual battle/reward transition using existing exact monster-list results.
- Membership lemmas ensure the erasure cannot hide unrelated records. An
  eligible complete record whose ID differs from the struck ID remains the
  same eligible record afterward. This holds through arbitrary finite lists
  of other-ID hits, and unique monster IDs give exact subsequent roster lookup.
- `Execution` indexes each hit's source/lookup witness by the actual state
  immediately before that hit, recursively using `Battle.strike`. The
  `spin_execution` theorem derives these witnesses for the actual spin hit
  list and arbitrary indexed payload builders. Distinctness is discharged
  from the existing unique-MID invariant and proved filter uniqueness; no
  extra caller assumption about untouched future targets is introduced.
- Eligibility here uses the fixed point of the admitted action. Relating
  this point to every intermediate attacker position, full phase/cooldown
  behavior and finalization remains separate. In particular, the existing
  battle executor continues an admitted spin after a boss changes phase;
  this proof does not declare that full phase/finalization goal satisfied.
- The original15 statements and runtime source are unchanged. All six full
  scopes remain OPEN: full authoritative dispatch/IO, rewards exactly once
  AND positive liveness including reload/respawn, all combat eligibility,
  authenticated ownership, reachable arithmetic/pure save correctness and
  all-seed completion. Planned and intermediate monster-source correctness
  does not close those complete requirements.

Sequential combat frame validation (recorded after installation):
- All 22 new laws and the complete mandatory safe proof closure pass both
  staged and installed checks. The original 15 proofs and statements remain
  unchanged. Four constructive probe laws check, including a nonempty player
  created by Connect/HELLO/CREATE for arbitrary world, seed and time, and the
  resulting intermediate spin sources with uniqueness derived from WorldOK.
- A concrete boss kill changes phase to 2 while preserving exact subsequent
  lookup of an unrelated eligible monster through the actual reward path.
  This demonstrates the theorem's scope without assuming phase remains active.
- Three negative checks reject the intended invalid obligations: using the
  old world in the recursive execution proof, declaring the struck record's
  ID different, and fabricating uniqueness for duplicate monster IDs.
- Generated main C is byte-for-byte identical to the previously validated
  installed C. No runtime sources, C artifact or native binary changed. The
  previous 1000 JavaScript / 108 native checks and fresh graphical, bot,
  session, protocol and save tests therefore remain applicable to this exact
  runtime; they were not rerun in this proof-only batch.
- Evidence, backup location and final installed hashes are recorded under
  `/private/tmp/bqcombat_frame`. Compiler/kernel and unrelated hashes match
  the preceding ledger. All six full proof scopes remain OPEN.

Current attacker across battle execution (21 safe laws, proof-only change):
- `combat_actor.bend` lifts the exact existing payout frame through player
  reordering, rewards and every actual battle strike. Each original roster
  member has a current record with the same PID, CID, full position, HP,
  death/respawn state, both cooldowns, cosmetics and name. Hero progression,
  XP, quests and scores may change, as intended. No uniqueness or health
  premise is needed for this existence/frame-preservation result.
- `Actor.Execution` strengthens the preceding fixed-point combat theorem:
  every hit has an actual player record in its intermediate world, equal PID
  and exact preserved frame, plus an eligible monster lookup relative to
  that current player's own zone/x/y. The theorem derives this for the actual
  indexed spin list from an initial actor member and unique monster IDs.
- `point_of` explicitly identifies the projection with the zone/x/y fields
  read by the live planner. The callback still supplies only indexed damage
  and payout payloads. Final actor frame preservation also holds for arbitrary
  finite hit lists, including boss rewards and level-ups.
- This discharges intermediate attacker-position framing. Connecting all
  accepted live-dispatch branches and admission outcomes remains work, as do
  phase/finalization, mixed tick schedules and the remaining full scopes.
  All six original requirements remain OPEN; no runtime source changed.

Current-attacker validation (recorded after installation):
- All 21 safe laws and the mandatory proof suite pass staged and installed.
  The original15 statements are unchanged. Eight constructive laws check:
  four preceding monster-frame witnesses and four actor witnesses, including
  an arbitrary-world/seed/time Connect/HELLO/CREATE origin, a concrete boss
  kill which levels the attacker to2, final frame preservation, and a nonempty
  two-hit spin indexed by each actual current attacker/world.
- Three negative checks fail at their intended obligations: omitting the
  current-position transport, using the old world in recursive execution,
  and equating the actor's position with a moved record's position.
- Generated game C is byte-for-byte identical to the installed validated C.
  Runtime sources, C and native binary are unchanged. The earlier 1000JS,
  108native and fresh GUI/bot/session/protocol/save results are inherited
  evidence for this exact runtime, not checks rerun in this proof-only batch.
- Evidence, backup location and final installed hashes are recorded under
  `/private/tmp/bqcombat_actor`. Compiler, kernel, original proofs and all
  unrelated file hashes remain intact. All six full scopes remain OPEN.

Actual admitted actor and command PID (14 safe laws, proof-only change):
- `combat_admitted.bend` proves that every Some actor returned by actual
  Combat.run is the exact record present in the updated roster and has the
  requested command PID. This follows from actual take/prepare/finish and
  needs no world-validity or uniqueness premise. Rejections remain None.
- The law reaches actual LiveCombat.prepare and LiveCombat.run. Any accepted
  actor retains the previous exact payout frame in the actual resulting world
  for any supplied planner and hit list. The affine planner is called once.
- Admitted.Sequence indexes every hit by Battle.strike with the command PID,
  while retaining a current-player membership/identity/frame and eligible
  monster lookup at that player's current position. The equality derived by
  admission connects this to Actor.Execution; spin_sequence derives it for
  indexed spin payloads using admitted membership and unique monster IDs.
- This proves admission-to-actor correspondence and final actor preservation
  through the live adapter. It does not prove arbitrary planner target safety:
  the intermediate-target theorem specifically requires the indexed spin list.
  Binding every live planner/dispatcher branch remains work, along with phase,
  finalization, scheduling and all remaining full scopes. All six remain OPEN.

Admitted-actor validation (recorded after installation):
- All14 safe laws and the full mandatory proof closure pass staged and
  installed. Original15 statements remain unchanged. Thirteen constructive
  probe laws pass: preceding monster/actor witnesses plus arbitrary fresh
  Connect/HELLO/CREATE followed by exact successful spin admission, actual
  LiveCombat.prepare validity, final actor preservation through LiveCombat.run
  for an arbitrary planner, a nonempty admitted two-hit spin, and rejection
  of an immediate repeated spin with the stamped cooldown.
- Three negative checks reject the intended obligations: removing the
  command-PID equality transport, claiming an accepted actor belongs to an
  empty roster, and replacing the accepted actor with its unstamped record.
- Generated main C is byte-for-byte identical to the installed validated C.
  No runtime source, C artifact or native binary changed. Previous1000JS,
  108native and fresh GUI/bot/session/protocol/save results remain applicable
  to this exact runtime; they were not rerun in this proof-only batch.
- Evidence, backup and final hashes are under `/private/tmp/bqcombat_admitted`.
  Compiler/kernel and unrelated hashes match the previous ledger. All six
  original full proof scopes remain OPEN.

Checked live spin planner (7 safe laws and actual runtime integration):
- `live_spin.bend` is now the function called by Bq.plan_spin. It selects
  the exact admitted actor, that actor's zone/x/y, and the complete original
  monster and metadata snapshots. Rejected admission returns no inputs and
  Quiet; accepted admission delegates to the existing indexed SpinPlans.run.
- The ordinary affine builder receives those exact snapshots and can supply
  only damage/payout payloads indexed by the selected complete monster list.
  Bq.live_spin_powers forwards the actor's hero to the unchanged calculator.
  Target selection, actor choice and list construction are in the safe module.
- The prepared_checked theorem follows actual LiveCombat.prepare and derives
  a command-PID-indexed sequence of eligible target lookups at each current
  actor's position. Its only world premise is unique monster IDs; admission
  membership/PID is derived, not assumed. The live_actor theorem also reaches
  the actual LiveCombat.run final world with this planner.
- Damage/catalog arithmetic, phase/finalization and full command dispatch
  remain separate obligations. Arbitrary builder payloads are not declared
  semantically correct rewards. All six original full scopes remain OPEN.

Live spin planner validation (recorded after installation):
- All7 new laws and the mandatory safe proof closure pass. Original15 proofs
  and statements are unchanged. All1020 JavaScript cases and128 native cases
  pass (20 new live planner cases plus previous48 spin and60 live combat).
- New cases check exact literal forwarding of full monster/actor/metadata
  snapshots, selecting a later roster player, first duplicate PID selection,
  independent/MAX attack cooldown, empty admitted animation, zero/MAX actor
  IDs and boundary metadata. Six rejection cases and six comparisons against
  the preserved previous complete planner also pass. The snapshot fixture's
  actual HP is35; its initially incorrect expected30 was corrected before gates.
- Sixteen constructive probe laws check, including arbitrary created-world
  admission, the checked live plan from actual prepare with uniqueness derived
  from WorldOK, and an exact nonempty two-hit plan with intermediate current
  actor/target witnesses. Four mutations fail intended contracts: wrong point,
  empty target snapshot, lost builder snapshot and visual on rejection.
- The validated native C and binary are installed byte-for-byte. Fresh combat
  and shop bots, graphical join/host autopilots, UTF-8 sockets, savedDB reload,
  session/identity/protocol cases and exact native save/restart checks pass.
  Fresh client and host screenshots were inspected.
- Evidence, backups and final hashes are in `/private/tmp/bqlive_spin`.
  Compiler/kernel and unrelated sources retain their prior hashes. All six
  original full proof scopes remain OPEN.

Checked live attack planner (11 safe laws and actual runtime integration):
- `live_attack.bend` is now the function called by Bq.plan_attack. It selects
  the exact admitted actor, reads its proved zone/x/y and facing direction,
  and chooses Targets.first from the actual full monster snapshot. Rejection
  and a missing eligible monster produce exactly empty inputs and Quiet.
- A single ordinary affine factory receives the actual monsters, actor,
  metadata and command PID. It returns a critical word and an affine payload
  closure. TargetPlans.attack calls that closure only for the selected monster
  and binds the monster ID itself. The factory cannot supply target IDs or
  replace the hit list. Existing critical and damage/payout formulas remain
  in Bq.live_attack_power/Bq.attack_power unchanged.
- The safe proofs identify the exact accepted plan and establish its current
  actor/eligible-monster witness in the command-indexed execution sequence.
  prepared_checked follows actual LiveCombat.prepare, deriving admitted actor
  membership and PID correspondence. Its only world premise is unique MIDs.
  live_actor reaches actual LiveCombat.run with this planner and final frame
  preservation. Missing targets produce no hit; eligible MID0 is a real hit.
- These proofs constrain selection, snapshots and effects. They do not prove
  arbitrary payloads implement the intended damage/reward arithmetic or all
  critical-probability properties. Full dispatch, phase/finalization, schedules
  and the other original requirements remain work. All six scopes stay OPEN.

Live attack planner validation (recorded after installation):
- All11 new safe laws and the installed mandatory proof closure pass; original15
  proofs and statements remain unchanged. All1044 JavaScript cases and140 native
  cases pass (new24 attack cases, previous56 target and60 live combat cases).
- The new cases compare exact snapshot payloads and every attack visual field,
  including critical word and direction. They cover selected later players,
  duplicate IDs, independent/MAX spin cooldown, zero/MAX actor IDs, boundary
  metadata, missing/dead/cooling actors, ended phase, empty/distant targets and
  eligible MID0. Eight comparisons use the preserved previous complete planner,
  including a Ready with differing actor/command PID to check exact roll inputs.
- Twenty constructive probe laws check, including successful attack admission
  after arbitrary-world/seed/time Connect/HELLO/CREATE, checked live planning
  with uniqueness derived from WorldOK, and an exact nonempty critical attack
  plan with its current actor/target execution witness. Six mutations reject
  wrong direction, missing target, lost critical word, wrong command PID,
  lost monster snapshot and an effect on rejection at their intended laws.
- The validated native C and binary are installed byte-for-byte. Fresh combat
  and shop bots, graphical join/host autopilots, UTF-8 exchange, savedDB reload,
  session/identity/protocol checks and exact native save/restart checks pass.
  Fresh client and host screenshots were inspected.
- Evidence, backups and final hashes are in `/private/tmp/bqlive_attack`.
  Compiler/kernel and unrelated sources retain their prior hashes. All six
  original full proof scopes remain OPEN.

Immediate repetition after completed combat (22 safe laws, proof-only change):
- `combat_repeat.bend` proves exact player lookup from full-record membership
  and unique player IDs, including membership behind earlier roster entries.
  The lookup returns the actual updated player, not merely a matching ID.
- Actual Combat.run acceptance gives the exact stamped cooldown (4 attack or
  25 spin). The existing complete payout frame transfers that cooldown through
  all hits, rewards, level-ups and reordering to the final accepted actor.
- Repeat.live_twice follows two actual LiveCombat.run calls for either kind,
  with arbitrary first and second affine planners. If the first admission is
  Some, the second result is exactly Repeat.quiet: unchanged metadata, maps and
  monsters, no notices or combat visual, and the same complete player records
  restored after lookup. Players.take_restores proves this is a permutation.
  The initial premise is unique player/connection IDs; final uniqueness is
  derived through the actual command. No health or monster premise is needed.
- The theorem concerns immediate repetition after accepted admission. It does
  not assume ticks, respawn or arbitrary intervening commands preserve cooldown,
  and does not settle sequences whose first admission was rejected. Those and
  mixed schedules, phase/finalization and all remaining full scopes stay open.
  All six original full requirements remain OPEN. No runtime source changes.

Completed-combat repetition validation (recorded after installation):
- All22 safe laws and the mandatory installed proof closure pass. Original15
  statements remain unchanged. Twenty-six constructive probe laws pass:
  previous20 witnesses plus arbitrary-created-world repetition for either
  command kind, exact immediate repeated spin/attack results with a hostile
  second plan, a first spin which kills and levels its actor to2 while phase
  stays1, and exact lookup of a full player behind another roster entry.
- The concrete repetition witnesses use actual checked LiveSpin/LiveAttack
  planners and a player initially behind another player; their unique-ID
  witness is explicit. The universal created-world witness extracts uniqueness
  from the actual Connect/HELLO/CREATE SeededWorld.OK proof, with no assumed
  initial validity. Existing exact admission probes rule out vacuous rejection.
- Four negative checks fail at the intended obligations: returning a stale
  frame's cooldown proof, reusing the old world for repetition, claiming a
  fresh zero-cooldown actor is locked, and fabricating duplicate-player uniqueness.
- Generated main C is byte-for-byte identical to the installed validated C.
  Runtime sources and native binary remain unchanged. Previous1044JS/140native
  and fresh bot/GUI/session/protocol/save checks remain applicable to this exact
  runtime; they were not rerun in this proof-only batch.
- Evidence, backups and final hashes are under `/private/tmp/bqcombat_repeat`.
  Kernel/compiler and unrelated hashes match the previous ledger. All six full
  scopes remain OPEN, including rejected-first-command and intervening-tick/
  respawn/other-command scheduling obligations beyond this accepted-repeat law.

Repetition regardless of initial admission (12 safe laws, proof-only change):
- `combat_rejected.bend` proves that replaying actual Combat.run on its own
  updated roster rejects the next same-kind request. Missing lookup is proved
  to mean absence, including a nonempty roster; found players use actual
  prepare_repeat and exact target-ID preservation. This admission-only result
  needs no validity or uniqueness premise and covers accepted or rejected input.
- Rejected.Inert specifies every world field and complete player record:
  metadata, maps and monsters are unchanged; players form a proved permutation
  of the original complete records; notices are Nil and visual is Quiet.
- Rejected.live_twice combines both first-admission branches through two actual
  LiveCombat.run calls. With unique initial player/connection IDs, arbitrary
  planners and scores, an immediate same-kind/PID retry is Inert. There is no
  accepted-first premise or Unit branch in this final theorem. The previous
  stronger exact quiet-result law for accepted-first remains intact.
- This closes the rejected-first gap in immediate same-kind repetition. It
  does not cover intervening ticks, respawn, clock updates or other commands;
  those require separate composition. All six original full scopes remain
  OPEN, including mixed scheduling, phase/finalization, full dispatch/IO,
  authenticated ownership, arithmetic/save and all-seed completion.

Unconditional immediate repetition validation (recorded after installation):
- All12 safe laws and the mandatory installed proof closure pass. Original15
  statements remain unchanged. Thirty-five constructive probe laws pass:
  previous26 witnesses plus arbitrary-created-world unconditional repetition
  for both kinds/any planners, accepted spin/attack cases, five rejected-first
  cases (missing, dead, cooling, inactive and empty), and a closed assertion
  that those five first admissions actually return None.
- The universal witness extracts unique IDs from the actual fresh-world
  Connect/HELLO/CREATE invariant. The final Inert theorem has no accepted-first
  condition; its constructor includes a proved permutation of complete player
  records and exact world/notices/visual equality. Existing accepted-first
  tests still include kills and level-up while phase stays active.
- Four negative checks reject discarding the rejected branch's proof, using
  the original world instead of the first result, supplying a combat visual,
  and changing phase while claiming Inert. Intended type errors were inspected.
- Generated main C is byte-for-byte identical to the installed validated C.
  Runtime sources and native binary remain unchanged. Previous1044JS/140native
  and fresh bot/GUI/session/protocol/save checks remain applicable to this exact
  runtime; they were not rerun in this proof-only batch.
- Evidence, backups and final hashes are under `/private/tmp/bqcombat_rejected`.
  Kernel/compiler and unrelated hashes match the prior ledger. The rejected-first
  gap in immediate repetition is closed. Intervening ticks, respawn, clock updates,
  other commands and all six full original scopes remain OPEN.

Clock updates between combat commands (7 safe laws, proof-only change):
- `combat_clock.bend` composes the actual WorldClock.set used by Bq.set_now
  with two actual LiveCombat.run calls. It proves a same-kind/PID retry is
  Rejected.Inert relative to the clock-updated first result, whether the first
  command was accepted or rejected. Only initial player/connection uniqueness
  is required; arbitrary timestamps, scores and affine state-dependent planners
  are quantified. Full records are preserved up to roster permutation, with
  no notices or combat visual. The new clock value is retained.
- The accepted branch transports the proved actor cooldown and derived final
  uniqueness through exact roster preservation. The rejected branch transports
  actual admission replay through unchanged phase. Neither branch assumes
  its required postcondition. Callback plans are evaluated once on each actual
  prepared world, including the clock update before the second preparation.
- Server inspection: Bq.loop sets now before Bq.drain(64,...) and normally
  ticks after draining. This is a theorem about the clock setter composition;
  it does not assert that server loops omit their gameplay ticks.
- This closes the clock-only gap in two-command repetition, including all U32
  timestamps without monotonicity assumptions. Intervening gameplay ticks,
  respawn and other commands, finite spam traces, phase/finalization and all
  six original full scopes remain OPEN.

Clock-combat repetition validation (recorded after installation):
- All7 safe laws and the full mandatory installed proof closure pass. Original15
  statements remain unchanged. Forty-five constructive probe laws pass:
  previous35 plus arbitrary-created-world clock repetition for both command
  kinds/any planners/timestamps, seven accepted/rejected fixtures each quantified
  over time, exact full results at timestamps0 and U32.MAX, and literal clock
  retention checks at0, U32.MAX and201. Creation uniqueness comes from the
  actual Connect/HELLO/CREATE invariant; accepted fixtures really kill/level up.
- Four intended type failures reject discarding the rejected-first branch,
  omitting the clock setter from the second world, preserving the old timestamp
  while claiming Inert relative to the new world, and claiming a fresh actor's
  zero spin cooldown equals the stamped delay. Error locations were inspected.
- Generated main C is byte-for-byte identical to the installed validated C.
  Runtime sources and native binary remain unchanged. Previous1044JS/140native
  plus fresh bot/GUI/session/protocol/save checks from bqlive_attack remain
  evidence for this exact runtime; they were not rerun in this proof-only batch.
- Evidence, backups and final hashes: `/private/tmp/bqcombat_clock`.
  Kernel/compiler and unrelated hashes match the previous ledger. The clock-only
  two-command gap is closed; gameplay ticks/respawns/intervening commands and
  all six original full requirements remain OPEN.

Finite same-kind/PID combat streams (5 safe laws, proof-only change):
- `combat_spam.bend` defines a finite list of affine requests, each carrying
  its own timestamp, score and state-dependent planner. Spam.trace applies
  actual WorldClock.set and LiveCombat.run to the previous actual result.
  Every entry records that command's input world and complete output result.
- Spam.safe proves every entry after the first is Rejected.Inert: complete
  player records are preserved up to permutation, all other world fields retain
  their per-command values (including the new clock), notices are Nil and
  visual is Quiet. It quantifies over any finite request list, either combat
  kind and any PID, with only initial player/connection uniqueness. Neither
  successful initial admission nor assumed post-command uniqueness is required.
- Spam.tail proves the stronger suffix theorem after a real completed command.
  Each induction step derives uniqueness of its input from actual previous
  combat and clock operations, then applies CombatClock.live_twice. Affine
  planners are evaluated once on each actual prepared world; their resulting
  Data plans are shared with the proof. The Request timestamp/score fields
  are explicitly shared as Data; callback functions remain affine.
- Exact nil/cons equations pin the executor to actual LiveCombat.run, and
  Spam.length proves one complete entry per request. This prevents silently
  dropping requests from the specified stream while claiming finite coverage.
- This closes finite same-kind/PID retry composition with arbitrary clock
  writes and no intervening gameplay transitions. Mixed kinds/players, ticks,
  respawn, phase/finalization, live dispatcher/IO and all six full original
  requirements remain OPEN. This proof helper does not replace the server loop.

Finite combat stream validation (recorded after installation):
- All5 safe laws and the full mandatory installed proof closure pass. Original15
  statements remain unchanged. Fifty-nine constructive probe laws pass:
  previous45 plus actual-created-world safety for arbitrary affine request lists
  and either kind; exact observation of current timestamp/score by a planner;
  empty/singleton streams; five-request attack/spin and missing/dead/cooling/
  inactive/empty streams; exact full logs for both accepted-first kinds; and
  exact five-entry length. Creation uniqueness is derived from actual
  Connect/HELLO/CREATE, not assumed as an extra fixture premise.
- Concrete retry clocks are201, U32.MAX,0,250; scores also vary to0 and MAX.
  The state-dependent retry planner attempts further damage/rewards/visuals.
  Exact result logs show each retry retains the first command's complete
  post-world except the newly set clock; no further notices/visuals occur.
  Prior witnesses establish that the first accepted spin kills and levels up.
- Four negative checks fail at intended obligations: omitting the recursive
  suffix proof, feeding subsequent requests an old world, an executor that
  drops requests (rejected by the independent length proof), and claiming the
  actually accepted first combat command is itself Inert. Errors inspected.
- Generated main C is byte-for-byte identical to the installed validated C.
  Runtime sources and native binary remain unchanged. Previous1044JS/140native
  plus fresh bot/GUI/session/protocol/save checks from bqlive_attack remain
  evidence for this exact runtime; not rerun in this proof-only batch.
- Evidence, backups and final hashes: `/private/tmp/bqcombat_spam`.
  Kernel/compiler and unrelated hashes match the previous ledger. Finite
  same-kind/PID retry composition with clock updates is now proved. Mixed
  commands/players, intervening gameplay ticks/respawns and all six original
  full requirements remain OPEN.

Player cooldown upkeep and availability (28 safe laws, proof-only change):
- `cooldown_tick.bend` pins both combat counters through actual Vitals.live_tick,
  wait, fall, revive, hit and upkeep, then actual Players.upkeep and Players.hurt.
  Live upkeep decreases each counter by one with saturation; hits including
  lethal hits preserve them; dead waiting preserves them; readiness at actual
  respawn<=1 resets them. The player refinement pins the vital state inside
  actual movement and hero-based healing; vital upkeep equations also pin
  revival flags and the real readiness test.
- Cooldown.dec proves the actual U32 decrement equals natural predecessor,
  using the proved word conversion boundary; it never assumes wrapping
  subtraction. Cooldown.run performs actual Players.upkeep for arbitrary finite
  lists of movement plans, tick words and spawn coordinates. For an initially
  living player, run_alive and run_exact derive final liveness flag and exact
  saturated cooldown subtraction by the number of upkeep steps.
- Cooldown.run_ready is positive availability: if the number of actual living-
  player upkeep steps reaches the initial cooldown, actual Combat.prepare in
  phase1 accepts and stamps the cooldown again. The final zero counter and
  living flag are derived, not supplied as final-state assumptions.
- This is the player-upkeep and damage layer. It does not assert that arbitrary
  full-world ticks leave a player alive: AI damage follows upkeep and can kill;
  inactive world ticks skip upkeep. Whole-roster correspondence, full tick/AI
  composition, respawn scheduling, mixed commands and all six original full
  requirements remain OPEN.

Player cooldown upkeep validation (recorded after installation):
- All28 safe laws and the mandatory installed proof closure pass. Original15
  statements remain unchanged. Seventy-five constructive probe laws pass:
  previous59 plus arbitrary upkeep streams after cooldown stamping and after
  actual Connect/HELLO/CREATE; literal attack4,3,2,1,0,0 and spin25,24,1,0,0
  boundaries; positive acceptance at4/25; rejection one step earlier and in
  inactive phase after expiry; dead wait with counters intact; full actual
  revival result/event/position/reset counters; renewed combat availability;
  lethal damage retaining both counters; arbitrary player/damage/kind frame;
  and arbitrary additional upkeep keeping an expired cooldown at zero.
- Five intended type failures reject using the pre-upkeep player in induction,
  claiming readiness after3 attack upkeep steps, decrementing a dead waiting
  player's counters, retaining a stamped cooldown after revival, and clearing
  a cooldown on lethal damage. Error locations and mismatches were inspected.
- Generated main C is byte-for-byte identical to the installed validated C.
  Runtime sources and native binary remain unchanged. Previous1044JS/140native
  plus fresh bot/GUI/session/protocol/save checks from bqlive_attack remain
  evidence for this exact runtime; not rerun in this proof-only batch.
- Evidence, backups and final hashes: `/private/tmp/bqcooldown_tick`.
  Kernel/compiler and unrelated hashes match the previous ledger. Exact living
  player upkeep decay and positive availability are proved, together with
  damage/death/wait/revival counter rules. Complete world tick/AI/roster
  composition and all six original full requirements remain OPEN.

ID-paired cooldowns through complete live ticks (25 safe laws, proof-only):
- `cooldown_roster.bend` projects each player to one Frame containing PID, CID,
  attack and spin together. A standard constructive permutation relates whole
  frames; ID and counter lists cannot be independently permuted. Projection
  and permutation cardinality laws independently exclude omitted records.
- The ordered-hit proof follows actual Players.take/hit_taken/strike/apply_hits,
  including missing targets and lethal/repeated hits. It preserves complete
  ID-and-counter records while admitting the actual lookup roster permutation.
- Upkeep has an exact per-record specification based solely on the old death
  flag and respawn counter: living branch decrements both counters, dead waiting
  preserves them, respawn<=1 clears them. It proves actual Players.upkeep_all
  matches this specification, including default movement plans when absent.
- Composition reaches Simulation.begin/finish/tick, movement and monster
  planning, selected AI contexts/damage and finally actual LiveTick.run.
  TickCooldown.live quantifies over every world and timer: final player frames
  are a permutation of the specification computed from initial players and
  actual phase. No assumed final cooldowns, survival, uniqueness or AI-plan
  predicates are required. Inactive phases preserve initial frame records.
- This closes the exact one-live-tick roster cooldown composition obligation.
  It does not prove an arbitrary player survives the tick or remains combat-
  eligible: AI can kill after upkeep. Multi-tick identity/survival/respawn
  scheduling, mixed commands and all six full original scopes remain OPEN.

Live-tick cooldown roster validation (recorded after installation):
- All25 safe laws and the mandatory installed proof closure pass. Original15
  statements remain unchanged. Ninety-one constructive probe laws pass:
  previous75 plus arbitrary-created-world actual LiveTick.run; arbitrary ordered
  hits; missing/repeated/zero-ID hits; missing movement plans; full Simulation.tick
  and live tick permutation proofs and exact literal frame lists; actual lethal
  damage and revival event lists in both tick paths; inactive/empty ticks;
  paired record cardinality; and explicit live target eligibility.
- The live fixture contains three players with different PID/CID/cooldown pairs:
  a waiting corpse retains6/8, a ready corpse revives with0/0, and a living player
  decrements4/25 to3/24 before an actual monster hit kills it. Target lookup moves
  that last player to the head. Full frame lists and revival/death events match.
  The target is at14,8 outside the village. The first fixture at6,4 was correctly
  excluded by village protection; it was corrected, not accepted as a hit test.
- Five intended failures reject an unjustified fixed-order equality after hits,
  dropping frame records, reassigning counters between distinct IDs, applying
  upkeep decay in inactive phase, and decrementing a dead waiting counter.
  Every final rejection has its intended type-error location; failed fixture
  attempts were resolved before rerunning the negative suite.
- Generated main C is byte-for-byte identical to the installed validated C.
  Runtime sources and native binary remain unchanged. Previous1044JS/140native
  plus fresh bot/GUI/session/protocol/save checks from bqlive_attack remain
  evidence for this exact runtime; not rerun in this proof-only batch.
- Evidence, backups and final hashes: `/private/tmp/bqcooldown_roster`.
  Kernel/compiler and unrelated hashes match the previous ledger. Exact complete
  one-live-tick cooldown evolution is proved with IDs paired to both counters.
  Multi-tick/command scheduling, survival/respawn obligations and all six original
  full requirements remain OPEN.

Individual cooldown tracking and finite live-tick histories (19 safe laws):
- `cooldown_actor.bend` transfers full Frame membership through the constructive
  roster permutation and recovers an actual player record with membership in
  the final full roster. Tracked.live gives Tracked.Observed for the expected
  PID/CID/attack/spin frame from any initial player membership, without assuming
  survival, health, uniqueness or a particular AI branch.
- Projection/source/reification proofs connect original player membership to
  the expected frame and back to the final player, including missing-list
  contradictions and reordered records. Expected frames preserve the original
  PID and CID. Tracked.Lookup additionally pins actual Players.take by PID to
  Some of that full player and retains its roster membership and frame equality.
- Tracked.seeded_lookup derives final PID uniqueness from actual LiveTick.seeded
  and the initial SeededWorld.OK, then proves the exact lookup. Final validity,
  presence and counters are not supplied as postconditions.
- Tracked.follow proves a Trace for any finite list of actual live ticks. Each
  step stores the actual next player, membership in that tick's actual world,
  and the exact cooldown frame computed from the preceding player/phase. Its
  recursive tail uses the world returned by LiveTick.run, not a stale snapshot.
  Done requires both an empty input list and actual current membership. The
  affine observation eliminator passes each recovered record into the proof.
- Each input U32 is that tick's death/respawn delay, not a clock timestamp.
  Gameplay tick advancement, target selection and monster attacks remain the
  actual LiveTick operations. Histories include death/wait/revival rules and
  inactive phases; they do not assume every tick decrements a cooldown.
- This closes per-player existence/frame tracking over finite tick histories
  and exact valid-world one-tick lookup. Quantitative availability across mixed
  command/tick/survival schedules, authenticated ownership and all six original
  full requirements remain OPEN.

Tracked player cooldown validation (recorded after installation):
- All19 safe laws and the mandatory installed proof closure pass. Original15
  statements remain unchanged. One hundred three constructive probe laws pass:
  previous91 plus exact tracked lookup after arbitrary-seed Connect/HELLO/CREATE;
  finite histories for arbitrary tick lists from those created worlds; actual
  living/waiting/reviving/inactive player observations; zero-tick, death/respawn,
  varying-death-timer and inactive histories; literal PID lookup vital states
  across a four-tick lifecycle; and exact full-record lookup after lethal damage.
- The lifecycle checks use actual LiveTick.run with death timer2: the same PID
  begins atHP1/cooldowns4/25, dies with3/24 and timer2, waits with3/24 and timer1,
  revives atHP35 with0/0, and remains alive at0/0 on the next tick. Exact Some
  lookup results rule out missing-player fallback and track the actual record.
- Five intended type failures reject reading the original roster as the final
  roster, skipping a nonempty tick history, passing a stale world to its tail,
  claiming lookup selects the second differing record under duplicate PIDs,
  and recovering a player from an empty roster. Error locations inspected.
- Generated main C is byte-for-byte identical to the installed validated C.
  Runtime sources and native binary remain unchanged. Previous1044JS/140native
  plus fresh bot/GUI/session/protocol/save checks from bqlive_attack remain
  evidence for this exact runtime; not rerun in this proof-only batch.
- Evidence, backups and final hashes: `/private/tmp/bqcooldown_actor`.
  Kernel/compiler and unrelated hashes match the previous ledger. Individual
  cooldown frame tracking through arbitrary finite live-tick histories and
  valid-world one-tick PID lookup are proved. Mixed-command scheduling and
  quantitative survival/availability obligations, plus all six original full
  requirements, remain OPEN.

Other-kind commands preserve protected cooldowns (16 safe laws, proof-only):
- `combat_other.bend` pairs each player PID/CID with the cooldown of the kind
  other than the intervening command. Other.prepare preserves this frame through
  actual admission. Original full-player membership follows the actual take
  permutation; replacement distinguishes selected-head and untouched-tail cases.
- Other.admission recovers a matching actual player for any tracked member and
  any acting PID, without uniqueness or health assumptions. The payout-frame
  projection and existing Actor.battle_run then preserve it through actual
  ordered strikes, kills, rewards and level changes. Other.live reaches actual
  LiveCombat.run with arbitrary affine planners and both admission branches.
- Other.live_held preserves an already-proved Held cooldown through a command
  of the other kind, for any acting PID. Other.retry composes the intervening
  command with the protected retry and proves Rejected.Inert. It derives final
  uniqueness via actual command execution from initial player/connection
  uniqueness; final membership and cooldown are derived, not assumed.
- The intervening command may act as the tracked player, another player, or a
  missing PID, and may be accepted or rejected. Planners are evaluated once on
  actual Ready values. The retry preserves the intervening result, including
  any legitimate rewards, while emitting no additional effects.
- This closes this mixed-kind cooldown preservation and retry obligation. It
  does not cover same-kind commands by distinct players, elapsed gameplay ticks
  in this composition, or arbitrary mixed schedules. All six original full
  requirements remain OPEN.

Mixed combat cooldown validation (recorded after installation):
- All 16 safe laws and the mandatory installed proof closure pass; original 15
  statements remain unchanged. All 116 constructive probe laws pass, including
  actual attack-spin-attack and spin-attack-spin execution, protected cooldowns
  after kills and rewards, another player's intervening command, missing PID,
  rejected intervening command, and arbitrary affine command planners.
- Both initial commands actually execute: the concrete mixed sequences reach
  cooldowns 4/25 and two kills. The final retry equals the complete quiet result
  of the intervening world. Foreign-command probes verify actual reward receipt.
- Five intended type failures reject the wrong protected cooldown, dropping the
  reward frame, using a stale retry world, resetting a protected counter, and
  admitting the protected retry. The reported error locations were inspected.
- Generated main C is byte-for-byte identical to installed validated C; runtime
  sources and native binary are unchanged. Previous 1044 JS / 140 native checks
  and fresh bot/GUI/session/protocol/save checks from bqlive_attack apply to this
  exact runtime and were not rerun in this proof-only batch.
- Evidence, backup and final hashes: `/private/tmp/bqcombat_other`.
  Kernel/compiler and unrelated hashes match the previous ledger. Same-kind
  commands by other players, mixed command/tick scheduling and quantitative
  availability remain to be composed. All six original full scopes remain OPEN.

Distinct-player combat frame preservation (9 safe laws, proof-only):
- `combat_foreign.bend` follows the actual complete tracked player through the
  take permutation. The selected head has the acting PID by Players.take_id;
  a distinct tracked PID therefore lies in the untouched tail. Admission keeps
  that full record, even when the acting player is rejected or missing.
- Foreign.live composes this with Actor.battle_run over actual ordered strikes
  and payouts. It recovers an actual final member with the same Payout.Frame:
  PID/CID, position, HP, death/respawn state, both cooldowns, style and name.
  It permits arbitrary command kind, phase, roster and affine planner; it needs
  initial membership and distinct PIDs, but no uniqueness or health premise.
  The frame excludes hero/XP/quests/scores/kills; no claim is made about those.
- Foreign.live_held preserves either protected cooldown independently of the
  intervening command kind. Foreign.retry derives final uniqueness from initial
  Admission.Unique and proves Rejected.Inert for the actual protected retry
  after the actual intervening world. Final membership/lock/uniqueness are not
  assumed. Each affine planner is called once on its actual Ready value.
- This covers same-kind commands by another player, complementing Other.live.
  Elapsed gameplay ticks and arbitrary mixed schedules remain to be composed;
  all six original full requirements remain OPEN.

Distinct-player combat validation (recorded after installation):
- All 9 safe laws and the mandatory installed proof closure pass. Original 15
  statements are unchanged. All 128 constructive laws pass: previous 116 plus
  arbitrary-seed created-world tracking, arbitrary distinct acting PID/kind
  and affine planners, same-kind attack/spin actor preservation and retry,
  missing/rejected intervening commands, exact Some lookup frames, actual
  intervening rewards/counters/PIDs, and complete quiet retry results.
- In both same-kind multiplayer sequences the intervening PID 2 actually kills
  the remaining monster and earns a reward. Its counters/kills are 4/0/1 for
  attack and 0/25/1 for spin; tracked PID 1 retains its pre-intervention frame.
  The original player's subsequent retry is exactly quiet in that new world.
- Five intended type failures reject substituting the acting player for the
  tracked player, dropping the post-reward frame, using a stale retry world,
  claiming a player's own accepted command preserves its full frame, and
  admitting an already locked retry. Error locations and mismatches inspected.
- Generated main C is byte-for-byte identical to installed validated C. Runtime
  sources and native binary are unchanged. Previous 1044 JS / 140 native and
  fresh bot/GUI/session/protocol/save checks from bqlive_attack apply to this
  exact runtime and were not rerun in this proof-only batch.
- Evidence, backup and final hashes: `/private/tmp/bqcombat_foreign`.
  Kernel/compiler and unrelated hashes match the prior ledger. Foreign-player
  commands now preserve both cooldowns through admission and rewards. Arbitrary
  mixed command/tick schedules and quantitative availability remain open, as do
  all six original full requirements.

Arbitrary finite combat streams (14 safe laws, proof-only):
- `combat_mixed.bend` combines same-player rejection, distinct-player frame
  preservation, and other-kind cooldown preservation. Mixed.live_held covers
  any acting PID and command kind, preserving the actual protected Held witness
  from initial Held and Admission.Unique. It derives same-PID equality from the
  actual comparison; rejected lookup restores the full tracked record through
  the real take permutation. Mixed.guarded proves Rejected.Inert whenever the
  current request is the protected player/kind; other requests may earn rewards.
- Mixed.Request carries its own kind, PID, timestamp, score and affine planner.
  Mixed.trace applies actual WorldClock.set and LiveCombat.run, threads each
  returned world into the next request, and retains every actual entry and the
  final world. No gameplay ticks occur in this trace; timestamps are not ticks.
- Mixed.safe proves Mixed.OK for any finite request list: every entry has final
  Held, final roster uniqueness, and the protected-request guard. The final
  world is retained with exact equality to the trace result, final Held and
  final uniqueness. No intermediate/post-state validity is assumed.
- Mixed.retry composes a further actual affine planner after that actual final
  world and proves Rejected.Inert. Request callbacks and the retry planner are
  consumed once. Mixed.length proves exactly one recorded entry per request.
- Mixed.after_first derives the initial lock and uniqueness from a real first
  command, conditionally on that command's actual Some admission. On that branch
  the entire arbitrary suffix is certified; a rejected first command supplies
  no lock witness. Concrete accepted attack/spin probes inhabit the full OK.
- This closes arbitrary finite no-gameplay-tick combat scheduling from an
  accepted command. Quantitative cooldown availability across live ticks and
  respawn resets remains to be composed. All six original full scopes are OPEN.

Arbitrary combat stream validation (recorded after installation):
- All 14 safe laws and the mandatory installed proof closure pass. Original 15
  statements remain unchanged. All 145 constructive laws pass: previous 128
  plus arbitrary finite attack/spin suffixes and a final affine retry; arbitrary
  seed/world/time/kind/first planner on actual created worlds; concrete accepted
  attack/spin first commands supplying full suffix certificates; empty streams;
  seven-entry lengths and complete actual traces; exact final retries, player
  frames, retained rewards and final clocks; and state-dependent planner inputs.
- The seven-request traces mix both player IDs, both command kinds, missing PID
  99, accepted and rejected commands, different scores and timestamps including
  MAX, zero and decreasing values. Final PID 2 counters/kills are 4/25/1; PID 1
  retains the protected cooldown despite the intervening reward. Final time is
  400. The separate clock-dependent planner emits the actual 333/PID2/score70
  visual, while the protected request at time444 remains quiet.
- Five intended type failures reject dropping a recorded entry's certificate,
  proving the recursive tail at a stale world, skipping an input request,
  admitting a final protected retry, and retaining the initial timestamp after
  the actual stream. Error locations and mismatches inspected.
- Generated main C is byte-for-byte identical to installed validated C. Runtime
  sources and native binary are unchanged. Previous 1044 JS / 140 native and
  fresh bot/GUI/session/protocol/save checks from bqlive_attack apply to this
  exact runtime and were not rerun in this proof-only batch.
- Evidence, backup and final hashes: `/private/tmp/bqcombat_mixed`.
  Kernel/compiler and unrelated hashes match the previous ledger. Finite mixed
  combat scheduling without gameplay ticks is proved from a real accepted
  command. Mixed gameplay-tick scheduling and quantitative availability remain
  open, together with all six original full requirements.

Positive remaining cooldowns and actual tick composition (20 safe laws):
- `combat_cooling.bend` generalizes the rejection witness to any strictly positive
  actual cooldown, including 1. Cooling.Held stores an actual roster member,
  the tracked PID and positivity of that record's actual counter; it does not
  require the initial attack/spin stamp of 4/25. The previous proofs are retained.
- Actual unique lookup plus Combat.cooling_rejected proves exact quiet results
  and Rejected.Inert. Full payout and other-kind frames transfer positivity
  through rewards. Cooling.live_held covers arbitrary intervening command kinds
  and PIDs; own retries restore the full roster through the actual take
  permutation, while other commands may execute. Cooling.after_command derives
  final membership/positivity/uniqueness and proves the actual retry is inert.
- Cooling.next projects the expected counter from the established exact tracked
  LiveTick frame. Cooling.tick recovers the actual post-tick player and tracked
  PID using Tracked.live, then derives positive Held when that computed next
  counter is positive. Neither the final player nor final membership is assumed.
  It handles live decay, lethal hits, dead waiting and inactive phases. Respawn
  readiness computes zero and cannot supply a positive witness.
- Cooling.tick_inert and Cooling.tick_command derive final uniqueness from
  LiveTick.seeded and initial SeededWorld.OK, then compose the actual tick with
  a protected retry, or an arbitrary intervening combat command plus retry.
  Affine planners run once on the actual ready world. The positivity premise
  refers to the counter computed from the pre-tick player/phase; it is explicit
  because cooldown expiry and respawn resets legitimately permit reuse.
- This connects partial cooldowns to actual tick/command execution. Arbitrary
  mixed tick/command histories and quantitative availability across lifecycle
  changes remain to be composed. All six original full requirements stay OPEN.

Partial cooldown / live-tick validation (recorded after installation):
- All 20 safe laws and the mandatory installed proof closure pass. Original 15
  statements remain unchanged. All 161 constructive laws pass: previous 145
  plus actual expired-attack execution and accepted-command roster and positive-next-counter laws; arbitrary
  seed/time/kind/timer on actual created worlds with retry or arbitrary command
  then retry; a one-tick remaining cooldown after three actual LiveTicks;
  arbitrary intervening commands and concrete other-kind/foreign kills; literal
  live decay 4,3,2,1,0 and rejection/availability at 1/0; actual retained rewards;
  lethal, waiting and inactive ticks; and the exact zero counter at respawn.
- The created-world proofs derive initial validity from actual Connect/HELLO/
  CREATE and LiveCombat.run_seeded, then derive post-tick uniqueness via the
  actual LiveTick.seeded law. They assume no post-tick member or validity.
- At remaining attack counter 1, a same-player spin earns the second kill while
  leaving attack 1 and stamping spin25. A foreign attack earns its first kill;
  the protected retry remains inert in each actual reward-bearing world.
- Five intended type failures reject allowing zero as a positive cooldown,
  reusing the pre-tick player/roster as the post-tick observation, using the old
  counter instead of the computed next counter, claiming a positive lock after
  revival, and admitting an early retry at remaining counter1. Errors inspected.
- Generated main C is byte-for-byte identical to installed validated C. Runtime
  sources and native binary are unchanged. Previous 1044 JS / 140 native and
  fresh bot/GUI/session/protocol/save checks from bqlive_attack apply to this
  exact runtime and were not rerun in this proof-only batch.
- Evidence, backup and final hashes: `/private/tmp/bqcombat_cooling`.
  Kernel/compiler and unrelated hashes match the previous ledger. Positive
  remaining cooldowns now compose actual ticks with combat and retries. General
  mixed histories and quantitative lifecycle availability remain open, along
  with all six original full requirements.

Exact arbitrary combat transitions (16 safe laws, proof-only):
- `combat_transition.bend` recovers the prepared tracked player from actual
  unique lookup. Transition.taken/admission follow Players.take and the actual
  Combat.prepare/finish result, for either accepted or rejected admission.
  Transition.own reaches the actual final reward-bearing roster via the
  existing full payout-frame preservation theorem.
- Transition.live covers any acting PID, kind, score and affine planner. If the
  requested PID equals the tracked PID, its expected frame is that player's
  actual Combat.prepare result; otherwise its frame is unchanged. PID equality
  is derived from the actual comparison. The proof needs initial membership
  and Admission.Unique, with no positivity, readiness, health or phase premise.
- The preserved payout frame contains PID/CID, position, HP, death/respawn state,
  attack/spin counters, style and name. Hero/XP/quest/score/kill fields may change
  through rewards; no complete player-record equality is claimed after payouts.
- Transition.live_computed returns an actual Tracked.Observed member with the
  exact PID/CID/attack/spin frame. Its explicit rule leaves both counters and
  IDs unchanged for another PID or blocked admission; accepted own attack
  sets attack4 and retains spin, accepted own spin sets spin25 and retains
  attack. The formula is proved equal to actual preparation and final execution.
- The two observations, Transition.live_computed for commands and Tracked.live
  for ticks, now describe exact counter steps across expiry and resets without
  assuming every step remains positive. Arbitrary mixed history composition and
  quantitative lifecycle availability remain open, as do all six full scopes.

Exact combat-transition validation (recorded after installation):
- All 16 safe laws and the mandatory installed proof closure pass. Original 15
  statements remain unchanged. All 177 constructive laws pass: previous 161
  plus arbitrary-seed created-world transitions with arbitrary command kind,
  PID, score and affine planner; exact accepted attack/spin frames and the
  reward-bearing full payout frame; locked, other-kind, foreign, missing, dead
  and inactive command cases; partial counter1 and expired counter0; actual
  post-respawn attack/spin observations; literal post-respawn final frames and
  a table of the explicit counter rule.
- The accepted command cases use actual runtime planners and existing real
  kills/rewards. The post-respawn world comes from actual LiveTick.run starting
  with a dead player, respawn timer1 and counters7/9. Its actual counters reset
  to0/0; subsequent real attack and spin produce4/0 and0/25 respectively.
- Five intended type failures reject treating a foreign PID as the tracked
  actor, using attack delay3, clearing the other cooldown, keeping the old
  unprepared player through own-command admission, and stamping a dead player's
  rejected command. Error locations and mismatches inspected.
- Generated main C is byte-for-byte identical to installed validated C. Runtime
  sources and native binary are unchanged. Previous 1044 JS / 140 native and
  fresh bot/GUI/session/protocol/save checks from bqlive_attack apply to this
  exact runtime and were not rerun in this proof-only batch.
- Evidence, backup and final hashes: `/private/tmp/bqcombat_transition`.
  Kernel/compiler and unrelated hashes match the previous ledger. Exact command
  and tick counter transitions can now be composed across zero and positive
  counters. General mixed histories and quantitative lifecycle availability
  remain open, along with all six original full requirements.

Unrestricted finite combat/live-tick histories (19 safe laws, proof-only):
- `combat_history.bend` defines affine TickRequest and CommandRequest inputs.
  The latter supplies a timestamp, kind, PID, score and planner. The planner is
  called once on actual timed LiveCombat.prepare; the resulting Data plan is
  recorded. History.trace threads actual LiveTick.run or timed LiveCombat.at
  worlds into the next request, retaining every entry and the final world.
- History.tick_unique derives both PID and CID uniqueness through actual tick
  upkeep, AI contexts, planning and damage. History.observe composes exact
  Tracked.live and Transition.live_computed observations. Initial membership
  and Admission.Unique suffice; no health, phase or positive-cooldown premise
  restricts the history. It can cross zero, death, waiting and revival freely.
- History.Follow links every entry to its actual preceding world and player,
  actual operation/result world, actual next player/member and exact paired
  PID/CID/attack/spin frame. Its terminal indices link the final witness to that
  same chain. Done requires an empty suffix, equal terminal world/player and
  actual membership. No step or transition is omitted.
- Each command step also carries History.Guard: when the tracked PID issues a
  command blocked by cooldown, death or phase, its actual result is
  Rejected.Inert in the timed world. This follows exact lookup and Combat.reject;
  both the blocking decision and PID comparison are computed from the actual
  pre-command player/world. Other players and accepted commands may act.
- History.safe derives the complete Follow, final member, final uniqueness and
  unchanged tracked PID for any finite input list. The certificate retains actual
  final world/entries with exact equality to History.trace; affine callbacks and
  the remaining input list are consumed once. History.length proves one entry
  per request. History.final_lookup derives actual Some lookup by the original
  PID, with no assumed final member or lookup result.
- Independently, History.seeded preserves complete SeededWorld.OK through the
  same actual mixed trace from initial SeededWorld.OK, using actual clock,
  combat and live-tick preservation laws. This covers pure seeded-world state,
  not the still-open dispatcher/IO/authentication obligations.
- This closes finite mixed combat/tick player tracking, exact cooldown evolution,
  and blocked-command inertness across those histories. Quantitative lifecycle
  availability and the other full-scope obligations remain open. All six
  original full requirements remain OPEN.

Mixed live-history validation (recorded after installation):
- All 19 safe laws and the mandatory installed proof closure pass. Original 15
  statements remain unchanged. All 197 constructive laws pass: previous 177
  plus arbitrary created-world mixed histories, full seeded-world preservation,
  final original-PID lookup, arbitrary lifecycle histories, concrete living and
  waiting-player certificates, empty histories, exact lifecycle/expiry lengths,
  literal Some lookup rows and counter frames, exact clock updates, retained
  multiplayer rewards, actual affine planner inputs and inactive histories.
- The ten-step lifecycle starts at HP1/counters4/25, then follows actual command,
  lethal tick, another player's command, waiting tick, dead-player retry,
  revival tick, accepted attack, living tick, accepted spin, and missing PID.
  The same PID1/CID11 ends alive at HP35/counters3/25. Exact intermediate rows
  prove death timer2, waiting timer1, revival counter reset0/0 and fresh stamps.
- The nine-step expiry history interleaves another player's rewarded spin and
  own commands with real ticks. Tracked attack values evolve3,3,2,2,1,1,0,4,4;
  the other cooldown evolves independently, and PID2 retains its earned kill.
  The original PID has an actual Some final lookup, not a fallback record.
- State-dependent planners record actual timestamp/PID/score inputs333/2/70 and
  444/1/80 around ticks. Inactive ten-step histories keep both counters zero and
  certify their blocked commands. Each certificate includes actual inertness
  whenever its tracked player's command is blocked by cooldown, death or phase.
- Six intended type failures reject skipping a tick, a stale recursive world,
  dropping an entry certificate, giving a planner a stale untimed world,
  dropping blocked-command evidence, and leaving an expired counter unstamped
  after an accepted command. Error locations and mismatches inspected.
- Generated main C is byte-for-byte identical to installed validated C. Runtime
  sources and native binary are unchanged. Previous 1044 JS / 140 native and
  fresh bot/GUI/session/protocol/save checks from bqlive_attack apply to this
  exact runtime and were not rerun in this proof-only batch.
- Evidence, backup and final hashes: `/private/tmp/bqcombat_history`.
  Kernel/compiler and unrelated hashes match the previous ledger. Finite mixed
  combat/live-tick tracking and blocked-command inertness are now proved across
  lifecycle changes. Quantitative availability and all six original full-scope
  requirements remain OPEN.

Quantitative cooldown bounds and actual availability (20 safe laws):
- `combat_bounds.bend` folds the existing actual History.Follow certificate.
  Bounds.ticks counts only active upkeep steps taking the live branch. Death
  waiting and inactive steps count zero; revival resets the counter without
  increasing the count. In a valid world this is the active living-tick count.
- Bounds.use identifies accepted own commands of the protected kind from the
  actual PID comparison, kind and blocking decision. Bounds.Unused/NoReuse
  require that none occur in the interval; other players, the other attack
  type, and rejected own commands remain allowed. This explicit condition is
  necessary because an accepted reuse legitimately restarts the cooldown.
- Bounds.step proves an upper bound for the actual next counter using the exact
  observed frame. Commands satisfying NoReuse preserve the protected counter;
  live ticks take its predecessor; waiting/inactive ticks preserve it; revival
  clears it. Word decrement is related to natural predecessor without wrap.
- Bounds.fold proves final_counter <= max(initial_counter - counted_ticks, 0)
  along the complete certified history, including lifecycle changes. Its
  recursion follows the actual entry list; impossible Done/Step shapes are
  refuted and the exact tail certificate is transported through list equality.
  Bounds.bound exposes the estimate on a complete actual History.OK certificate.
- Bounds.expired derives exact U32 zero when counted ticks reach the initial
  counter. Bounds.ready then derives actual LiveCombat.prepare admission of
  Some{stamped final player} under final living and active-phase conditions.
  Final player membership, uniqueness and original PID come from History.OK;
  final cooldown and lookup/admission are proved, not assumed. The readiness
  conditions inspect that actual certificate and include NoReuse and enough
  counted ticks. They are sufficient; a revival may make reuse possible sooner.
- This closes the quantitative interval bound and next-command availability
  under the stated scheduling/lifecycle conditions. Positive hit/reward liveness
  and remaining dispatcher, authentication, persistence and completion scopes
  remain open. All six original full requirements remain OPEN.

Quantitative cooldown validation (recorded after installation):
- All 20 safe laws and the mandatory installed proof closure pass. Original 15
  statements remain unchanged. All 217 constructive laws pass: previous 197
  plus six actual intervals with NoReuse and bound proofs; conditions and actual
  admission witnesses for attack, revival and spin intervals; exact measured
  initial/count/final/upper-bound values; and commands executed after the bound.
- The measured tuples [initial, counted live ticks, final, upper bound] are:
  attack [4,4,0,0], partial [4,3,1,1], early revival reset [4,1,0,3], revival
  followed by living ticks [4,4,0,0], spin [25,25,0,0], inactive [4,0,4,4].
  These are actual mixed History.safe certificates, including foreign rewarded
  commands, blocked retries, death, waiting, revival and other-kind commands.
- Actual commands after the proved bound stamp attack4/spin24 with the original
  actor's existing kill retained, and spin25 with a second kill after 25 real
  live ticks. The readiness theorem derives Some of the stamped actual player
  from the history certificate, exact zero, original PID and initial conditions.
- Six intended type failures reject counting waiting/inactive ticks as progress,
  ignoring an accepted reuse, claiming four-tick readiness after three counted
  ticks, admitting a dead player with zero cooldown, and admitting a player
  while the game is inactive. Error locations and mismatches inspected.
- Generated main C is byte-for-byte identical to installed validated C. Runtime
  sources and native binary are unchanged. Previous 1044 JS / 140 native and
  fresh bot/GUI/session/protocol/save checks from bqlive_attack apply to this
  exact runtime and were not rerun in this proof-only batch.
- Evidence, backup and final hashes: `/private/tmp/bqcombat_bounds`.
  Kernel/compiler and unrelated hashes match the previous ledger. Quantitative
  interval expiry and next-command admission are proved under explicit NoReuse,
  enough counted ticks, final living and active-phase conditions. Positive hit/
  reward liveness and all six original full-scope requirements remain OPEN.

Positive lethal attack reward liveness (18 safe laws, proof-only):
- `combat_lethal.bend` constructively selects the actual first eligible monster
  from any eligible roster member. The selected monster may precede that
  witness. Empty selection contradicts complete rejection of the witnessed
  eligible member; the certificate includes the actual selected record,
  equality to Targets.first, and its roster membership/eligibility.
- Kill information preserves the selected monster's original MID, kind, rare
  flag and zone through damage. A successful unique-ID lookup, live flag and
  damage at least current HP derive the actual Roster.strike kill report;
  the report is not assumed. Source membership, eligibility and authoritative
  monster uniqueness derive that lookup and living flag.
- Lethal.reward composes the actual report with Battle.strike_reported. A
  singleton run has exactly its actual strike notices; ready_reward carries
  this through LiveCombat.finish and pack to exactly one reward notice.
- selected_attack uses the actual first target and arbitrary affine power
  calculator. The selected target source is derived from Targets.first_source.
  Actual admitted-player membership and its requested PID derive reward
  recipient presence; no assumed final reward or successful payout is used.
- Lethal.planned/live accept the full LiveAttack.Builder used by the live
  planner. BuiltEnough evaluates the same calculator on actual prepared
  monsters/player/metadata/PID and the same selected monster. The proof calls
  the runtime builder and its power closure once each. Criteria requires actual
  admission, first selection and unique monster IDs; enough damage is explicit.
  Admitted.live_prepare derives actor membership and PID for LiveCombat.run.
- This closes conditional lethal normal-attack reward dispatch for the actual
  pure live planner. It does not assert arbitrary catalog damage is lethal,
  derive eventual repeated-damage kills, or prove arbitrary roster/respawn reward
  uniqueness. Spin, quest/run finalization, persistence, authenticated ownership,
  outer IO and all six original full-scope requirements remain OPEN.

Lethal attack validation (recorded after installation):
- All 18 safe laws and the mandatory installed proof closure pass. Original 15
  statements remain unchanged. All 234 constructive laws pass: previous 217
  plus actual first-selection existence and order, original boss kill identity,
  live boss and multiplayer rewards, selection past dead/far/wrong-zone records,
  a real lethal attack on the selected later target, sufficient exact-HP damage
  for arbitrary prepared inputs, an all-seed conditional created-world theorem,
  actual calculator metadata/selected-record input, reward after four real live
  ticks, exact cooldown/kill counters, retained skipped records, actual PID1/PID2
  recipient counts and the original monster identities in actual reward notices.
- The exact-HP calculator produces damage100 from the actual selected monster
  and visual critical field200 from actual prepared metadata. Actual recipient
  lookup yields kills1 for PID1 and kills0 for PID2. After the initial kill and
  four real ticks, another actual attack yields one reward and total kills2.
  Actual original kill notices include boss {kind9,rare0,zone0,MID7} and the
  later selected normal monster {kind0,rare0,zone0,MID8}.
- Seven intended type failures reject removing sufficient-damage evidence,
  zero damage against HP1, choosing a later eligible monster instead of the
  actual first one, duplicate monster IDs, dead/inactive actors, and treating an
  out-of-range monster as eligible. Error locations and mismatches inspected.
- Generated main C is byte-for-byte identical to installed validated C. Runtime
  sources and native binary are unchanged. Previous 1044 JS / 140 native and
  fresh bot/GUI/session/protocol/save checks from bqlive_attack apply to this
  exact runtime and were not rerun in this proof-only batch.
- Evidence, backup and final hashes: `/private/tmp/bqattack_liveness`.
  Kernel/compiler and unrelated hashes match the previous ledger. Conditional
  lethal normal-attack reward liveness is now derived from actual selection,
  admission and calculator damage. General repeated-damage/respawn/spin/quest/run
  reward lifecycles and all six original full-scope requirements remain OPEN.

Positive ordered spin reward liveness (13 safe laws, proof-only):
- `spin_lethal.bend` binds sufficient damage to every actual selected monster
  and its indexed power. SpinKill.Enough requires decoded damage >= decoded
  current HP for each selected record; it neither assumes a kill result nor
  treats a nonlethal power as sufficient.
- SpinKill.run proves actual Battle.run produces exactly as many reward notices
  as selected records. At each step, Lethal.reward derives a real lethal kill
  and one reward notice. CombatFrame.survivor_sources preserves the complete
  remaining records through the actual strike; monster ID uniqueness is
  preserved. Distinct selected IDs prevent reusing a killed record for a later
  selected target. Actor.battle_strike preserves the actual recipient witness
  through payouts; its PID equality derives real recipient presence again.
- The recursion threads the actual post-strike state, including metadata,
  roster changes and player rewards. It makes no intermediate active-phase
  assumption. A boss reward can set phase2 while Battle.run continues the
  already admitted spin. Notice concatenation proves the exact total count.
- SpinKill.filtered derives selection sources and selected uniqueness from the
  actual Targets.filter and authoritative monster uniqueness. ready/planned/live
  carry the count through actual LiveCombat.finish/run and LiveSpin.plan, using
  the full affine LiveSpin.Builder on actual prepared monsters/player/meta and
  the actual selected list. The builder is consumed once. Admission evidence
  derives actual actor membership and requested PID.
- Rejected admission has selected count0 and no notices; an accepted empty spin
  also has count0. Otherwise the count is the complete eligible filter length.
  Sufficient actual calculator damage remains explicit. This count theorem does
  not assert every accepted spin has a target or that catalog damage is lethal.
- SpinKill.Reports additionally exposes each original selected monster's actual
  kill report immediately before its own hit. reports/filtered_reports follow
  the same changing state and powers; planned_reports/live_reports tie these
  certificates to the same actual prepared world and full live builder.
- Conditional lethal spin reward dispatch and individual kill reports are now
  proved. General repeated/nonlethal attacks, arbitrary death/respawn histories,
  quest/run reward lifecycles, catalog arithmetic, persistence and authenticated
  ownership remain open. All six original full-scope requirements remain OPEN.

Lethal spin validation (recorded after installation):
- All 13 safe laws and the mandatory installed proof closure pass. Original 15
  statements remain unchanged. All 252 constructive laws pass: previous 234
  plus universally sufficient exact-HP powers, sufficient actual prepared
  builder, all-seed created-world reward counts and individual reports, actual
  two-target boss spin count/reports/notice order/final phase/powers, reversed
  target order, skipped ineligible targets, multiplayer count and recipient,
  blocked/missing actor counts, empty-spin count/stamp and post-expiry reward.
- Boss-first and boss-last spins both produce two rewards in the actual selected
  order. Boss-first changes phase to2 before the second strike and still yields
  both original kill identities. Powers are bound to the actual selected HP1
  and HP100 records. Actual multiplayer lookup yields kills2 for PID1 and
  kills0 for PID2. Dead/inactive/cooling/missing admissions yield zero rewards.
  An accepted empty spin yields zero rewards and stamps spin25. After25 actual
  live ticks, a reused spin produces the remaining monster's one reward.
- Seven intended type failures reject weakening every-target lethal evidence,
  recursing with the stale pre-hit state, nonlethal damage on the second target,
  duplicate selected IDs, dropping one actual reward, assigning an existing
  actor's reward theorem to another PID, and rewarding an inactive command.
  The foreign-recipient case applies SpinKill.input_reward with real source,
  member and damage evidence and fails specifically at the false PID equality.
  Error locations and mismatches inspected for all seven final cases.
- Generated main C is byte-for-byte identical to installed validated C. Runtime
  sources and native binary are unchanged. Previous 1044 JS / 140 native and
  fresh bot/GUI/session/protocol/save checks from bqlive_attack apply to this
  exact runtime and were not rerun in this proof-only batch.
- Evidence, backup and final hashes: `/private/tmp/bqspin_liveness`.
  Kernel/compiler and unrelated hashes match the previous ledger. Conditional
  lethal spin count and original individual kill reports now follow the actual
  ordered live execution. Arbitrary damage/death/respawn/reward lifecycles and
  all six original full-scope requirements remain OPEN.

Dead-monster preservation and reward exclusion (28 safe laws, proof-only):
- `dead_rewards.bend` lifts the actual dead-hit no-op through complete roster
  lookup and Battle.strike. Initial full-record membership and authoritative
  unique monster IDs derive the actual lookup. A direct hit on the dead monster
  deals zero, reports no kill, preserves its entire record, and emits no reward
  notices. Roster reordering is allowed; full world equality is not assumed.
- Hits on another ID preserve the full tracked record through the exact erased-
  target roster frame. The membership proof uses generic roster membership,
  without falsely requiring a dead monster to be eligible for attack selection.
  step_member/run_member preserve the same dead record through arbitrary inputs,
  damage, payout plans, acting PID and score; monster uniqueness is derived at
  each actual post-strike state.
- Independently, every reward notice emitted by an actual Battle.strike has the
  input's requested monster ID. Roster.take_id and hit-ID preservation connect
  the actual kill report to that target; actual payout/notice constructors carry
  that identity through reward dispatch, including absent recipients.
- Dead.Clear proves every notice has an ID different from the tracked dead
  monster. A same-ID strike is exactly quiet; a different-ID strike can only
  emit notices for its own ID. Concatenation and arbitrary Battle.run preserve
  Clear, while deriving the next full-record membership/uniqueness each time.
- Dead.Command permits a different input, player ID and score at every step.
  Dead.trace threads actual Battle.strike state and notice concatenation.
  Dead.trace_safe derives final full dead-record membership, final monster
  uniqueness and Clear for the complete trace. Dead.safe_zero converts this to
  zero notices for that MID; Dead.final_lookup derives actual Some of the exact
  original full record, with no assumed final lookup or fallback record.
- This closes reward exclusion for an already-dead tracked monster over arbitrary
  no-tick strike intervals, allowing positive rewards for other targets. Actual
  LiveCombat admission/planner/clock trace wrappers and the initial lethal-hit
  construction of the generic dead certificate remain to be composed. Ticks,
  waiting, legitimate respawn and subsequent reward lifetimes require separate
  lifecycle tracking; a dead record is not claimed permanent across respawn.
  All six original full-scope requirements remain OPEN.

Dead-monster reward validation (recorded after installation):
- All 28 safe laws and the mandatory installed proof closure pass. Original 15
  statements remain unchanged. All 268 constructive laws pass: previous 252
  plus actual post-attack dead record lookup, arbitrary mixed-player trace
  safety/zero rewards/final lookup, arbitrary ordered spin input reward
  exclusion, concrete mixed trace and exact reward counts/identity/recipient/
  record retention, direct maximum-word damage no-op, actual post-spin dead
  roster, arbitrary post-spin boss trace, concrete empty reward trace and
  empty input certificate.
- The actual initial attack kills MID7, leaving dead1/HP0/respawn80. The six-step
  trace alternates PIDs2/1/99, direct dead-target hits with damageMAX/10/0,
  MID8's real lethal hit and retry, and missing MID99. Reward counts are exactly
  MID7=0, MID8=1, total1. The actual MID8 notice retains its normal kind0 despite
  supplied payout kind9. Actual player lookup yields kills1 for each PID1/PID2:
  the original attack rewarded PID1 and the new other-monster kill rewarded PID2.
  MID7's entire original dead record, including respawn80, remains unchanged.
- A real two-target live spin supplies the other starting world. Its actual
  roster is dead normal MID8 followed by permanent-dead boss MID7; arbitrary
  later strike traces preserve that boss and exclude its rewards. The concrete
  repeated/missing-target trace emits no notices because both targets are dead.
- Seven intended type failures reject removing the dead-flag premise, recursing
  on a stale trace state, rewriting reward notice identity to0, treating a live
  record as dead, duplicate MIDs, awarding the already-dead monster, and
  suppressing the other monster's legitimate reward. Exact errors inspected.
- Generated main C is byte-for-byte identical to installed validated C. Runtime
  sources and native binary are unchanged. Previous 1044 JS / 140 native and
  fresh bot/GUI/session/protocol/save checks from bqlive_attack apply to this
  exact runtime and were not rerun in this proof-only batch.
- Evidence, backup and final hashes: `/private/tmp/bqdead_rewards`.
  Kernel/compiler and unrelated hashes match the previous ledger. Arbitrary
  strike intervals exclude rewards for an already-dead tracked monster while
  permitting other rewards. Generic initial lethal-hit, live command/clock,
  tick/respawn lifetime composition and all six full requirements remain OPEN.

Exactly one lethal reward followed by arbitrary strikes (13 safe laws):
- `reward_once.bend` starts with an eligible complete monster record in the
  actual roster, authoritative unique IDs, sufficient damage and an existing
  reward recipient. It derives the actual post-hit monster from Monsters.hit,
  its retained ID and dead flag, and actual membership through Roster.take,
  strike_result and Battle.strike. No assumed initial corpse or final lookup
  is used to establish this lifetime's starting death.
- Once.first_count derives one actual reward for the requested MID. Lethal.reward
  supplies positive reward dispatch; Dead.battle_target supplies actual notice
  identity. Once.only_count converts the actual total count to that MID's count.
- Once.tail_safe derives Dead.Safe for arbitrary later commands from the actual
  lethal-hit state. Each later command can choose a different PID, score, target,
  damage and payout plan. The exact corpse, final uniqueness and exclusion of
  further rewards for its MID follow through actual changing states.
- Once.run retains both the actual first result and every later strike result.
  Once.assemble/prove combine the first reward count1 and derived suffix count0
  using filtered-count concatenation. The resulting Certificate includes the
  actual final corpse membership, final monster uniqueness, its derived dead
  flag and exactly one reward notice for the original MID over the entire run.
  Once.final_lookup derives actual Some of that post-hit corpse by original ID.
- This is an exactly-one result with positive first dispatch, not merely an
  upper bound or an assumed dead-state exclusion. Other targets can still pay;
  the overall trace may contain more than one reward notice. No tick/respawn is
  part of this strike interval. Generic actual admission/planner/clock wrappers,
  waiting/respawn lifetimes and all six full-scope requirements remain OPEN.

Exactly-once lethal reward validation (recorded after installation):
- All 13 safe laws and the mandatory installed proof closure pass. Original 15
  statements remain unchanged. All 283 constructive laws pass: previous 268
  plus actual attack admission/result bridges, arbitrary later-strike
  certificate/count/final corpse, concrete mixed certificate/counts/notice
  order/recipients, empty suffix, initial later-roster selection, arbitrary
  boss suffix, actual spin-result bridge and exact boss/spin reward counts.
- The initial strike state is the actual attack's admitted roster, including
  attack4. Its entire first Battle.Result equals the actual LiveCombat attack's
  simulation and notices. A first lethal MID7 hit followed by the prior six
  mixed-player strikes gives counts MID7=1, MID8=1, total2, in that notice order.
  Actual recipient lookup yields kills1 for each PID1/PID2. Final MID7 lookup
  returns its derived original post-hit corpse with HP0/dead1/respawn80.
- Selecting a later initial roster entry has an arbitrary-suffix certificate,
  with actual lookup derived from membership and uniqueness. A boss-first
  admitted spin also has an arbitrary-suffix certificate. The two-hit example's
  complete Battle.Result equals the actual LiveCombat spin's simulation and
  notices, with one original boss reward and one normal-enemy reward, total2.
- Seven intended type failures reject dropping the actual first reward from
  the combined result, an absent initial recipient, a nonlethal first hit, an
  already-dead initial target, duplicate MIDs, a second reward for the tracked
  monster, and suppressing the other monster's legitimate reward. Exact error
  locations and mismatches inspected for every case.
- Generated main C is byte-for-byte identical to installed validated C. Runtime
  sources and native binary are unchanged. Previous 1044 JS / 140 native and
  fresh bot/GUI/session/protocol/save checks from bqlive_attack apply to this
  exact runtime and were not rerun in this proof-only batch.
- Evidence, backup and final hashes: `/private/tmp/bqreward_once`.
  Kernel/compiler and unrelated hashes match the previous ledger. Exactly one
  reward for a real initial lethal strike followed by arbitrary strike commands
  is proved under explicit initial eligibility/uniqueness/damage/recipient
  conditions. Generic live command/clock, tick/respawn and broader reward
  lifecycle composition and all six original full requirements remain OPEN.

Actual live command reward histories (17 safe laws, proof-only):
- `live_dead.bend` carries the exact dead monster member, monster uniqueness and
  reward exclusion through Battle.execute, actual LiveCombat.finish and run.
  Rejected admission preserves the monster roster with no notices; admitted
  execution uses the actual planned Battle.run. finish_simulation/notices relate
  both fields to the same actual output. No post-state member/lookup is assumed.
- Actual WorldClock.set updates precede admission and planning. Initial monster
  membership/uniqueness transfers through that real clock update. Arbitrary
  Data plans are allowed; a rejected admission still gates their execution.
- LiveDead.Request is affine and supplies now/kind/PID/score/planner. trace calls
  the planner once on actual timed LiveCombat.prepare and retains each complete
  actual LiveCombat.Result, including its world, notices and visual. The next
  request receives that actual final world. No request or rejected result is
  dropped; length proves one result per input request.
- LiveDead.TraceSafe retains the actual Run plus equality to the indexed trace,
  so proof construction never reruns an affine callback. Its final member and
  uniqueness are derived at each step; Clear excludes the tracked dead MID from
  all accumulated actual notices. zero and final_lookup derive no further
  rewards and actual Some of the unchanged corpse by its original MID.
- LiveDead.after_once composes an existing Once.Certificate with an arbitrary
  actual timed live-command suffix starting from the prefix's actual state and
  supplied maps. OnceTrace retains that suffix certificate and proves the
  concatenated original-prefix and live-suffix notices contain exactly one
  reward for the original MID. The corpse and initial final-state invariant
  come from the lethal certificate, not from extra assumed suffix inputs.
- This closes no-tick dead-reward/exactly-one composition through actual combat
  admission, arbitrary planners, timestamps and mixed players/kinds. Full
  generic construction of the initial live attack/spin prefix certificate,
  actual tick/wait/respawn lifetimes, persistence and all six original full
  requirements remain OPEN. No external clock monotonicity or arithmetic-wrap
  safety follows from this reward-count proof.

Live dead-monster reward validation (recorded after installation):
- All 17 safe laws and the mandatory installed proof closure pass. Original 15
  statements remain unchanged. All 303 constructive laws pass: previous 283
  plus arbitrary live command and timed-plan safety, arbitrary affine trace
  safety/zero rewards/final lookup/result count, concrete mixed trace/counts/
  clocks/visuals/lookup/recipients, empty trace, arbitrary live suffix after a
  lethal prefix and exact reward count, complete prefix/suffix counts, arbitrary
  boss-prefix suffix, inactive trace, dead-player trace and actual rejection.
- Seven actual requests use clocks [201,202,MAX,0,203,204,205], mixed PIDs1/2/99,
  attack/spin and real or hostile planners. The actual results retain all seven
  clocks and visuals. The accepted state-dependent planner exposes actual MAX,
  PID2 and score70 in its visual. Rejected hostile/clock plans have Quiet visuals.
  MID7 has zero new notices, MID8 has one, total1; actual recipient lookup keeps
  kills1 for both players and original corpse lookup remains Some of dead MID7.
- Including the certified actual attack prefix gives counts MID7=1, MID8=1,
  total2. This exact-one composition also checks for arbitrary affine suffixes
  and a real boss-spin prefix. Inactive-phase and dead-player commands cannot
  execute supplied hostile plans. Timestamp wrap does not alter this count
  proof; clock monotonicity and arithmetic safety remain separate obligations.
- Seven intended type failures reject a stale untimed planner world, omitting
  an actual command result, recursing from the stale prior world, reusing the
  old living monster in place of the derived corpse, rewarding the dead target,
  suppressing another target's reward, and executing a rejected hostile plan.
  Exact error locations and mismatches inspected for every case.
- Generated main C is byte-for-byte identical to installed validated C. Runtime
  sources and native binary are unchanged. Previous 1044 JS / 140 native and
  fresh bot/GUI/session/protocol/save checks from bqlive_attack apply to this
  exact runtime and were not rerun in this proof-only batch.
- Evidence, backup and final hashes: `/private/tmp/bqlive_dead`.
  Kernel/compiler and unrelated hashes match the previous ledger. No-tick
  reward exclusion and exactly-one composition now follow actual timed combat
  commands and planners. Generic initial live prefix construction, actual
  tick/respawn lifetimes and all six original full requirements remain OPEN.

Actual initial attack and reward history (11 safe laws, proof-only):
- `attack_once.bend` constructs Once.Certificate directly from the actual
  LiveCombat.finish result of an admitted lethal single-target attack. view_pack
  relates its world/notices to the exact Battle.run result. The original member,
  eligibility, uniqueness and sufficient damage establish the actual corpse,
  resulting uniqueness, dead flag and exactly one reward; post-state facts are
  derived. Recipient presence follows actual admitted-actor membership/PID.
- selected_attack uses the actual first selection and its derived Source.
  selected_tuning/planned/live consume the actual full LiveAttack.Builder on
  actual prepared monsters, admitted actor, metadata and requested PID. Enough
  concerns that same selected monster and calculated damage. Missing admission
  cannot satisfy Criteria. No alternative builder or target is substituted.
- Prefix retains the complete actual LiveCombat.Result, its equality to the
  indexed attack, actual calculated damage and Once.Certificate. The erased
  attack index permits composition without reevaluating an affine builder.
- after_result uses Terrain.world_roundtrip to start LiveDead.after_once from
  the exact prefix world, including actual maps. History retains the actual
  prefix, its certificate and the complete proved actual live suffix. extend
  and live_history consume arbitrary affine timed requests once, without
  dropping commands or recomputing their planners.
- exactly_once and live_exactly_once prove filtered original-MID count=1 over
  the original attack notices concatenated with every actual suffix notice.
  The generic initial live attack prefix gap is now closed for these no-tick
  histories. Initial generic spin certificates and actual tick/wait/respawn
  lifetime composition remain open, as do all six original full requirements.
  No clock monotonicity, arithmetic-wrap safety, authentication or persistence
  conclusion is implied by this reward-count theorem.

Actual lethal attack history validation (recorded after installation):
- All 11 safe laws and the mandatory installed proof closure pass. Original 15
  statements remain unchanged. All 315 constructive laws pass: prior 303 plus
  arbitrary full-builder prefix, arbitrary full-builder/timed-request history,
  generic exact reward count, multiplayer minor prefix/history/count, boss
  history, actual state-dependent calculator with skipped ineligible records,
  all-seed creation conditional on actual selection, concrete seven-command
  mixed history/count and empty suffix.
- The initial attack certificate now comes from the actual full builder and
  admitted target; the earlier concrete singleton bridge is unnecessary for
  generic no-tick composition. Exact-count proof includes initial notices and
  every later command result. Boss phase changes, varied players, timestamps,
  hostile later plans and state-dependent damage are covered by these cases.
- Seven intended type failures reject feeding a different PID to the initial
  builder, replacing actual maps with empty maps, omitting suffix requests,
  omitting initial attack notices, choosing a later target instead of the first
  eligible one, claiming zero damage kills a one-HP monster, and claiming an
  attack certificate for a missing player. Exact mismatches were inspected.
- Generated main C is byte-for-byte identical to installed validated C. Runtime
  sources and native binary are unchanged. Previous 1044 JS / 140 native and
  fresh bot/GUI/session/protocol/save checks from bqlive_attack apply to this
  exact runtime and were not rerun for this proof-only change.
- Evidence, backup and final hashes: `/private/tmp/bqattack_once`. Kernel,
  compiler and unrelated hashes match the prior ledger. The initial generic
  normal attack prefix is now connected to arbitrary actual timed no-tick
  combat suffixes. Generic spin prefixes, tick/respawn lifetime composition
  and all six original full requirements remain OPEN.

Actual initial spin and per-target reward history (13 safe laws, proof-only):
- `spin_once.bend` proves commands_run, relating the complete actual Battle.run
  result to Dead.trace of the same inputs/PID/score. head transports Once.prove
  through that equality to certify a lethal first hit plus arbitrary remaining
  inputs. It derives actual corpse membership, final uniqueness, dead flag and
  exactly-one filtered reward count; it assumes no post-state facts.
- prepend uses a proved Clear prefix to retain a later target's Once.Certificate
  over the full combined result. prepend_all applies it to every remaining
  selected target, deriving prefix exclusion from actual strike notices (Only)
  and distinct selected IDs. No earlier rewards are discarded from the result.
- Certificates is indexed by the full ordered selection, the full indexed
  powers and the same actual final Battle.Result. run constructs a certificate
  for every member. Its recursive call receives the actual previous strike's
  final state, with remaining full-record sources, monster uniqueness and
  recipient membership derived from combat frame/actor proofs. Earlier hits
  may change game phase, including a boss reward before another selected hit.
- Bundle retains the powers and all certificates. Prefix retains the complete
  actual LiveCombat.Result, equality to the indexed result and the Bundle for
  the actual selected list. ready uses the whole pack/view equality; filtered
  derives Sources and selected uniqueness from the actual filter. planned/live
  use the full actual LiveSpin.Builder and actual prepared state. Rejected
  admission and accepted empty selections produce empty indexed bundles.
- choose/pick use full-record selection membership to extract a certificate for
  any selected target, including later targets with their own calculated power.
  live_history consumes an arbitrary affine timed request suffix once, starting
  from the complete actual spin output world/maps. live_exactly_once proves one
  original-MID reward across all initial spin notices and all suffix notices.
  Builders are consumed once; no suffix is recomputed for other targets within
  an invocation. The theorem is universally quantified over the chosen member.
- This closes the generic initial all-lethal spin prefix and arbitrary selected
  member no-tick history bridge. It assumes unique actual monster IDs and that
  each actual selected power is sufficient for its own selected record. Mixed
  lethal/nonlethal selected powers, actual tick/wait/respawn lifetime histories,
  finalization/reload and all six original full requirements remain OPEN.

Actual lethal spin history validation (recorded after installation):
- All 13 safe laws and the mandatory installed proof closure pass. Original 15
  statements remain unchanged. All 333 constructive laws pass: prior 315 plus
  arbitrary full-builder prefix, arbitrary selected-member/affine-request
  history and exact count; boss-first, normal-after-boss, boss-last, normal-first,
  multiplayer first/later and skipped-ineligible histories; all-seed actual
  creation prefix/member history; empty, missing-player and cooling prefixes;
  actual seven-command mixed later-target/boss counts and actual later power.
- Every target certificate refers to the same complete actual spin output.
  The later normal target still receives exactly one reward after an earlier
  boss changes phase; reversed ordering and varying powers retain the actual
  selected identity. The later target's certificate computes damage100 from
  its own power, while the preceding boss uses damage1.
- Seven intended type failures reject stale recursive state, omitted prefix
  notices, replacing actual damage with zero, giving the full builder a stale
  empty roster, replacing actual selection with an empty list, substituting
  zero for the chosen target's power and claiming membership for an unselected
  corpse. Exact mismatch locations were inspected. The corpse negative's
  initial misplaced import was corrected before recording its intended failure.
- Generated main C is byte-for-byte identical to installed validated C. Runtime
  sources and native binary are unchanged. Previous 1044 JS / 140 native and
  fresh bot/GUI/session/protocol/save checks from bqlive_attack apply to this
  exact runtime and were not rerun for this proof-only change.
- Evidence, backup and final hashes: `/private/tmp/bqspin_once`. Kernel,
  compiler and unrelated hashes match the prior ledger. Generic all-lethal
  spin prefixes now connect any selected member to an arbitrary actual timed
  no-tick combat suffix. Mixed lethal/nonlethal powers, tick/respawn lifetime
  composition and all six original full requirements remain OPEN.

Mixed-damage spin reward history (10 safe laws, proof-only):
- `spin_mixed.bend` removes the previous requirement that every selected power
  be lethal. MixedSpin.Slot identifies one actual full selected record and
  proves sufficient damage for that record's own indexed Power. Other powers
  are unrestricted. member derives actual selection membership from Slot.
- run constructs a Chosen/Once.Certificate for that target over the complete
  actual Battle.run. At the chosen head, SpinOnce.head permits arbitrary later
  inputs. For a later target, actual earlier hits derive remaining full-record
  sources, monster-ID uniqueness and current recipient membership before the
  recursive call. No lethality condition is imposed on those earlier powers.
- Selected-ID distinctness and Slot membership establish that an earlier hit's
  actual notices contain no tracked-target reward. prepend retains those
  notices in the complete result while transporting the derived exactly-one
  certificate. Final corpse membership/dead flag/uniqueness are derived.
- pack/ready/filtered connect that certificate to the actual complete live spin
  result and maps. BuiltSlot evaluates the same full affine LiveSpin.Builder on
  actual prepared monsters, admitted player, metadata and actual selected list.
  Missing admission yields Empty; a Slot cannot claim a rejected or unselected
  target. planned/live consume the actual builder once and derive admission.
- live_history and live_exactly_once compose an arbitrary affine timed command
  suffix from that actual spin world. They retain all original spin notices
  and all subsequent command results, proving original-MID count=1. Neither
  initial nor suffix planners are rerun in a proof invocation.
- Generic mixed-power initial spin/no-tick histories are now covered. The
  theorem assumes unique actual monster IDs and sufficient actual damage for
  the tracked selected record. Actual tick/wait/respawn lifetime histories,
  reward finalization/reload and all six original full requirements remain
  OPEN. This reward-count proof makes no arithmetic-wrap or authentication claim.

Mixed-damage spin history validation (recorded after installation):
- All 10 safe laws and the mandatory installed proof closure pass. Original 15
  statements remain unchanged. All 352 constructive laws pass: prior 333 plus
  arbitrary full-builder prefix/history/count; arbitrary earlier and later U32
  damage; zero/MAX earlier damage, boss then partial and partial then boss;
  actual multiplayer state-dependent history/powers/health/rewards/recipients/
  suffix count; empty suffix; derived selection membership; skipped ineligible
  targets; all-seed actual creation conditional on the actual chosen Slot.
- The arbitrary-other-damage proofs impose no lethality requirement on the
  earlier or later target. Concrete zero and MAX damage are accepted without
  a unary MAX comparison premise. The actual metadata-dependent calculator
  produces powers [42,100], leaving the earlier monster at HP158 and killing
  the later monster. Only MID8 is rewarded; player kill counters are [1,0].
  Its complete spin plus actual seven-command timed suffix still has MID8
  reward count=1. Boss-first and boss-last mixed cases also check.
- Seven intended type failures reject insufficient chosen damage, a different
  full target record, an unselected corpse, missing player admission, stale
  recursive state, supplying a stale roster to the full builder, and omitting
  earlier notices from the complete result. Exact error locations/mismatches
  were inspected; no negative mutation is installed.
- Generated main C is byte-for-byte identical to installed validated C. Runtime
  sources and native binary are unchanged. Previous 1044 JS / 140 native and
  fresh bot/GUI/session/protocol/save checks from bqlive_attack apply to this
  exact runtime and were not rerun for this proof-only change.
- Evidence, backup and final hashes: `/private/tmp/bqspin_mixed`. Kernel,
  compiler and unrelated hashes match the prior ledger. Generic initial mixed
  spin prefixes now connect the chosen lethal target to an arbitrary actual
  timed no-tick suffix without requiring other selected hits to be lethal.
  Tick/respawn lifetime composition and all six original full scopes remain OPEN.

Actual monster lifetime boundary (21 safe laws, proof-only):
- `monster_life.bend` defines the rebirth event from the exact Monsters.tick
  phase and AI.commit plan. Active/Dormant phases emit no event; Rebirth emits
  one precisely for Spawn. spawn_dead covers normalization of zero maximum HP.
  wait_dead, rebirth_dead, dead_tick and step_dead prove the actual output dead
  flag equals zero on that event and one otherwise, given original dead=1.
- plan_event/event_spawn derive the actual Spawn plan requirement. gate_event/
  boundary prove the exact timer conditions: timer differs from MAX, timer<=1,
  and the committed plan is Spawn. permanent_event excludes a new life for a
  permanent corpse. no_event_dead/event_alive expose the two output states.
- Certificate retains the entire actual AI.Step and equality to AI.step of the
  original record and actual plan. classify derives its conserved ID/zone key,
  no outgoing attack and exact dead/event relationship. It assumes no post-state
  fields. Timer-ready Rest/Move/Attack keep the old dead record; they do not
  revive it. Waiting may change the full record, so full-corpse equality cannot
  be used across waiting ticks.
- plan_for follows the same ordered plan position as AI.run; missing plans
  default to Rest. prepend_head/prepend_member/run_member derive the exact
  actual updated record's membership in the complete AI.run output. Follow ties
  that membership and lifetime certificate to the same original input member
  and actual positional plan. Other roster members may be alive or dead.
- step_id/run_unique/final_lookup derive Some of that exact updated record by
  its original MID when original IDs are unique. Positional membership tracking
  itself needs no uniqueness premise; it does not substitute an ambiguous ID
  search for the actual record's position.
- This completes classification and tracking through an actual ordered AI.run.
  Lifting the changed record/event through zone partitioning, actual planning,
  full LiveTick and mixed reward histories remains OPEN, along with respawn
  epoch composition, finalization/reload and all six original full scopes.

Monster lifetime boundary validation (recorded after installation):
- All 21 safe laws and the mandatory installed proof closure pass. Original 15
  statements remain unchanged. All 375 constructive laws pass: prior 352 plus
  arbitrary step certificate, actual positional roster tracking, unique final
  ID lookup, exact boundary conditions, arbitrary waiting plan, waiting timer
  decrement/death, timer1/0 respawns, alive result and Spawn requirement, ready
  non-spawn actions, permanent event exclusion/ignored spawn, zero maximum HP
  normalization, live-monster Spawn rejection, actual ordered/missing/extra-plan
  behavior and arbitrary dead-step attack exclusion.
- Concrete waiting timer2 becomes1 without spawning. Timers1/0 with Spawn
  produce the exact new record, retaining MID7/zone2 while adopting kind6,
  rare1, position12/13 and HP/max50; target/attack/dead/timer reset to zero.
  Rest/Move/Attack at timer1 preserve the dead record and emit no attack.
  Permanent MAX ignores Spawn. Requested maxHP0 produces a live HP/max1 record.
- Actual positional tracking is tested on a mixed roster with an alive member
  and two distinct dead full records sharing MID7. That proof needs no unique-ID
  assumption. Final ID lookup is separately checked on a unique roster. Missing
  plans use Rest; extra Spawn plans cannot add monsters.
- Seven intended type failures reject a spawn event in Dormant, declaring all
  Rebirth phases alive without Spawn, taking the wrong positional plan, reusing
  the stale original record as actual output, reviving a permanent corpse,
  claiming a waiting record is unchanged, and supplying duplicate IDs to the
  unique lookup theorem. Exact error locations and mismatches were inspected.
- Generated main C is byte-for-byte identical to installed validated C. Runtime
  sources and native binary are unchanged. Previous 1044 JS / 140 native and
  fresh bot/GUI/session/protocol/save checks from bqlive_attack apply to this
  exact runtime and were not rerun for this proof-only change.
- Evidence, backup and final hashes: `/private/tmp/bqmonster_life`. Kernel,
  compiler and unrelated hashes match the prior ledger. Actual ordered AI-run
  lifetime classification/tracking is proved; zone/planner/full LiveTick lifting,
  mixed reward epoch histories and all six original full scopes remain OPEN.

Planned zone lifetime tracking (12 safe laws, proof-only):
- `zone_life.bend` derives membership of an original full record in its own
  Roster.zone filter. keep_member/zone_member preserve that exact record.
  concat_left/right and merge_left/right carry an updated record through the
  actual ordered output merges, including other zones' monsters and hits.
- plans selects p0/p1/p2/p3 using a checked Zones.Valid witness. embed proves
  membership from that exact selected zone's AI.run in the complete actual
  AI.run_zones result. Arbitrary U32 zones are not assumed valid.
- plan uses Life.plan_for at the target's position in its actual zone-filtered
  list. run_member derives the exact AI.step output's membership after all zone
  updates and merges. Follow retains Life.Certificate and membership for that
  same actual plan and output, preserving ID/zone and exact respawn/dead status.
- final_lookup derives Some of the actual updated record by its original MID
  using input zone validity and monster uniqueness, actual run_zones uniqueness,
  positional membership and actual step-ID preservation. No final lookup or
  unchanged-corpse assumption is introduced.
- run_planned/planned_plan use exactly Planning.actions' four context-based
  plan lists, maps and tick. planned instantiates the zone certificate for those
  real plans. finish lifts it into the actual active Planning.finish monster
  roster while the implementation applies player hits and advances metadata.
- This closes zone filtering/merging and active context-based planning for the
  tracked monster's lifetime certificate. Actual AIRefs context selection,
  complete LiveTick including inactive worlds, mixed reward epochs, persistence
  and all six original full requirements remain OPEN.

Planned zone lifetime validation (recorded after installation):
- All 12 safe laws and the mandatory installed proof closure pass. Original 15
  statements remain unchanged. All 392 constructive laws pass: prior 375 plus
  arbitrary own-zone membership, zone follow, actual planned follow and active
  Planning.finish; each of five interleaved records covering all four zones;
  actual filtered order, second-within-zone plan, missing local plan, exact
  merged output, missing-plan death preservation, unique final lookup, arbitrary
  maps/tick/context waiting plan and actual active finish timer decrement.
- The interleaved input zones [3,0,2,1,2] become the actual merged order
  [0,1,2,2,3]. The fifth global record takes the second zone2 plan and respawns
  with its exact new fields. The earlier waiting zone2 record only decrements
  its timer. The zone1 Rest and zone3 Attack plans do not revive dead records.
  If the second zone2 plan is absent, that target receives Rest and stays dead.
- The waiting-plan probe matches empty/nonempty context lists so its actual
  selected plan reduces to Rest in both cases. This resolved its initial
  definitional-equality failure; the theorem was not weakened.
- Seven intended type failures reject wrong-zone plans, global rather than
  filtered position, dropping a merged prefix, substituting zero for the actual
  planner clock, using an inactive finish in the active theorem, a zone4 witness
  and claiming the old corpse survives an actual respawn. Exact mismatches and
  error locations were inspected; no negative mutation is installed.
- Generated main C is byte-for-byte identical to installed validated C. Runtime
  sources and native binary are unchanged. Previous 1044 JS / 140 native and
  fresh bot/GUI/session/protocol/save checks from bqlive_attack apply to this
  exact runtime and were not rerun for this proof-only change.
- Evidence, backup and final hashes: `/private/tmp/bqzone_life`. Kernel,
  compiler and unrelated hashes match the prior ledger. Active Planning.finish
  now retains the exact zone-planned lifetime certificate. Actual AIRefs context
  selection, full LiveTick and mixed reward epochs remain OPEN, as do all six
  original full requirements.

Actual live tick lifetime tracking (14 safe laws, proof-only):
- tick_life.bend represents an inactive tick by None and an active tick by its
  actual selected AI plan. Tracked retains exact updated-record membership,
  ID/zone preservation, dead status conditional on the actual respawn event,
  no outgoing hit by the initially dead monster, and derived output uniqueness.
- mode selects the real per-zone plan using actual post-upkeep players, damage
  lists, maps and metadata clock. finish follows AIRefs.finish; simulate and
  finish_tick follow actual damage unpacking and LiveTick output packing.
- prepare_member transports original membership through actual Locomotion.begin.
  decision reconstructs exactly LiveTick.run's preparation, damages and context
  selection. run derives Tracked for the actual final world, using initial
  membership, death, valid zones and unique monster IDs. Inactive worlds retain
  the original record; they do not execute AI upkeep or decrement its timer.
- after_id and lookup recover the exact updated record by its original MID.
  no_event_dead and event_alive distinguish a corpse from an actual respawn.
- continue, after_commands and after_commands_zero feed the actual updated
  corpse and complete post-tick world into arbitrary affine timed combat request
  sequences. When the tick did not respawn the monster, its filtered reward
  count remains zero. Updated membership and uniqueness are derived, not assumed.
- This composes one actual tick with arbitrary subsequent combat commands.
  Arbitrary mixed multiple-tick histories, per-lifetime positive reward liveness,
  quest/finalization/reload guarantees and all six original full scopes remain
  OPEN. No outgoing AI hit is not a global player-counter conservation theorem.

Actual live tick lifetime validation (recorded after installation):
- All 14 safe laws and the mandatory installed proof closure pass. Original 15
  statements remain unchanged. All 413 constructive laws pass (prior 392 plus
  21): arbitrary actual tick certificate and final lookup, arbitrary timed combat
  suffix safety and zero rewards; actual attack then tick with exact timer79
  corpse, arbitrary suffix and seven real combat requests; inactive unchanged
  corpse and arbitrary suffix; permanent corpse; actual ready respawn event,
  live updated record and final lookup; actual tick map preservation.
- A real lethal attack produces timer80; the following active tick produces
  timer79. Lookup and subsequent reward exclusion use that updated record.
  The inactive case preserves timer1, while the active timer1 case uses the
  actual Population rebirth plan and produces a live record.
- Seven intended type failures reject inactive AI upkeep, swapped damage
  contexts, stale planner clock, pre-tick command world, pre-tick corpse,
  allowing a respawn in the corpse continuation, and claiming a respawn is dead.
  The first damage mutation reused an affine list and was rejected for that
  unrelated reason; swapping both lists corrected the negative test so it
  checks the intended context mismatch. No negative mutation is installed.
- Generated main C is byte-for-byte identical to installed validated C. Runtime
  sources and native binary are unchanged. Previous 1044 JS / 140 native and
  bot/GUI/session/protocol/save checks from bqlive_attack apply to this exact
  runtime and were not rerun for this proof-only change.
- Evidence, backup and final hashes: /private/tmp/bqtick_life. Kernel, compiler
  and unrelated hashes match the prior ledger. Complete actual LiveTick
  lifetime tracking and one tick followed by arbitrary timed combat commands
  are covered. Arbitrary mixed multiple-tick histories, reward epochs and all
  six original full requirements remain OPEN.

Permanent death mixed histories (16 safe laws, proof-only):
- permanent_history.bend reuses the actual History.trace request interpreter,
  including affine callbacks, recorded actual plans and before/after worlds.
  It introduces no substitute command or tick transition.
- bounds extracts valid monster zones and unique IDs from SeededWorld.OK.
  member_zone derives the tracked record's own valid zone from exact membership.
  after proves every actual AI plan leaves a permanently dead record unchanged,
  including Spawn; event proves it cannot cause a respawn. Both require dead1
  and the actual permanent timer MAX. Neither holds merely because HP is zero.
- tick_from/tick carry the exact original record into the actual full tick's
  world using TickLife.run and Permanent.after. step also handles arbitrary
  actual timed combat operations via LiveDead.timed_safe. It retains actual
  membership, output uniqueness and exclusion from that operation's notices.
- operation_notices reads each actual recorded command's original world, clock
  and plan; notices concatenates every command's Battle.Notices in order.
  Tick entries contribute no Battle.Notices. This is a combat-reward statement,
  not a claim that ticks have no player events or counter effects.
- safe structurally consumes arbitrary History.Request lists and evaluates
  each planner once against actual timed preparation. It uses History.step_seeded
  to derive the next world's invariant at every step, and transports the exact
  same permanent corpse. Safe retains the actual entire Run, exact final
  membership and uniqueness, and Clear for all actual recorded command notices.
  add/empty/eliminate support affine composition; zero and lookup derive zero
  filtered rewards and final Some of that exact full record by its original MID.
- compose_once/after_once/exactly_once retain the real lethal prefix's notices
  and all mixed suffix notices. Given Once.Certificate for AttackOnce.view(first),
  valid SeededWorld.OK of the actual first result world, and permanent timer of
  the actual killed record, the entire prefix-plus-suffix MID count is one.
  These prefix conditions are explicit; the theorem does not assume a count
  for the suffix or final record membership/uniqueness.
- This establishes arbitrary mixed tick/command reward exclusion for permanent
  deaths and its composition with a verified lethal result. Ordinary waiting
  corpses, actual respawn boundaries and repeated reward epochs remain OPEN,
  as do quests/finalization/reload and all six original full requirements.

Permanent death mixed history validation (recorded after installation):
- All 16 safe laws and the mandatory installed proof closure pass. Original 15
  statements remain unchanged. All 430 constructive laws pass: prior413 plus17.
  New laws instantiate arbitrary affine mixed history safety, zero rewards,
  exact final lookup and prefix-plus-history exactly once; arbitrary AI plan
  permanence and no event; Spawn ignored and inactive unchanged; actual tick
  for arbitrary phase/timer and actual command for arbitrary clock/kind/PID/
  score/plan; a nine-operation mixed history and its actual world.
- The concrete history interleaves five ticks and four commands, two player
  IDs and missing PID99, clock MAX then0, tick timer MAX/0/2 and actual planners.
  MID7 remains the exact permanent corpse with zero new rewards; MID8 receives
  one real reward. The inactive phase also preserves the original corpse.
  Actual final maps and the exact nine-entry history length are checked.
- The initial member-zone proof needed an erased roster index so recursion
  decreases the membership witness. Forward declarations were reordered to
  follow the language's definition order. Constructive probe alias mistakes
  (B versus Battle, A versus AI) were fixed; statements were not weakened.
- Seven intended type failures reject ordinary timer80 as permanent, a living
  monster, substituting an empty command plan, using the pre-clock world for
  notices, dropping the prefix notices, skipping the actual tick world during
  recursive composition, and claiming two rewards. Mismatches and error
  locations were inspected. No negative mutation is installed.
- Generated main C is byte-for-byte identical to installed validated C. Runtime
  sources and native binary are unchanged. Prior 1044 JS / 140 native and
  bot/GUI/session/protocol/save checks from bqlive_attack apply to this exact
  runtime and were not rerun for this proof-only batch.
- Evidence, backup and final hashes: /private/tmp/bqpermanent_history. Kernel,
  compiler and unrelated hashes match the prior ledger. Permanent death now
  composes across arbitrary actual mixed histories. Ordinary respawn lifetime
  histories and all six original full requirements remain OPEN.

Ordinary respawn prefixes (16 safe laws, proof-only):
- epoch_history.bend records the complete actual History.trace result and a
  Path linking every before-world, recorded operation, actual step output and
  final world. record/record_add consume each affine planner once against its
  actual timed preparation. Neither the suffix nor its final world is dropped.
- Follow distinguishes Done, Wait, Command and Birth. Tick cases carry original
  membership/death, own-zone validity, the real TickLife.decision plan, its
  Tracked certificate and the actual event equality. Wait continues with the
  changed full monster record and preserved ID. Birth retains the untouched
  remaining entries and stops the current corpse's exclusion guarantee.
- Command retains the actual timed LiveCombat result, its equality to the
  recorded operation, LiveDead.Safe, and its continuation on the actual world.
  The command plan/clock/result cannot be substituted independently.
- wait_from/tick_branch/step_follow construct these cases. follow folds the
  actual Path with a continuation that accepts the next exact dead member;
  History.step_seeded derives valid worlds throughout. from_record/report
  produce Follow for arbitrary finite affine mixed request histories starting
  with a dead member of a valid seeded world. No permanent timer is required.
- prefix reconstructs each exact entry through the first respawn tick, including
  all earlier commands and waiting ticks; remaining retains all later entries.
  split proves prefix plus remaining equals the original complete entry list.
  The prefix function is structurally recursive in Follow; its runtime world
  and monster are supplied using the matching indices in these theorems.
- notices reads the stored actual command results. notices_exact equates it
  with Permanent.notices of that reconstructed prefix. clear/zero prove the
  original MID has zero combat reward notices there, transporting ID equality
  through changing corpse records. No outgoing tick player-event or global
  counter-conservation claim is inferred from this Battle.Notice theorem.
- reborn identifies whether the certificate reached Birth. exhausted proves
  the remaining list is empty when reborn is False, so the prefix covers the
  whole history in that case. Birth requires an actual True respawn event.
- cut_from/cut retain the actual full Run, Follow, prefix/remainder, both exact
  projection equalities, the full-history split and prefix reward count zero.
  This is the end-to-end result for arbitrary actual mixed histories from a
  valid seeded world. Ordinary timers can change, and legitimate later rewards
  after rebirth are preserved outside this dead lifetime's prefix.
- Composition with positive lethal prefixes for ordinary lifetimes, repeated
  epochs, quests/finalization/reload and all six original full scopes remain
  OPEN. The previous permanent-history exactly-once theorem remains intact.

Ordinary respawn prefix validation (recorded after installation):
- All 16 safe laws and the mandatory installed proof closure pass. Original 15
  statements remain unchanged. All 450 constructive laws pass: prior430 plus20.
  Arbitrary actual record, report and cut; arbitrary split, zero and exhausted
  conclusions; concrete full Follow/Cut, actual timer decrement, Birth marker,
  exact prefix/suffix lengths and contents, prefix zero, full split and real
  later reward; and a short waiting history with no birth and empty remainder.
- The concrete actual history has Tick2, clockMAX/Spin/PID99, Tick2, then
  clock0/Attack/PID1 with a lethal plan. The tracked MID7 timer2 becomes timer1,
  survives the intervening missing-player command, then actually respawns.
  The certified prefix contains exactly the first three operations, with zero
  MID7 rewards. The retained one-command suffix kills the respawned monster
  and produces one real MID7 reward; the whole history therefore counts one.
  The proof correctly preserves that legitimate later reward.
- A one-tick waiting history reaches Done with reborn False, empty remaining
  entries and zero rewards. Initial timer2 does not falsely count as a birth.
  Concrete fixtures use actual transitions and direct Follow witnesses; they
  are not claimed to satisfy the generic seeded-world premise with empty maps.
- The initial path fold failed structural recursion while its world index was
  live. Path now reifies each start world with an equality to the erased index;
  the fold decreases the actual Path and transports the exact world invariant.
  Prefix generation similarly recurses in Follow before receiving runtime
  world/monster arguments. No termination bypass or weaker theorem was used.
- Seven intended type failures reject premature Birth, continuation with the
  stale corpse, discarding the post-birth suffix, dropping a waiting tick from
  the prefix, dropping a command's notices, using the wrong command clock,
  and claiming that a Birth exhausts the remaining history. Error locations
  and semantic mismatches were inspected. No negative mutation is installed.
- Generated main C is byte-for-byte identical to installed validated C. Runtime
  sources and native binary are unchanged. Prior 1044 JS / 140 native and
  bot/GUI/session/protocol/save checks from bqlive_attack apply to this exact
  runtime and were not rerun for this proof-only batch.
- Evidence, backup and final hashes: /private/tmp/bqepoch_history. Kernel,
  compiler and unrelated hashes match the prior ledger. Ordinary corpse
  reward exclusion now spans arbitrary actual mixed histories up to first
  respawn. Positive prefix composition, repeated reward epochs and all six
  original full requirements remain OPEN.

Ordinary lifetime exactly-once composition (10 safe laws, proof-only):
- epoch_once.bend keeps Epoch.Cut as the exact actual mixed run, corpse lifetime
  prefix, remaining entries and first-respawn evidence. prefix and born project
  its stored prefix and actual Follow event marker.
- concat_nil plus full_prefix show that when born is False, the certified
  prefix equals the full actual History.entries(run). This uses the stored
  split, remaining equality and Epoch.exhausted; it does not assume the history
  was empty or contained no ticks. prefix_zero and full_zero expose the
  filtered original corpse MID reward count for the prefix or entire history.
- Lifetime.Certificate retains the Cut for the actual killed record in the
  actual first LiveCombat result world and proves one original-MID reward in
  that result's notices plus the Cut's certified prefix notices.
- compose transports Once.after_id and combines the real initial reward with
  Cut.zero via LiveDead.one_plus_zero. after_once derives the actual corpse's
  membership/death from Once.Certificate for AttackOnce.view(first) and obtains
  the Cut through arbitrary affine mixed requests starting from that actual
  first world. No permanent timer or fixed corpse record is assumed.
- at derives post-command SeededWorld.OK from the initial world using the
  actual LiveCombat.at result. run invokes the affine initial planner once
  against actual preparation, then uses that exact plan and lethal certificate.
  Both retain the actual mixed suffix, initial result, maps, MID and damage.
- exactly_once exposes the initial-plus-dead-lifetime-prefix count. full_once
  proves the initial-plus-complete-history count when the actual Cut reports
  no respawn. It makes no unconditional one-reward claim across legitimate
  later respawns; Epoch's retained later history remains intact.
- The lethal certificate, admission/selection/damage premises needed to obtain
  it, and initial seeded-world validity remain explicit. Repeated lifetime
  composition, positive eventual-kill liveness, quests/finalization/reload and
  all six original full scopes remain OPEN.

Ordinary lifetime exactly-once validation (recorded after installation):
- All 10 safe laws and the mandatory installed proof closure pass. Original 15
  statements remain unchanged. All 469 constructive laws pass: prior450 plus19.
  Arbitrary full-prefix and whole-history zero; arbitrary after_once, actual at
  and affine run wrappers; arbitrary prefix exactly once and complete-history
  exactly once under no actual respawn; concrete lethal certificate, lifetime
  certificate, no-birth marker, full-prefix identity, zero suffix and one total
  reward; unrelated reward, total notices, exact final corpse timer; and the
  prior real rebirth case's True marker and zero dead-lifetime prefix.
- The concrete first actual attack kills MID7 and emits one reward. A real
  tick updates its corpse timer80 to79. Another player's actual spin kills
  MID8. The subsequent mixed history emits zero new MID7 rewards, its lifetime
  prefix equals its entire entry list, and the initial-plus-history count is
  exactly one for MID7. MID8 also counts one and the combined notice count is
  two. Final MID7 lookup returns the exact timer79 corpse.
- The ordinary rebirth fixture from the preceding batch still reports born
  True and has prefix reward count zero; its legitimate later reward is
  retained outside that prefix. It cannot satisfy the no-birth premise.
- A parenthesis typo in the initial compose statement was corrected before
  the module passed. No statement was weakened and no unsafe bypass was used.
- Seven intended type failures reject a zero-reward initial prefix, treating
  respawn as exhaustion, losing the actual maps, reusing input validity as
  post-command validity, substituting an empty plan, discarding initial
  notices, and extending exactly_once to the full history unconditionally.
  Error locations and mismatches were inspected; no negative is installed.
- Generated main C is byte-for-byte identical to installed validated C. Runtime
  sources and native binary are unchanged. Prior 1044 JS / 140 native and
  bot/GUI/session/protocol/save checks from bqlive_attack apply to this exact
  runtime and were not rerun for this proof-only batch.
- Evidence, backup and final hashes: /private/tmp/bqepoch_once. Kernel, compiler
  and unrelated hashes match the prior ledger. Exactly-once lethal rewards now
  compose through ordinary actual mixed dead lifetimes and through the whole
  mixed history when no respawn occurs. Repeated lifetimes, liveness and all
  six original full requirements remain OPEN.
