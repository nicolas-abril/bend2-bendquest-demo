import Base
import ./ai_refs.bend as F
import ./references.bend as Ref
import ./players.bend as P
import ./monsters.bend as M
import ./simulation.bend as S
import ./planning.bend as Plan
import ./landscape.bend as L
import ./terrain.bend as T
import ./population.bend as Pop
import ./vitals.bend as V
import ./players_check.bend as Test
import ./simulation_check.bend as ST
import ./world.bend as W
import ./playerids.bend as Id

def player(+pid: U32,zone: U32,x: U32,y: U32,moving: U32,hp: U32,dead: U32,timer: U32) -> P.Players.State:
  ST.player(pid,zone,x,y,moving,hp,dead,timer,0,0)

def monster(mid: U32,zone: U32,target: U32,cooldown: U32) -> M.Monsters.State:
  M.Monsters.State{mid,0,0,zone,14,8,18,18,target,cooldown,0,0}

def corpse(mid: U32,zone: U32,target: U32,timer: U32) -> M.Monsters.State:
  M.Monsters.State{mid,0,0,zone,14,8,0,18,target,0,1,timer}

def state(phase: U32,tick: U32,players: List<&2,P.Players.State>,monsters: List<&2,M.Monsters.State>) -> S.Simulation.State:
  S.Simulation.State{ST.meta(phase,tick),players,monsters}

def all(+players: List<&2,P.Players.State>,monsters: List<&2,M.Monsters.State>) -> Bool:
  match monsters:
    case Nil{}: True{}
    case Con{head,rest}: Bool.and(Ref.References.exists(players,Ref.References.target(head)),all(players,rest))

def valid(+value: S.Simulation.State) -> Bool: all(S.Simulation.players(value),S.Simulation.monsters(value))

def targets(monsters: List<&2,M.Monsters.State>) -> List<&2,U32>:
  match monsters:
    case Nil{}: Nil{}
    case Con{head,rest}: Con{Ref.References.target(head),targets(rest)}

def same_words(a: List<&2,U32>,b: List<&2,U32>) -> Bool:
  match a:
    case Nil{}:
      match b:
        case Nil{}: True{}
        case Con{head,rest}: False{}
    case Con{head,rest}:
      match b:
        case Nil{}: False{}
        case Con{other,later}: Bool.and(U32.is_eq(head,other),same_words(rest,later))

def tick(value: S.Simulation.State,d0: List<&2,U32>,d1: List<&2,U32>,d2: List<&2,U32>,d3: List<&2,U32>) -> S.Simulation.State:
  S.Simulation.state(F.AIRefs.tick(value,L.Landscape.maps(0),d0,d1,d2,d3,Plan.Planning.rules(40)))

def checked(label: String,+actual: S.Simulation.State,expected: List<&2,U32>) -> IO(Unit):
  Test.verdict(label,Bool.and(valid(actual),same_words(targets(S.Simulation.monsters(actual)),expected)))

def death(value: S.Simulation.State) -> Bool:
  match value:
    case S.Simulation.State{meta,players,monsters}:
      match players:
        case Nil{}: False{}
        case Con{head,rest}: U32.is_eq(V.Vitals.dead(P.Players.vitals(head)),1)

@unsafe
def server_result(result: T.Terrain.World & List<&1,W.Bq.OutL>) -> S.Simulation.State:
  match result:
    case Tuple{world,outs}: T.Terrain.simulation(world)

@unsafe
def server(value: S.Simulation.State) -> S.Simulation.State: server_result(W.Bq.tick_world(T.Terrain.world(L.Landscape.maps(0),value)))

@unsafe
def main() -> IO(Unit):
  do IO<Unit>:
    Unit <- checked("selected tick acquires an existing player",tick(state(1,0,[player(1,0,14,8,0,30,0,0)],[monster(7,0,0,0)]),Nil{},Nil{},Nil{},Nil{}),[1])
    Unit <- checked("selected tick retains an existing reference while cooling",tick(state(1,0,[player(1,0,14,8,0,30,0,0)],[monster(7,0,1,5)]),Nil{},Nil{},Nil{},Nil{}),[1])
    Unit <- checked("selected tick clears target when player enters village",tick(state(1,0,[player(1,0,12,8,0,30,0,0)],[monster(7,0,1,0)]),Nil{},Nil{},Nil{},Nil{}),[0])
    Unit <- checked("selected tick clears target when player changes zone",tick(state(1,0,[player(1,1,14,8,0,30,0,0)],[monster(7,0,1,0)]),Nil{},Nil{},Nil{},Nil{}),[0])
    Unit <- checked("selected tick releases dead player target",tick(state(1,0,[player(1,0,14,8,0,0,1,5)],[monster(7,0,1,0)]),Nil{},Nil{},Nil{},Nil{}),[0])
    Unit <- checked("post-upkeep respawn is excluded from monster targets",tick(state(1,0,[player(1,0,14,8,0,0,1,1)],[monster(7,0,1,0)]),Nil{},Nil{},Nil{},Nil{}),[0])
    Unit <- checked("movement is applied before target selection",tick(state(1,0,[player(1,0,13,8,1,30,0,0)],[monster(7,0,0,0)]),Nil{},Nil{},Nil{},Nil{}),[1])
    Unit <- checked("monster waiting preserves an existing reference",tick(state(1,0,[player(1,0,14,8,0,30,0,0)],[corpse(7,0,1,5)]),Nil{},Nil{},Nil{},Nil{}),[1])
    Unit <- checked("monster respawn clears its old reference",tick(state(1,0,[player(1,0,14,8,0,30,0,0)],[corpse(7,0,1,1)]),Nil{},Nil{},Nil{},Nil{}),[0])
    Unit <- checked("zero respawn timer clears old reference",tick(state(1,0,[player(1,0,14,8,0,30,0,0)],[corpse(7,0,1,0)]),Nil{},Nil{},Nil{},Nil{}),[0])
    Unit <- checked("permanent monster death retains valid reference",tick(state(1,0,[player(1,0,14,8,0,30,0,0)],[corpse(7,0,1,4294967295)]),Nil{},Nil{},Nil{},Nil{}),[1])
    Unit <- checked("empty player roster leaves zero targets",tick(state(1,0,Nil{},[monster(7,0,0,0),corpse(8,1,0,1)]),Nil{},Nil{},Nil{},Nil{}),[0,0])
    Unit <- checked("empty monster roster cannot acquire a target",tick(state(1,0,[player(1,0,14,8,0,30,0,0)],Nil{}),Nil{},Nil{},Nil{},Nil{}),Nil{})
    Unit <- checked("maximum player ID remains referenceable",tick(state(1,0,[player(4294967295,0,14,8,0,30,0,0)],[monster(7,0,0,0)]),Nil{},Nil{},Nil{},Nil{}),[4294967295])
    Unit <- checked("tick wrap preserves selected reference",tick(state(1,4294967295,[player(1,0,14,8,0,30,0,0)],[monster(7,0,1,0)]),Nil{},Nil{},Nil{},Nil{}),[1])
    Unit <- checked("inactive phase 0 retains references",tick(state(0,0,[player(1,0,14,8,0,30,0,0)],[monster(7,0,1,0)]),Nil{},Nil{},Nil{},Nil{}),[1])
    Unit <- checked("inactive phase 2 retains references",tick(state(2,0,[player(1,0,14,8,0,30,0,0)],[monster(7,0,1,0)]),Nil{},Nil{},Nil{},Nil{}),[1])
    Unit <- checked("inactive phase 4294967295 retains references",tick(state(4294967295,0,[player(1,0,14,8,0,30,0,0)],[monster(7,0,1,0)]),Nil{},Nil{},Nil{},Nil{}),[1])
    Unit <- checked("lethal AI damage leaves referenced player in roster",tick(state(1,0,[player(1,0,14,8,0,30,0,0)],[monster(7,0,0,0)]),[100],Nil{},Nil{},Nil{}),[1])
    Unit <- Test.verdict("lethal AI damage actually kills the target",death(tick(state(1,0,[player(1,0,14,8,0,30,0,0)],[monster(7,0,0,0)]),[100],Nil{},Nil{},Nil{})))
    Unit <- checked("ordered simultaneous hits retain target membership",tick(state(1,0,[player(1,0,14,8,0,30,0,0)],[monster(7,0,0,0),monster(8,0,0,0)]),[100,100],Nil{},Nil{},Nil{}),[1,1])
    Unit <- checked("extra damage entries cannot introduce target IDs",tick(state(1,0,[player(1,0,14,8,0,30,0,0)],[monster(7,0,0,0)]),[0,4294967295,999],Nil{},Nil{},Nil{}),[1])
    Unit <- checked("zone processing selects references from matching rosters",tick(state(1,0,[player(1,0,14,8,0,30,0,0),player(2,1,14,8,0,30,0,0),player(3,2,14,8,0,30,0,0),player(4,3,14,8,0,30,0,0)],[monster(10,3,0,0),monster(11,1,0,0),monster(12,0,0,0),monster(13,2,0,0)]),[100],[100],[100],[100]),[1,2,3,4])
    Unit <- checked("server finish uses checked reference pipeline",server(state(1,0,[player(1,0,14,8,0,30,0,0)],[monster(7,0,0,0)])),[1])
    Unit <- Test.verdict("selected tick trace preserves fresh seed 0 references",valid(F.AIRefs.tick_trace([F.AIRefs.Damages{Nil{},Nil{},Nil{},Nil{}},F.AIRefs.Damages{[4294967295],Nil{},Nil{},Nil{}}],T.Terrain.simulation(Pop.Population.fresh(1,0,0)),L.Landscape.maps(0),Plan.Planning.rules(40))))
    Unit <- Test.verdict("selected tick trace preserves fresh seed 4294967295 references",valid(F.AIRefs.tick_trace([F.AIRefs.Damages{Nil{},Nil{},Nil{},Nil{}},F.AIRefs.Damages{[4294967295],Nil{},Nil{},Nil{}}],T.Terrain.simulation(Pop.Population.fresh(1,4294967295,0)),L.Landscape.maps(4294967295),Plan.Planning.rules(40))))
    Unit <- Test.verdict("mixed create tick remove tick sequence preserves references",valid(F.AIRefs.trace([F.AIRefs.Command{Id.PlayerIds.Create{11,P.Players.Style{0,0,0,0,0,0},Nil{}},Unit{}},F.AIRefs.Ticking{F.AIRefs.Damages{Nil{},Nil{},Nil{},Nil{}},Plan.Planning.rules(40)},F.AIRefs.Command{Id.PlayerIds.Remove{1},Unit{}},F.AIRefs.Ticking{F.AIRefs.Damages{Nil{},Nil{},Nil{},Nil{}},Plan.Planning.rules(40)}],T.Terrain.simulation(Pop.Population.fresh(1,0,0)),L.Landscape.maps(0))))
    IO.pure(Unit,Unit{})

#| PASS selected tick acquires an existing player
#| PASS selected tick retains an existing reference while cooling
#| PASS selected tick clears target when player enters village
#| PASS selected tick clears target when player changes zone
#| PASS selected tick releases dead player target
#| PASS post-upkeep respawn is excluded from monster targets
#| PASS movement is applied before target selection
#| PASS monster waiting preserves an existing reference
#| PASS monster respawn clears its old reference
#| PASS zero respawn timer clears old reference
#| PASS permanent monster death retains valid reference
#| PASS empty player roster leaves zero targets
#| PASS empty monster roster cannot acquire a target
#| PASS maximum player ID remains referenceable
#| PASS tick wrap preserves selected reference
#| PASS inactive phase 0 retains references
#| PASS inactive phase 2 retains references
#| PASS inactive phase 4294967295 retains references
#| PASS lethal AI damage leaves referenced player in roster
#| PASS lethal AI damage actually kills the target
#| PASS ordered simultaneous hits retain target membership
#| PASS extra damage entries cannot introduce target IDs
#| PASS zone processing selects references from matching rosters
#| PASS server finish uses checked reference pipeline
#| PASS selected tick trace preserves fresh seed 0 references
#| PASS selected tick trace preserves fresh seed 4294967295 references
#| PASS mixed create tick remove tick sequence preserves references
