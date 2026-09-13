import Base
import ./game.bend as G
import ./rewards.bend as R
import ./world.bend as W
import ./compat.bend as C

def hero(level: Nat, charm: G.Bq.Maybe(Nat)) -> G.Bq.Hero:
  G.Bq.Hero.Hero{Nil{}, Fail{Unit{}}, Fail{Unit{}}, Fail{Unit{}}, charm, 10n, level, 3n, 3n, 3n, 0n}

def count(hero: G.Bq.Hero, kind: U32) -> U32:
  match hero:
    case G.Bq.Hero.Hero{inv, wea, arm, hel, charm, gold, level, strength, agility, vitality, points}:
      W.Bq.bag_count(inv, kind)

def verdict(name: String, ok: Bool) -> IO(Unit):
  match ok:
    case True{}:
      IO.print("PASS " ++ name)
    case False{}:
      IO.die(Unit, 1, "FAIL " ++ name)

def check(name: String, +result: R.Rewards.Result, expected_level: U32, expected_xp: U32, expected_ups: U32, expected_max: U32) -> IO(Unit):
  match result:
    case R.Rewards.Result{h, xp, levels}:
      verdict(name, Bool.and(U32.is_eq(U32.from_nat(R.Rewards.level(h)), expected_level), Bool.and(U32.is_eq(xp, expected_xp), Bool.and(U32.is_eq(levels, expected_ups), U32.is_eq(R.Rewards.maximum(h, 4294967295), expected_max)))))

def from_world(result: C.Bq.Pair.Pair(G.Bq.Hero, (h => C.Bq.Pair.Pair(U32, (xp => U32))))) -> R.Rewards.Result:
  match result:
    case Tuple{h, rest}:
      match rest:
        case Tuple{xp, levels}:
          R.Rewards.Result{h, xp, levels}

def main() -> IO(Unit):
  do IO<Unit>:
    Unit <- check("XP below threshold", R.Rewards.gain(hero(1n, Fail{Unit{}}), 20, 4), 1, 24, 0, 35)
    Unit <- check("XP exact threshold", R.Rewards.gain(hero(1n, Fail{Unit{}}), 20, 5), 2, 0, 1, 37)
    Unit <- check("XP multiple levels and charm", R.Rewards.gain(hero(1n, Done{17n}), 0, 130), 3, 5, 2, 69)
    Unit <- check("XP level cap", R.Rewards.gain(hero(19n, Fail{Unit{}}), 0, 10000), 20, 975, 1, 73)
    Unit <- check("XP already capped", R.Rewards.gain(hero(20n, Fail{Unit{}}), 50, 10000), 20, 10050, 0, 73)
    Unit <- check("XP zero fuel", R.Rewards.go(0n, hero(1n, Fail{Unit{}}), 130, 7), 1, 130, 7, 35)
    Unit <- check("XP one-step budget", R.Rewards.go(1n, hero(1n, Fail{Unit{}}), 130, 0), 2, 105, 1, 37)
    Unit <- check("server XP adapter", from_world(W.Bq.gain_xp(hero(1n, Done{17n}), 0, 130)), 3, 5, 2, 69)
    Unit <- verdict("server maximum adapter", U32.is_eq(W.Bq.hero_maxhp(hero(3n, Done{17n})), 69))
    Unit <- verdict("server gold grant", U32.is_eq(U32.from_nat(G.Bq.hero_gold(W.Bq.hero_add_gold(hero(3n, Done{17n}), 100))), 110))
    Unit <- verdict("server item grant", U32.is_eq(count(W.Bq.hero_add_item(hero(3n, Done{17n}), 13), 13), 1))
    Unit <- verdict("side quest potion grant", U32.is_eq(count(W.Bq.sideq_reward(hero(3n, Done{17n}), 0), 0), 3))
    Unit <- verdict("side quest first item", U32.is_eq(count(W.Bq.sideq_reward(hero(3n, Done{17n}), 1), 13), 1))
    Unit <- verdict("side quest second item", U32.is_eq(count(W.Bq.sideq_reward(hero(3n, Done{17n}), 2), 16), 1))
    Unit <- verdict("side quest retains health charm", U32.is_eq(W.Bq.hero_maxhp(W.Bq.sideq_reward(hero(3n, Done{17n}), 0)), 69))
    return Unit{}

#| PASS XP below threshold
#| PASS XP exact threshold
#| PASS XP multiple levels and charm
#| PASS XP level cap
#| PASS XP already capped
#| PASS XP zero fuel
#| PASS XP one-step budget
#| PASS server XP adapter
#| PASS server maximum adapter
#| PASS server gold grant
#| PASS server item grant
#| PASS side quest potion grant
#| PASS side quest first item
#| PASS side quest second item
#| PASS side quest retains health charm
