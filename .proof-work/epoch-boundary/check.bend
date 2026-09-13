import Base
import ./game.bend as Game
import ./compat.bend as C
import ./support.bend as Support

# Funded purchase, rejected second purchase, rejected empty-inventory quaff,
# both damage caps, and movement at the left and right map boundaries.
def verdict(ok: Bool, name: String) -> IO(Unit):
  match ok:
    case True{}:
      IO.print("PASS " ++ name)
    case False{}:
      IO.die(Unit, 1, "FAIL " ++ name)

def check(name: String, actual: U32, expected: U32) -> IO(Unit):
  verdict(U32.is_eq(actual, expected), name)

def main() -> IO(Unit):
  do IO<Unit>:
    Unit <- check("purchase", U32.from_nat(Game.Bq.hero_gold(Game.Bq.hero_step(       Game.Bq.HOp.Buy{0n}, Game.Bq.fresh_hero))), 2)
    Unit <- check("insufficient gold", U32.from_nat(Game.Bq.hero_gold(Game.Bq.hero_step(       Game.Bq.HOp.Buy{0n}, Game.Bq.hero_step(         Game.Bq.HOp.Buy{0n}, Game.Bq.fresh_hero)))), 2)
    Unit <- check("empty quaff", U32.from_nat(Game.Bq.hero_gold(Game.Bq.hero_step(       Game.Bq.HOp.Quaff{}, Game.Bq.fresh_hero))), 10)
    Unit <- check("player damage cap", U32.from_nat(Game.Bq.damage(U32.to_nat(1000), 1n, 0n, True{})), 999)
    Unit <- check("monster damage cap", U32.from_nat(Game.Bq.mob_damage(100n, 0n, 10n)), 9)
    Unit <- check("left boundary", U32.from_nat(Game.Bq.walk_x(30n, 0n, Game.Bq.Dir.DL{})), 0)
    Unit <- check("right boundary", U32.from_nat(Game.Bq.walk_x(30n, 29n, Game.Bq.Dir.DR{})), 29)
    Unit <- check("UTF-8 round trip", C.Bq.bit(Support.Bq.String.eq(
      C.Bq.Bytes.to_string(C.Bq.Bytes.from_string(C.Bq.text("café 🌲"))), C.Bq.text("café 🌲"))), 1)
    return Unit{}

#| PASS purchase
#| PASS insufficient gold
#| PASS empty quaff
#| PASS player damage cap
#| PASS monster damage cap
#| PASS left boundary
#| PASS right boundary
#| PASS UTF-8 round trip
