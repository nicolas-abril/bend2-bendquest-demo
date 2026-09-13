import Base
import ./terrain.bend as Terrain
import ./simulation.bend as S
import ./players.bend as P
import ./monsters.bend as M
import ./ai.bend as A
import ./vitals.bend as V
import ./game.bend as G
import ./world.bend as W
import ./compat.bend as C
import ./support.bend as L
import ./players_check.bend as T
import ./ai_check.bend as MT

def same_meta(a: S.Simulation.Meta, b: S.Simulation.Meta) -> Bool:
  match a:
    case S.Simulation.Meta{ap, aw, as, at, astart, an, asi, af, app, amm}:
      match b:
        case S.Simulation.Meta{bp, bw, bs, bt, bstart, bn, bsi, bf, bpp, bmm}:
          Bool.and(U32.is_eq(ap,bp), Bool.and(U32.is_eq(aw,bw), Bool.and(U32.is_eq(as,bs), Bool.and(U32.is_eq(at,bt), Bool.and(U32.is_eq(astart,bstart), Bool.and(U32.is_eq(an,bn), Bool.and(U32.is_eq(asi,bsi), Bool.and(U32.is_eq(af,bf), Bool.and(U32.is_eq(app,bpp), U32.is_eq(amm,bmm))))))))))

def same_state(a: S.Simulation.State, b: S.Simulation.State) -> Bool:
  match a:
    case S.Simulation.State{am, ap, aobs}:
      match b:
        case S.Simulation.State{bm, bp, bobs}:
          Bool.and(same_meta(am,bm), Bool.and(T.same_players(ap,bp), MT.same_list(aobs,bobs)))

def result(label: String, actual: S.Simulation.Result, expected: S.Simulation.State, events: List<&2, P.Players.Event>) -> IO(Unit):
  match actual:
    case S.Simulation.Result{state, actual_events}:
      T.verdict(label, Bool.and(same_state(state, expected), T.same_events(actual_events, events)))

def meta(phase: U32, tick: U32) -> S.Simulation.Meta:
  S.Simulation.Meta{phase,7,41,tick,100,200,3,400,51,450}

def rules() -> S.Simulation.Rules:
  S.Simulation.Rules{4,8,40}

def player(+pid: U32, zone: U32, x: U32, y: U32, moving: U32, hp: U32, dead: U32, timer: U32, attack: U32, spin: U32) -> P.Players.State:
  P.Players.State{pid,U32.add(pid,10),G.Bq.fresh_hero,P.Players.Pos{zone,x,y,1,moving},V.Vitals.State{hp,42,dead,timer,attack,spin},P.Players.Style{1,2,3,4,5,6},P.Players.Quest{1,2,3,4,5,6},P.Players.Meta{7,8,9,T.name()}}

def monster(mid: U32, zone: U32, target: U32, attack: U32) -> M.Monsters.State:
  M.Monsters.State{mid,0,0,zone,22,10,20,20,target,attack,0,0}

def original_players() -> List<&2, P.Players.State>:
  [player(1,0,20,10,1,34,0,0,3,7),player(2,2,11,10,1,0,1,1,3,7),player(3,0,20,11,1,1,0,0,3,7)]

def original_monsters() -> List<&2, M.Monsters.State>:
  [monster(13,1,999,1),monster(11,0,1,1),monster(12,0,3,1)]

def initial(phase: U32, tick: U32) -> S.Simulation.State:
  S.Simulation.State{meta(phase,tick),original_players,original_monsters}

def player_plans() -> List<&2, P.Players.Plan>:
  [P.Players.Walk{20,10},P.Players.Walk{99,99},P.Players.Walk{20,11}]

def plan() -> S.Simulation.Plan:
  S.Simulation.Plan{player_plans,[A.AI.Attack{1,6},A.AI.Attack{3,6}],[A.AI.Attack{999,6}],Nil{},Nil{}}

def quiet_plan() -> S.Simulation.Plan:
  S.Simulation.Plan{Nil{},[A.AI.Attack{1,6},A.AI.Attack{3,6}],[A.AI.Attack{999,6}],Nil{},Nil{}}

def upkeep_players() -> List<&2, P.Players.State>:
  [player(1,0,20,10,1,35,0,0,2,6),player(2,0,4,8,0,35,0,0,0,0),player(3,0,20,11,1,3,0,0,2,6)]

def active_expected() -> S.Simulation.State:
  S.Simulation.State{meta(1,1),[player(3,0,20,11,0,0,1,40,2,6),player(1,0,20,10,1,29,0,0,2,6),player(2,0,4,8,0,35,0,0,0,0)],[monster(11,0,1,9),monster(12,0,3,9),monster(13,1,999,9)]}

def trace_expected() -> S.Simulation.State:
  S.Simulation.State{meta(1,2),[player(3,0,20,11,0,0,1,39,2,6),player(1,0,20,10,1,29,0,0,1,5),player(2,0,4,8,0,35,0,0,0,0)],[monster(11,0,1,8),monster(12,0,3,8),monster(13,1,999,8)]}

def same_hits(a: List<&2, A.AI.Hit>, b: List<&2, A.AI.Hit>) -> Bool:
  match a:
    case Nil{}:
      match b:
        case Nil{}:
          True{}
        case Con{head, rest}:
          False{}
    case Con{ah, at}:
      match ah:
        case A.AI.Hit{ap, ad}:
          match b:
            case Nil{}:
              False{}
            case Con{bh, bt}:
              match bh:
                case A.AI.Hit{bp, bd}:
                  Bool.and(U32.is_eq(ap,bp), Bool.and(U32.is_eq(ad,bd), same_hits(at,bt)))

def hits() -> List<&2, A.AI.Hit>:
  [A.AI.Hit{0,4294967295},A.AI.Hit{7,1},A.AI.Hit{7,0}]

def first_snapshot(outs: List<&1, W.Bq.OutL>, prefix: C.Bq.String) -> Bool:
  match outs:
    case Nil{}:
      False{}
    case Con{head, rest}:
      match head:
        case W.Bq.OutL.All{line}:
          False{}
        case W.Bq.OutL.To{cid, line}:
          False{}
        case W.Bq.OutL.Log{line}:
          False{}
        case W.Bq.OutL.ZoneL{zone, line}:
          Bool.and(U32.is_eq(zone,0), L.Bq.String.eq(L.Bq.List.take(Char,8,line),prefix))

@unsafe
def world_result(label: String, actual: C.Bq.Pair.Pair(W.Bq.World, (world => List<&1, W.Bq.OutL>)), expected: S.Simulation.State, prefix: C.Bq.String) -> IO(Unit):
  match actual:
    case Tuple{world, outs}:
      match world:
        case Terrain.Terrain.World{wm, players, monsters, maps}:
          +shared_outs = {outs : List<&1, W.Bq.OutL>}
          T.verdict(label, Bool.and(same_state(S.Simulation.State{wm,players,monsters},expected), Bool.and(U32.is_eq(T.out_count(shared_outs),5), first_snapshot(shared_outs,prefix))))

def world(phase: U32, tick: U32) -> W.Bq.World:
  Terrain.Terrain.World{meta(phase,tick),[player(1,0,20,10,1,34,0,0,3,7)],[monster(11,0,0,1)],W.Bq.gen_maps(0)}

def main() -> IO(Unit):
  do IO<Unit>:
    Unit <- result("active tick orders upkeep AI and hits", S.Simulation.tick(initial(1,0),plan,rules), active_expected, [P.Players.Revived{2,12},P.Players.Died{3,13,T.name()}])
    Unit <- result("phase zero freezes gameplay", S.Simulation.tick(initial(0,0),plan,rules),initial(0,1),Nil{})
    Unit <- result("completed phase freezes gameplay", S.Simulation.tick(initial(2,0),plan,rules),initial(2,1),Nil{})
    Unit <- result("unknown phase freezes gameplay", S.Simulation.tick(initial(4294967295,0),plan,rules),initial(4294967295,1),Nil{})
    Unit <- result("empty active tick", S.Simulation.tick(S.Simulation.State{meta(1,0),Nil{},Nil{}},plan,rules),S.Simulation.State{meta(1,1),Nil{},Nil{}},Nil{})
    Unit <- result("tick word boundary is explicit", S.Simulation.tick(initial(2,4294967295),plan,rules),initial(2,0),Nil{})
    Unit <- T.result("prepared players expose completed upkeep", S.Simulation.prepared_upkeep(S.Simulation.begin(initial(1,0),player_plans,rules)),upkeep_players,[P.Players.Revived{2,12}])
    Unit <- T.verdict("preparation retains original monsters", MT.same_list(S.Simulation.prepared_monsters(S.Simulation.begin(initial(1,0),player_plans,rules)),original_monsters))
    Unit <- T.verdict("AI hit conversion preserves ordered payloads",same_hits(S.Simulation.restore_attacks(S.Simulation.attacks(hits)),hits))
    Unit <- T.verdict("successive ticks preserve lifecycle order",same_state(S.Simulation.trace([plan,quiet_plan],initial(1,0),rules),trace_expected))
    Unit <- world_result("server AI targets players after movement",W.Bq.tick_world(world(1,0)),S.Simulation.State{meta(1,1),[player(1,0,21,10,1,31,0,0,2,6)],[monster(11,0,1,9)]},C.Bq.text("SNAP 0 0"))
    Unit <- world_result("server inactive tick retains snapshot clock",W.Bq.tick_world(world(2,9)),S.Simulation.State{meta(2,10),[player(1,0,20,10,1,34,0,0,3,7)],[monster(11,0,0,1)]},C.Bq.text("SNAP 9 0"))
    return Unit{}

#| PASS active tick orders upkeep AI and hits
#| PASS phase zero freezes gameplay
#| PASS completed phase freezes gameplay
#| PASS unknown phase freezes gameplay
#| PASS empty active tick
#| PASS tick word boundary is explicit
#| PASS prepared players expose completed upkeep
#| PASS preparation retains original monsters
#| PASS AI hit conversion preserves ordered payloads
#| PASS successive ticks preserve lifecycle order
#| PASS server AI targets players after movement
#| PASS server inactive tick retains snapshot clock
