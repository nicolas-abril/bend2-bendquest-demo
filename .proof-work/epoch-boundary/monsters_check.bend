import Base
import ./monsters.bend as M
import ./world.bend as W
import ./compat.bend as C

def same(a: Bool, b: Bool) -> Bool:
  Bool.not(Bool.xor(a, b))

def verdict(name: String, ok: Bool) -> IO(Unit):
  match ok:
    case True{}:
      IO.print("PASS " ++ name)
    case False{}:
      IO.die(Unit, 1, "FAIL " ++ name)

def monster(hp: U32, maximum: U32, dead: U32, timer: U32, kind: U32) -> M.Monsters.State:
  M.Monsters.State{7, kind, 1, 0, 20, 10, hp, maximum, 99, 4, dead, timer}

def state_ok(state: M.Monsters.State, ehp: U32, edead: U32, etimer: U32, eattack: U32, etarget: U32) -> Bool:
  match state:
    case M.Monsters.State{mid, kind, rare, zone, x, y, hp, maximum, target, attack, dead, timer}:
      Bool.and(U32.is_eq(mid, 7), Bool.and(U32.is_eq(hp, ehp), Bool.and(U32.is_eq(dead, edead), Bool.and(U32.is_eq(timer, etimer), Bool.and(U32.is_eq(attack, eattack), U32.is_eq(target, etarget))))))

def hit(name: String, result: M.Monsters.Hit, ehp: U32, edead: U32, etimer: U32, eattack: U32, etarget: U32, ekilled: Bool, edealt: U32) -> IO(Unit):
  match result:
    case M.Monsters.Hit{next, killed, dealt}:
      verdict(name, Bool.and(state_ok(next, ehp, edead, etimer, eattack, etarget), Bool.and(same(killed, ekilled), U32.is_eq(dealt, edealt))))

def phase_code(phase: M.Monsters.Phase) -> U32:
  match phase:
    case M.Monsters.Active{}:
      0
    case M.Monsters.Dormant{}:
      1
    case M.Monsters.Rebirth{}:
      2

def tick(name: String, result: M.Monsters.Tick, ehp: U32, edead: U32, etimer: U32, eattack: U32, etarget: U32, ephase: U32) -> IO(Unit):
  match result:
    case M.Monsters.Tick{next, phase}:
      verdict(name, Bool.and(state_ok(next, ehp, edead, etimer, eattack, etarget), U32.is_eq(phase_code(phase), ephase)))

def spawn_ok(state: M.Monsters.State, +expected: U32) -> Bool:
  match state:
    case M.Monsters.State{mid, kind, rare, zone, x, y, hp, maximum, target, attack, dead, timer}:
      Bool.and(U32.is_eq(hp, expected), Bool.and(U32.is_eq(maximum, expected), Bool.and(U32.is_eq(dead, 0), Bool.and(U32.is_eq(timer, 0), Bool.and(U32.is_eq(attack, 0), U32.is_eq(target, 0))))))

def KillInfo() -> Type:
  C.Bq.Pair.Pair(U32, (kind => C.Bq.Pair.Pair(U32, (rare => C.Bq.Pair.Pair(U32, (zone => U32))))))

def Strike() -> Type:
  C.Bq.Pair.Pair(List<&2, W.Bq.Mob>, (ms => C.Bq.Pair.Pair(Result<&1, &1, Unit, KillInfo>, (kill => U32))))

def metadata(info: KillInfo) -> Bool:
  match info:
    case Tuple{kind, rest}:
      match rest:
        case Tuple{rare, tail}:
          match tail:
            case Tuple{zone, mid}:
              Bool.and(U32.is_eq(kind, 0), Bool.and(U32.is_eq(rare, 1), Bool.and(U32.is_eq(zone, 0), U32.is_eq(mid, 7))))

def killed_once(result: Strike) -> IO(Unit):
  match result:
    case Tuple{monsters, rest}:
      match rest:
        case Tuple{kill, dealt}:
          match kill:
            case Fail{unit}:
              verdict("server lethal kill metadata", False{})
            case Done{info}:
              verdict("server lethal kill metadata", Bool.and(metadata(info), U32.is_eq(dealt, 20)))

def no_kill(result: Strike) -> IO(Unit):
  match result:
    case Tuple{monsters, rest}:
      match rest:
        case Tuple{kill, dealt}:
          match kill:
            case Fail{unit}:
              verdict("server repeated kill rejected", U32.is_eq(dealt, 0))
            case Done{info}:
              verdict("server repeated kill rejected", False{})

def strike_again(result: Strike) -> IO(Unit):
  match result:
    case Tuple{monsters, rest}:
      no_kill(W.Bq.strike_mob(monsters, 7, 999))

def ai_state(name: String, result: C.Bq.Pair.Pair(W.Bq.Mob, (m => Result<&1, &1, Unit, C.Bq.Pair.Pair(U32, (pid => U32))>)), expected_hp: U32, expected_dead: U32, expected_timer: U32, expected_attack: U32, expected_target: U32, expected_hit: Bool) -> IO(Unit):
  match result:
    case Tuple{monster, hit}:
      match hit:
        case Fail{unit}:
          verdict(name, Bool.and(state_ok(monster, expected_hp, expected_dead, expected_timer, expected_attack, expected_target), same(expected_hit, False{})))
        case Done{info}:
          verdict(name, Bool.and(state_ok(monster, expected_hp, expected_dead, expected_timer, expected_attack, expected_target), same(expected_hit, True{})))

def respawned_state(+monster: M.Monsters.State) -> IO(Unit):
  match monster:
    case M.Monsters.State{mid, kind, rare, zone, x, y, hp, maximum, target, attack, dead, timer}:
      verdict("server monster respawn", Bool.and(U32.is_eq(mid, 7), Bool.and(U32.is_eq(dead, 0), Bool.and(U32.is_eq(timer, 0), Bool.and(U32.is_eq(hp, maximum), U32.is_gt(hp, 0))))))

def ai_respawn(result: C.Bq.Pair.Pair(W.Bq.Mob, (m => Result<&1, &1, Unit, C.Bq.Pair.Pair(U32, (pid => U32))>))) -> IO(Unit):
  match result:
    case Tuple{monster, hit}:
      respawned_state(monster)

def main() -> IO(Unit):
  do IO<Unit>:
    Unit <- hit("monster nonlethal hit", M.Monsters.hit(monster(20, 20, 0, 0, 0), 19, 80), 1, 0, 0, 4, 99, False{}, 19)
    Unit <- hit("monster lethal hit", M.Monsters.hit(monster(20, 20, 0, 0, 0), 20, 80), 0, 1, 80, 0, 0, True{}, 20)
    Unit <- hit("monster overkill", M.Monsters.hit(monster(20, 20, 0, 0, 0), 4294967295, 80), 0, 1, 80, 0, 0, True{}, 20)
    Unit <- hit("monster dead hit no-op", M.Monsters.hit(monster(0, 20, 1, 17, 0), 999, 80), 0, 1, 17, 4, 99, False{}, 0)
    Unit <- tick("monster cooldown tick", M.Monsters.tick(monster(10, 20, 0, 0, 0)), 10, 0, 0, 3, 99, 0)
    Unit <- tick("Maw regeneration", M.Monsters.tick(monster(10, 100, 0, 0, 9)), 40, 0, 0, 3, 99, 0)
    Unit <- tick("Maw regeneration cap", M.Monsters.tick(monster(95, 100, 0, 0, 9)), 100, 0, 0, 3, 99, 0)
    Unit <- tick("monster respawn waits", M.Monsters.tick(monster(0, 20, 1, 2, 0)), 0, 1, 1, 4, 99, 1)
    Unit <- tick("monster respawn ready", M.Monsters.tick(monster(0, 20, 1, 1, 0)), 0, 1, 1, 4, 99, 2)
    Unit <- tick("boss stays dead", M.Monsters.tick(monster(0, 100, 1, 4294967295, 9)), 0, 1, 4294967295, 4, 99, 1)
    Unit <- verdict("positive monster initialization", spawn_ok(M.Monsters.spawn(7, 0, 0, 0, 20, 10, 20), 20))
    Unit <- verdict("zero maximum is normalized", spawn_ok(M.Monsters.spawn(7, 0, 0, 0, 20, 10, 0), 1))
    Unit <- killed_once(W.Bq.strike_mob([monster(20, 20, 0, 0, 0)], 7, 20))
    Unit <- strike_again(W.Bq.strike_mob([monster(20, 20, 0, 0, 0)], 7, 20))
    Unit <- ai_state("server permanent boss death", W.Bq.ai_mob(monster(0, 100, 1, 4294967295, 9), Nil{}, Nil{}, 0), 0, 1, 4294967295, 4, 99, False{})
    Unit <- ai_state("server monster wait", W.Bq.ai_mob(monster(0, 20, 1, 2, 0), Nil{}, Nil{}, 0), 0, 1, 1, 4, 99, False{})
    Unit <- ai_state("server live Maw regeneration", W.Bq.ai_mob(monster(10, 100, 0, 0, 9), Nil{}, Nil{}, 0), 40, 0, 0, 3, 0, False{})
    Unit <- ai_respawn(W.Bq.ai_mob(monster(0, 20, 1, 1, 0), Nil{}, Nil{}, 0))
    Unit <- ai_state("server monster cooldown blocks attack", W.Bq.ai_mob(monster(20, 20, 0, 0, 0), [Tuple{99, Tuple{21, 10}}], Nil{}, 0), 20, 0, 0, 3, 99, False{})
    Unit <- ai_state("server adjacent monster attacks", W.Bq.ai_mob(M.Monsters.State{7, 0, 1, 0, 20, 10, 20, 20, 99, 1, 0, 0}, [Tuple{99, Tuple{21, 10}}], Nil{}, 0), 20, 0, 0, 9, 99, True{})
    return Unit{}

#| PASS monster nonlethal hit
#| PASS monster lethal hit
#| PASS monster overkill
#| PASS monster dead hit no-op
#| PASS monster cooldown tick
#| PASS Maw regeneration
#| PASS Maw regeneration cap
#| PASS monster respawn waits
#| PASS monster respawn ready
#| PASS boss stays dead
#| PASS positive monster initialization
#| PASS zero maximum is normalized
#| PASS server lethal kill metadata
#| PASS server repeated kill rejected
#| PASS server permanent boss death
#| PASS server monster wait
#| PASS server live Maw regeneration
#| PASS server monster respawn
#| PASS server monster cooldown blocks attack
#| PASS server adjacent monster attacks
