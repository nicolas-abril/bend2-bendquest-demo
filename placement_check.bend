import Base
import ./population.bend as Pop
import ./planning.bend as Plan
import ./placement.bend as Place
import ./terrain.bend as T
import ./monsters.bend as M
import ./players.bend as P
import ./vitals.bend as V
import ./roster.bend as R
import ./habitat.bend as H
import ./simulation.bend as S
import ./world.bend as W
import ./compat.bend as C
import ./ai.bend as A
import ./players_check.bend as Test
import ./game.bend as G

def position_ok(+maps: T.Terrain.Maps,+monster: M.Monsters.State) -> Bool:
  +pos = H.Habitat.pos(monster)
  Bool.and(T.Terrain.can_walk(maps,pos),Bool.not(T.Terrain.in_village(pos)))

def positions(+maps: T.Terrain.Maps,monsters: List<&2,M.Monsters.State>) -> Bool:
  match monsters:
    case Nil{}: True{}
    case Con{head,rest}: Bool.and(position_ok(maps,head),positions(maps,rest))

def life(+monster: M.Monsters.State) -> Bool:
  match monster:
    case M.Monsters.State{mid,kind,rare,zone,x,y,hp,maximum,target,attack,dead,respawn}:
      +health = hp
      Bool.and(U32.is_le(health,maximum),Bool.or(Bool.and(U32.is_eq(dead,0),U32.is_gt(health,0)),Bool.and(U32.is_eq(dead,1),U32.is_eq(health,0))))

def lives(monsters: List<&2,M.Monsters.State>) -> Bool:
  match monsters:
    case Nil{}: True{}
    case Con{head,rest}: Bool.and(life(head),lives(rest))

def absent(+id: U32,monsters: List<&2,M.Monsters.State>) -> Bool:
  match monsters:
    case Nil{}: True{}
    case Con{head,rest}: Bool.and(U32.is_ne(id,R.Roster.id(head)),absent(id,rest))

def distinct(monsters: List<&2,M.Monsters.State>) -> Bool:
  match monsters:
    case Nil{}: True{}
    case Con{head,rest}:
      +tail = rest
      Bool.and(absent(R.Roster.id(head),tail),distinct(tail))

def initial_world_ok(world: T.Terrain.World) -> Bool:
  match world:
    case T.Terrain.World{meta,players,monsters,maps}:
      +ms = monsters
      Bool.and(G.Bq.Nat.eq(R.Roster.length(ms),31n),Bool.and(positions(maps,ms),Bool.and(lives(ms),distinct(ms))))

def fallen(monster: M.Monsters.State) -> M.Monsters.State:
  match monster:
    case M.Monsters.State{mid,kind,rare,zone,x,y,hp,maximum,target,attack,dead,respawn}:
      +k = kind
      M.Monsters.State{mid,k,rare,zone,x,y,0,maximum,0,0,1,M.Monsters.choose(U32.is_ge(k,6),4294967295,1)}

def fallen_all(monsters: List<&2,M.Monsters.State>) -> List<&2,M.Monsters.State>:
  match monsters:
    case Nil{}: Nil{}
    case Con{head,rest}: Con{fallen(head),fallen_all(rest)}

def deaths(world: T.Terrain.World) -> T.Terrain.World:
  match world:
    case T.Terrain.World{meta,players,monsters,maps}: T.Terrain.World{meta,players,fallen_all(monsters),maps}

def reborn(+monster: M.Monsters.State) -> Bool:
  match monster:
    case M.Monsters.State{mid,kind,rare,zone,x,y,hp,maximum,target,attack,dead,respawn}:
      Bool.or(Bool.and(U32.is_ge(kind,6),U32.is_eq(dead,1)),Bool.and(U32.is_lt(kind,6),U32.is_eq(dead,0)))

def all_reborn(monsters: List<&2,M.Monsters.State>) -> Bool:
  match monsters:
    case Nil{}: True{}
    case Con{head,rest}: Bool.and(reborn(head),all_reborn(rest))

def respawn_ok(result: C.Bq.Pair.Pair(W.Bq.World,(world => List<&1,W.Bq.OutL>))) -> Bool:
  match result:
    case Tuple{world,events}:
      match world:
        case T.Terrain.World{meta,players,monsters,maps}:
          +ms = monsters
          Bool.and(G.Bq.Nat.eq(R.Roster.length(ms),31n),Bool.and(positions(maps,ms),Bool.and(lives(ms),Bool.and(distinct(ms),all_reborn(ms)))))

def spot_result(+maps: T.Terrain.Maps,+zone: U32,pair: U32 & U32) -> Bool:
  match pair:
    case Tuple{x,y}:
      +pos = {P.Players.Pos{zone,x,y,0,0} : P.Players.Pos}
      Bool.and(T.Terrain.can_walk(maps,pos),Bool.not(T.Terrain.in_village(pos)))

def spot_ok(+maps: T.Terrain.Maps,+zone: U32,salt: U32) -> Bool:
  spot_result(maps,zone,W.Bq.spawn_spot(maps,zone,salt))

def planner_ok(+maps: T.Terrain.Maps,+monsters: List<&2,M.Monsters.State>,contexts: List<&2,Plan.Planning.Context>,tick: U32) -> Bool:
  +next = A.AI.monsters(A.AI.run(monsters,Plan.Planning.plans(monsters,contexts,maps,tick)))
  Bool.and(G.Bq.Nat.eq(R.Roster.length(next),R.Roster.length(monsters)),Bool.and(positions(maps,next),lives(next)))

def main() -> IO(Unit):
  do IO<Unit>:
    Unit <- Test.verdict("base remainder boundary 0",Bool.and(U32.is_eq(U32.mod(0,13),0),U32.is_eq(U32.mod(0,26),0)))
    Unit <- Test.verdict("base remainder boundary 1",Bool.and(U32.is_eq(U32.mod(1,13),1),U32.is_eq(U32.mod(1,26),1)))
    Unit <- Test.verdict("base remainder boundary 12",Bool.and(U32.is_eq(U32.mod(12,13),12),U32.is_eq(U32.mod(12,26),12)))
    Unit <- Test.verdict("base remainder boundary 13",Bool.and(U32.is_eq(U32.mod(13,13),0),U32.is_eq(U32.mod(13,26),13)))
    Unit <- Test.verdict("base remainder boundary 25",Bool.and(U32.is_eq(U32.mod(25,13),12),U32.is_eq(U32.mod(25,26),25)))
    Unit <- Test.verdict("base remainder boundary 26",Bool.and(U32.is_eq(U32.mod(26,13),0),U32.is_eq(U32.mod(26,26),0)))
    Unit <- Test.verdict("base remainder boundary 27",Bool.and(U32.is_eq(U32.mod(27,13),1),U32.is_eq(U32.mod(27,26),1)))
    Unit <- Test.verdict("base remainder boundary 2147483648",Bool.and(U32.is_eq(U32.mod(2147483648,13),11),U32.is_eq(U32.mod(2147483648,26),24)))
    Unit <- Test.verdict("base remainder boundary 4294967295",Bool.and(U32.is_eq(U32.mod(4294967295,13),8),U32.is_eq(U32.mod(4294967295,26),21)))
    Unit <- Test.verdict("initial world has 31 distinct healthy walkable monsters seed 0",initial_world_ok(W.Bq.fresh_world(7,0,4294967295)))
    Unit <- Test.verdict("ordinary monsters respawn and bosses stay dead seed 0",respawn_ok(W.Bq.tick_world(deaths(W.Bq.fresh_world(7,0,4294967295)))))
    Unit <- Test.verdict("spawn outside village on walkable tile seed 0 zone 0",Bool.and(spot_ok(W.Bq.gen_maps(0),0,0),Bool.and(spot_ok(W.Bq.gen_maps(0),0,17),spot_ok(W.Bq.gen_maps(0),0,4294967295))))
    Unit <- Test.verdict("spawn outside village on walkable tile seed 0 zone 1",Bool.and(spot_ok(W.Bq.gen_maps(0),1,0),Bool.and(spot_ok(W.Bq.gen_maps(0),1,17),spot_ok(W.Bq.gen_maps(0),1,4294967295))))
    Unit <- Test.verdict("spawn outside village on walkable tile seed 0 zone 2",Bool.and(spot_ok(W.Bq.gen_maps(0),2,0),Bool.and(spot_ok(W.Bq.gen_maps(0),2,17),spot_ok(W.Bq.gen_maps(0),2,4294967295))))
    Unit <- Test.verdict("spawn outside village on walkable tile seed 0 zone 3",Bool.and(spot_ok(W.Bq.gen_maps(0),3,0),Bool.and(spot_ok(W.Bq.gen_maps(0),3,17),spot_ok(W.Bq.gen_maps(0),3,4294967295))))
    Unit <- Test.verdict("initial world has 31 distinct healthy walkable monsters seed 17",initial_world_ok(W.Bq.fresh_world(7,17,4294967295)))
    Unit <- Test.verdict("ordinary monsters respawn and bosses stay dead seed 17",respawn_ok(W.Bq.tick_world(deaths(W.Bq.fresh_world(7,17,4294967295)))))
    Unit <- Test.verdict("spawn outside village on walkable tile seed 17 zone 0",Bool.and(spot_ok(W.Bq.gen_maps(17),0,0),Bool.and(spot_ok(W.Bq.gen_maps(17),0,17),spot_ok(W.Bq.gen_maps(17),0,4294967295))))
    Unit <- Test.verdict("spawn outside village on walkable tile seed 17 zone 1",Bool.and(spot_ok(W.Bq.gen_maps(17),1,0),Bool.and(spot_ok(W.Bq.gen_maps(17),1,17),spot_ok(W.Bq.gen_maps(17),1,4294967295))))
    Unit <- Test.verdict("spawn outside village on walkable tile seed 17 zone 2",Bool.and(spot_ok(W.Bq.gen_maps(17),2,0),Bool.and(spot_ok(W.Bq.gen_maps(17),2,17),spot_ok(W.Bq.gen_maps(17),2,4294967295))))
    Unit <- Test.verdict("spawn outside village on walkable tile seed 17 zone 3",Bool.and(spot_ok(W.Bq.gen_maps(17),3,0),Bool.and(spot_ok(W.Bq.gen_maps(17),3,17),spot_ok(W.Bq.gen_maps(17),3,4294967295))))
    Unit <- Test.verdict("initial world has 31 distinct healthy walkable monsters seed 2147483648",initial_world_ok(W.Bq.fresh_world(7,2147483648,4294967295)))
    Unit <- Test.verdict("ordinary monsters respawn and bosses stay dead seed 2147483648",respawn_ok(W.Bq.tick_world(deaths(W.Bq.fresh_world(7,2147483648,4294967295)))))
    Unit <- Test.verdict("spawn outside village on walkable tile seed 2147483648 zone 0",Bool.and(spot_ok(W.Bq.gen_maps(2147483648),0,0),Bool.and(spot_ok(W.Bq.gen_maps(2147483648),0,17),spot_ok(W.Bq.gen_maps(2147483648),0,4294967295))))
    Unit <- Test.verdict("spawn outside village on walkable tile seed 2147483648 zone 1",Bool.and(spot_ok(W.Bq.gen_maps(2147483648),1,0),Bool.and(spot_ok(W.Bq.gen_maps(2147483648),1,17),spot_ok(W.Bq.gen_maps(2147483648),1,4294967295))))
    Unit <- Test.verdict("spawn outside village on walkable tile seed 2147483648 zone 2",Bool.and(spot_ok(W.Bq.gen_maps(2147483648),2,0),Bool.and(spot_ok(W.Bq.gen_maps(2147483648),2,17),spot_ok(W.Bq.gen_maps(2147483648),2,4294967295))))
    Unit <- Test.verdict("spawn outside village on walkable tile seed 2147483648 zone 3",Bool.and(spot_ok(W.Bq.gen_maps(2147483648),3,0),Bool.and(spot_ok(W.Bq.gen_maps(2147483648),3,17),spot_ok(W.Bq.gen_maps(2147483648),3,4294967295))))
    Unit <- Test.verdict("initial world has 31 distinct healthy walkable monsters seed 4294967295",initial_world_ok(W.Bq.fresh_world(7,4294967295,4294967295)))
    Unit <- Test.verdict("ordinary monsters respawn and bosses stay dead seed 4294967295",respawn_ok(W.Bq.tick_world(deaths(W.Bq.fresh_world(7,4294967295,4294967295)))))
    Unit <- Test.verdict("spawn outside village on walkable tile seed 4294967295 zone 0",Bool.and(spot_ok(W.Bq.gen_maps(4294967295),0,0),Bool.and(spot_ok(W.Bq.gen_maps(4294967295),0,17),spot_ok(W.Bq.gen_maps(4294967295),0,4294967295))))
    Unit <- Test.verdict("spawn outside village on walkable tile seed 4294967295 zone 1",Bool.and(spot_ok(W.Bq.gen_maps(4294967295),1,0),Bool.and(spot_ok(W.Bq.gen_maps(4294967295),1,17),spot_ok(W.Bq.gen_maps(4294967295),1,4294967295))))
    Unit <- Test.verdict("spawn outside village on walkable tile seed 4294967295 zone 2",Bool.and(spot_ok(W.Bq.gen_maps(4294967295),2,0),Bool.and(spot_ok(W.Bq.gen_maps(4294967295),2,17),spot_ok(W.Bq.gen_maps(4294967295),2,4294967295))))
    Unit <- Test.verdict("spawn outside village on walkable tile seed 4294967295 zone 3",Bool.and(spot_ok(W.Bq.gen_maps(4294967295),3,0),Bool.and(spot_ok(W.Bq.gen_maps(4294967295),3,17),spot_ok(W.Bq.gen_maps(4294967295),3,4294967295))))
    Unit <- Test.verdict("missing contexts retain monster validity",planner_ok(W.Bq.gen_maps(17),Pop.Population.initial(W.Bq.gen_maps(17)),[],4294967295))
    Unit <- Test.verdict("extra contexts preserve the single-monster roster",planner_ok(W.Bq.gen_maps(17),[Pop.Population.boss(1,0)],[Plan.Planning.idle,Plan.Planning.idle,Plan.Planning.idle],0))
    Unit <- Test.verdict("missing contexts still permit lifecycle respawn",planner_ok(W.Bq.gen_maps(17),fallen_all(Pop.Population.initial(W.Bq.gen_maps(17))),[],0))
    return Unit{}

#| PASS base remainder boundary 0
#| PASS base remainder boundary 1
#| PASS base remainder boundary 12
#| PASS base remainder boundary 13
#| PASS base remainder boundary 25
#| PASS base remainder boundary 26
#| PASS base remainder boundary 27
#| PASS base remainder boundary 2147483648
#| PASS base remainder boundary 4294967295
#| PASS initial world has 31 distinct healthy walkable monsters seed 0
#| PASS ordinary monsters respawn and bosses stay dead seed 0
#| PASS spawn outside village on walkable tile seed 0 zone 0
#| PASS spawn outside village on walkable tile seed 0 zone 1
#| PASS spawn outside village on walkable tile seed 0 zone 2
#| PASS spawn outside village on walkable tile seed 0 zone 3
#| PASS initial world has 31 distinct healthy walkable monsters seed 17
#| PASS ordinary monsters respawn and bosses stay dead seed 17
#| PASS spawn outside village on walkable tile seed 17 zone 0
#| PASS spawn outside village on walkable tile seed 17 zone 1
#| PASS spawn outside village on walkable tile seed 17 zone 2
#| PASS spawn outside village on walkable tile seed 17 zone 3
#| PASS initial world has 31 distinct healthy walkable monsters seed 2147483648
#| PASS ordinary monsters respawn and bosses stay dead seed 2147483648
#| PASS spawn outside village on walkable tile seed 2147483648 zone 0
#| PASS spawn outside village on walkable tile seed 2147483648 zone 1
#| PASS spawn outside village on walkable tile seed 2147483648 zone 2
#| PASS spawn outside village on walkable tile seed 2147483648 zone 3
#| PASS initial world has 31 distinct healthy walkable monsters seed 4294967295
#| PASS ordinary monsters respawn and bosses stay dead seed 4294967295
#| PASS spawn outside village on walkable tile seed 4294967295 zone 0
#| PASS spawn outside village on walkable tile seed 4294967295 zone 1
#| PASS spawn outside village on walkable tile seed 4294967295 zone 2
#| PASS spawn outside village on walkable tile seed 4294967295 zone 3
#| PASS missing contexts retain monster validity
#| PASS extra contexts preserve the single-monster roster
#| PASS missing contexts still permit lifecycle respawn
