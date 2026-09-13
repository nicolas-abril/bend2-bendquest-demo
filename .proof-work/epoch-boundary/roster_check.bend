import Base
import ./roster.bend as R
import ./monsters.bend as M
import ./world.bend as W
import ./compat.bend as C

def monster(mid: U32, +hp: U32) -> M.Monsters.State:
  M.Monsters.State{mid, 0, 0, 0, 20, 10, hp, hp, 99, 4, 0, 0}

def verdict(name: String, ok: Bool) -> IO(Unit):
  match ok:
    case True{}:
      IO.print("PASS " ++ name)
    case False{}:
      IO.die(Unit, 1, "FAIL " ++ name)

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

def same_found(a: Maybe<&2, M.Monsters.State>, b: Maybe<&2, M.Monsters.State>) -> Bool:
  match a:
    case None{}:
      match b:
        case None{}:
          True{}
        case Some{monster}:
          False{}
    case Some{am}:
      match b:
        case None{}:
          False{}
        case Some{bm}:
          same_monster(am, bm)

def take(name: String, result: R.Roster.Take, expected: List<&2, M.Monsters.State>, selected: Maybe<&2, M.Monsters.State>) -> IO(Unit):
  match result:
    case R.Roster.Take{others, found}:
      verdict(name, Bool.and(same_list(others, expected), same_found(found, selected)))

def kill_ok(kill: Maybe<&2, R.Roster.Kill>, expected: U32) -> Bool:
  match kill:
    case None{}:
      U32.is_eq(expected, 0)
    case Some{info}:
      match info:
        case R.Roster.Kill{kind, rare, zone, mid}:
          Bool.and(U32.is_eq(expected, mid), Bool.and(U32.is_eq(kind, 0), Bool.and(U32.is_eq(rare, 0), U32.is_eq(zone, 0))))

def strike(name: String, result: R.Roster.Strike, expected: List<&2, M.Monsters.State>, killed: U32, damage: U32) -> IO(Unit):
  match result:
    case R.Roster.Strike{monsters, kill, dealt}:
      verdict(name, Bool.and(same_list(monsters, expected), Bool.and(kill_ok(kill, killed), U32.is_eq(dealt, damage))))

def world_take(result: C.Bq.Pair.Pair(List<&2, W.Bq.Mob>, (ms => Result<&1, &1, Unit, W.Bq.Mob>))) -> R.Roster.Take:
  match result:
    case Tuple{others, found}:
      match found:
        case Fail{unit}:
          R.Roster.Take{others, None{}}
        case Done{monster}:
          R.Roster.Take{others, Some{monster}}

def KillInfo() -> Type:
  C.Bq.Pair.Pair(U32, (kind => C.Bq.Pair.Pair(U32, (rare => C.Bq.Pair.Pair(U32, (zone => U32))))))

def world_kill(info: KillInfo) -> R.Roster.Kill:
  match info:
    case Tuple{kind, rest}:
      match rest:
        case Tuple{rare, tail}:
          match tail:
            case Tuple{zone, mid}:
              R.Roster.Kill{kind, rare, zone, mid}

def world_strike(result: C.Bq.Pair.Pair(List<&2, W.Bq.Mob>, (ms => C.Bq.Pair.Pair(Result<&1, &1, Unit, KillInfo>, (kill => U32))))) -> R.Roster.Strike:
  match result:
    case Tuple{monsters, rest}:
      match rest:
        case Tuple{kill, dealt}:
          match kill:
            case Fail{unit}:
              R.Roster.Strike{monsters, None{}, dealt}
            case Done{info}:
              R.Roster.Strike{monsters, Some{world_kill(info)}, dealt}

def main() -> IO(Unit):
  +a = monster(1, 10)
  +b = monster(2, 20)
  +c = monster(3, 30)
  +all = {[a, b, c] : List<&2, M.Monsters.State>}
  +dead_b = {M.Monsters.State{2, 0, 0, 0, 20, 10, 0, 20, 0, 0, 1, 80} : M.Monsters.State}
  do IO<Unit>:
    Unit <- take("roster first lookup", R.Roster.take(all, 1), [b, c], Some{a})
    Unit <- take("roster middle lookup", R.Roster.take(all, 2), [a, c], Some{b})
    Unit <- take("roster last lookup", R.Roster.take(all, 3), [a, b], Some{c})
    Unit <- take("roster missing lookup", R.Roster.take(all, 4), all, None{})
    Unit <- take("roster empty lookup", R.Roster.take(Nil{}, 1), Nil{}, None{})
    Unit <- take("roster zero ID", R.Roster.take([monster(0, 10), b], 0), [b], Some{monster(0, 10)})
    Unit <- take("roster maximum ID", R.Roster.take([a, monster(4294967295, 10)], 4294967295), [a], Some{monster(4294967295, 10)})
    Unit <- take("roster first duplicate", R.Roster.take([b, monster(2, 30)], 2), [monster(2, 30)], Some{b})
    Unit <- strike("roster middle lethal strike", R.Roster.strike(all, 2, 99), [dead_b, a, c], 2, 20)
    Unit <- strike("roster missing strike no-op", R.Roster.strike(all, 4, 99), all, 0, 0)
    Unit <- verdict("roster concatenation", same_list(R.Roster.concat([a], [b, c]), all))
    Unit <- take("server middle lookup", world_take(W.Bq.take_mob(2, all)), [a, c], Some{b})
    Unit <- strike("server middle strike", world_strike(W.Bq.strike_mob(all, 2, 99)), [dead_b, a, c], 2, 20)
    return Unit{}

#| PASS roster first lookup
#| PASS roster middle lookup
#| PASS roster last lookup
#| PASS roster missing lookup
#| PASS roster empty lookup
#| PASS roster zero ID
#| PASS roster maximum ID
#| PASS roster first duplicate
#| PASS roster middle lethal strike
#| PASS roster missing strike no-op
#| PASS roster concatenation
#| PASS server middle lookup
#| PASS server middle strike
