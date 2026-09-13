import Base
import ./locomotion.bend as L
import ./terrain.bend as Terrain
import ./players.bend as P
import ./vitals.bend as V
import ./simulation.bend as S
import ./ai.bend as A
import ./world.bend as W
import ./compat.bend as C
import ./players_check.bend as T
import ./simulation_check.bend as ST
import ./terrain_check.bend as Maps
import ./interactions_check.bend as IT

def same_plan(a: P.Players.Plan,b: P.Players.Plan) -> Bool:
  match a:
    case P.Players.Walk{ax,ay}:
      match b:
        case P.Players.Walk{bx,by}: Bool.and(U32.is_eq(ax,bx),U32.is_eq(ay,by))

def same_plans(a: List<&2,P.Players.Plan>,b: List<&2,P.Players.Plan>) -> Bool:
  match a:
    case Nil{}:
      match b:
        case Nil{}: True{}
        case Con{h,t}: False{}
    case Con{ah,at}:
      match b:
        case Nil{}: False{}
        case Con{bh,bt}: Bool.and(same_plan(ah,bh),same_plans(at,bt))

def check_plan(label: String,actual: P.Players.Plan,x: U32,y: U32) -> IO(Unit):
  T.verdict(label,same_plan(actual,P.Players.Walk{x,y}))

def actor(moving: U32,hp: U32,dead: U32,timer: U32) -> P.Players.State:
  ST.player(1,0,6,4,moving,hp,dead,timer,3,7)

def quiet() -> L.Locomotion.Actions: L.Locomotion.Actions{Nil{},Nil{},Nil{},Nil{}}
def attacks() -> L.Locomotion.Actions:
  L.Locomotion.Actions{[A.AI.Attack{1,6},A.AI.Attack{3,6}],[A.AI.Attack{999,6}],Nil{},Nil{}}

def prepared_players() -> List<&2,P.Players.State>:
  [ST.player(1,0,21,10,1,35,0,0,2,6),ST.player(2,0,4,8,0,35,0,0,0,0),ST.player(3,0,21,11,1,3,0,0,2,6)]

def after_battle() -> S.Simulation.State:
  S.Simulation.State{ST.meta(1,1),[ST.player(3,0,21,11,0,0,1,40,2,6),ST.player(1,0,21,10,1,29,0,0,2,6),ST.player(2,0,4,8,0,35,0,0,0,0)],[ST.monster(11,0,1,9),ST.monster(12,0,3,9),ST.monster(13,1,999,9)]}

def after_two() -> S.Simulation.State:
  S.Simulation.State{ST.meta(1,2),[ST.player(3,0,21,11,0,0,1,39,2,6),ST.player(1,0,22,10,1,29,0,0,1,5),ST.player(2,0,4,8,0,35,0,0,0,0)],[ST.monster(11,0,1,8),ST.monster(12,0,3,8),ST.monster(13,1,999,8)]}

def wall_world(phase: U32,tick: U32) -> Terrain.Terrain.World:
  Terrain.Terrain.World{ST.meta(phase,tick),[actor(1,34,0,0)],Nil{},Maps.blocked_right}

def check_world(label: String,actual: C.Bq.Pair.Pair(W.Bq.World,(world => List<&1,W.Bq.OutL>)),expected: S.Simulation.State,maps: Terrain.Terrain.Maps) -> IO(Unit):
  match actual:
    case Tuple{world,outs}:
      +shared = world
      T.verdict(label,Bool.and(ST.same_state(Terrain.Terrain.simulation(shared),expected),IT.same_maps(Terrain.Terrain.maps(shared),maps)))

def main() -> IO(Unit):
  do IO<Unit>:
    Unit <- check_plan("planner commits an open step",L.Locomotion.plan(Maps.open_maps,actor(1,34,0,0)),7,4)
    Unit <- check_plan("planner retains position at a wall",L.Locomotion.plan(Maps.blocked_right,actor(1,34,0,0)),6,4)
    Unit <- check_plan("planner respects halt",L.Locomotion.plan(Maps.open_maps,actor(0,34,0,0)),6,4)
    Unit <- check_plan("planner accepts any nonzero moving flag",L.Locomotion.plan(Maps.open_maps,actor(4294967295,34,0,0)),7,4)
    Unit <- T.verdict("planner preserves roster order",same_plans(L.Locomotion.plans(ST.original_players,Maps.open_maps),[P.Players.Walk{21,10},P.Players.Walk{12,10},P.Players.Walk{21,11}]))
    Unit <- T.verdict("inactive planning returns no plans",same_plans(L.Locomotion.tick_plans(False{},ST.original_players,Maps.open_maps),Nil{}))
    Unit <- T.step("upkeep moves and regenerates exactly once",P.Players.upkeep(actor(1,34,0,0),L.Locomotion.plan(Maps.open_maps,actor(1,34,0,0)),0,4,8),ST.player(1,0,7,4,1,35,0,0,2,6),Nil{})
    Unit <- T.step("collision blocks movement but permits regeneration",P.Players.upkeep(actor(1,34,0,0),L.Locomotion.plan(Maps.blocked_right,actor(1,34,0,0)),0,4,8),ST.player(1,0,6,4,1,35,0,0,2,6),Nil{})
    Unit <- T.step("halted upkeep retains position and profile",P.Players.upkeep(actor(0,34,0,0),L.Locomotion.plan(Maps.open_maps,actor(0,34,0,0)),0,4,8),ST.player(1,0,6,4,0,35,0,0,2,6),Nil{})
    Unit <- T.step("dead upkeep ignores a proposed open step",P.Players.upkeep(actor(1,0,1,2),L.Locomotion.plan(Maps.open_maps,actor(1,0,1,2)),0,4,8),actor(1,0,1,1),Nil{})
    Unit <- T.step("respawn replaces movement with the spawn position",P.Players.upkeep(ST.player(2,3,27,16,1,0,1,1,3,7),L.Locomotion.plan(Maps.open_maps,ST.player(2,3,27,16,1,0,1,1,3,7)),0,4,8),ST.player(2,0,4,8,0,35,0,0,0,0),[P.Players.Revived{2,12}])
    Unit <- T.result("whole upkeep applies aligned plans and respawn",P.Players.upkeep_all(ST.original_players,L.Locomotion.plans(ST.original_players,Maps.open_maps),0,4,8),prepared_players,[P.Players.Revived{2,12}])
    Unit <- T.result("begin exposes moved and revived players to AI",S.Simulation.prepared_upkeep(L.Locomotion.begin(ST.initial(1,0),Maps.open_maps,ST.rules)),prepared_players,[P.Players.Revived{2,12}])
    Unit <- T.result("inactive begin retains complete players",S.Simulation.prepared_upkeep(L.Locomotion.begin(ST.initial(2,0),Maps.open_maps,ST.rules)),ST.original_players,Nil{})
    Unit <- ST.result("complete tick orders movement revival and hits",L.Locomotion.tick(ST.initial(1,0),Maps.open_maps,attacks,ST.rules),after_battle,[P.Players.Revived{2,12},P.Players.Died{3,13,T.name()}])
    Unit <- T.verdict("tick trace moves survivors and keeps dead players still",ST.same_state(L.Locomotion.trace([attacks,attacks],ST.initial(1,0),Maps.open_maps,ST.rules),after_two))
    Unit <- ST.result("inactive tick does not execute movement or attacks",L.Locomotion.tick(ST.initial(0,17),Maps.open_maps,attacks,ST.rules),ST.initial(0,18),Nil{})
    Unit <- ST.result("unknown phase does not execute movement or attacks",L.Locomotion.tick(ST.initial(4294967295,17),Maps.open_maps,attacks,ST.rules),ST.initial(4294967295,18),Nil{})
    Unit <- ST.result("tick wrap retains movement and timer semantics",L.Locomotion.tick(S.Simulation.State{ST.meta(1,4294967295),[actor(1,34,0,0)],Nil{}},Maps.open_maps,quiet,ST.rules),S.Simulation.State{ST.meta(1,0),[ST.player(1,0,7,4,1,34,0,0,2,6)],Nil{}},Nil{})
    Unit <- ST.result("empty roster tick cannot create a player",L.Locomotion.tick(S.Simulation.State{ST.meta(1,0),Nil{},Nil{}},Maps.open_maps,attacks,ST.rules),S.Simulation.State{ST.meta(1,1),Nil{},Nil{}},Nil{})
    Unit <- T.result("lethal hits halt at the current walkable position",P.Players.apply_hits([P.Players.Attack{1,100},P.Players.Attack{1,100}], [ST.player(1,0,7,4,1,35,0,0,2,6)],40),[ST.player(1,0,7,4,0,0,1,40,2,6)],[P.Players.Died{1,11,T.name()}])
    Unit <- T.world_result("server upkeep uses the checked planner",W.Bq.upkeep_all(ST.original_players,Maps.open_maps,0),prepared_players,2)
    Unit <- check_world("server tick preserves full state at a wall",W.Bq.tick_world(wall_world(1,0)),S.Simulation.State{ST.meta(1,1),[ST.player(1,0,6,4,1,35,0,0,2,6)],Nil{}},Maps.blocked_right)
    Unit <- check_world("server inactive tick preserves full state and maps",W.Bq.tick_world(wall_world(2,0)),S.Simulation.State{ST.meta(2,1),[actor(1,34,0,0)],Nil{}},Maps.blocked_right)
    return Unit{}

#| PASS planner commits an open step
#| PASS planner retains position at a wall
#| PASS planner respects halt
#| PASS planner accepts any nonzero moving flag
#| PASS planner preserves roster order
#| PASS inactive planning returns no plans
#| PASS upkeep moves and regenerates exactly once
#| PASS collision blocks movement but permits regeneration
#| PASS halted upkeep retains position and profile
#| PASS dead upkeep ignores a proposed open step
#| PASS respawn replaces movement with the spawn position
#| PASS whole upkeep applies aligned plans and respawn
#| PASS begin exposes moved and revived players to AI
#| PASS inactive begin retains complete players
#| PASS complete tick orders movement revival and hits
#| PASS tick trace moves survivors and keeps dead players still
#| PASS inactive tick does not execute movement or attacks
#| PASS unknown phase does not execute movement or attacks
#| PASS tick wrap retains movement and timer semantics
#| PASS empty roster tick cannot create a player
#| PASS lethal hits halt at the current walkable position
#| PASS server upkeep uses the checked planner
#| PASS server tick preserves full state at a wall
#| PASS server inactive tick preserves full state and maps
