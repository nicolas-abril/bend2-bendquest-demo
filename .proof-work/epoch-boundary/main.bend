import Base
import ./bendquest.bend as Game
import ./proofs.bend as Proofs
import ./compat.bend as C

def main() -> IO(Unit):
  do IO<Unit>:
    Unit <- Game.Bq.start
    C.Bq.IO.finish()
