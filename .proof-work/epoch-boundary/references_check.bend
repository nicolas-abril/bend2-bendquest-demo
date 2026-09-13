import Base
import ./references.bend as Ref
import ./world.bend as W
import ./terrain.bend as T
import ./simulation.bend as S
import ./players.bend as P
import ./monsters.bend as M
import ./landscape.bend as L
import ./population.bend as Pop
import ./players_check.bend as Test
import ./simulation_check.bend as ST

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

def same_maps(a: T.Terrain.Maps,b: T.Terrain.Maps) -> Bool:
  match a:
    case Nil{}:
      match b:
        case Nil{}: True{}
        case Con{head,rest}: False{}
    case Con{head,rest}:
      match b:
        case Nil{}: False{}
        case Con{other,later}: Bool.and(same_words(head,other),same_maps(rest,later))

def same_world(+a: T.Terrain.World,+b: T.Terrain.World) -> Bool:
  Bool.and(ST.same_state(T.Terrain.simulation(a),T.Terrain.simulation(b)),same_maps(T.Terrain.maps(a),T.Terrain.maps(b)))

def player(pid: U32,cid: U32) -> P.Players.State:
  P.Players.spawn(pid,cid,P.Players.Style{0,0,0,0,0,0},Nil{},14,8)

def monster(mid: U32,target: U32) -> M.Monsters.State:
  M.Monsters.State{mid,7,1,1,22,8,139,950,target,17,0,0}

def corpse(target: U32) -> M.Monsters.State:
  M.Monsters.State{81,9,0,3,15,7,0,6500,target,4294967295,1,4294967295}

def world(players: List<&2,P.Players.State>,monsters: List<&2,M.Monsters.State>) -> T.Terrain.World:
  T.Terrain.World{S.Simulation.Meta{1,71,0,4294967295,100,200,3,400,4294967295,450},players,monsters,L.Landscape.maps(0)}

def valid_list(+players: List<&2,P.Players.State>,monsters: List<&2,M.Monsters.State>) -> Bool:
  match monsters:
    case Nil{}: True{}
    case Con{head,rest}: Bool.and(Ref.References.exists(players,Ref.References.target(head)),valid_list(players,rest))

def valid(+world: T.Terrain.World) -> Bool:
  valid_list(S.Simulation.players(T.Terrain.simulation(world)),S.Simulation.monsters(T.Terrain.simulation(world)))

@unsafe
def check(label: String,actual: T.Terrain.World,expected: T.Terrain.World) -> IO(Unit):
  Test.verdict(label,same_world(actual,expected))

@unsafe
def main() -> IO(Unit):
  do IO<Unit>:
    Unit <- check("disconnect clears deleted player target",W.Bq.del_plr(world([player(1,11)],[monster(91,1)]),1),world(Nil{},[monster(91,0)]))
    Unit <- check("removal retains another live target",W.Bq.del_plr(world([player(1,11),player(2,12)],[monster(91,2)]),1),world([player(2,12)],[monster(91,2)]))
    Unit <- check("removal retains zero sentinel",W.Bq.del_plr(world([player(1,11)],[monster(91,0)]),1),world(Nil{},[monster(91,0)]))
    Unit <- check("removal repairs older stale target",W.Bq.del_plr(world([player(1,11)],[monster(91,999)]),1),world(Nil{},[monster(91,0)]))
    Unit <- check("missing removal repairs stale target",W.Bq.del_plr(world([player(1,11)],[monster(91,999)]),9),world([player(1,11)],[monster(91,0)]))
    Unit <- check("missing removal retains exact valid world",W.Bq.del_plr(world([player(1,11)],[monster(91,1),monster(92,0)]),9),world([player(1,11)],[monster(91,1),monster(92,0)]))
    Unit <- check("empty roster clears all nonzero targets",W.Bq.del_plr(world(Nil{},[monster(91,1),monster(92,4294967295),monster(93,0)]),1),world(Nil{},[monster(91,0),monster(92,0),monster(93,0)]))
    Unit <- check("middle removal retains records and monster order",W.Bq.del_plr(world([player(1,11),player(2,12),player(3,13)],[monster(91,2),monster(92,1),monster(93,3),monster(94,999)]),2),world([player(1,11),player(3,13)],[monster(91,0),monster(92,1),monster(93,3),monster(94,0)]))
    Unit <- check("last removal retains records",W.Bq.del_plr(world([player(1,11),player(2,12),player(3,13)],[monster(91,3),monster(92,1)]),3),world([player(1,11),player(2,12)],[monster(91,0),monster(92,1)]))
    Unit <- check("maximum player ID target cleared",W.Bq.del_plr(world([player(4294967295,11)],[monster(91,4294967295)]),4294967295),world(Nil{},[monster(91,0)]))
    Unit <- check("maximum live player ID target retained",W.Bq.del_plr(world([player(1,11),player(4294967295,12)],[monster(91,4294967295)]),1),world([player(4294967295,12)],[monster(91,4294967295)]))
    Unit <- check("zero player removal retains zero sentinel",W.Bq.del_plr(world([player(0,11),player(1,12)],[monster(91,0),monster(92,1)]),0),world([player(1,12)],[monster(91,0),monster(92,1)]))
    Unit <- check("duplicate player ID retains remaining target",W.Bq.del_plr(world([player(1,11),player(1,12)],[monster(91,1)]),1),world([player(1,12)],[monster(91,1)]))
    Unit <- check("target lookup uses player ID not connection ID",W.Bq.del_plr(world([player(1,22),player(2,1)],[monster(91,1),monster(92,2),monster(93,22)]),1),world([player(2,1)],[monster(91,0),monster(92,2),monster(93,0)]))
    Unit <- check("dead boss target repair preserves death and cooldown",W.Bq.del_plr(world([player(1,11)],[corpse(1)]),1),world(Nil{},[corpse(0)]))
    Unit <- check("live dead-boss target retained exactly",W.Bq.del_plr(world([player(1,11),player(2,12)],[corpse(2)]),1),world([player(2,12)],[corpse(2)]))
    Unit <- check("removal handles empty monster roster",W.Bq.del_plr(world([player(1,11),player(2,12)],Nil{}),1),world([player(2,12)],Nil{}))
    Unit <- check("empty world removal is unchanged",W.Bq.del_plr(world(Nil{},Nil{}),4294967295),world(Nil{},Nil{}))
    Unit <- check("repeated removal is stable",W.Bq.del_plr(W.Bq.del_plr(world([player(1,11),player(2,12)],[monster(91,1),monster(92,2)]),1),1),world([player(2,12)],[monster(91,0),monster(92,2)]))
    Unit <- check("sequential disconnects clear both targets",W.Bq.del_plr(W.Bq.del_plr(world([player(1,11),player(2,12)],[monster(91,1),monster(92,2)]),1),2),world(Nil{},[monster(91,0),monster(92,0)]))
    Unit <- Test.verdict("fresh seed 0 has valid target references",valid(Pop.Population.fresh(1,0,0)))
    Unit <- Test.verdict("fresh seed 1 has valid target references",valid(Pop.Population.fresh(1,1,0)))
    Unit <- Test.verdict("fresh seed 2147483648 has valid target references",valid(Pop.Population.fresh(1,2147483648,0)))
    Unit <- Test.verdict("fresh seed 4294967295 has valid target references",valid(Pop.Population.fresh(1,4294967295,0)))
    IO.pure(Unit,Unit{})

#| PASS disconnect clears deleted player target
#| PASS removal retains another live target
#| PASS removal retains zero sentinel
#| PASS removal repairs older stale target
#| PASS missing removal repairs stale target
#| PASS missing removal retains exact valid world
#| PASS empty roster clears all nonzero targets
#| PASS middle removal retains records and monster order
#| PASS last removal retains records
#| PASS maximum player ID target cleared
#| PASS maximum live player ID target retained
#| PASS zero player removal retains zero sentinel
#| PASS duplicate player ID retains remaining target
#| PASS target lookup uses player ID not connection ID
#| PASS dead boss target repair preserves death and cooldown
#| PASS live dead-boss target retained exactly
#| PASS removal handles empty monster roster
#| PASS empty world removal is unchanged
#| PASS repeated removal is stable
#| PASS sequential disconnects clear both targets
#| PASS fresh seed 0 has valid target references
#| PASS fresh seed 1 has valid target references
#| PASS fresh seed 2147483648 has valid target references
#| PASS fresh seed 4294967295 has valid target references
