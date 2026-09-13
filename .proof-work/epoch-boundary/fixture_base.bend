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

