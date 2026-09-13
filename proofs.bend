# Original Bendquest guarantees, stated against the kernel used by the server.
# Each witness must satisfy the full original statement.
import Base
import ./epoch_once.bend as Lifetime
import ./epoch_history.bend as Epoch
import ./permanent_history.bend as Permanent
import ./tick_life.bend as TickLife
import ./zone_life.bend as ZoneLife
import ./monster_life.bend as Life
import ./spin_mixed.bend as MixedSpin
import ./spin_once.bend as SpinOnce
import ./attack_once.bend as AttackOnce
import ./live_dead.bend as LiveDead
import ./reward_once.bend as Once
import ./dead_rewards.bend as Dead
import ./spin_lethal.bend as SpinKill
import ./combat_lethal.bend as Lethal
import ./combat_bounds.bend as Bounds
import ./combat_history.bend as History
import ./combat_transition.bend as Transition
import ./combat_cooling.bend as Cooling
import ./combat_mixed.bend as Mixed
import ./combat_foreign.bend as Foreign
import ./combat_other.bend as Other
import ./cooldown_actor.bend as Tracked
import ./cooldown_roster.bend as TickCooldown
import ./cooldown_tick.bend as Cooldown
import ./combat_spam.bend as Spam
import ./combat_clock.bend as CombatClock
import ./combat_rejected.bend as Rejected
import ./combat_repeat.bend as Repeat
import ./live_attack.bend as LiveAttack
import ./live_spin.bend as LiveSpin
import ./combat_admitted.bend as Admitted
import ./combat_actor.bend as Actor
import ./combat_frame.bend as CombatFrame
import ./spin_plans.bend as SpinPlans
import ./combat_targets.bend as CombatTargets
import ./target_plans.bend as TargetPlans
import ./live_combat.bend as LiveCombat
import ./live_commands.bend as LiveCommands
import ./live_tick.bend as LiveTick
import ./seeded_trace.bend as SeededTrace
import ./channel_restart.bend as ChannelRestart
import ./restart_trace.bend as RestartTrace
import ./rebinding.bend as Rebinding
import ./rebuild.bend as Rebuild
import ./id_capacity.bend as IdCapacity
import ./word_successor.bend as WordSuccessor
import ./admission_search.bend as AdmissionSearch
import ./tick_bindings.bend as TickBindings
import ./frame_bindings.bend as FrameBindings
import ./disconnect.bend as Disconnect
import ./creation.bend as Creation
import ./selection.bend as Selection
import ./connections.bend as Connections
import ./sessions.bend as Sessions
import ./worldstate.bend as WorldState
import ./nonzero.bend as Nonzero
import ./ai_refs.bend as AIRefs
import ./targeting.bend as Targeting
import ./membership.bend as Membership
import ./references.bend as References
import ./playerids.bend as PlayerIds
import ./admission.bend as Admission
import ./allocation.bend as Allocation
import ./identity.bend as Identity
import ./planning.bend as Planning
import ./population.bend as Population
import ./placement.bend as Placement
import ./remainders.bend as Remainders
import ./pursuit.bend as Pursuit
import ./habitat.bend as Habitat
import ./landscape.bend as Landscape
import ./locomotion.bend as L
import ./terrain.bend as Terrain
import ./battle.bend as Battle
import ./combat.bend as Combat
import ./navigation.bend as Navigation
import ./interactions.bend as Interactions
import ./payouts.bend as Payouts
import ./inventory.bend as Inventory
import ./game.bend as Game
import ./health.bend as Health
import ./growth.bend as Growth
import ./rewards.bend as Rewards
import ./vitals.bend as Vitals
import ./monsters.bend as Monsters
import ./roster.bend as Roster
import ./ai.bend as AI
import ./zones.bend as Zones
import ./players.bend as Players
import ./simulation.bend as Simulation

# Rejected actions leave the entire hero unchanged.
law rejected_op_is_noop:
  for +op: Game.Bq.HOp
  for +h: Game.Bq.Hero
  for +given_2: {Game.Bq.hop_ok(op, h) == False{} : Bool}
  {Game.Bq.hero_step(op, h) == h : Game.Bq.Hero}

def rejected_op_is_noop(op, h, given_2):
  Game.Bq.rejected_op_is_noop(op, h, given_2)

# Equipping preserves every item count.
law equip_preserves_census:
  for +k: Nat
  for +h: Game.Bq.Hero
  {Game.Bq.census(Game.Bq.hero_step(Game.Bq.HOp.Equip{k}, h)) == Game.Bq.census(h) : Game.Bq.Bag}

def equip_preserves_census(k, h):
  Game.Bq.equip_preserves_census(k, h)

# Unequipping preserves every item count.
law unequip_preserves_census:
  for +s: Game.Bq.ISlot
  for +h: Game.Bq.Hero
  {Game.Bq.census(Game.Bq.hero_step(Game.Bq.HOp.Unequip{s}, h)) == Game.Bq.census(h) : Game.Bq.Bag}

def unequip_preserves_census(s, h):
  Game.Bq.unequip_preserves_census(s, h)

# Any sequence of transfers preserves every item count.
law transfers_preserve_census:
  for +ops: List<&2, Game.Bq.HOp>
  for +given_1: {Game.Bq.transfers(ops) == True{} : Bool}
  for +h: Game.Bq.Hero
  {Game.Bq.census(Game.Bq.hero_run(ops, h)) == Game.Bq.census(h) : Game.Bq.Bag}

def transfers_preserve_census(ops, given_1, h):
  Game.Bq.transfers_preserve_census(ops, given_1, h)

# A valid purchase adds exactly the purchased item.
law buy_mints_exactly_one:
  for +k: Nat
  for +h: Game.Bq.Hero
  for +given_2: {Game.Bq.buy_ok(k, h) == True{} : Bool}
  {Game.Bq.census(Game.Bq.hero_step(Game.Bq.HOp.Buy{k}, h)) == Game.Bq.Bag.add(Game.Bq.one(k), Game.Bq.census(h)) : Game.Bq.Bag}

def buy_mints_exactly_one(k, h, given_2):
  Game.Bq.buy_mints_exactly_one(k, h, given_2)

# A valid purchase spends exactly its price.
law buy_burns_exact_gold:
  for +k: Nat
  for +h: Game.Bq.Hero
  for +given_2: {Game.Bq.buy_ok(k, h) == True{} : Bool}
  {Game.Bq.Nat.add(Game.Bq.iprice(k), Game.Bq.hero_gold(Game.Bq.hero_step(Game.Bq.HOp.Buy{k}, h))) == Game.Bq.hero_gold(h) : Nat}

def buy_burns_exact_gold(k, h, given_2):
  Game.Bq.buy_burns_exact_gold(k, h, given_2)

# A priced item with sufficient gold is always purchased.
law shop_never_refuses_a_funded_buy:
  for +k: Nat
  for +given_1: {Game.Bq.Nat.lt(0n, Game.Bq.iprice(k)) == True{} : Bool}
  for +h: Game.Bq.Hero
  for +given_3: {Game.Bq.Nat.le(Game.Bq.iprice(k), Game.Bq.hero_gold(h)) == True{} : Bool}
  {Game.Bq.census(Game.Bq.hero_step(Game.Bq.HOp.Buy{k}, h)) == Game.Bq.Bag.add(Game.Bq.one(k), Game.Bq.census(h)) : Game.Bq.Bag}

def shop_never_refuses_a_funded_buy(k, given_1, h, given_3):
  Game.Bq.shop_never_refuses_a_funded_buy(k, given_1, h, given_3)

# Drinking a potion consumes exactly one potion.
law quaff_burns_one_potion:
  for +h: Game.Bq.Hero
  for +given_1: {Game.Bq.quaff_ok(h) == True{} : Bool}
  {Game.Bq.Bag.add(Game.Bq.one(Game.Bq.POTION), Game.Bq.census(Game.Bq.hero_step(Game.Bq.HOp.Quaff{}, h))) == Game.Bq.census(h) : Game.Bq.Bag}

def quaff_burns_one_potion(h, given_1):
  Game.Bq.quaff_burns_one_potion(h, given_1)

# Only level-up creates stat points, exactly three.
law ops_respect_stat_budget:
  for +op: Game.Bq.HOp
  for +h: Game.Bq.Hero
  {Game.Bq.stat_total(Game.Bq.hero_step(op, h)) == Game.Bq.stat_expect(op, h) : Nat}

def ops_respect_stat_budget(op, h):
  Game.Bq.ops_respect_stat_budget(op, h)

# Every operation preserves legal equipment.
law ops_respect_requirements:
  for +op: Game.Bq.HOp
  for +h: Game.Bq.Hero
  for +given_2: Game.Bq.WellEquipped(h)
  Game.Bq.WellEquipped(Game.Bq.hero_step(op, h))

def ops_respect_requirements(op, h, given_2):
  Game.Bq.ops_respect_requirements(op, h, given_2)

# Player damage never exceeds DMG_CAP.
law damage_capped:
  for +watk: Nat
  for +str: Nat
  for +df: Nat
  for +crit: Bool
  {Game.Bq.Nat.le(Game.Bq.damage(watk, str, df, crit), Game.Bq.DMG_CAP) == True{} : Bool}

def damage_capped(watk, str, df, crit):
  Game.Bq.damage_capped(watk, str, df, crit)

# Player damage is always at least one.
law damage_at_least_one:
  for +watk: Nat
  for +str: Nat
  for +df: Nat
  for +crit: Bool
  {Game.Bq.Nat.le(1n, Game.Bq.damage(watk, str, df, crit)) == True{} : Bool}

def damage_at_least_one(watk, str, df, crit):
  Game.Bq.damage_at_least_one(watk, str, df, crit)

# A monster hit is strictly below the hero maximum health.
law no_instakill:
  for +matk: Nat
  for +df: Nat
  for +lv: Nat
  for +vit: Nat
  {Game.Bq.Nat.lt(Game.Bq.mob_damage(matk, df, Game.Bq.max_hp(lv, vit)), Game.Bq.max_hp(lv, vit)) == True{} : Bool}

def no_instakill(matk, df, lv, vit):
  Game.Bq.no_instakill(matk, df, lv, vit)

# A step preserves both map bounds.
law walk_stays_in_bounds:
  for +w: Nat
  for +h: Nat
  for +x: Nat
  for +given_3: {Game.Bq.Nat.lt(x, w) == True{} : Bool}
  for +y: Nat
  for +given_5: {Game.Bq.Nat.lt(y, h) == True{} : Bool}
  for +d: Game.Bq.Dir
  {Game.Bq.Bool.and(Game.Bq.Nat.lt(Game.Bq.walk_x(w, x, d), w), Game.Bq.Nat.lt(Game.Bq.walk_y(h, y, d), h)) == True{} : Bool}

def walk_stays_in_bounds(w, h, x, given_3, y, given_5, d):
  Game.Bq.walk_stays_in_bounds(w, h, x, given_3, y, given_5, d)

# A step moves each coordinate by at most one tile.
law walk_is_adjacent:
  for +w: Nat
  for +h: Nat
  for +x: Nat
  for +y: Nat
  for +d: Game.Bq.Dir
  {Game.Bq.Bool.and(Game.Bq.near(x, Game.Bq.walk_x(w, x, d)), Game.Bq.near(y, Game.Bq.walk_y(h, y, d))) == True{} : Bool}

def walk_is_adjacent(w, h, x, y, d):
  Game.Bq.walk_is_adjacent(w, h, x, y, d)
