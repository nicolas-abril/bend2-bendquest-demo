import Base
import ./players.bend as P
import ./vitals.bend as V
import ./game.bend as G
import ./world.bend as W
import ./compat.bend as C
import ./data.bend as D

def same(a: Bool, b: Bool) -> Bool:
  Bool.not(Bool.xor(a, b))

def state(hp: U32, dead: U32, timer: U32) -> V.Vitals.State:
  V.Vitals.State{hp, 42, dead, timer, 3, 7}

def verdict(name: String, ok: Bool) -> IO(Unit):
  match ok:
    case True{}:
      IO.print("PASS " ++ name)
    case False{}:
      IO.die(Unit, 1, "FAIL " ++ name)

def state_ok(actual: V.Vitals.State, ehp: U32, edead: U32, etimer: U32, eatk: U32, espin: U32) -> Bool:
  match actual:
    case V.Vitals.State{hp, xp, dead, timer, attack, spin}:
      Bool.and(U32.is_eq(hp, ehp), Bool.and(U32.is_eq(xp, 42), Bool.and(U32.is_eq(dead, edead), Bool.and(U32.is_eq(timer, etimer), Bool.and(U32.is_eq(attack, eatk), U32.is_eq(spin, espin))))))

def hit(name: String, result: V.Vitals.Hit, ehp: U32, edead: U32, etimer: U32, efell: Bool) -> IO(Unit):
  match result:
    case V.Vitals.Hit{next, fell}:
      verdict(name, Bool.and(state_ok(next, ehp, edead, etimer, 3, 7), same(fell, efell)))

def upkeep(name: String, result: V.Vitals.Upkeep, ehp: U32, edead: U32, etimer: U32, eatk: U32, espin: U32, erevive: Bool, ewalk: Bool) -> IO(Unit):
  match result:
    case V.Vitals.Upkeep{next, revived, walk}:
      verdict(name, Bool.and(state_ok(next, ehp, edead, etimer, eatk, espin), Bool.and(same(revived, erevive), same(walk, ewalk))))

def player(vit: V.Vitals.State, moving: U32) -> W.Bq.Plr:
  P.Players.State{1, 1, G.Bq.fresh_hero, P.Players.Pos{0, 10, 10, 1, moving}, vit, P.Players.Style{0, 0, 0, 0, 0, 0}, P.Players.Quest{0, 0, 0, 0, 0, 0}, W.Bq.make_meta(0, 0, 0, C.Bq.text("proof-test"))}

def out_count(outs: List<&1, W.Bq.OutL>) -> U32:
  match outs:
    case Nil{}:
      0
    case Con{out, rest}:
      U32.add(1, out_count(rest))

# One death produces a broadcast and a server log entry.
def hit_player(p: W.Bq.Plr, outs: List<&1, W.Bq.OutL>) -> IO(Unit):
  match p:
    case P.Players.State{pid, cid, hero, pos, vit, style, qst, meta}:
      match pos:
        case P.Players.Pos{zone, x, y, dir, moving}:
          verdict("server repeated hit list", Bool.and(state_ok(vit, 0, 1, D.Bq.RESPAWN_TICKS, 3, 7), Bool.and(U32.is_eq(out_count(outs), 2), U32.is_eq(moving, 0))))

def hit_players(ps: List<&2, W.Bq.Plr>, outs: List<&1, W.Bq.OutL>) -> IO(Unit):
  match ps:
    case Nil{}:
      verdict("server repeated hit list", False{})
    case Con{p, rest}:
      hit_player(p, outs)

def world_hits(result: C.Bq.Pair.Pair(List<&2, W.Bq.Plr>, (ps => List<&1, W.Bq.OutL>))) -> IO(Unit):
  match result:
    case Tuple{players, outs}:
      hit_players(players, outs)

def world_revived_player(p: W.Bq.Plr, outs: List<&1, W.Bq.OutL>) -> IO(Unit):
  match p:
    case P.Players.State{pid, cid, hero, pos, vit, style, qst, meta}:
      match pos:
        case P.Players.Pos{zone, x, y, dir, moving}:
          verdict("server respawn adapter", Bool.and(state_ok(vit, 35, 0, 0, 0, 0), Bool.and(U32.is_eq(zone, 0), Bool.and(U32.is_eq(x, D.Bq.SPAWN_X), Bool.and(U32.is_eq(y, D.Bq.SPAWN_Y), Bool.and(U32.is_eq(moving, 0), U32.is_eq(out_count(outs), 2)))))))

def world_revived(result: C.Bq.Pair.Pair(W.Bq.Plr, (p => List<&1, W.Bq.OutL>))) -> IO(Unit):
  match result:
    case Tuple{p, outs}:
      world_revived_player(p, outs)

def main() -> IO(Unit):
  do IO<Unit>:
    Unit <- hit("nonlethal vital hit", V.Vitals.hit(state(35, 0, 0), 34, 80), 1, 0, 0, False{})
    Unit <- hit("exact lethal vital hit", V.Vitals.hit(state(35, 0, 0), 35, 80), 0, 1, 80, True{})
    Unit <- hit("overkill vital hit", V.Vitals.hit(state(35, 0, 0), 4294967295, 80), 0, 1, 80, True{})
    Unit <- hit("dead hit preserves timer", V.Vitals.hit(state(0, 1, 17), 4294967295, 80), 0, 1, 17, False{})
    Unit <- hit("zero damage stays alive", V.Vitals.hit(state(35, 0, 0), 0, 80), 35, 0, 0, False{})
    Unit <- upkeep("respawn timer waits", V.Vitals.upkeep(state(0, 1, 2), 2, 35), 0, 1, 1, 3, 7, False{}, False{})
    Unit <- upkeep("respawn timer expires", V.Vitals.upkeep(state(0, 1, 1), 2, 35), 35, 0, 0, 0, 0, True{}, False{})
    Unit <- upkeep("zero timer respawns", V.Vitals.upkeep(state(0, 1, 0), 2, 35), 35, 0, 0, 0, 0, True{}, False{})
    Unit <- upkeep("live tick regenerates", V.Vitals.upkeep(state(30, 0, 0), 2, 35), 32, 0, 0, 2, 6, False{}, True{})
    Unit <- upkeep("live tick caps healing", V.Vitals.upkeep(state(34, 0, 0), 2, 35), 35, 0, 0, 2, 6, False{}, True{})
    Unit <- upkeep("zero cooldown stays zero", V.Vitals.upkeep(V.Vitals.State{35, 42, 0, 0, 0, 0}, 2, 35), 35, 0, 0, 0, 0, False{}, True{})
    Unit <- upkeep("hero maximum respawn", V.Vitals.upkeep_hero(state(0, 1, 1), 0, G.Bq.fresh_hero, 4294967295), 35, 0, 0, 0, 0, True{}, False{})
    Unit <- world_hits(W.Bq.apply_hits([player(state(35, 0, 0), 1)], [Tuple{99, 1000}, Tuple{1, 1000}, Tuple{1, 1000}, Tuple{1, 1000}]))
    Unit <- world_revived(W.Bq.upkeep_plr(player(state(0, 1, 1), 1), Nil{}, 0))
    return Unit{}

#| PASS nonlethal vital hit
#| PASS exact lethal vital hit
#| PASS overkill vital hit
#| PASS dead hit preserves timer
#| PASS zero damage stays alive
#| PASS respawn timer waits
#| PASS respawn timer expires
#| PASS zero timer respawns
#| PASS live tick regenerates
#| PASS live tick caps healing
#| PASS zero cooldown stays zero
#| PASS hero maximum respawn
#| PASS server repeated hit list
#| PASS server respawn adapter
