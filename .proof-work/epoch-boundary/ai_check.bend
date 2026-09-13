import Base
import ./ai.bend as A
import ./monsters.bend as M
import ./world.bend as W
import ./compat.bend as C

def same_monster(a: M.Monsters.State, b: M.Monsters.State) -> Bool:
  match a:
    case M.Monsters.State{a_mid, a_kind, a_rare, a_zone, a_x, a_y, a_hp, a_maximum, a_target, a_attack, a_dead, a_respawn}:
      match b:
        case M.Monsters.State{b_mid, b_kind, b_rare, b_zone, b_x, b_y, b_hp, b_maximum, b_target, b_attack, b_dead, b_respawn}:
          Bool.and(U32.is_eq(a_mid, b_mid), Bool.and(U32.is_eq(a_kind, b_kind), Bool.and(U32.is_eq(a_rare, b_rare), Bool.and(U32.is_eq(a_zone, b_zone), Bool.and(U32.is_eq(a_x, b_x), Bool.and(U32.is_eq(a_y, b_y), Bool.and(U32.is_eq(a_hp, b_hp), Bool.and(U32.is_eq(a_maximum, b_maximum), Bool.and(U32.is_eq(a_target, b_target), Bool.and(U32.is_eq(a_attack, b_attack), Bool.and(U32.is_eq(a_dead, b_dead), Bool.and(U32.is_eq(a_respawn, b_respawn), True{}))))))))))))

def same_list(a: List<&2, M.Monsters.State>, b: List<&2, M.Monsters.State>) -> Bool:
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
          Bool.and(same_monster(ah, bh), same_list(at, bt))

def verdict(name: String, ok: Bool) -> IO(Unit):
  match ok:
    case True{}:
      IO.print("PASS " ++ name)
    case False{}:
      IO.die(Unit, 1, "FAIL " ++ name)

def m(mid: U32, zone: U32, kind: U32, hp: U32, maximum: U32, cd: U32, dead: U32, timer: U32) -> M.Monsters.State:
  M.Monsters.State{mid, kind, 0, zone, 20, 10, hp, maximum, 99, cd, dead, timer}

def same_hit(hit: Maybe<&2, A.AI.Hit>, target: U32, damage: U32) -> Bool:
  match hit:
    case None{}:
      Bool.and(U32.is_eq(target, 0), U32.is_eq(damage, 0))
    case Some{hit}:
      match hit:
        case A.AI.Hit{pid, dealt}:
          Bool.and(U32.is_eq(pid, target), U32.is_eq(dealt, damage))

def step(name: String, result: A.AI.Step, expected: M.Monsters.State, target: U32, damage: U32) -> IO(Unit):
  match result:
    case A.AI.Step{monster, hit}:
      verdict(name, Bool.and(same_monster(monster, expected), same_hit(hit, target, damage)))

def no_hits(hits: List<&2, A.AI.Hit>) -> Bool:
  match hits:
    case Nil{}:
      True{}
    case Con{hit, rest}:
      False{}

def run(name: String, result: A.AI.Result, expected: List<&2, M.Monsters.State>) -> IO(Unit):
  match result:
    case A.AI.Result{monsters, hits}:
      verdict(name, Bool.and(same_list(monsters, expected), no_hits(hits)))

def world_no_hits(hits: List<&1, C.Bq.Pair.Pair(U32, (pid => U32))>) -> Bool:
  match hits:
    case Nil{}:
      True{}
    case Con{hit, rest}:
      False{}

def world_result(result: C.Bq.Pair.Pair(List<&2, W.Bq.Mob>, (ms => List<&1, C.Bq.Pair.Pair(U32, (pid => U32))>)), expected: List<&2, M.Monsters.State>) -> IO(Unit):
  match result:
    case Tuple{monsters, hits}:
      verdict("server four-zone AI composition", Bool.and(same_list(monsters, expected), world_no_hits(hits)))

def main() -> IO(Unit):
  +live = m(1, 0, 0, 10, 20, 4, 0, 0)
  +ticked = m(1, 0, 0, 10, 20, 3, 0, 0)
  +boss = m(2, 1, 9, 0, 100, 4, 1, 4294967295)
  +ready = m(3, 2, 0, 0, 20, 4, 1, 1)
  +wandered = {M.Monsters.State{1, 0, 0, 0, 21, 11, 10, 20, 8, 3, 0, 0} : M.Monsters.State}
  +attacked = {M.Monsters.State{1, 0, 0, 0, 20, 10, 10, 20, 8, 9, 0, 0} : M.Monsters.State}
  +reborn = {M.Monsters.State{3, 5, 1, 2, 25, 12, 60, 60, 0, 0, 0, 0} : M.Monsters.State}
  +world_mobs = {[m(1, 3, 0, 10, 20, 4, 0, 0), m(2, 0, 9, 10, 100, 4, 0, 0), m(3, 2, 0, 0, 20, 4, 1, 2), m(4, 1, 0, 20, 20, 1, 0, 0)] : List<&2, M.Monsters.State>}
  +world_expected = {[M.Monsters.State{2, 9, 0, 0, 20, 10, 40, 100, 0, 3, 0, 0}, M.Monsters.State{4, 0, 0, 1, 20, 10, 20, 20, 0, 0, 0, 0}, m(3, 2, 0, 0, 20, 4, 1, 1), M.Monsters.State{1, 0, 0, 3, 20, 10, 10, 20, 0, 3, 0, 0}] : List<&2, M.Monsters.State>}
  do IO<Unit>:
    Unit <- step("AI rest applies upkeep once", A.AI.step(live, A.AI.Rest{}), ticked, 0, 0)
    Unit <- step("AI movement preserves vitals", A.AI.step(live, A.AI.Move{21, 11, 8}), wandered, 0, 0)
    Unit <- step("AI blocked attack plan", A.AI.step(live, A.AI.Attack{8, 50}), ticked, 0, 0)
    Unit <- step("AI ready attack plan", A.AI.step(m(1, 0, 0, 10, 20, 1, 0, 0), A.AI.Attack{8, 50}), attacked, 8, 50)
    Unit <- step("AI live spawn plan ignored", A.AI.step(live, A.AI.Spawn{5, 1, 25, 12, 60}), ticked, 0, 0)
    Unit <- step("AI permanent boss ignores spawn", A.AI.step(boss, A.AI.Spawn{5, 1, 25, 12, 60}), boss, 0, 0)
    Unit <- step("AI dead monster cannot attack", A.AI.step(m(3, 2, 0, 0, 20, 4, 1, 2), A.AI.Attack{8, 50}), ready, 0, 0)
    Unit <- step("AI respawn cannot attack", A.AI.step(ready, A.AI.Attack{8, 50}), ready, 0, 0)
    Unit <- step("AI respawn uses original ID and zone", A.AI.step(ready, A.AI.Spawn{5, 1, 25, 12, 60}), reborn, 0, 0)
    Unit <- run("AI missing plans preserve list", A.AI.run([live, boss], Nil{}), [ticked, boss])
    Unit <- run("AI extra plans create no monsters", A.AI.run([live], [A.AI.Rest{}, A.AI.Spawn{5, 1, 25, 12, 60}]), [ticked])
    Unit <- run("AI four-zone composition", A.AI.run_zones(world_mobs, [A.AI.Move{20, 10, 0}], [A.AI.Move{20, 10, 0}], [A.AI.Rest{}], [A.AI.Move{20, 10, 0}]), world_expected)
    Unit <- world_result(W.Bq.tick_mobs(world_mobs, Nil{}, Nil{}, 0), world_expected)
    return Unit{}

#| PASS AI rest applies upkeep once
#| PASS AI movement preserves vitals
#| PASS AI blocked attack plan
#| PASS AI ready attack plan
#| PASS AI live spawn plan ignored
#| PASS AI permanent boss ignores spawn
#| PASS AI dead monster cannot attack
#| PASS AI respawn cannot attack
#| PASS AI respawn uses original ID and zone
#| PASS AI missing plans preserve list
#| PASS AI extra plans create no monsters
#| PASS AI four-zone composition
#| PASS server four-zone AI composition
