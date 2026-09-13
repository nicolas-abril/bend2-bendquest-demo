import Base
import ./terrain.bend as Terrain
import ./payouts.bend as X
import ./players.bend as P
import ./game.bend as G
import ./vitals.bend as V
import ./world.bend as W
import ./compat.bend as C
import ./players_check.bend as T
import ./simulation_check.bend as ST
import ./simulation.bend as S
import ./monsters.bend as M
import ./ai_check.bend as MT

def fixture_hero(bag: G.Bq.Bag,gold: Nat,lv: Nat,pts: Nat) -> G.Bq.Hero:
  G.Bq.Hero.Hero{bag,Fail{Unit{}},Fail{Unit{}},Fail{Unit{}},Fail{Unit{}},gold,lv,3n,3n,3n,pts}

def fixture_quest(main: U32,cull: U32,side0: U32,side1: U32,side2: U32,claimed: U32) -> P.Players.Quest:
  P.Players.Quest{main,cull,side0,side1,side2,claimed}

def fixture_player(+pid: U32,hero: G.Bq.Hero,hp: U32,xp: U32,dead: U32,q: P.Players.Quest,score: U32,kills: U32,found: U32) -> P.Players.State:
  P.Players.State{pid,U32.add(pid,10),hero,P.Players.Pos{0,9,4,3,1},V.Vitals.State{hp,xp,dead,7,3,9},P.Players.Style{1,2,3,4,5,6},q,P.Players.Meta{score,kills,found,T.name()}}

def fresh() -> P.Players.State: fixture_player(2,G.Bq.fresh_hero,35,20,0,fixture_quest(1,7,0,0,0,0),10,3,0)
def weak() -> P.Players.State: fixture_player(2,G.Bq.fresh_hero,1,20,0,fixture_quest(1,7,0,0,0,0),10,3,0)
def slain() -> P.Players.State: fixture_player(2,G.Bq.fresh_hero,0,20,1,fixture_quest(1,7,0,0,0,0),10,3,0)
def plain() -> X.Payout.Plan: X.Payout.Plan{0,10,2,1,5,50,4294967295,60,0,8,60}
def complete() -> P.Players.State: fixture_player(2,fixture_hero(Nil{},12n,2n,3n),35,5,0,fixture_quest(2,8,0,0,0,0),71,4,0)
def side_before() -> P.Players.State: fixture_player(2,G.Bq.fresh_hero,35,0,0,fixture_quest(1,2,4,3,5,0),10,3,0)
def side_done() -> P.Players.State: fixture_player(2,fixture_hero([3n],10n,1n,0n),35,0,0,fixture_quest(1,2,5,3,5,1),60,3,0)
def side_plan() -> X.Payout.Plan: X.Payout.Plan{1,0,0,1,5,50,0,0,0,8,60}
def loot_before() -> P.Players.State: fixture_player(2,G.Bq.fresh_hero,35,0,0,fixture_quest(1,2,0,0,0,0),10,3,0)
def loot_once() -> P.Players.State: fixture_player(2,fixture_hero([0n,0n,0n,1n],10n,1n,0n),35,0,0,fixture_quest(1,2,0,0,0,0),70,3,8)
def loot_twice() -> P.Players.State: fixture_player(2,fixture_hero([0n,0n,0n,2n],10n,1n,0n),35,0,0,fixture_quest(1,2,0,0,0,0),70,3,8)
def warden() -> X.Payout.Plan: X.Payout.Plan{6,0,0,1,5,50,4294967295,60,0,8,60}
def stage_player(pid: U32,stage: U32,score: U32) -> P.Players.State: fixture_player(pid,G.Bq.fresh_hero,35,0,0,fixture_quest(stage,8,0,0,0,0),score,3,0)

def same_maybe(a: Maybe<&2,U32>,b: Maybe<&2,U32>) -> Bool:
  match a:
    case None{}:
      match b:
        case None{}: True{}
        case Some{x}: False{}
    case Some{x}:
      match b:
        case None{}: False{}
        case Some{y}: U32.is_eq(x,y)

def kill_result(label: String,actual: X.Payout.Kill,expected: P.Players.State,side: Maybe<&2,U32>,drop: Maybe<&2,U32>,levels: U32) -> IO(Unit):
  match actual:
    case X.Payout.Kill{player,actual_side,actual_drop,actual_levels}:
      T.verdict(label,Bool.and(T.same_player(player,expected),Bool.and(same_maybe(actual_side,side),Bool.and(same_maybe(actual_drop,drop),U32.is_eq(actual_levels,levels)))))

def side_result(label: String,actual: X.Payout.Side,expected: P.Players.State,done: Maybe<&2,U32>) -> IO(Unit):
  match actual:
    case X.Payout.Side{player,completed}: T.verdict(label,Bool.and(T.same_player(player,expected),same_maybe(completed,done)))

def drop_result(label: String,actual: X.Payout.Drop,expected: P.Players.State,item: Maybe<&2,U32>) -> IO(Unit):
  match actual:
    case X.Payout.Drop{player,drop}: T.verdict(label,Bool.and(T.same_player(player,expected),same_maybe(drop,item)))

def fixture_meta(phase: U32,sigils: U32,fame: U32) -> S.Simulation.Meta: S.Simulation.Meta{phase,7,41,17,100,200,sigils,fame,51,450}
def mobs() -> List<&2,M.Monsters.State>: [M.Monsters.State{7,0,0,0,4,4,0,10,0,0,1,10}]
def fixture_world(players: List<&2,P.Players.State>) -> W.Bq.World: Terrain.Terrain.World{fixture_meta(1,0,19),players,mobs,[[123]]}

def same_maps(maps: List<&2,List<&2,U32>>) -> Bool:
  match maps:
    case Nil{}: False{}
    case Con{head,rest}:
      match head:
        case Nil{}: False{}
        case Con{x,xs}:
          match xs:
            case Con{a,b}: False{}
            case Nil{}:
              match rest:
                case Con{a,b}: False{}
                case Nil{}: U32.is_eq(x,123)

@unsafe
def world_result(label: String,actual: C.Bq.Pair.Pair(W.Bq.World,(w => List<&1,W.Bq.OutL>)),expected: List<&2,P.Players.State>,wm_expected: S.Simulation.Meta,outputs: U32) -> IO(Unit):
  match actual:
    case Tuple{w,outs}:
      match w:
        case Terrain.Terrain.World{wm,players,monsters,maps}:
          +shared_outs = {outs : List<&1,W.Bq.OutL>}
          T.verdict(label,Bool.and(ST.same_meta(wm,wm_expected),Bool.and(T.same_players(players,expected),Bool.and(MT.same_list(monsters,mobs),Bool.and(same_maps(maps),U32.is_eq(T.out_count(shared_outs),outputs))))))

@unsafe
def server_result(label: String,actual: C.Bq.Pair.Pair(P.Players.State,(p => List<&1,W.Bq.OutL>)),expected: P.Players.State,outputs: U32) -> IO(Unit):
  match actual:
    case Tuple{player,outs}:
      +shared_outs = {outs : List<&1,W.Bq.OutL>}
      T.verdict(label,Bool.and(T.same_player(player,expected),U32.is_eq(T.out_count(shared_outs),outputs)))

def main() -> IO(Unit):
  do IO<Unit>:
    Unit <- kill_result("payout XP gold and main quest compose",X.Payout.kill(fresh,plain),complete,None{},None{},1)
    Unit <- kill_result("payout retains one health through level up",X.Payout.kill(weak,plain),fixture_player(2,fixture_hero(Nil{},12n,2n,3n),1,5,0,fixture_quest(2,8,0,0,0,0),71,4,0),None{},None{},1)
    Unit <- kill_result("payout retains dead vital state",X.Payout.kill(slain,plain),fixture_player(2,fixture_hero(Nil{},12n,2n,3n),0,5,1,fixture_quest(2,8,0,0,0,0),71,4,0),None{},None{},1)
    Unit <- side_result("side quest increments only selected counter",X.Payout.side(loot_before,0,5,50),fixture_player(2,G.Bq.fresh_hero,35,0,0,fixture_quest(1,2,1,0,0,0),10,3,0),None{})
    Unit <- side_result("side quest completion grants three potions",X.Payout.side(side_before,0,5,50),side_done,Some{0})
    Unit <- side_result("claimed side quest exact no-op",X.Payout.side(side_done,0,5,50),side_done,None{})
    Unit <- side_result("invalid side quest exact no-op",X.Payout.side(side_before,4294967295,1,50),side_before,None{})
    Unit <- side_result("second side quest pays correct item",X.Payout.side(side_before,1,4,90),fixture_player(2,fixture_hero([0n,0n,0n,0n,0n,0n,0n,0n,0n,0n,0n,0n,0n,1n],10n,1n,0n),35,0,0,fixture_quest(1,2,4,4,5,2),100,3,0),Some{1})
    Unit <- side_result("third side quest pays correct item",X.Payout.side(side_before,2,6,120),fixture_player(2,fixture_hero([0n,0n,0n,0n,0n,0n,0n,0n,0n,0n,0n,0n,0n,0n,0n,0n,1n],10n,1n,0n),35,0,0,fixture_quest(1,2,4,3,6,4),130,3,0),Some{2})
    Unit <- drop_result("missing loot preserves complete player",X.Payout.drop(loot_before,4294967295,60),loot_before,None{})
    Unit <- drop_result("first rare loot grants item and find score",X.Payout.drop(loot_before,3,60),loot_once,Some{3})
    Unit <- drop_result("repeat loot grants item without find score",X.Payout.drop(loot_once,3,60),loot_twice,Some{3})
    Unit <- kill_result("side quest and loot rewards both retained",X.Payout.kill(side_before,side_plan),fixture_player(2,fixture_hero([4n],10n,1n,0n),35,0,0,fixture_quest(1,2,5,3,5,1),61,4,1),Some{0},Some{0},0)
    Unit <- T.verdict("sigil advances only matching players",T.same_players(X.Payout.sigil_all([stage_player(1,2,10),stage_player(2,3,20),stage_player(3,2,30)],2,200),[stage_player(1,3,210),stage_player(2,3,20),stage_player(3,3,230)]))
    Unit <- T.verdict("nonwarden kill does not advance quests",T.same_players(X.Payout.advance([stage_player(1,2,10)],0,200),[stage_player(1,2,10)]))
    Unit <- T.verdict("world payout conserves all players",T.same_players(X.Payout.roster(X.Payout.run([stage_player(1,2,10),stage_player(2,2,20),stage_player(3,3,30)],2,warden,200)),[fixture_player(2,G.Bq.fresh_hero,35,0,0,fixture_quest(3,8,0,0,0,0),221,4,0),stage_player(1,3,210),stage_player(3,3,30)]))
    Unit <- T.verdict("missing killer retains roster",T.same_players(X.Payout.roster(X.Payout.run([fresh,T.a],99,warden,200)),[fresh,T.a]))
    Unit <- T.verdict("payout sequence preserves successive XP",T.same_players(X.Payout.trace([X.Payout.Award{2,plain},X.Payout.Award{2,plain}],[fresh],200),[fixture_player(2,fixture_hero(Nil{},14n,2n,3n),35,15,0,fixture_quest(2,8,0,0,0,0),72,5,0)]))
    Unit <- server_result("server rare kill applies full payout",W.Bq.kill_reward(fresh,0,1,0,17,100,7),fixture_player(2,fixture_hero([0n,0n,0n,1n],34n,2n,3n),35,59,0,fixture_quest(2,8,0,0,0,0),150,4,8),7)
    Unit <- world_result("server missing killer leaves world intact",W.Bq.on_mob_kill(fixture_world([fresh,T.a]),99,9,0,3,7),[fresh,T.a],fixture_meta(1,0,19),0)
    Unit <- world_result("server rare kill preserves maps and monsters",W.Bq.on_mob_kill(fixture_world([T.a,fresh,T.c]),2,0,1,0,7),[fixture_player(2,fixture_hero([0n,0n,0n,1n],34n,2n,3n),35,59,0,fixture_quest(2,8,0,0,0,0),150,4,8),T.a,T.c],fixture_meta(1,0,19),7)
    return Unit{}

#| PASS payout XP gold and main quest compose
#| PASS payout retains one health through level up
#| PASS payout retains dead vital state
#| PASS side quest increments only selected counter
#| PASS side quest completion grants three potions
#| PASS claimed side quest exact no-op
#| PASS invalid side quest exact no-op
#| PASS second side quest pays correct item
#| PASS third side quest pays correct item
#| PASS missing loot preserves complete player
#| PASS first rare loot grants item and find score
#| PASS repeat loot grants item without find score
#| PASS side quest and loot rewards both retained
#| PASS sigil advances only matching players
#| PASS nonwarden kill does not advance quests
#| PASS world payout conserves all players
#| PASS missing killer retains roster
#| PASS payout sequence preserves successive XP
#| PASS server rare kill applies full payout
#| PASS server missing killer leaves world intact
#| PASS server rare kill preserves maps and monsters
