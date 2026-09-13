import Base
import ./players.bend as P
import ./game.bend as G
import ./vitals.bend as V
import ./world.bend as W
import ./compat.bend as C

def verdict(name: String, ok: Bool) -> IO(Unit):
  match ok:
    case True{}:
      IO.print("PASS " ++ name)
    case False{}:
      IO.die(Unit, 1, "FAIL " ++ name)

def same_char(a: Char, b: Char) -> Bool:
  match a:
    case Chr{a0}:
      match b:
        case Chr{b0}:
          Bool.and(U32.is_eq(a0, b0), True{})

def same_name(a: List<&2, Char>, b: List<&2, Char>) -> Bool:
  match a:
    case Nil{}:
      match b:
        case Nil{}:
          True{}
        case Con{head, rest}:
          False{}
    case Con{ah, at}:
      match b:
        case Nil{}:
          False{}
        case Con{bh, bt}:
          Bool.and(same_char(ah, bh), same_name(at, bt))

def same_bag(a: List<&2, Nat>, b: List<&2, Nat>) -> Bool:
  match a:
    case Nil{}:
      match b:
        case Nil{}:
          True{}
        case Con{head, rest}:
          False{}
    case Con{ah, at}:
      match b:
        case Nil{}:
          False{}
        case Con{bh, bt}:
          Bool.and(G.Bq.Nat.eq(ah, bh), same_bag(at, bt))

def same_slot(a: G.Bq.Maybe(Nat), b: G.Bq.Maybe(Nat)) -> Bool:
  match a:
    case Fail{unit}:
      match b:
        case Fail{unit}:
          True{}
        case Done{value}:
          False{}
    case Done{a}:
      match b:
        case Fail{unit}:
          False{}
        case Done{b}:
          G.Bq.Nat.eq(a, b)

def same_hero(a: G.Bq.Hero, b: G.Bq.Hero) -> Bool:
  match a:
    case G.Bq.Hero.Hero{a0, a1, a2, a3, a4, a5, a6, a7, a8, a9, a10}:
      match b:
        case G.Bq.Hero.Hero{b0, b1, b2, b3, b4, b5, b6, b7, b8, b9, b10}:
          Bool.and(same_bag(a0, b0), Bool.and(same_slot(a1, b1), Bool.and(same_slot(a2, b2), Bool.and(same_slot(a3, b3), Bool.and(same_slot(a4, b4), Bool.and(G.Bq.Nat.eq(a5, b5), Bool.and(G.Bq.Nat.eq(a6, b6), Bool.and(G.Bq.Nat.eq(a7, b7), Bool.and(G.Bq.Nat.eq(a8, b8), Bool.and(G.Bq.Nat.eq(a9, b9), Bool.and(G.Bq.Nat.eq(a10, b10), True{})))))))))))

def same_pos(a: P.Players.Pos, b: P.Players.Pos) -> Bool:
  match a:
    case P.Players.Pos{a0, a1, a2, a3, a4}:
      match b:
        case P.Players.Pos{b0, b1, b2, b3, b4}:
          Bool.and(U32.is_eq(a0, b0), Bool.and(U32.is_eq(a1, b1), Bool.and(U32.is_eq(a2, b2), Bool.and(U32.is_eq(a3, b3), Bool.and(U32.is_eq(a4, b4), True{})))))

def same_vitals(a: V.Vitals.State, b: V.Vitals.State) -> Bool:
  match a:
    case V.Vitals.State{a0, a1, a2, a3, a4, a5}:
      match b:
        case V.Vitals.State{b0, b1, b2, b3, b4, b5}:
          Bool.and(U32.is_eq(a0, b0), Bool.and(U32.is_eq(a1, b1), Bool.and(U32.is_eq(a2, b2), Bool.and(U32.is_eq(a3, b3), Bool.and(U32.is_eq(a4, b4), Bool.and(U32.is_eq(a5, b5), True{}))))))

def same_style(a: P.Players.Style, b: P.Players.Style) -> Bool:
  match a:
    case P.Players.Style{a0, a1, a2, a3, a4, a5}:
      match b:
        case P.Players.Style{b0, b1, b2, b3, b4, b5}:
          Bool.and(U32.is_eq(a0, b0), Bool.and(U32.is_eq(a1, b1), Bool.and(U32.is_eq(a2, b2), Bool.and(U32.is_eq(a3, b3), Bool.and(U32.is_eq(a4, b4), Bool.and(U32.is_eq(a5, b5), True{}))))))

def same_quest(a: P.Players.Quest, b: P.Players.Quest) -> Bool:
  match a:
    case P.Players.Quest{a0, a1, a2, a3, a4, a5}:
      match b:
        case P.Players.Quest{b0, b1, b2, b3, b4, b5}:
          Bool.and(U32.is_eq(a0, b0), Bool.and(U32.is_eq(a1, b1), Bool.and(U32.is_eq(a2, b2), Bool.and(U32.is_eq(a3, b3), Bool.and(U32.is_eq(a4, b4), Bool.and(U32.is_eq(a5, b5), True{}))))))

def same_meta(a: P.Players.Meta, b: P.Players.Meta) -> Bool:
  match a:
    case P.Players.Meta{a0, a1, a2, a3}:
      match b:
        case P.Players.Meta{b0, b1, b2, b3}:
          Bool.and(U32.is_eq(a0, b0), Bool.and(U32.is_eq(a1, b1), Bool.and(U32.is_eq(a2, b2), Bool.and(same_name(a3, b3), True{}))))

def same_player(a: P.Players.State, b: P.Players.State) -> Bool:
  match a:
    case P.Players.State{a0, a1, a2, a3, a4, a5, a6, a7}:
      match b:
        case P.Players.State{b0, b1, b2, b3, b4, b5, b6, b7}:
          Bool.and(U32.is_eq(a0, b0), Bool.and(U32.is_eq(a1, b1), Bool.and(same_hero(a2, b2), Bool.and(same_pos(a3, b3), Bool.and(same_vitals(a4, b4), Bool.and(same_style(a5, b5), Bool.and(same_quest(a6, b6), Bool.and(same_meta(a7, b7), True{}))))))))

def same_players(a: List<&2, P.Players.State>, b: List<&2, P.Players.State>) -> Bool:
  match a:
    case Nil{}:
      match b:
        case Nil{}:
          True{}
        case Con{head, rest}:
          False{}
    case Con{ah, at}:
      match b:
        case Nil{}:
          False{}
        case Con{bh, bt}:
          Bool.and(same_player(ah, bh), same_players(at, bt))

def same_event(a: P.Players.Event, b: P.Players.Event) -> Bool:
  match a:
    case P.Players.Died{ap, ac, an}:
      match b:
        case P.Players.Died{bp, bc, bn}:
          Bool.and(U32.is_eq(ap, bp), Bool.and(U32.is_eq(ac, bc), same_name(an, bn)))
        case P.Players.Revived{bp, bc}:
          False{}
    case P.Players.Revived{ap, ac}:
      match b:
        case P.Players.Died{bp, bc, bn}:
          False{}
        case P.Players.Revived{bp, bc}:
          Bool.and(U32.is_eq(ap, bp), U32.is_eq(ac, bc))

def same_events(a: List<&2, P.Players.Event>, b: List<&2, P.Players.Event>) -> Bool:
  match a:
    case Nil{}:
      match b:
        case Nil{}:
          True{}
        case Con{head, rest}:
          False{}
    case Con{ah, at}:
      match b:
        case Nil{}:
          False{}
        case Con{bh, bt}:
          Bool.and(same_event(ah, bh), same_events(at, bt))

def same_found(a: Maybe<&2, P.Players.State>, b: Maybe<&2, P.Players.State>) -> Bool:
  match a:
    case None{}:
      match b:
        case None{}:
          True{}
        case Some{b}:
          False{}
    case Some{a}:
      match b:
        case None{}:
          False{}
        case Some{b}:
          same_player(a, b)

def taken(label: String, actual: P.Players.Take, others: List<&2, P.Players.State>, found: Maybe<&2, P.Players.State>) -> IO(Unit):
  match actual:
    case P.Players.Take{actual_others, actual_found}:
      verdict(label, Bool.and(same_players(actual_others, others), same_found(actual_found, found)))

def result(label: String, actual: P.Players.Result, players: List<&2, P.Players.State>, events: List<&2, P.Players.Event>) -> IO(Unit):
  match actual:
    case P.Players.Result{actual_players, actual_events}:
      verdict(label, Bool.and(same_players(actual_players, players), same_events(actual_events, events)))

def step(label: String, actual: P.Players.Step, player: P.Players.State, events: List<&2, P.Players.Event>) -> IO(Unit):
  result(label, P.Players.prepend_step(actual, P.Players.Result{Nil{}, Nil{}}), [player], events)

def name() -> List<&2, Char>:
  P.Players.share_name(C.Bq.text("Étoile🌟"))

def p(+pid: U32, x: U32, hp: U32, dead: U32, timer: U32) -> P.Players.State:
  P.Players.State{pid, U32.add(pid, 10), G.Bq.fresh_hero, P.Players.Pos{2, x, 10, 1, 1}, V.Vitals.State{hp, 42, dead, timer, 3, 7}, P.Players.Style{1, 2, 3, 4, 5, 6}, P.Players.Quest{1, 2, 3, 4, 5, 6}, P.Players.Meta{7, 8, 9, name()}}

def ended(+pid: U32, x: U32) -> P.Players.State:
  P.Players.State{pid, U32.add(pid, 10), G.Bq.fresh_hero, P.Players.Pos{2, x, 10, 1, 0}, V.Vitals.State{0, 42, 1, 40, 3, 7}, P.Players.Style{1, 2, 3, 4, 5, 6}, P.Players.Quest{1, 2, 3, 4, 5, 6}, P.Players.Meta{7, 8, 9, name()}}

def ticked(+pid: U32, zone: U32, x: U32, y: U32, moving: U32, hp: U32, dead: U32, timer: U32, acd: U32, scd: U32) -> P.Players.State:
  P.Players.State{pid, U32.add(pid, 10), G.Bq.fresh_hero, P.Players.Pos{zone, x, y, 1, moving}, V.Vitals.State{hp, 42, dead, timer, acd, scd}, P.Players.Style{1, 2, 3, 4, 5, 6}, P.Players.Quest{1, 2, 3, 4, 5, 6}, P.Players.Meta{7, 8, 9, name()}}

def out_count(outs: List<&1, W.Bq.OutL>) -> U32:
  match outs:
    case Nil{}:
      0
    case Con{head, rest}:
      U32.add(1, out_count(rest))

def world_result(label: String, actual: C.Bq.Pair.Pair(List<&2, W.Bq.Plr>, (ps => List<&1, W.Bq.OutL>)), expected: List<&2, P.Players.State>, outputs: U32) -> IO(Unit):
  match actual:
    case Tuple{players, outs}:
      verdict(label, Bool.and(same_players(players, expected), U32.is_eq(out_count(outs), outputs)))

def a() -> P.Players.State:
  p(1, 10, 35, 0, 0)

def b() -> P.Players.State:
  p(2, 11, 5, 0, 0)

def c() -> P.Players.State:
  p(3, 12, 20, 0, 0)

def all() -> List<&2, P.Players.State>:
  [a, b, c]

def hits() -> List<&2, P.Players.Attack>:
  [P.Players.Attack{99, 1000}, P.Players.Attack{2, 6}, P.Players.Attack{1, 1000}, P.Players.Attack{1, 1000}, P.Players.Attack{2, 6}, P.Players.Attack{3, 0}]

def hit_expected() -> List<&2, P.Players.State>:
  [p(3, 12, 19, 0, 0), ended(2, 11), ended(1, 10)]

def deaths() -> List<&2, P.Players.Event>:
  [P.Players.Died{2, 12, name()}, P.Players.Died{1, 11, name()}]

def waiting() -> P.Players.State:
  p(1, 10, 0, 1, 2)

def ready() -> P.Players.State:
  p(2, 11, 0, 1, 1)

def reborn() -> P.Players.State:
  ticked(2, 0, 4, 8, 0, 35, 0, 0, 0, 0)

def fresh() -> P.Players.State:
  P.Players.State{7, 17, G.Bq.fresh_hero, P.Players.Pos{0, 4, 8, 1, 0}, V.Vitals.State{35, 0, 0, 0, 0, 0}, P.Players.Style{1, 2, 3, 4, 5, 6}, P.Players.Quest{0, 0, 0, 0, 0, 0}, P.Players.Meta{0, 0, 0, name()}}

def northbound(y: U32, hp: U32, acd: U32, scd: U32) -> P.Players.State:
  P.Players.State{1, 11, G.Bq.fresh_hero, P.Players.Pos{0, 4, y, 2, 1}, V.Vitals.State{hp, 42, 0, 0, acd, scd}, P.Players.Style{1, 2, 3, 4, 5, 6}, P.Players.Quest{1, 2, 3, 4, 5, 6}, P.Players.Meta{7, 8, 9, name()}}

def main() -> IO(Unit):
  do IO<Unit>:
    Unit <- taken("player first lookup", P.Players.take(all, 1), [b,c], Some{a})
    Unit <- taken("player middle lookup", P.Players.take(all, 2), [a,c], Some{b})
    Unit <- taken("player last lookup", P.Players.take(all, 3), [a,b], Some{c})
    Unit <- taken("player missing lookup", P.Players.take(all, 99), all, None{})
    Unit <- taken("player duplicate selects first", P.Players.take([a,p(1,15,5,0,0),c], 1), [p(1,15,5,0,0),c], Some{a})
    Unit <- taken("player maximum ID", P.Players.take([p(4294967295,10,35,0,0),a], 4294967295), [a], Some{p(4294967295,10,35,0,0)})
    Unit <- result("player ordered hit list", P.Players.apply_hits(hits, all, 40), hit_expected, deaths)
    Unit <- result("player missing attacks are no-ops", P.Players.apply_hits([P.Players.Attack{99,4294967295}], all, 40), all, Nil{})
    Unit <- step("dead player full record unchanged", P.Players.hurt(waiting, 4294967295, 40), waiting, Nil{})
    Unit <- step("player upkeep heals once", P.Players.upkeep(c, P.Players.Walk{13,10}, 0, 4, 8), ticked(3,2,13,10,1,22,0,0,2,6), Nil{})
    Unit <- step("player upkeep off regeneration tick", P.Players.upkeep(c, P.Players.Walk{13,10}, 1, 4, 8), ticked(3,2,13,10,1,20,0,0,2,6), Nil{})
    Unit <- step("dead player ignores movement plan", P.Players.upkeep(waiting, P.Players.Walk{99,99}, 0, 4, 8), p(1,10,0,1,1), Nil{})
    Unit <- step("player respawn retains profile", P.Players.upkeep(ready, P.Players.Walk{99,99}, 0, 4, 8), reborn, [P.Players.Revived{2,12}])
    Unit <- result("player mixed upkeep list", P.Players.upkeep_all([c,ready,waiting], [P.Players.Walk{13,10},P.Players.Walk{99,99}], 0, 4, 8), [ticked(3,2,13,10,1,22,0,0,2,6),reborn,p(1,10,0,1,1)], [P.Players.Revived{2,12}])
    Unit <- result("player extra plans create no players", P.Players.upkeep_all([c], [P.Players.Walk{13,10},P.Players.Walk{99,99}], 0,4,8), [ticked(3,2,13,10,1,22,0,0,2,6)], Nil{})
    Unit <- result("player missing plan retains position", P.Players.upkeep_all([c], Nil{}, 0,4,8), [ticked(3,2,12,10,1,22,0,0,2,6)], Nil{})
    Unit <- world_result("server full player hit list", W.Bq.apply_hits(all, [Tuple{99,1000},Tuple{2,6},Tuple{1,1000},Tuple{1,1000},Tuple{2,6},Tuple{3,0}]), hit_expected, 4)
    Unit <- world_result("server full player upkeep list", W.Bq.upkeep_all([c,ready,waiting], Nil{}, 0), [ticked(3,2,12,10,1,22,0,0,2,6),reborn,p(1,10,0,1,1)], 2)
    Unit <- verdict("server fresh player profile", same_player(W.Bq.mk_plr(7,17,1,2,3,4,5,6,C.Bq.text("Étoile🌟")), fresh))
    Unit <- verdict("player Unicode name round trip", same_name(P.Players.share_name(P.Players.text_name(name())), name()))
    Unit <- world_result("server movement through spawn passage", W.Bq.upkeep_all([northbound(8,20,3,7)], W.Bq.gen_maps(0), 0), [northbound(7,22,2,6)], 0)
    return Unit{}

#| PASS player first lookup
#| PASS player middle lookup
#| PASS player last lookup
#| PASS player missing lookup
#| PASS player duplicate selects first
#| PASS player maximum ID
#| PASS player ordered hit list
#| PASS player missing attacks are no-ops
#| PASS dead player full record unchanged
#| PASS player upkeep heals once
#| PASS player upkeep off regeneration tick
#| PASS dead player ignores movement plan
#| PASS player respawn retains profile
#| PASS player mixed upkeep list
#| PASS player extra plans create no players
#| PASS player missing plan retains position
#| PASS server full player hit list
#| PASS server full player upkeep list
#| PASS server fresh player profile
#| PASS player Unicode name round trip
#| PASS server movement through spawn passage
