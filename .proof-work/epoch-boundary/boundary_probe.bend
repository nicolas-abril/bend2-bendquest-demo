import Base
import ./epoch_boundary.bend as EB
import ./epoch_history.bend as E
import ./epoch_once.bend as LT
import ./permanent_history.bend as PH
import ./tick_life.bend as TL
import ./live_tick.bend as LiveTick
import ./combat_history.bend as History
import ./live_combat.bend as Fight
import ./live_dead.bend as LiveDead
import ./reward_once.bend as Once
import ./attack_once.bend as AO
import ./combat.bend as Combat
import ./monsters.bend as M
import ./vitals.bend as V
import ./roster.bend as R
import ./identity.bend as I
import ./combat_targets.bend as Targets
import ./terrain.bend as T
import ./simulation.bend as S
import ./seeded_world.bend as SW
import ./sessions.bend as Sess
import ./ai.bend as AI
import ./zones.bend as Z
import ./world_clock.bend as Clock
import ./battle.bend as Battle
import ./payouts.bend as Pay
import ./players.bend as P
import ./dead_rewards.bend as Dead
import ./live_attack.bend as LA
import ./live_spin.bend as LS
import ./spin_plans.bend as Spin
import ./target_plans.bend as TP

def fixture_actor() -> P.Players.State: P.Players.spawn(1,1,P.Players.Style{0,0,0,0,0,0},[Chr{65}],6,4)
def other_player() -> P.Players.State: P.Players.spawn(2,2,P.Players.Style{0,0,0,0,0,0},[Chr{66}],8,4)
def minor() -> M.Monsters.State: M.Monsters.State{7,0,0,0,6,4,1,100,0,0,0,0}
def survivor() -> M.Monsters.State: M.Monsters.State{8,0,0,0,7,4,100,100,0,0,0,0}
def fixture_state() -> S.Simulation.State: S.Simulation.State{S.Simulation.Meta{1,1,41,17,100,200,0,0,2,400},[fixture_actor],[minor,survivor]}
def repeat_world() -> T.Terrain.World: T.Terrain.world(Nil{},S.Simulation.State{S.Simulation.meta(fixture_state),[other_player,fixture_actor],[minor,survivor]})
def fixture_payout() -> Pay.Payout.Plan: Pay.Payout.Plan{9,25,0,0,99,0,4294967295,0,0,99,0}
def fixed_attack_builder(+monsters: List<&2,M.Monsters.State>,+player: P.Players.State,+meta: S.Simulation.Meta,+pid: U32) -> LA.LiveAttack.Tuning: LA.LiveAttack.Tuning{1,(monster => TP.TargetPlans.Power{1,fixture_payout})}
def first_attack(ready: Fight.LiveCombat.Ready) -> Fight.LiveCombat.Plan: LA.LiveAttack.plan(ready,fixed_attack_builder)
def hostile_second(ready: Fight.LiveCombat.Ready) -> Fight.LiveCombat.Plan: Fight.LiveCombat.Plan{[Battle.Battle.Input{7,1,fixture_payout},Battle.Battle.Input{8,1,fixture_payout}],Fight.LiveCombat.Attack{0,6,4,1,7,1}}
def large_powers(selected: List<&2,M.Monsters.State>) -> Spin.SpinPlans.Powers(selected):
  match selected:
    case Nil{}: Unit{}
    case Con{head,rest}: Tuple{TP.TargetPlans.Power{100,fixture_payout},large_powers(rest)}
def large_spin_builder(+monsters: List<&2,M.Monsters.State>,+player: P.Players.State,+meta: S.Simulation.Meta,+selected: List<&2,M.Monsters.State>) -> Spin.SpinPlans.Powers(selected): large_powers(selected)
def large_spin(ready: Fight.LiveCombat.Ready) -> Fight.LiveCombat.Plan: LS.LiveSpin.plan(ready,large_spin_builder)
def attacked_world() -> T.Terrain.World: Fight.LiveCombat.world(Fight.LiveCombat.run(repeat_world,Combat.Combat.Attack{},1,60,first_attack))
def dead_tracked() -> M.Monsters.State: M.Monsters.State{7,0,0,0,6,4,0,100,0,0,1,80}
def dead_start() -> S.Simulation.State: T.Terrain.simulation(attacked_world)
def dead_inside() -> Targets.Targets.In<dead_tracked,S.Simulation.monsters(dead_start)>: Targets.Targets.Here{[survivor],{==}}
def dead_unique() -> I.Identity.Monsters(S.Simulation.monsters(dead_start)): Tuple{Tuple{{==},Unit{}},Tuple{Unit{},Unit{}}}
def tick_life_attack_world() -> T.Terrain.World: LiveTick.LiveTick.world(LiveTick.LiveTick.run(attacked_world,2))
def tick_life_attack_after() -> M.Monsters.State: M.Monsters.State{7,0,0,0,6,4,0,100,0,0,1,79}
def tick_life_attack_zones() -> Z.Zones.All(S.Simulation.monsters(T.Terrain.simulation(attacked_world))): Tuple{Z.Zones.Hollow{{==}},Tuple{Z.Zones.Hollow{{==}},Unit{}}}
def tick_life_attack_tracked() -> TL.TickLife.Tracked<dead_tracked,Some{AI.AI.Rest{}},S.Simulation.monsters(T.Terrain.simulation(tick_life_attack_world))>: TL.TickLife.run(attacked_world,2,dead_tracked,Z.Zones.Hollow{{==}},dead_inside,{==},tick_life_attack_zones,dead_unique)


def epoch_corpse(timer: U32) -> M.Monsters.State: M.Monsters.State{7,0,0,0,6,4,0,100,0,0,1,timer}
def epoch_world() -> T.Terrain.World: T.Terrain.World{S.Simulation.meta(fixture_state),[fixture_actor],[epoch_corpse(2)],Nil{}}
def epoch_w1() -> T.Terrain.World: History.History.step(epoch_world,History.History.Tick{2})
def epoch_command() -> History.History.Operation: History.History.Command{4294967295,Combat.Combat.Spin{},99,60,hostile_second(Fight.LiveCombat.prepare(Clock.WorldClock.set(epoch_w1,4294967295),Combat.Combat.Spin{},99,60))}
def epoch_w2() -> T.Terrain.World: History.History.step(epoch_w1,epoch_command)
def epoch_w3() -> T.Terrain.World: History.History.step(epoch_w2,History.History.Tick{2})
def epoch_large_plan(ready: Fight.LiveCombat.Ready) -> Fight.LiveCombat.Plan: Fight.LiveCombat.Plan{[Battle.Battle.Input{7,1000,Pay.Payout.Plan{9,25,0,0,99,0,4294967295,0,0,99,0}}],Fight.LiveCombat.Attack{0,6,4,1,7,1}}
def epoch_later_requests() -> List<&1,History.History.Request>: [History.History.CommandRequest{0,Combat.Combat.Attack{},1,60,epoch_large_plan}]
def epoch_requests() -> List<&1,History.History.Request>: [History.History.TickRequest{2},History.History.CommandRequest{4294967295,Combat.Combat.Spin{},99,60,hostile_second},History.History.TickRequest{2},History.History.CommandRequest{0,Combat.Combat.Attack{},1,60,epoch_large_plan}]
def epoch_run() -> History.History.Run: History.History.trace(epoch_requests,epoch_world)
def epoch_remaining() -> List<&2,History.History.Entry>: History.History.entries(History.History.trace(epoch_later_requests,epoch_w3))
def epoch_birth_entries() -> List<&2,History.History.Entry>: Con{History.History.Entry{epoch_w2,History.History.Tick{2},epoch_w3},epoch_remaining}
def epoch_command_entries() -> List<&2,History.History.Entry>: Con{History.History.Entry{epoch_w1,epoch_command,epoch_w2},epoch_birth_entries}
def epoch_in0() -> Targets.Targets.In<epoch_corpse(2),S.Simulation.monsters(T.Terrain.simulation(epoch_world))>: Targets.Targets.Here{Nil{},{==}}
def epoch_in1() -> Targets.Targets.In<epoch_corpse(1),S.Simulation.monsters(T.Terrain.simulation(epoch_w1))>: Targets.Targets.Here{Nil{},{==}}
def epoch_in2() -> Targets.Targets.In<epoch_corpse(1),S.Simulation.monsters(T.Terrain.simulation(epoch_w2))>: Targets.Targets.Here{Nil{},{==}}
def epoch_unique0() -> I.Identity.Monsters(S.Simulation.monsters(T.Terrain.simulation(epoch_world))): Tuple{Unit{},Unit{}}
def epoch_unique1() -> I.Identity.Monsters(S.Simulation.monsters(T.Terrain.simulation(epoch_w1))): Tuple{Unit{},Unit{}}
def epoch_unique2() -> I.Identity.Monsters(S.Simulation.monsters(T.Terrain.simulation(epoch_w2))): Tuple{Unit{},Unit{}}
def epoch_zones0() -> Z.Zones.All(S.Simulation.monsters(T.Terrain.simulation(epoch_world))): Tuple{Z.Zones.Hollow{{==}},Unit{}}
def epoch_zones2() -> Z.Zones.All(S.Simulation.monsters(T.Terrain.simulation(epoch_w2))): Tuple{Z.Zones.Hollow{{==}},Unit{}}
def epoch_mode2() -> Maybe<&2,AI.AI.Plan>: TL.TickLife.decision(epoch_w2,2,epoch_corpse(1),Z.Zones.Hollow{{==}},epoch_in2)
def epoch_birth() -> E.Epoch.Follow<epoch_birth_entries,epoch_w2,epoch_corpse(1)>:
  E.Epoch.Birth{2,epoch_remaining,{==},Z.Zones.Hollow{{==}},epoch_in2,{==},epoch_mode2,{==},TL.TickLife.run(epoch_w2,2,epoch_corpse(1),Z.Zones.Hollow{{==}},epoch_in2,{==},epoch_zones2,epoch_unique2),{==}}
def epoch_before_birth() -> E.Epoch.Follow<epoch_command_entries,epoch_w1,epoch_corpse(1)>:
  +plan = hostile_second(Fight.LiveCombat.prepare(Clock.WorldClock.set(epoch_w1,4294967295),Combat.Combat.Spin{},99,60))
  E.Epoch.Command{4294967295,Combat.Combat.Spin{},99,60,plan,epoch_birth_entries,{==},{==},Fight.LiveCombat.at(Clock.WorldClock.set(epoch_w1,4294967295),Combat.Combat.Spin{},99,60,plan),{==},LiveDead.LiveDead.timed_safe(epoch_w1,4294967295,Combat.Combat.Spin{},99,60,plan,epoch_corpse(1),epoch_in1,epoch_unique1,{==}),epoch_birth}
def epoch_follow() -> E.Epoch.Follow<History.History.entries(epoch_run),epoch_world,epoch_corpse(2)>:
  E.Epoch.Wait{2,epoch_command_entries,{==},Z.Zones.Hollow{{==}},epoch_in0,{==},Some{AI.AI.Rest{}},{==},TL.TickLife.run(epoch_world,2,epoch_corpse(2),Z.Zones.Hollow{{==}},epoch_in0,{==},epoch_zones0,epoch_unique0),{==},{==},epoch_before_birth}
def epoch_prefix() -> List<&2,History.History.Entry>: E.Epoch.prefix(History.History.entries(epoch_run),epoch_world,epoch_corpse(2),epoch_follow)(epoch_world,epoch_corpse(2))

def epoch_short_entries() -> List<&2,History.History.Entry>: [History.History.Entry{epoch_world,History.History.Tick{2},epoch_w1}]
def epoch_short_follow() -> E.Epoch.Follow<epoch_short_entries,epoch_world,epoch_corpse(2)>:
  E.Epoch.Wait{2,Nil{},{==},Z.Zones.Hollow{{==}},epoch_in0,{==},Some{AI.AI.Rest{}},{==},TL.TickLife.run(epoch_world,2,epoch_corpse(2),Z.Zones.Hollow{{==}},epoch_in0,{==},epoch_zones0,epoch_unique0),{==},{==},E.Epoch.Done{{==},epoch_in1,epoch_unique1,{==}}}

def lifetime_first() -> Fight.LiveCombat.Result: Fight.LiveCombat.run(repeat_world,Combat.Combat.Attack{},1,60,first_attack)
def lifetime_first_once() -> Once.Once.Certificate<minor,1,AO.AttackOnce.view(lifetime_first)>: Once.Once.Certificate{dead_inside,dead_unique,{==},{==}}
def lifetime_tick_member(-monster: M.Monsters.State,-mode: Maybe<&2,AI.AI.Plan>,-monsters: List<&2,M.Monsters.State>,tracked: TL.TickLife.Tracked<monster,mode,monsters>) -> Targets.Targets.In<TL.TickLife.after(monster,mode),monsters>:
  match tracked:
    case TL.TickLife.Tracked{inside,key,dead,quiet,unique}: inside
def lifetime_tick_unique(-monster: M.Monsters.State,-mode: Maybe<&2,AI.AI.Plan>,-monsters: List<&2,M.Monsters.State>,tracked: TL.TickLife.Tracked<monster,mode,monsters>) -> I.Identity.Monsters(monsters):
  match tracked:
    case TL.TickLife.Tracked{inside,key,dead,quiet,unique}: unique
def lifetime_plan() -> Fight.LiveCombat.Plan: large_spin(Fight.LiveCombat.prepare(Clock.WorldClock.set(tick_life_attack_world,4294967295),Combat.Combat.Spin{},2,60))
def lifetime_second() -> Fight.LiveCombat.Result: Fight.LiveCombat.at(Clock.WorldClock.set(tick_life_attack_world,4294967295),Combat.Combat.Spin{},2,60,lifetime_plan)
def lifetime_operation() -> History.History.Operation: History.History.Command{4294967295,Combat.Combat.Spin{},2,60,lifetime_plan}
def lifetime_requests() -> List<&1,History.History.Request>: [History.History.TickRequest{2},History.History.CommandRequest{4294967295,Combat.Combat.Spin{},2,60,large_spin}]
def lifetime_run() -> History.History.Run: History.History.trace(lifetime_requests,attacked_world)
def lifetime_command_entries() -> List<&2,History.History.Entry>: [History.History.Entry{tick_life_attack_world,lifetime_operation,Fight.LiveCombat.world(lifetime_second)}]
def lifetime_safe() -> LiveDead.LiveDead.Safe<tick_life_attack_after,lifetime_second>:
  LiveDead.LiveDead.timed_safe(tick_life_attack_world,4294967295,Combat.Combat.Spin{},2,60,lifetime_plan,tick_life_attack_after,lifetime_tick_member(dead_tracked,Some{AI.AI.Rest{}},S.Simulation.monsters(T.Terrain.simulation(tick_life_attack_world)),tick_life_attack_tracked),lifetime_tick_unique(dead_tracked,Some{AI.AI.Rest{}},S.Simulation.monsters(T.Terrain.simulation(tick_life_attack_world)),tick_life_attack_tracked),{==})
def lifetime_done(-result: Fight.LiveCombat.Result,-monster: M.Monsters.State,dead: {V.Vitals.dead(M.Monsters.vitals(monster)) == 1 : U32},safe: LiveDead.LiveDead.Safe<monster,result>) -> E.Epoch.Follow<Nil{},Fight.LiveCombat.world(result),monster>:
  match safe:
    case LiveDead.LiveDead.Safe{inside,unique,clear}: E.Epoch.Done{{==},inside,unique,dead}
def lifetime_command_follow() -> E.Epoch.Follow<lifetime_command_entries,tick_life_attack_world,tick_life_attack_after>:
  E.Epoch.Command{4294967295,Combat.Combat.Spin{},2,60,lifetime_plan,Nil{},{==},{==},lifetime_second,{==},lifetime_safe,lifetime_done(lifetime_second,tick_life_attack_after,{==},lifetime_safe)}
def lifetime_follow() -> E.Epoch.Follow<History.History.entries(lifetime_run),attacked_world,dead_tracked>:
  E.Epoch.Wait{2,lifetime_command_entries,{==},Z.Zones.Hollow{{==}},dead_inside,{==},Some{AI.AI.Rest{}},{==},tick_life_attack_tracked,{==},{==},lifetime_command_follow}
def lifetime_cut() -> E.Epoch.Cut<lifetime_run,attacked_world,dead_tracked>: E.Epoch.cut_from(lifetime_run,attacked_world,dead_tracked,E.Epoch.Report{lifetime_run,{==},lifetime_follow})
def lifetime_certificate() -> LT.Lifetime.Certificate<minor,1,lifetime_first,lifetime_run>: LT.Lifetime.compose(minor,1,lifetime_first,lifetime_run,{==},lifetime_cut)


law boundary_arbitrary_observed:
  for +world: T.Terrain.World
  for +monster: M.Monsters.State
  for -entries: List<&2,History.History.Entry>
  for +follow: E.Epoch.Follow<entries,world,monster>
  EB.Boundary.OK<monster,EB.Boundary.point(entries,world,monster,follow)(world,monster)>
def boundary_arbitrary_observed(world,monster,entries,follow): EB.Boundary.observe(entries,world,monster,follow)(world,monster,{==},{==})

law boundary_arbitrary_lookup:
  for +world: T.Terrain.World
  for +monster: M.Monsters.State
  for -entries: List<&2,History.History.Entry>
  for +follow: E.Epoch.Follow<entries,world,monster>
  {R.Roster.found(R.Roster.take(S.Simulation.monsters(T.Terrain.simulation(EB.Boundary.world(EB.Boundary.point(entries,world,monster,follow)(world,monster)))),R.Roster.id(monster))) == Some{EB.Boundary.monster(EB.Boundary.point(entries,world,monster,follow)(world,monster))} : Maybe<&2,M.Monsters.State>}
def boundary_arbitrary_lookup(world,monster,entries,follow): EB.Boundary.lookup(monster,EB.Boundary.point(entries,world,monster,follow)(world,monster),EB.Boundary.observe(entries,world,monster,follow)(world,monster,{==},{==}))

law boundary_arbitrary_marker:
  for -entries: List<&2,History.History.Entry>
  for -world: T.Terrain.World
  for -monster: M.Monsters.State
  for +follow: E.Epoch.Follow<entries,world,monster>
  {EB.Boundary.born(EB.Boundary.point(entries,world,monster,follow)(world,monster)) == E.Epoch.reborn(entries,world,monster,follow) : Bool}
def boundary_arbitrary_marker(entries,world,monster,follow): EB.Boundary.marker(entries,world,monster,follow)

law boundary_arbitrary_prefix_end:
  for -entries: List<&2,History.History.Entry>
  for -world: T.Terrain.World
  for -monster: M.Monsters.State
  for +follow: E.Epoch.Follow<entries,world,monster>
  {EB.Boundary.world(EB.Boundary.point(entries,world,monster,follow)(world,monster)) == EB.Boundary.last(E.Epoch.prefix(entries,world,monster,follow)(world,monster),world) : T.Terrain.World}
def boundary_arbitrary_prefix_end(entries,world,monster,follow): EB.Boundary.prefix_end(entries,world,monster,follow)

law boundary_arbitrary_valid:
  for +world: T.Terrain.World
  for +monster: M.Monsters.State
  for -entries: List<&2,History.History.Entry>
  for +states: List<&2,Sess.Sessions.State>
  for +follow: E.Epoch.Follow<entries,world,monster>
  for +valid: SW.SeededWorld.OK<world,states>
  SW.SeededWorld.OK<EB.Boundary.world(EB.Boundary.point(entries,world,monster,follow)(world,monster)),states>
def boundary_arbitrary_valid(world,monster,entries,states,follow,valid): EB.Boundary.valid(entries,world,monster,states,follow)(world,monster,valid)

law boundary_arbitrary_report:
  for requests: List<&1,History.History.Request>
  for +world: T.Terrain.World
  for +monster: M.Monsters.State
  for +states: List<&2,Sess.Sessions.State>
  for +valid: SW.SeededWorld.OK<world,states>
  for +inside: Targets.Targets.In<monster,S.Simulation.monsters(T.Terrain.simulation(world))>
  for +dead: {V.Vitals.dead(M.Monsters.vitals(monster)) == 1 : U32}
  EB.Boundary.Report<History.History.trace(requests,world),world,monster,states>
def boundary_arbitrary_report(requests,world,monster,states,valid,inside,dead): EB.Boundary.report(requests,world,monster,states,valid,inside,dead)

law boundary_arbitrary_report_lookup:
  for -run: History.History.Run
  for -world: T.Terrain.World
  for +monster: M.Monsters.State
  for -states: List<&2,Sess.Sessions.State>
  for +report: EB.Boundary.Report<run,world,monster,states>
  {R.Roster.found(R.Roster.take(S.Simulation.monsters(T.Terrain.simulation(EB.Boundary.world(EB.Boundary.result(run,world,monster,states,report)))),R.Roster.id(monster))) == Some{EB.Boundary.monster(EB.Boundary.result(run,world,monster,states,report))} : Maybe<&2,M.Monsters.State>}
def boundary_arbitrary_report_lookup(run,world,monster,states,report): EB.Boundary.report_lookup(run,world,monster,states,report)

law boundary_arbitrary_cut:
  for -run: History.History.Run
  for +world: T.Terrain.World
  for +monster: M.Monsters.State
  for -states: List<&2,Sess.Sessions.State>
  for +report: EB.Boundary.Report<run,world,monster,states>
  E.Epoch.Cut<run,world,monster>
def boundary_arbitrary_cut(run,world,monster,states,report): EB.Boundary.to_cut(run,world,monster,states,report)

def boundary_birth() -> EB.Boundary.State: EB.Boundary.point(History.History.entries(epoch_run),epoch_world,epoch_corpse(2),epoch_follow)(epoch_world,epoch_corpse(2))
def boundary_birth_ok() -> EB.Boundary.OK<epoch_corpse(2),boundary_birth>: EB.Boundary.observe(History.History.entries(epoch_run),epoch_world,epoch_corpse(2),epoch_follow)(epoch_world,epoch_corpse(2),{==},{==})

law boundary_real_birth_world:
  {EB.Boundary.world(boundary_birth) == epoch_w3 : T.Terrain.World}
def boundary_real_birth_world(): {==}

law boundary_real_birth_record:
  {EB.Boundary.monster(boundary_birth) == TL.TickLife.after(epoch_corpse(1),epoch_mode2) : M.Monsters.State}
def boundary_real_birth_record(): {==}

law boundary_real_birth_marker:
  {EB.Boundary.born(boundary_birth) == True{} : Bool}
def boundary_real_birth_marker(): EB.Boundary.marker(History.History.entries(epoch_run),epoch_world,epoch_corpse(2),epoch_follow)

law boundary_real_birth_lookup:
  {R.Roster.found(R.Roster.take(S.Simulation.monsters(T.Terrain.simulation(epoch_w3)),7)) == Some{TL.TickLife.after(epoch_corpse(1),epoch_mode2)} : Maybe<&2,M.Monsters.State>}
def boundary_real_birth_lookup(): EB.Boundary.lookup(epoch_corpse(2),boundary_birth,boundary_birth_ok)

law boundary_real_birth_alive:
  {V.Vitals.dead(M.Monsters.vitals(EB.Boundary.monster(boundary_birth))) == 0 : U32}
def boundary_real_birth_alive(): EB.Boundary.alive(epoch_corpse(2),boundary_birth,boundary_birth_ok,{==})

law boundary_real_birth_prefix:
  {EB.Boundary.world(boundary_birth) == EB.Boundary.last(epoch_prefix,epoch_world) : T.Terrain.World}
def boundary_real_birth_prefix(): EB.Boundary.prefix_end(History.History.entries(epoch_run),epoch_world,epoch_corpse(2),epoch_follow)

def boundary_found_dead(found: Maybe<&2,M.Monsters.State>) -> Maybe<&2,U32>:
  match found:
    case None{}: None{}
    case Some{monster}: Some{V.Vitals.dead(M.Monsters.vitals(monster))}

law boundary_later_final_dead:
  {boundary_found_dead(R.Roster.found(R.Roster.take(S.Simulation.monsters(T.Terrain.simulation(History.History.world(epoch_run))),7))) == Some{1} : Maybe<&2,U32>}
def boundary_later_final_dead(): {==}

def boundary_short() -> EB.Boundary.State: EB.Boundary.point(epoch_short_entries,epoch_world,epoch_corpse(2),epoch_short_follow)(epoch_world,epoch_corpse(2))
def boundary_short_ok() -> EB.Boundary.OK<epoch_corpse(2),boundary_short>: EB.Boundary.observe(epoch_short_entries,epoch_world,epoch_corpse(2),epoch_short_follow)(epoch_world,epoch_corpse(2),{==},{==})

law boundary_short_world:
  {EB.Boundary.world(boundary_short) == epoch_w1 : T.Terrain.World}
def boundary_short_world(): {==}

law boundary_short_record:
  {EB.Boundary.monster(boundary_short) == epoch_corpse(1) : M.Monsters.State}
def boundary_short_record(): {==}

law boundary_short_dead:
  {V.Vitals.dead(M.Monsters.vitals(EB.Boundary.monster(boundary_short))) == 1 : U32}
def boundary_short_dead(): EB.Boundary.dead(epoch_corpse(2),boundary_short,boundary_short_ok,{==})

law boundary_short_lookup:
  {R.Roster.found(R.Roster.take(S.Simulation.monsters(T.Terrain.simulation(epoch_w1)),7)) == Some{epoch_corpse(1)} : Maybe<&2,M.Monsters.State>}
def boundary_short_lookup(): EB.Boundary.lookup(epoch_corpse(2),boundary_short,boundary_short_ok)

def boundary_lifetime() -> EB.Boundary.State: EB.Boundary.point(History.History.entries(lifetime_run),attacked_world,dead_tracked,lifetime_follow)(attacked_world,dead_tracked)
def boundary_lifetime_ok() -> EB.Boundary.OK<dead_tracked,boundary_lifetime>: EB.Boundary.observe(History.History.entries(lifetime_run),attacked_world,dead_tracked,lifetime_follow)(attacked_world,dead_tracked,{==},{==})

law boundary_lifetime_world:
  {EB.Boundary.world(boundary_lifetime) == History.History.world(lifetime_run) : T.Terrain.World}
def boundary_lifetime_world(): {==}

law boundary_lifetime_record:
  {EB.Boundary.monster(boundary_lifetime) == tick_life_attack_after : M.Monsters.State}
def boundary_lifetime_record(): {==}

law boundary_lifetime_lookup:
  {R.Roster.found(R.Roster.take(S.Simulation.monsters(T.Terrain.simulation(History.History.world(lifetime_run))),7)) == Some{tick_life_attack_after} : Maybe<&2,M.Monsters.State>}
def boundary_lifetime_lookup(): EB.Boundary.lookup(dead_tracked,boundary_lifetime,boundary_lifetime_ok)

law boundary_lifetime_dead:
  {V.Vitals.dead(M.Monsters.vitals(EB.Boundary.monster(boundary_lifetime))) == 1 : U32}
def boundary_lifetime_dead(): EB.Boundary.dead(dead_tracked,boundary_lifetime,boundary_lifetime_ok,{==})
